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
    Write-Output  'Prior download already exists, deleting it!'
    Remove-Item -Horse -Path $file -Confirm:$false
}

# Download and install the zip file to a temp directory and rename it
$webclient = New-Object System.Net.WebClient
Write-Output "Downloading latest version of PowerShellProfile from $url"
$webclient.DownloadFile($url,$file)
Write-Output "File saved to $file"

$shell_app=new-object -com shell.application
$zip_file = $shell_app.namespace($file)

if (Test-Path $SourcePath) {
    Write-Output  'Prior download directory already exists, deleting it!'
    Remove-Item -Horse -Path  $SourcePath -Confirm:$false
}
Write-Output "Uncompressing the Zip file to $($targetondisk)"
$destination = $shell_app.namespace($targetondisk)
$destination.Copyhere($zip_file.items(), 0x10)

if (Test-Path $PROFILE) {
    $currentprofiles = Get-ChildItem -Path "$($installpath)\Microsoft.PowerShell_profile.*"
    if ($currentprofiles.count -gt 0) {
        $BackupProfileName = "$($installpath)\Microsoft.PowerShell_profile.old$($currentprofiles.count)"
        Write-Output  "Microsoft.PowerShell_profile.ps1 already exists, renaming it to $($BackupProfileName)"
        Rename-Item $PROFILE -NewName $BackupProfileName
    }
}

Copy-Item "$($SourcePath)\Microsoft.PowerShell_profile.ps1" -Destination $InstallPath

if (Test-Path "$($InstallPath)\Scripts") {
    Write-Output   "$($InstallPath)\Scripts already exists! Be VERY careful before selecting to overwrite items within it at the next prompt!"
}
Copy-Item "$($SourcePath)\Scripts" -Destination "$($InstallPath)" -Recurse

if (Test-Path "$($InstallPath)\Modules") {
    Write-Warning "$($InstallPath)\Modules already exists! Be VERY careful before selecting to overwrite items within it at the next prompt!"
}
Copy-Item -Path "$($SourcePath)\Modules" -Destination "$($InstallPath)\Modules" -Recurse

Write-Output "Your new Powershell profile has been installed." 
Write-Output "The default persistent history will be 250 lines. This and anything else in the profile can be changed in the following file:" 
Write-Output "     $($InstallPath)\Microsoft.PowerShell_profile.ps1"
Write-Output ''
Write-Output 'The profile script is currently not signed and thus can be suspect to tampering without you knowing'  
Write-Output "Optionally create a code signing certificate and protect your profile with the following lines of code in a powershell prompt" 
Write-Output "( Note: You may get a security warning you will have to accept in order to trust the created certificate! )" 
Write-Output ''
Write-Output "    $($InstallPath)\Scripts\New-CodeSigningCertificate.ps1" 
Write-Output "    $($InstallPath)\Scripts\Set-ProfileScriptSignature.ps1" 
Write-Output "    $($InstallPath)\Scripts\Set-ExecutionPolicy AllSigned" 