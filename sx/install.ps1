# sx installer
#
# Installs the `sx` PowerShell module and its dependency (`powershell-yaml`).
# Safe to re-run; existing config is never overwritten.
#
# Usage:
#   .\install.ps1
#
# Steps performed:
#   1. Install NuGet provider (if missing)
#   2. Trust PSGallery
#   3. Install powershell-yaml (if missing)
#   4. Copy sx.psm1 / sx.psd1 to user's PowerShell Modules folder
#   5. Copy sx.config.example.yaml -> ~/.ssh/sx.config.yaml (only if absent)
#   6. Add `Import-Module sx` to current $PROFILE (if missing)

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step { param([string]$msg) Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$msg) Write-Host "    $msg" -ForegroundColor Green }
function Write-Skip { param([string]$msg) Write-Host "    $msg" -ForegroundColor DarkGray }

# --- 1. NuGet provider --------------------------------------------------------
Write-Step 'Checking NuGet provider'
$nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
if (-not $nuget -or $nuget.Version -lt [version]'2.8.5.201') {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    Write-Ok 'NuGet provider installed.'
} else {
    Write-Skip "NuGet provider already present ($($nuget.Version))."
}

# --- 2. Trust PSGallery -------------------------------------------------------
Write-Step 'Ensuring PSGallery is trusted'
$gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
if ($gallery -and $gallery.InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Write-Ok 'PSGallery set to Trusted.'
} else {
    Write-Skip 'PSGallery already trusted.'
}

# --- 3. powershell-yaml -------------------------------------------------------
Write-Step 'Checking powershell-yaml module'
$yaml = Get-Module -ListAvailable -Name powershell-yaml | Select-Object -First 1
if (-not $yaml) {
    Install-Module powershell-yaml -Scope CurrentUser -Force -AllowClobber
    $yaml = Get-Module -ListAvailable -Name powershell-yaml | Select-Object -First 1
    Write-Ok "powershell-yaml installed ($($yaml.Version))."
} else {
    Write-Skip "powershell-yaml already installed ($($yaml.Version))."
}

# --- 4. Copy sx module --------------------------------------------------------
Write-Step 'Installing sx module'
$userModuleRoot = ($env:PSModulePath -split ';') |
    Where-Object { $_ -like "$env:USERPROFILE*" } |
    Select-Object -First 1
if (-not $userModuleRoot) {
    $userModuleRoot = Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Modules'
}
$sxDest = Join-Path $userModuleRoot 'sx'
if (-not (Test-Path $sxDest)) {
    New-Item -ItemType Directory -Path $sxDest -Force | Out-Null
}
Copy-Item -Path (Join-Path $here 'sx.psm1') -Destination $sxDest -Force
Copy-Item -Path (Join-Path $here 'sx.psd1') -Destination $sxDest -Force
Write-Ok "Module copied to $sxDest"

# --- 5. Example config --------------------------------------------------------
Write-Step 'Setting up config file'
$sshDir = Join-Path $env:USERPROFILE '.ssh'
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
}
$configDest = Join-Path $sshDir 'sx.config.yaml'
if (Test-Path $configDest) {
    Write-Skip "Config already exists, leaving it alone: $configDest"
} else {
    Copy-Item -Path (Join-Path $here 'sx.config.example.yaml') -Destination $configDest
    Write-Ok "Example config written to $configDest"
}

# --- 6. Profile ---------------------------------------------------------------
Write-Step 'Wiring up $PROFILE'
$profilePath = $PROFILE
$profileDir = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $profilePath)) {
    Set-Content -Path $profilePath -Value "Import-Module sx`r`n" -Encoding UTF8
    Write-Ok "Created $profilePath with Import-Module sx"
} else {
    $existing = Get-Content -Raw -Path $profilePath
    if ($existing -match '(?m)^\s*Import-Module\s+sx\b') {
        Write-Skip 'Import-Module sx already in $PROFILE.'
    } else {
        Add-Content -Path $profilePath -Value "`r`nImport-Module sx`r`n"
        Write-Ok "Appended Import-Module sx to $profilePath"
    }
}

Write-Host ''
Write-Host 'Done. Open a new PowerShell session, then:' -ForegroundColor Green
Write-Host '  - Edit ~/.ssh/sx.config.yaml with your sessions'
Write-Host '  - Run `sx` to list sessions, or `sx <name>` to connect'
