#requires -Version 2 -Modules posh-git

function Write-Theme
{
    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )
    
    # write # and space
    Write-Prompt -Object '#' -ForegroundColor $sl.PromptHighlightColor
    # write user
    $user = [Environment]::UserName
    Write-Prompt -Object " $user" -ForegroundColor $sl.PromptHighlightColor
    # write at (devicename)
    $device = $env:computername
    Write-Prompt -Object " at" -ForegroundColor $sl.PromptForegroundColor
    Write-Prompt -Object " $device" -ForegroundColor $sl.GitDefaultColor
    # write in (folder)
    Write-Prompt -Object " in" -ForegroundColor $sl.PromptForegroundColor
    $prompt = (Get-Location).Path.Replace($HOME,'~')
    Write-Prompt -Object " $prompt" -ForegroundColor $sl.AdminIconForegroundColor
    # write on (git:branchname status)    
    $status = Get-VCSStatus
    if ($status)
    {
        $sl.GitBranchSymbol = ''
        $themeInfo = Get-VcsInfo -status ($status)
        Write-Prompt -Object ' on git:' -ForegroundColor $sl.PromptForegroundColor
        Write-Prompt -Object "$($themeInfo.VcInfo) " -ForegroundColor $themeInfo.BackgroundColor 
    }
    # write [time]
    $timeStamp = Get-Date -Format T
    Write-Host " [$timeStamp]" -ForegroundColor $sl.PromptForegroundColor
    # check for elevated prompt
    If (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
    {
        Write-Prompt -Object "$($sl.ElevatedSymbol) " -ForegroundColor $sl.AdminIconForegroundColor
    }
    # check the last command state and indicate if failed
    $foregroundColor = $sl.PromptHighlightColor
    If ($lastCommandFailed)
    {
        $foregroundColor = $sl.CommandFailedIconForegroundColor
    }

    if ($with)
    {
        Write-Prompt -Object "$($with.ToUpper()) " -BackgroundColor $sl.WithBackgroundColor -ForegroundColor $sl.WithForegroundColor
    }

    $promptSymbol = [char]::ConvertFromUtf32(0x279C)
    Write-Prompt -Object "$promptSymbol" -ForegroundColor $foregroundColor
}

function Get-TimeSinceLastCommit
{
    return (git log --pretty=format:'%cr' -1)
}

$sl = $global:ThemeSettings #local settings
$sl.PromptHighlightColor = [ConsoleColor]::DarkBlue
$sl.PromptForegroundColor = [ConsoleColor]::White
$sl.PromptHighlightColor = [ConsoleColor]::DarkBlue
$sl.WithForegroundColor = [ConsoleColor]::DarkRed
$sl.WithBackgroundColor = [ConsoleColor]::Magenta