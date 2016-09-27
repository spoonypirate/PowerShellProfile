#requires -Version 2 -Modules posh-git

function Write-Theme
{
    param(
        [bool]
        $lastCommandFailed,
        [string]
        $with
    )

    $prompt = (Get-Location).Path.Replace($HOME,'~')
    if ($prompt -eq '~')
    {
        $prompt = $prompt + '\'
    }

    Write-Prompt -Object $prompt -ForegroundColor $sl.PromptForegroundColor
    
    $status = Get-VCSStatus
    if ($status)
    {
        $vcsInfo = Get-VcsInfo -status ($status)
        $info = $vcsInfo.VcInfo
        Write-Prompt -Object " $info" -ForegroundColor $vcsInfo.BackgroundColor
    }
    
    #check for elevated prompt
    If (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator'))
    {
        Write-Prompt -Object " $($sl.ElevatedSymbol)" -ForegroundColor $sl.AdminIconForegroundColor
    }

    #check the last command state and indicate if failed
    If ($lastCommandFailed)
    {
        Write-Prompt -Object " $($sl.FailedCommandSymbol)" -ForegroundColor $sl.CommandFailedIconForegroundColor
    }

    $timeStamp = Get-Date -Format T
    $clock = [char]::ConvertFromUtf32(0x25F7)
    $timestamp = "$clock $timeStamp"

    if ($status)
    {
        $timeStamp = Get-TimeSinceLastCommit
    }

    Set-CursorForRightBlockWrite -textLength $timestamp.Length
    Write-Host $timeStamp -ForegroundColor $sl.PromptBackgroundColor
  
    if ($with)
    {
        Write-Prompt -Object "$($with.ToUpper()) " -BackgroundColor $sl.WithBackgroundColor -ForegroundColor $sl.WithForegroundColor
    }

    $promptSymbol = [char]::ConvertFromUtf32(0x25B6)
    Write-Prompt -Object "$promptSymbol" -ForegroundColor $sl.PromptBackgroundColor
}

function Get-TimeSinceLastCommit
{
    return (git log --pretty=format:'%cr' -1)
}

$sl = $global:ThemeSettings #local settings
$sl.PromptForegroundColor = [ConsoleColor]::DarkBlue
$sl.WithForegroundColor = [ConsoleColor]::DarkRed
$sl.PromptHighlightColor = [ConsoleColor]::DarkBlue
$sl.WithBackgroundColor = [ConsoleColor]::Magenta
$sl.PromptSymbolColor = [ConsoleColor]::White