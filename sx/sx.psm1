$script:ConfigPath = Join-Path $env:USERPROFILE '.ssh\sx.config.yaml'

function Get-SxConfig {
    if (-not (Test-Path $script:ConfigPath)) {
        Write-Error "Config not found: $script:ConfigPath"
        return $null
    }
    if (-not (Get-Module -Name 'powershell-yaml')) {
        Import-Module powershell-yaml -ErrorAction Stop
    }
    $raw = Get-Content -Raw -Path $script:ConfigPath -Encoding UTF8
    return ConvertFrom-Yaml -Yaml $raw -Ordered
}

function Get-SxSessionNames {
    try {
        $cfg = Get-SxConfig
    } catch {
        return @()
    }
    if ($null -eq $cfg -or $null -eq $cfg.sessions) { return @() }
    return @($cfg.sessions.Keys | Sort-Object)
}

function Resolve-SxPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    if ($Path.StartsWith('~')) {
        $rest = $Path.Substring(1).TrimStart('/', '\')
        return Join-Path $env:USERPROFILE $rest
    }
    return $Path
}

function Resolve-SxKey {
    param($KeyValue, $KeyAliases)
    if ([string]::IsNullOrWhiteSpace($KeyValue)) {
        # No key on session — prefer `keys.default` from config, else fall
        # back to the conventional ~/.ssh/id_rsa.
        if ($KeyAliases -and $KeyAliases.Contains('default')) {
            return Resolve-SxPath $KeyAliases['default']
        }
        $default = Join-Path $env:USERPROFILE '.ssh\id_rsa'
        if (Test-Path $default) { return $default }
        return $null
    }
    if ($KeyAliases -and $KeyAliases.Contains($KeyValue)) {
        return Resolve-SxPath $KeyAliases[$KeyValue]
    }
    return Resolve-SxPath $KeyValue
}

function Resolve-SxColor {
    param([string]$Color, [string]$Name, $ColorConfig)
    if (-not [string]::IsNullOrWhiteSpace($Color)) { return $Color }
    if (-not $ColorConfig) { return $null }

    foreach ($rule in $ColorConfig.match) {
        $pattern = $rule.pattern
        if (-not [string]::IsNullOrWhiteSpace($pattern) -and $Name.Contains($pattern)) {
            return $rule.color
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ColorConfig.default)) {
        return $ColorConfig.default
    }
    return $null
}

function Show-SxSessionList {
    param($Sessions)
    $rows = @()
    foreach ($k in ($Sessions.Keys | Sort-Object)) {
        $s = $Sessions[$k]
        $port = if ($s.port) { $s.port } else { 22 }
        $rows += [PSCustomObject]@{
            Name = $k
            Host = $s.host
            User = $s.user
            Port = $port
        }
    }
    $rows | Format-Table -AutoSize
}

function sx {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    $cfg = Get-SxConfig
    if ($null -eq $cfg) { return }

    $sessions = $cfg.sessions
    if ($null -eq $sessions) {
        Write-Warning "No 'sessions' defined in $script:ConfigPath."
        return
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Show-SxSessionList -Sessions $sessions
        return
    }

    if (-not $sessions.Contains($Name)) {
        Write-Error "Session '$Name' not found. Run 'sx' to list available sessions."
        return
    }

    $s = $sessions[$Name]
    $sshHost = $s.host
    if ([string]::IsNullOrWhiteSpace($sshHost)) {
        Write-Error "Session '$Name' has no 'host' defined."
        return
    }

    $port = if ($s.port) { [int]$s.port } else { 22 }
    $user = $s.user
    $keyField = $s.'ssh-key'
    $keyPath = Resolve-SxKey -KeyValue $keyField -KeyAliases $cfg.keys
    $color = Resolve-SxColor -Color $s.color -Name $Name -ColorConfig $cfg.colors

    $userHost = if (-not [string]::IsNullOrWhiteSpace($user)) { "$user@$sshHost" } else { $sshHost }
    $sshArgs = @($userHost)
    if ($port -ne 22) { $sshArgs += @('-p', "$port") }
    if ($keyPath) {
        if (Test-Path $keyPath) {
            $sshArgs += @('-i', $keyPath)
        } else {
            Write-Warning "SSH key not found at: $keyPath"
        }
    }

    $inWT = -not [string]::IsNullOrWhiteSpace($env:WT_SESSION)
    if (-not $inWT) {
        # Not running under Windows Terminal — just run ssh inline.
        $oldTitle = $host.UI.RawUI.WindowTitle
        $host.UI.RawUI.WindowTitle = $Name
        try { & ssh.exe @sshArgs } finally { $host.UI.RawUI.WindowTitle = $oldTitle }
        return
    }

    # Open a new tab in the SAME WT window, focused. wt new-tab focuses
    # the new tab on creation, so the SSH session takes focus immediately.
    $wtArgs = @('-w', '0', 'new-tab', '--title', $Name, '--suppressApplicationTitle')
    if ($color) { $wtArgs += @('--tabColor', $color) }
    $wtArgs += @('ssh.exe') + $sshArgs
    & wt.exe @wtArgs

    $closeCurrent = $false
    if ($cfg.options) {
        $closeCurrent = [bool]$cfg.options.'close-current-tab'
    }
    if ($closeCurrent) {
        [Environment]::Exit(0)
    }
}

