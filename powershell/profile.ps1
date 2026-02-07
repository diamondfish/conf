# -----------------------------------------------------------------------------
# Misc
# -----------------------------------------------------------------------------
# Enable UTF-8 support so the icons/borders look clean
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# -----------------------------------------------------------------------------
# Chocolatey
# https://chocolatey.org/install
# -----------------------------------------------------------------------------
# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
function ssh-conero { ssh nanto@178.62.234.27 }

# -----------------------------------------------------------------------------
# Terminal Icons
# https://github.com/devblackops/Terminal-Icons
# Install-Module -Name Terminal-Icons -Repository PSGallery
# -----------------------------------------------------------------------------
Import-Module -Name Terminal-Icons

# -----------------------------------------------------------------------------
# Predictors
# https://learn.microsoft.com/en-us/powershell/scripting/learn/shell/using-predictors?view=powershell-7.5
# Install-PSResource -Name PSReadLine
# -----------------------------------------------------------------------------
Set-PSReadLineOption -PredictionViewStyle ListView

# -----------------------------------------------------------------------------
# Simplified pwd (and cwd) output
# -----------------------------------------------------------------------------
# Remove the default 'pwd' alias so we can redefine it
Remove-Item -Path Alias:\pwd -ErrorAction SilentlyContinue

# Define the primary function
function Get-CurrentPath {
  (Get-Location).Path
}

# Create aliases for both 'pwd' and 'cwd'
New-Alias -Name pwd -Value Get-CurrentPath
New-Alias -Name cwd -Value Get-CurrentPath

# -----------------------------------------------------------------------------
# Functions to handle moving up in the directory tree
# -----------------------------------------------------------------------------
function .. {
  # Go up N levels
  param($n = 1)

  # If user provides something that isn't a number, default to 1
  if ($n -isnot [int]) {
    try { $n = [int]$n } catch { $n = 1 }
  }

  $path = ".."
  for ($i = 1; $i -lt $n; $i++) {
    $path += "\.."
  }

  # Resolve-Path checks if the result is valid
  # If N is too high, it will just land at the Root (C:\) and stop
  Set-Location $path
}
function ... { Set-Location ..\.. }     # Go up 2 levels
function .... { Set-Location ..\..\.. } # Go up 3 levels

# -----------------------------------------------------------------------------
# Custom SSH function to update the powershell title
# -----------------------------------------------------------------------------
function ssh {
  param([string]$target)

  # Change title to show we are remote
  $oldTitle = $host.ui.RawUI.WindowTitle
  $host.ui.RawUI.WindowTitle = "SSH $target"

  # Run the actual ssh command
  # Avoid infinite loop due to the function being called ssh. 
  # Using the full path tells PowerShell to run the command from disk.
  # The "&" is the call operator that let's us call a string.
  & C:\Windows\System32\OpenSSH\ssh.exe $target

  # Restore the title when we come back
  $host.ui.RawUI.WindowTitle = $oldTitle
}

# -----------------------------------------------------------------------------
# Prompt styling
# $ <current_dir> input
# -----------------------------------------------------------------------------
function Prompt {
  $currentDir = Split-Path -Leaf (Get-Location)
  Write-Host "$ " -NoNewline -ForegroundColor Green
  Write-Host "$currentDir" -NoNewline -ForegroundColor Cyan
  $host.ui.RawUI.WindowTitle = "$currentDir"
  return " "
}

# -----------------------------------------------------------------------------
# Zoxide
# winget install sharkdp.fd
# winget install ajeetdsouza.zoxide
# -----------------------------------------------------------------------------
# Zoxide initialization. Should be at the end according to the docs.
Invoke-Expression (& { (zoxide init powershell | Out-String) })
