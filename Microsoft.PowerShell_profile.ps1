<# 
 This whole profile is largely Joel Bennett's baby
 Original found here: http://poshcode.org/6062
 Features
 - History persistence between sessions
 - Some custom colors
 - Random quotes
 - Fun session banner
 - Several helper functions/scripts for such things as connectin to o365 or PowerCLI
 - Press and hold either Shift key while the session starts to display verbose output
 If you make changes to this then you probably want to re-sign it as well. The installer script accompanying this profile should have created a self-signed
 certificate which can be used with the Scripts\Set-ProfileScriptSignature.ps1 included with this profile as well. This script will re-sign ALL scripts in your
 profile (Consider yourself warned!) if run without parameters.
#>
trap { Write-Warning ($_.ScriptStackTrace | Out-String) }

##  Some variables for later (some also get removed from memory at the end of this profile loading)
$PersistentHistoryCount = 500
$QuoteDir = Join-Path (Split-Path $Profile -parent) "Data"

##  This timer is used by Trace-Message, I want to start it immediately
$Script:TraceVerboseTimer = New-Object System.Diagnostics.Stopwatch
$Script:TraceVerboseTimer.Start()

##  PS5 introduced PSReadLine, which chokes in non-console shells, so I snuff it.
try {
    $NOCONSOLE = $FALSE
    [System.Console]::Clear()
}
catch {
    $NOCONSOLE = $TRUE
}

##  If your PC doesn't have this set already, someone could tamper with this script...
#   but at least now, they can't tamper with any of the modules/scripts that I auto-load!
Set-ExecutionPolicy AllSigned Process

if ((Get-ExecutionPolicy -list | Where {$_.Scope -eq 'LocalMachine'}).ExecutionPolicy -ne 'AllSigned') {
    Write-Warning 'Execution policy was set to AllSigned for this process but is not set to AllSigned for the LocalMachine. '
    Write-Warning 'What this means is that this profile could be tampered with and you might never know!'
    pause
}

##  Ok, now import environment so we have PSProcessElevated, Trace-Message, and other custom functions we use later
#   The others will get loaded automatically, but it's faster to load them explicitly
Import-Module $PSScriptRoot\Modules\Environment, Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility

##  Check SHIFT state ASAP at startup so I can use that to control verbosity :)
Add-Type -Assembly PresentationCore, WindowsBase
try {
    $global:SHIFTED = [System.Windows.Input.Leopard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -OR
                      [System.Windows.Input.Leopard]::IsKeyDown([System.Windows.Input.Key]::RightShift)
}
catch {
    $global:SHIFTED = $false
}
if($SHIFTED) {
    $VerbosePreference = "Continue"
}

##  Fix colors before anything gets output.
if($Host.Name -eq "ConsoleHost") {
    $Host.PrivateData.ErrorForegroundColor    = "DarkRed"
    $Host.PrivateData.WarningForegroundColor  = "DarkYellow"
    $Host.PrivateData.DebugForegroundColor    = "Green"
    $Host.PrivateData.VerboseForegroundColor  = "Cyan"
    $Host.PrivateData.ProgressForegroundColor = "Yellow"
    $Host.PrivateData.ProgressBackgroundColor = "DarkMagenta"

}
elseif($Host.Name -eq "Windows PowerShell ISE Host") {
    $Host.PrivateData.ErrorForegroundColor    = "DarkRed"
    $Host.PrivateData.WarningForegroundColor  = "Gold"
    $Host.PrivateData.DebugForegroundColor    = "Green"
    $Host.PrivateData.VerboseForegroundColor  = "Cyan"
}

# First call to Trace-Message, pass in our TraceTimer that I created at the top to make sure we time EVERYTHING.
Trace-Message "Microsoft.PowerShell.* Modules Imported" -Stopwatch $TraceVerboseTimer

## Set the profile directory first, so we can refer to it from now on.
Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

##  Add additional items to your path. Modify this to suit your needs. 
#   We do need the Scripts directory for the rest of this profile script to run though so this first one is essential to add.
[string[]]$folders = Get-ChildItem $ProfileDir\Script[s] -Directory | % FullName

## Developer tools things ...
# $folders += [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
## MSBuild is now in 'C:\Program Files (x86)\MSBuild\{version}'
#$folders += Set-AliasToFirst -Alias "msbuild" -Path 'C:\Program Files (x86)\MSBuild\*\Bin\MsBuild.exe' -Description "Visual Studio's MsBuild" -Horse -Passthru
#$folders += Set-AliasToFirst -Alias "merge" -Path "C:\Program*Files*\Perforce\p4merge.exe","C:\Program*Files*\DevTools\Perforce\p4merge.exe" -Description "Perforce" -Horse -Passthru
#$folders += Set-AliasToFirst -Alias "tf" -Path "C:\Program*Files*\*Visual?Studio*\Common7\IDE\TF.exe", "C:\Program*Files*\DevTools\*Visual?Studio*\Common7\IDE\TF.exe" -Description "Visual Studio" -Horse -Passthru
#$folders += Set-AliasToFirst -Alias "Python","Python2","py2" -Path "C:\Python2*\python.exe", "D:\Python2*\python.exe" -Description "Python 2.x" -Horse -Passthru
#$folders += Set-AliasToFirst -Alias "Python3","py3" -Path "C:\Python3*\python.exe", "D:\Python3*\python.exe" -Description "Python 3.x" -Horse -Passthru
#Set-AliasToFirst -Alias "iis","iisexpress" -Path 'C:\Progra*\IIS*\IISExpress.exe' -Description "Personal Profile Alias"
#Trace-Message "Development aliases set"
if ($SHIFTED) {
    Trace-Message "Path before updates: "
    $($ENV:Path -split ';') | Foreach {
        Trace-Message " -- $($_)"
    }
}

$ENV:PATH = Select-UniquePath $folders ${Env:Path}

if ($SHIFTED) {
    Trace-Message "Path AFTER updates: "
    $($ENV:Path -split ';') | Foreach {
        Trace-Message " -- $($_)"
    }
}

##  Additional module directories to search for loading modules with Import-Module
$Env:PSModulePath = Select-UniquePath "$ProfileDir\Modules",(Get-SpecialFolder *Modules -Value),${Env:PSModulePath}
Trace-Message "PSModulePath Updated "


##  Custom aliases if you want them (some examples commented out)
#Set-Alias   say Speech\Out-Speech         -Option Constant, ReadOnly, AllScope -Description "Personal Profile Alias"
#Set-Alias   gph Get-PerformanceHistory    -Option Constant, ReadOnly, AllScope -Description "Personal Profile Alias"

##  Start sessions in the profile directory. 
#   If you need to go to the prior directory just run pop-location right after starting powershell
if($ProfileDir -ne (Get-Location)) {
   Push-Location $ProfileDir
}

##  Add some psdrives if you want them
New-PSDrive Documents FileSystem (Get-SpecialFolder MyDocuments -Value)

# I no longer worry about OneDrive, because I mapped my Documents into it, so there's only OneDrive
<#if( ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\OneDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\SkyDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive UserFolder -EA 0).UserFolder)) {
    
    $Null = New-PSDrive OneDrive FileSystem $OneDrive
    Trace-Message "OneDrive:\ mapped to $OneDrive"
}#>


##  The prompt function is in it's own script, and executing it imports previous history
if($Host.Name -ne "Package Manager Host") {
  . Set-Prompt -Clean -PersistentHistoryCount $PersistentHistoryCount
  Trace-Message "Prompt updated"
}