function Find-WinSCP {
    $cmd = Get-Command winscp.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $candidates = @(
        "$env:ProgramFiles\WinSCP\WinSCP.exe",
        "${env:ProgramFiles(x86)}\WinSCP\WinSCP.exe",
        "$env:LOCALAPPDATA\Programs\WinSCP\WinSCP.exe"
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) { return $c }
    }
    return $null
}

function Get-WinScpPpkKey {
    param([string]$KeyPath, [string]$WinScpExe)
    if ([string]::IsNullOrWhiteSpace($KeyPath)) { return $null }
    if ($KeyPath -like '*.ppk') { return $KeyPath }
    if (-not (Test-Path $KeyPath)) { return $null }

    # Cache converted keys in ~/.ssh/.sxp/ so we never write next to the
    # user's original keys.
    $cacheDir = Join-Path $env:USERPROFILE '.ssh\.sxp'
    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
    }
    $ppk = Join-Path $cacheDir ([System.IO.Path]::GetFileName($KeyPath) + '.ppk')

    $needConvert = $true
    if (Test-Path $ppk) {
        if ((Get-Item $ppk).LastWriteTime -ge (Get-Item $KeyPath).LastWriteTime) {
            $needConvert = $false
        }
    }

    if ($needConvert) {
        # Prefer WinSCP.com (console) so /keygen doesn't pop a GUI window.
        $com = [System.IO.Path]::ChangeExtension($WinScpExe, '.com')
        $tool = if (Test-Path $com) { $com } else { $WinScpExe }
        Write-Host "sxp: converting $KeyPath -> $ppk (one-time, via WinSCP /keygen)" -ForegroundColor Cyan
        & $tool /keygen $KeyPath /output=$ppk | Out-Null
        if (-not (Test-Path $ppk)) {
            Write-Warning "Key conversion failed; WinSCP will fall back to a password prompt."
            return $null
        }
    }
    return $ppk
}

function sxp {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Name
    )

    $cfg = Get-SxConfig
    if ($null -eq $cfg) { return }

    $sessions = $cfg.sessions
    if ($null -eq $sessions) {
        Write-Warning "No 'sessions' defined in $script:ConfigPath."
        return
    }

    if ([string]::IsNullOrWhiteSpace($Name)) {
        Show-SxSessionList -Sessions $sessions
        return
    }

    if (-not $sessions.Contains($Name)) {
        Write-Error "Session '$Name' not found. Run 'sxp' to list available sessions."
        return
    }

    $winscp = Find-WinSCP
    if (-not $winscp) {
        Write-Error "WinSCP not found. Install from https://winscp.net or run: winget install WinSCP.WinSCP"
        return
    }

    $s = $sessions[$Name]
    $sshHost = $s.host
    if ([string]::IsNullOrWhiteSpace($sshHost)) {
        Write-Error "Session '$Name' has no 'host' defined."
        return
    }
    $port = if ($s.port) { [int]$s.port } else { 22 }
    $user = $s.user
    $keyField = $s.'ssh-key'
    $keyPath = Resolve-SxKey -KeyValue $keyField -KeyAliases $cfg.keys

    $url = if (-not [string]::IsNullOrWhiteSpace($user)) {
        "sftp://${user}@${sshHost}:${port}/"
    } else {
        "sftp://${sshHost}:${port}/"
    }

    $wsArgs = @($url)
    if ($keyPath -and (Test-Path $keyPath)) {
        $ppk = Get-WinScpPpkKey -KeyPath $keyPath -WinScpExe $winscp
        if ($ppk) { $wsArgs += "-privatekey=$ppk" }
    }

    & $winscp @wsArgs
}

$completer = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    $names = Get-SxSessionNames
    foreach ($n in $names) {
        if ($n -like "$wordToComplete*") {
            [System.Management.Automation.CompletionResult]::new($n, $n, 'ParameterValue', $n)
        }
    }
}
Register-ArgumentCompleter -CommandName sx  -ParameterName Name -ScriptBlock $completer
Register-ArgumentCompleter -CommandName sxp -ParameterName Name -ScriptBlock $completer

Export-ModuleMember -Function sx, sxp
