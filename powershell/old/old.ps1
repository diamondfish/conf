####		$cur = $(Get-Location).Path
####		
####		function prompt3 {
####			$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
####			###$cwd = Get-Location
####			$cwd = $(Get-Location).Path
####		
####			$dirname = Split-Path -Path $pwd -Leaf
####		
####			$host.ui.RawUI.WindowTitle = "$cwd"
####		
####			$ESC = [char]27
####			$CSG = "$ESC[92m" # green
####			$CS = "$ESC[36m"  #cyan
####			$CE = "$ESC[0m"
####		
####			$prompt = "$dirname "
####		
####			#return "$CSG$user$CE@$CS$dirname$CE$ "
####		
####		# 	if ($cur -cne $cwd) {
####		#		Write-Host "$cwd" -ForegroundColor Cyan
####		#		$cur = cwd
####		#	}
####			#echo "$cwd`n"
####			#echo "`n"
####			return "$cwd`n`n$ "
####		}
####		
####		function prompt2 
####		{  
####			return "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) "  
####		}
##
##
##
##    # Initialize a variable to track the last path
##    $script:lastPath = ""
##
##    function prompt {
##        # Get the current directory path
##        $currentPath = $(Get-Location).Path
##        $dirname = Split-Path -Path $pwd -Leaf
##
##        $host.ui.RawUI.WindowTitle = "$currentPath"
##
##        # Check if the path has changed since the last prompt
##        if ($currentPath -ne $script:lastPath) {
##            # Update the last path variable
##            $script:lastPath = $currentPath
##
##            # Write the current path in white text on a black background
##            Write-Host "`n$currentPath" -ForegroundColor Cyan
##        }
##
##        # Output the prompt character '$' without a newline
##        Write-Host '$' -ForegroundColor Green -NoNewline
##
##        # Return an empty string to avoid default prompt appearance
##        return " "
##    }
##
##
##clear

##oh-my-posh init pwsh | Invoke-Expression
##oh-my-posh init pwsh --config "C:\Users\coner\Documents\WindowsPowerShell\multiverse-neon.omp.json" | Invoke-Expression

## oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.omp.json' | Invoke-Expression
## oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/multiverse-neon.omp.json' | Invoke-Expression

#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/atomic.omp.json" | Invoke-Expression
#oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH/jandedobbeleer.omp.json" | Invoke-Expression

#oh-my-posh init pwsh --config "C:\Users\coner\Documents\WindowsPowerShell\mytheme-tight.omp.json" | Invoke-Expression

#clear

# Set-PSReadLineOption -PredictionViewStyle InlineView
# Set-PSReadLineOption -PredictionViewStyle ListView
# Install-Module -Name Terminal-Icons -Repository PSGallery

#echo "Loaded oh-my-posh default profile"
#if ($env:vscode) {
#    Write-Host "Running inside VS Code (vscode=$env:vscode)"
#    # Add additional configurations or commands for VS Code here
#} else {
#    Write-Host "Not running inside VS Code"
#    # Add configurations or commands for other environments here
#}