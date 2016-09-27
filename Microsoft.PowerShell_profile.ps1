trap { Write-Warning ($_.ScriptStackTrace | Out-String) }

$PersistentHistoryCount = 500
$Script:TraceVerboseTimer = New-Object System.Diagnostics.Stopwatch
$Script:TraceVerboseTimer.Start()

try {
    $NOCONSOLE = $FALSE
    [System.Console]::Clear()
}
catch {
    $NOCONSOLE = $TRUE
}

Import-Module Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility
if ($ProfileDir -ne ((Get-ChildItem $PROFILE).DirectoryName)) {
    Set-Variable ProfileDir (Get-ChildItem $PROFILE).DirectoryName -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue
}
Get-ChildItem $ProfileDir\Modules | ForEach-Object { Import-Module $_ }



If ($PSProcessElevated = $True) {
    Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
    function Import-Exchange { 
        $exchangeserver = "http://exchange.contoso.com/powershell"
        $exchangecred = (BetterCredentials\Get-Credential "$env:USERDOMAIN\$env:USERNAME") 
        $exchangesession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $exchangeserver -Credential $exchangecred
        Import-PSSession $exchangesession -AllowClobber
    } 
    Import-Module ActiveDirectory
}
[string[]]$folders = Get-ChildItem $ProfileDir\Script[s] -Directory | ForEach-Object FullName
##  Check SHIFT state ASAP at startup so I can use that to control verbosity :)
Add-Type -Assembly PresentationCore, WindowsBase
try {
    $global:SHIFTED = [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -OR
                      [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightShift)
}
catch {
    $global:SHIFTED = $false
}
if($SHIFTED) {
    $VerbosePreference = "Continue"
}

# First call to Trace-Message, pass in our TraceTimer that I created at the top to make sure we time EVERYTHING.
Trace-Message "Microsoft.PowerShell.* Modules Imported" -Stopwatch $TraceVerboseTimer

## Developer tools things ...
$folders += [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
## MSBuild is now in 'C:\Program Files (x86)\MSBuild\{version}'
#$folders += Set-AliasToFirst -Alias "msbuild" -Path 'C:\Program Files (x86)\MSBuild\14.0\Bin\MsBuild.exe' -Description "Visual Studio's MsBuild" -Force -Passthru
#$folders += Set-AliasToFirst -Alias "merge" -Path "C:\Program*Files*\Perforce\p4merge.exe","C:\Program*Files*\DevTools\Perforce\p4merge.exe" -Description "Perforce" -Force -Passthru
#$folders += Set-AliasToFirst -Alias "tf" -Path "C:\Program*Files*\*Visual?Studio*\Common7\IDE\TF.exe", "C:\Program*Files*\DevTools\*Visual?Studio*\Common7\IDE\TF.exe" -Description "Visual Studio" -Horse -Passthru
#$folders += Set-AliasToFirst -Alias "Python","Python2","py2" -Path "C:\Python2*\python.exe", "D:\Python2*\python.exe" -Description "Python 2.x" -Force -Passthru
#$folders += Set-AliasToFirst -Alias "Python3","py3" -Path "C:\Python3*\python.exe", "D:\Python3*\python.exe" -Description "Python 3.x" -Force -Passthru
#Set-AliasToFirst -Alias "iis","iisexpress" -Path 'C:\Progra*\IIS*\IISExpress.exe' -Description "Personal Profile Alias"
Trace-Message "Development aliases set"
if ($SHIFTED) {
    Trace-Message "Path before updates: "
    $($ENV:Path -split ';') | ForEach-Object {
        Trace-Message " -- $($_)"
    }
}

$ENV:PATH = Select-UniquePath $folders ${Env:Path}

if ($SHIFTED) {
    Trace-Message "Path AFTER updates: "
    $($ENV:Path -split ';') | ForEach-Object {
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
#New-PSDrive Documents FileSystem (Get-SpecialFolder MyDocuments -Value)
New-PSDrive -Name git -PSProvider FileSystem -Root C:\Tools\git -Scope Global | Out-Null

$PSDefaultParameterValues = @{
#    '*-Csv:Delimiter' = ';'
#    '*-Csv:NoTypeInformation' = $true
#    '*-DnsServer*:ComputerName' = 'pdc1.contoso.com'
#    '*-DnsServer*:ZoneName' = 'contoso.com'
#    'Add-DnsServerResourceRecord*:CreatePtr' = $true
}

function Sign ($filename) {
	$TempFile = "$($filename).UTF8"
	Get-Content $filename | Out-File $TempFile -Encoding UTF8
	Remove-Item $filename
	Rename-Item $TempFile $filename
    if ((Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert).count -eq 0) {
        Write-Error "No Code Signing Certificates Found under cert:\currentuser\my"
    } elseif ((Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert).count -eq 1) {
        $cert = @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)[0]
    } else {
        ForEach-Object ($item -in @(Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert)) {
            if ($item.GetExpirationDateString() -gt $(Get-Date)) {
                $cert = $item
            }
		}
    }
	Set-AuthenticodeSignature $filename $cert
}

## Fix em-dash screwing up our commands...
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param( $CommandName, $CommandLookupEventArgs )
    if($CommandName.Contains([char]8211)) {
        $CommandLookupEventArgs.Command = Get-Command ( $CommandName -replace ([char]8211), ([char]45) ) -ErrorAction Ignore
    }
}


## Start Explorer As Admin
Function Start-ExplorerAsAdmin {
    if (Get-Module BetterCredentials) {
        Start-Process Explorer -LoadUserProfile -Credential (BetterCredentials\Get-Credential "$env:USERDOMAIN\$env:username") 
    } else {
        Start-Process Explorer -LoadUserProfile -Credential (Get-Credential "$env:USERDOMAIN\$env:username")
    }
}
 
## Start PowerShell As Admin
Function Start-ADAdminCenter {
if (Get-Module BetterCredentials) {
        Start-Process $env:windir\system32\dsac.exe -LoadUserProfile -Credential (BetterCredentials\Get-Credential "$env:USERDOMAIN\$env:username") -Verb RunAs 
    } else {
        Start-Process $env:windir\system32\dsac.exe -LoadUserProfile -Credential (Get-Credential "$env:USERDOMAIN\$env:username") -Verb RunAs
    }
}

function get-java {
    param(
        [switch]$download
    )
    if ($download) {
        $page = Invoke-WebRequest -Uri "http://java.com/en/download/windows_offline.jsp"
        $version = $page.RawContent -split "`n" | Where-Object {$_ -match 'recommend'} | Select-Object -first 1 | ForEach-Object {$_ -replace '^[^v]+| \(.*$'}
        $link = $page.links.href | Where-Object {$_ -match '^http.*download'} | Select-Object -first 1
        Invoke-WebRequest $link -outfile "c:\tools\Java $version.exe"
    } else {
        ($(Invoke-WebRequest -Uri "http://java.com/en/download").Content.Split("`n") | Where-Object {$_ -match 'version'})[0]
    }
}

Trace-Message "Profile Finished Loading!" -KillTimer

## And finally, relax the code signing restriction so we can actually get work done
#Set-ExecutionPolicy RemoteSigned Process