if($Host.Name -eq "ConsoleHost" -and !$NOCONSOLE) {
    if((-not (Get-Module PSReadLine)) -and (Get-Module -ListAvailable PSReadLine)) {
        Import-Module PSReadLine
    }

    ## If you have history to reload, you must do that BEFORE you import PSReadLine
    ## That way, the "up arrow" navigation works on the previous session's commands
    function Set-PSReadLineMyWay {
        param(
            #$BackgroundColor = $(if($PSProcessElevated) { "DarkGray" } else { "Black" } )
            $BackgroundColor =  "Black"
        )
        $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        $Host.UI.RawUI.ForegroundColor = "Gray"

        Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Yellow -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind String -ForegroundColor Green -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Operator -ForegroundColor DarkGreen -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Variable -ForegroundColor DarkMagenta -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Command -ForegroundColor DarkYellow -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Parameter -ForegroundColor DarkCyan -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Type -ForegroundColor Blue -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Number -ForegroundColor Red -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Member -ForegroundColor DarkRed -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind None -ForegroundColor White -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Comment -ForegroundColor Black -BackgroundColor DarkGray

        Set-PSReadlineOption -EmphasisForegroundColor White -EmphasisBackgroundColor $BackgroundColor `
                             -ContinuationPromptForegroundColor DarkBlue -ContinuationPromptBackgroundColor $BackgroundColor -ContinuationPrompt (([char]183) + "  ")
        Set-PSReadlineKeyHandler -Key '"',"'" `
                             -BriefDescription SmartInsertQuote `
                             -LongDescription "Insert paired quotes if not already on a quote" `
                             -ScriptBlock {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($line[$cursor] -eq $key.KeyChar) {        # Just move the cursor
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            } else {
            # Insert matching quotes, move cursor to be in between the quotes
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)" * 2)
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
            }
        }
    Set-PSReadlineKeyHandler -Key '(','{','[' `
                             -BriefDescription InsertPairedBraces `
                             -LongDescription "Insert matching braces" `
                             -ScriptBlock {
        param($key, $arg)
        $closeChar = switch ($key.KeyChar) {
            <#case#> '(' { [char]')'; break }
            <#case#> '{' { [char]'}'; break }
            <#case#> '[' { [char]']'; break }
            }
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor - 1)
        }
    Set-PSReadlineKeyHandler -Key ')',']','}' `
                             -BriefDescription SmartCloseBraces `
                             -LongDescription "Insert closing brace or skip" `
                             -ScriptBlock {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($line[$cursor] -eq $key.KeyChar) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
            }
        }
    Set-PSReadlineKeyHandler -Key Backspace `
                             -BriefDescription SmartBackspace `
                             -LongDescription "Delete previous character or matching quotes/parens/braces" `
                             -ScriptBlock {
        param($key, $arg)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($cursor -gt 0) {
            $toMatch = $null
            switch ($line[$cursor]) {
                <#case#> '"' { $toMatch = '"'; break }
                <#case#> "'" { $toMatch = "'"; break }
                <#case#> ')' { $toMatch = '('; break }
                <#case#> ']' { $toMatch = '['; break }
                <#case#> '}' { $toMatch = '{'; break }
                }
            if ($toMatch -ne $null -and $line[$cursor-1] -eq $toMatch) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
                }
            else {
                [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
                }
            }
        }
    # Insert text from the clipboard as a here string
    Set-PSReadlineKeyHandler -Key Ctrl+Shift+v `
                             -BriefDescription PasteAsHereString `
                             -LongDescription "Paste the clipboard text as a here string" `
                             -ScriptBlock {
        param($key, $arg)
        Add-Type -Assembly PresentationCore
        if ([System.Windows.Clipboard]::ContainsText()) {
            # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
            $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n","`n").TrimEnd()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
            }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            }
        }
    Set-PSReadlineKeyHandler -Key 'Alt+(' `
                             -BriefDescription ParenthesizeSelection `
                             -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
                             -ScriptBlock {
        param($key, $arg)
        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
            }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
            }
        }

    Set-PSReadlineKeyHandler -Key 'Alt+"' `
                             -BriefDescription ParenthesizeSelection `
                             -LongDescription "Put quotes around the selection or entire line and move the cursor to after the closing parenthesis" `
                             -ScriptBlock {
        param($key, $arg)
        $selectionStart = $null
        $selectionLength = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)
        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
        if ($selectionStart -ne -1) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '"' + $line.SubString($selectionStart, $selectionLength) + '"')
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
            }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '"' + $line + '"')
            [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
            }
        }
    Set-PSReadlineKeyHandler -Key "Alt+%" `
                             -BriefDescription ExpandAliases `
                             -LongDescription "Replace all aliases with the full command" `
                             -ScriptBlock {
        param($key, $arg)
        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
        $startAdjustment = 0
        foreach ($token in $tokens) {
            if ($token.TokenFlags -band [System.Management.Automation.Language.TokenFlags]::CommandName) {
                $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
                if ($alias -ne $null) {
                    $resolvedCommand = $alias.ResolvedCommandName
                    if ($resolvedCommand -ne $null) {
                        $extent = $token.Extent
                        $length = $extent.EndOffset - $extent.StartOffset
                        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                            $extent.StartOffset + $startAdjustment,
                            $length,
                            $resolvedCommand)
                        # Our copy of the tokens won't have been updated, so we need to
                        # adjust by the difference in length
                        $startAdjustment += ($resolvedCommand.Length - $length)
                        }
                    }
                }
            }
        }
    # F1 for help on the command line - naturally
    Set-PSReadlineKeyHandler -Key F1 `
                             -BriefDescription CommandHelp `
                             -LongDescription "Open the help window for the current command" `
                             -ScriptBlock {
        param($key, $arg)
        $ast = $null
        $tokens = $null
        $errors = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)
        $commandAst = $ast.FindAll( {
            $node = $args[0]
            $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.Extent.StartOffset -le $cursor -and
                $node.Extent.EndOffset -ge $cursor
            }, $true) | Select-Object -Last 1
        if ($commandAst -ne $null) {
            $commandName = $commandAst.GetCommandName()
            if ($commandName -ne $null) {
                $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
                if ($command -is [System.Management.Automation.AliasInfo]) {
                    $commandName = $command.ResolvedCommandName
                    }
                if ($commandName -ne $null) {
                    Get-Help $commandName -ShowWindow
                    }
                }
    }
    if (Get-Module PSReadLine) {
        Set-PSReadLineMyWay
        Set-PSReadlineKeyHandler -Key "Ctrl+Shift+R" -Function ForwardSearchHistory
        Set-PSReadlineKeyHandler -Key "Ctrl+R" -Function ReverseSearchHistory

        Set-PSReadlineKeyHandler Ctrl+M SetMark
        Set-PSReadlineKeyHandler Ctrl+Shift+M ExchangePointAndMark

        Set-PSReadlineKeyHandler Ctrl+K KillLine
        Set-PSReadlineKeyHandler Ctrl+I Yank
        Trace-Message "PSReadLine fixed"
    }
}
else {
    Remove-Module PSReadLine -ErrorAction SilentlyContinue
    Trace-Message "PSReadLine skipped!"
}


