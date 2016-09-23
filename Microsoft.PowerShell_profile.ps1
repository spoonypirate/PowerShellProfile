trap { Write-Warning ($_.ScriptStackTrace | Out-String) }

##  Some variables for later (some also get removed from memory at the end of this profile loading)
$PersistentHistoryCount = 500

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

##  Ok, now import environment so we have PSProcessElevated, Trace-Message, and other custom functions we use later
#   The others will get loaded automatically, but it's faster to load them explicitly
Get-ChildItem $PSScriptRoot\Modules | foreach { Import-Module $_ }
Import-Module Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
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

# First call to Trace-Message, pass in our TraceTimer that I created at the top to make sure we time EVERYTHING.
Trace-Message "Microsoft.PowerShell.* Modules Imported" -Stopwatch $TraceVerboseTimer

## Set the profile directory first, so we can refer to it from now on.
Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

##  Add additional items to your path. Modify this to suit your needs. 
#   We do need the Scripts directory for the rest of this profile script to run though so this first one is essential to add.
[string[]]$folders = Get-ChildItem $ProfileDir\Script[s] -Directory | ForEach-Object FullName

#$ENV:PATH = Select-UniquePath $folders ${Env:Path}

#if ($SHIFTED) {
#    Trace-Message "Path AFTER updates: "
#    $($ENV:Path -split ';') | ForEach-Object {
#        Trace-Message " -- $($_)"
#    }
#}

##  Additional module directories to search for loading modules with Import-Module
#$Env:PSModulePath = Select-UniquePath "$ProfileDir\Modules",(Get-SpecialFolder *Modules -Value),${Env:PSModulePath}
#Trace-Message "PSModulePath Updated "

##  Start sessions in the profile directory. 
#   If you need to go to the prior directory just run pop-location right after starting powershell
if($ProfileDir -ne (Get-Location)) {
   Push-Location $ProfileDir
}

# Code signing function
function Sign-File ($filename) {
    $cert = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
    Set-AuthenticodeSignature $filename $cert
}

#rdp quick~!
Function rdp {
<#
.Synopsis
Open a RDP session from the console
.DESCRIPTION
Allows you to create an RDP session using the Connect-Mstsc function which will automatically pass current credentials created via Update-StoredCredential. Customize the $user and $pass variables to your preferences.
.EXAMPLE
To open an RDP session, type:

rdp -servername <nameofcomputer>
#>
Param([Parameter(Mandatory=$true)] $servername)
switch ($servername)    {
    127.0.0.1 { write-output "no no no!" }
    localhost { Write-Output "NO"}
    default { 
        Connect-Mstsc $servername (Get-Credential "ccmh_nt\mmasterson") }
    }
}
## Fix em-dash screwing up our commands...
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param( $CommandName, $CommandLookupEventArgs )
    if($CommandName.Contains([char]8211)) {
        $CommandLookupEventArgs.Command = Get-Command ( $CommandName -replace ([char]8211), ([char]45) ) -ErrorAction Ignore
    }
}
Trace-Message "Profile Finished Loading!" -KillTimer

## And finally, relax the code signing restriction so we can actually get work done
#Set-ExecutionPolicy RemoteSigned Process