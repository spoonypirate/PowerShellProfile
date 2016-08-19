Push-Location (Split-Path -Path $MyInvocation.MyCommand.Definition -Parent)

# Load posh-git-vagrant-status module from current directory
Import-Module .\posh-git-vagrant-status

# Set up a simple prompt, adding the git prompt parts inside git repos
function global:prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

    Write-Host($pwd.ProviderPath) -nonewline

    Write-VcsStatus
    #
    # Vagrant Status:
    #
    # Comment out/in which ever style of status you would like dont leave both
    # commented in or out.
    #
    # Examples:
    #
    # Simple: [-] [^]
    # Detailed: [-] [D:0 R:1]
    #
    #Write-VagrantStatusSimple
    Write-VagrantStatusDetailed

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "> "
}

Enable-GitColors

Pop-Location

Start-SshAgent -Quiet