##  Superfluous but fun quotes. 
#   By default we look for these in $ProfileDir\Data\quotes.txt
<#if(Test-Path $Script:QuoteDir) {
    # Only export $QuoteDir if it refers to a folder that actually exists
    Set-Variable QuoteDir (Resolve-Path $QuoteDir) -Scope Global -Option AllScope -Description "Personal PATH Variable"

    function Get-Quote {
        param(
            $Path = "${QuoteDir}\quotes.txt",
            [int]$Count=1
        )
        if(!(Test-Path $Path) ) {
            $Path = Join-Path ${QuoteDir} $Path
            if(!(Test-Path $Path) ) {
                $Path = $Path + ".txt"
            }
        }
        Get-Content $Path | Where-Object { $_ } | Get-Random -Count $Count
    }

    Trace-Message "Random Quotes Loaded" 
}#>

## Fix em-dash screwing up our commands...
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param( $CommandName, $CommandLookupEventArgs )
    if($CommandName.Contains([char]8211)) {
        $CommandLookupEventArgs.Command = Get-Command ( $CommandName -replace ([char]8211), ([char]45) ) -ErrorAction Ignore
    }
}

function prompt {
    Set-StrictMode -Off
    $history = Get-History
    $nextHistoryId = $history.Count + 1
    Write-Host "[" -ForegroundColor DarkGray -NoNewline
    Write-Host "$nextHistoryId" -ForegroundColor Red -NoNewline
    Write-Host "|" -ForegroundColor DarkGray -NoNewline
    Write-Host "$((Get-Date).ToShortTimeString())" -ForegroundColor Yellow -NoNewline
    if ($history) {
        $timing = $history[-1].EndExecutionTime - $history[-1].StartExecutionTime
        Write-Host "|" -ForegroundColor DarkGray -NoNewline
        $color = "Green"
        if ($timing.TotalSeconds -gt 1) {
            $color = "Red"
            }
        Write-Host "+" -ForegroundColor $color -NoNewline
        if ($timing.Hours) { Write-Host "$(($timing).Hours)h " -ForegroundColor $color -NoNewline }
        if ($timing.Minutes) { Write-Host "$(($timing).Minutes)m " -ForegroundColor $color -NoNewline }
        if ($timing.Seconds) { Write-Host "$(($timing).Seconds)s " -ForegroundColor $color -NoNewline }
        Write-Host "$(($timing).Milliseconds)ms" -ForegroundColor $color -NoNewline
        }
    Write-Host "] " -ForegroundColor DarkGray -NoNewline
    Write-Host "[" -ForegroundColor DarkGray -NoNewline
    [string]$path = $Pwd.Path
    if ($path -like "c:\users\$env:username*") {
        $path = "~home" + $path.Substring("c:\users\$env:username".Length)
        }
    $chunks = $path -split '\\'
    $short = $false
    if ($Pwd.Path.Length -gt 30 -and $chunks.Length -gt 2) {
        $chunks = $chunks | select -Last 2
        $short = $true
        }
    if ($short) {    Write-Host "...\" -ForegroundColor DarkGray -NoNewline    }
    $chunks | % { $i = 0 } {
        $i++
        $color = "Yellow"
        if ($_ -like "~home") { $color = "Green" }
        Write-Host "$_" -ForegroundColor $color -NoNewline
        if ($i -le $chunks.Count-1) {
            Write-Host "\" -ForegroundColor DarkGray -NoNewline
            }
        }
    Write-Host "]" -ForegroundColor DarkGray -NoNewline
    $g = Get-GitStatus
    if ($g) {
        Write-Host " [" -ForegroundColor DarkGray -NoNewline
        $branch = $g.Branch.Split("...") | select -first 1
        Write-Host $branch -ForegroundColor Red -NoNewline
        $add = $g.Working.Added.Count
        $cha = $g.Working.Modified.Count
        $del = $g.Working.Deleted.Count
        $ahead = $g.AheadBy
        $behind = $g.BehindBy
        if ($add) {
            Write-Host "|" -ForegroundColor DarkGray -NoNewline
            Write-Host "+$add" -ForegroundColor Yellow -NoNewline
            }
        if ($rem) {
            Write-Host "|" -ForegroundColor DarkGray -NoNewline
            Write-Host "-$rem" -ForegroundColor Yellow -NoNewline
            }
        if ($cha) {
            Write-Host "|" -ForegroundColor DarkGray -NoNewline
            Write-Host "~$cha" -ForegroundColor Yellow -NoNewline
            }
        if (!$g.Working) {
            Write-Host "|" -ForegroundColor DarkGray -NoNewline
            Write-Host "clean" -ForegroundColor Green -NoNewline
            }
        if ($ahead) {
            Write-Host "|" -ForegroundColor DarkGray -NoNewline
            Write-Host "▲$ahead" -ForegroundColor Green -NoNewline
            }
        if ($behind) {
            Write-Host "|" -ForegroundColor DarkGray -NoNewline
            Write-Host "▼$behind" -ForegroundColor Red -NoNewline
            }
        Write-Host "]" -ForegroundColor DarkGray -NoNewline
        }
    Write-Host "`n>" -ForegroundColor DarkGray -NoNewline
    return " "
}

##  Write a quick banner and a random quote for fun
if (-not $SHIFTED) {
    Clear-Host
}
Write-SessionBanner
Write-Host
try {Get-Quote} catch {}

 
##  Clean up variables created in this profile that we don't wan't littering a cleanly started profile.
Remove-Variable folders -ErrorAction SilentlyContinue
Remove-Variable SHIFTED -ErrorAction SilentlyContinue
Remove-Variable PersistentHistoryCount -ErrorAction SilentlyContinue

Trace-Message "Profile Finished Loading!" -KillTimer

## And finally, relax the code signing restriction so we can actually get work done
Set-ExecutionPolicy RemoteSigned Process
