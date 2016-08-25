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

##  This timer is used by Trace-Message, I want to start it immediately
$Script:TraceVerboseTimer = New-Object System.Diagnostics.Stopwatch
$Script:TraceVerboseTimer.Start()

##  PS5 introduced PSReadLine, which chokes in non-console shells, so I snuff it.
<#try {
    $NOCONSOLE = $FALSE
    [System.Console]::Clear()
}
catch {
    $NOCONSOLE = $TRUE
}#>

##  If your PC doesn't have this set already, someone could tamper with this script...
#   but at least now, they can't tamper with any of the modules/scripts that I auto-load!

<#
if ((Get-ExecutionPolicy -list | Where-Object {$_.Scope -eq 'LocalMachine'}).ExecutionPolicy -ne 'AllSigned') {
    Write-Warning 'Execution policy was set to AllSigned for this process but is not set to AllSigned for the LocalMachine. '
    Write-Warning 'What this means is that this profile could be tampered with and you might never know!'
    pause
    try { Set-ExecutionPolicy AllSigned Process } catch {write-error ''}
}#>

##  Ok, now import environment so we have PSProcessElevated, Trace-Message, and other custom functions we use later
#   The others will get loaded automatically, but it's faster to load them explicitly
Import-Module $PSScriptRoot\Modules\Environment, Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility



# First call to Trace-Message, pass in our TraceTimer that I created at the top to make sure we time EVERYTHING.
Trace-Message "Microsoft.PowerShell.* Modules Imported" -Stopwatch $TraceVerboseTimer

## Set the profile directory first, so we can refer to it from now on.
Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

##  Add additional items to your path. Modify this to suit your needs. 
#   We do need the Scripts directory for the rest of this profile script to run though so this first one is essential to add.
[string[]]$folders = Get-ChildItem $ProfileDir\Script[s] -Directory | ForEach-Object FullName

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
#New-PSDrive Documents FileSystem (Get-SpecialFolder MyDocuments -Value)

# I no longer worry about OneDrive, because I mapped my Documents into it, so there's only OneDrive
<#if( ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\OneDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\SkyDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive UserFolder -EA 0).UserFolder)) {
    
    $Null = New-PSDrive OneDrive FileSystem $OneDrive
    Trace-Message "OneDrive:\ mapped to $OneDrive"
}#>


## Fix em-dash screwing up our commands...
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param( $CommandName, $CommandLookupEventArgs )
    if($CommandName.Contains([char]8211)) {
        $CommandLookupEventArgs.Command = Get-Command ( $CommandName -replace ([char]8211), ([char]45) ) -ErrorAction Ignore
    }
}

 
##  Clean up variables created in this profile that we don't wan't littering a cleanly started profile.
Remove-Variable folders -ErrorAction SilentlyContinue
Remove-Variable PersistentHistoryCount -ErrorAction SilentlyContinue

Trace-Message "Profile Finished Loading!" -KillTimer

## And finally, relax the code signing restriction so we can actually get work done
Set-ExecutionPolicy RemoteSigned Process
