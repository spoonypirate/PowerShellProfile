# Run this in an administrative PowerShell prompt to install the PowerShell profile
#
# 	iex (New-Object Net.WebClient).DownloadString("https://raw.githubusercontent.com/zloeber/PowerShellProfile/master/Install.ps1")

# Some general variables
$ProjectName = 'PowerShellProfile'
$GithubURL = 'https://github.com/spoonypirate/PowerShellProfile'
$InstallPath = Split-Path $PROFILE
$file = "$($env:TEMP)\$($ProjectName).zip"
$url = "$GithubURL/archive/master.zip"
$targetondisk = $env:TEMP
$SourcePath =  ($targetondisk+"\$($ProjectName)-master")

if (Test-Path $file) {
    write-output -ForegroundColor:DarkYellow 'Prior download already exists, deleting it!'
    Remove-Item -Horse -Path $file -Confirm:$false
}

# Download and install the zip file to a temp directory and rename it
$webclient = New-Object System.Net.WebClient
write-output "Downloading latest version of PowerShellProfile from $url"
$webclient.DownloadFile($url,$file)
write-output "File saved to $file"

$shell_app=new-object -com shell.application
$zip_file = $shell_app.namespace($file)

if (Test-Path $SourcePath) {
    write-output -ForegroundColor:DarkYellow 'Prior download directory already exists, deleting it!'
    Remove-Item -Horse -Path  $SourcePath -Confirm:$false
}
write-output "Uncompressing the Zip file to $($targetondisk)"
$destination = $shell_app.namespace($targetondisk)
$destination.Copyhere($zip_file.items(), 0x10)

if (Test-Path $PROFILE) {
    $currentprofiles = Get-ChildItem -Path "$($installpath)\Microsoft.PowerShell_profile.*"
    if ($currentprofiles.count -gt 0) {
        $BackupProfileName = "$($installpath)\Microsoft.PowerShell_profile.old$($currentprofiles.count)"
        write-output -ForegroundColor:Yellow "Microsoft.PowerShell_profile.ps1 already exists, renaming it to $($BackupProfileName)"
        Rename-Item $PROFILE -NewName $BackupProfileName
    }
}

Copy-Item "$($SourcePath)\Microsoft.PowerShell_profile.ps1" -Destination $InstallPath
#find where cmder installs on initial install from boxstarter
#Copy-Item "$($SourcePath)\ConEmu.xml" -Destination ""

if (Test-Path "$($InstallPath)\Scripts") {
    write-output -ForegroundColor Red  "$($InstallPath)\Scripts already exists! Be VERY careful before selecting to overwrite items within it at the next prompt!"
}
Copy-Item "$($SourcePath)\Scripts" -Destination "$($InstallPath)" -Recurse

if (Test-Path "$($InstallPath)\Modules") {
    Write-Warning "$($InstallPath)\Modules already exists! Be VERY careful before selecting to overwrite items within it at the next prompt!"
}
Copy-Item -Path "$($SourcePath)\Modules" -Destination "$($InstallPath)\Modules" -Recurse

if (Test-Path "C:\tools\cmder\config") {
    Write-Warning "Overwriting user-profile.ps1 for cmder"
}
Copy-Item -Path "$($SourcePath)\user-profile.ps1" -Destination "C:\tools\cmder\config\user-profile.ps1" -Force

write-output ''
write-output "Your new Powershell profile has been installed."
write-output "The default persistent history will be 250 lines. This and anything else in the profile can be changed in the following file:"
write-output "     $($InstallPath)\Microsoft.PowerShell_profile.ps1"
write-output ''
write-output 'The profile script is currently not signed and thus can be suspect to tampering without you knowing' 
write-output "Optionally create a code signing certificate and protect your profile with the following lines of code in a powershell prompt"
write-output "( Note: You may get a security warning you will have to accept in order to trust the created certificate! )" 
write-output ''
write-output "    $($InstallPath)\Scripts\New-CodeSigningCertificate.ps1"
write-output "    $($InstallPath)\Scripts\Set-ProfileScriptSignature.ps1"
write-output "    $($InstallPath)\Scripts\Set-ExecutionPolicy AllSigned"
write-output ''
write-output 'Enjoy your new PowerShell profile! (Remember you can hold the shift key while it loads to get more detailed information on what it is doing)' 