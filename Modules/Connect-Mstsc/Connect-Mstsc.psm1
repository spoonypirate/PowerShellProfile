function Connect-Mstsc {
<#   
.SYNOPSIS   
Function to connect an RDP session without the password prompt
    
.DESCRIPTION 
This function provides the functionality to start an RDP session without having to type in the password
	
.PARAMETER ComputerName
This can be a single computername or an array of computers to which RDP session will be opened

.PARAMETER User
The user name that will be used to authenticate

.PARAMETER Password
The password that will be used to authenticate

.PARAMETER Credential
The PowerShell credential object that will be used to authenticate against the remote system

.PARAMETER Admin
Sets the /admin switch on the mstsc command: Connects you to the session for administering a server

.PARAMETER MultiMon
Sets the /multimon switch on the mstsc command: Configures the Remote Desktop Services session monitor layout to be identical to the current client-side configuration 

.PARAMETER FullScreen
Sets the /f switch on the mstsc command: Starts Remote Desktop in full-screen mode

.PARAMETER Public
Sets the /public switch on the mstsc command: Runs Remote Desktop in public mode

.PARAMETER Width
Sets the /w:<width> parameter on the mstsc command: Specifies the width of the Remote Desktop window

.PARAMETER Height
Sets the /h:<height> parameter on the mstsc command: Specifies the height of the Remote Desktop window

.NOTES   
Name: Connect-Mstsc
Author: Jaap Brasser
DateUpdated: 2015-07-02
Version: 1.2.1
Blog: http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com

.EXAMPLE   
. .\Connect-Mstsc.ps1
    
Description 
-----------     
This command dot sources the script to ensure the Connect-Mstsc function is available in your current PowerShell session

.EXAMPLE   
Connect-Mstsc -ComputerName server01 -User contoso\jaapbrasser -Password supersecretpw

Description 
-----------     
A remote desktop session to server01 will be created using the credentials of contoso\jaapbrasser

.EXAMPLE   
Connect-Mstsc server01,server02 contoso\jaapbrasser supersecretpw

Description 
-----------     
Two RDP sessions to server01 and server02 will be created using the credentials of contoso\jaapbrasser

.EXAMPLE   
server01,server02 | Connect-Mstsc -User contoso\jaapbrasser -Password supersecretpw -Width 1280 -Height 720

Description 
-----------     
Two RDP sessions to server01 and server02 will be created using the credentials of contoso\jaapbrasser and both session will be at a resolution of 1280x720.

.EXAMPLE   
Connect-Mstsc -ComputerName server01:3389 -User contoso\jaapbrasser -Password supersecretpw -Admin -MultiMon

Description 
-----------     
A RDP session to server01 at port 3389 will be created using the credentials of contoso\jaapbrasser and the /admin and /multimon switches will be set for mstsc

.EXAMPLE   
Connect-Mstsc -ComputerName server01:3389 -User contoso\jaapbrasser -Password supersecretpw -Public

Description 
-----------     
A RDP session to server01 at port 3389 will be created using the credentials of contoso\jaapbrasser and the /public switches will be set for mstsc

.EXAMPLE
Connect-Mstsc -ComputerName 192.168.1.10 -Credential $Cred

Description 
-----------     
A RDP session to the system at 192.168.1.10 will be created using the credentials stored in the $cred variable.

.EXAMPLE   
Get-AzureVM | Get-AzureEndPoint -Name 'Remote Desktop' | ForEach-Object { Connect-Mstsc -ComputerName ($_.Vip,$_.Port -join ':') -User contoso\jaapbrasser -Password supersecretpw }

Description 
-----------     
A RDP session is started for each Azure Virtual Machine with the user contoso\jaapbrasser and password supersecretpw

.EXAMPLE
PowerShell.exe -Command "& {. .\Connect-Mstsc.ps1; Connect-Mstsc server01 contoso\jaapbrasser supersecretpw -Admin}"

Description
-----------
An remote desktop session to server01 will be created using the credentials of contoso\jaapbrasser connecting to the administrative session, this example can be used when scheduling tasks or for batch files.
#>
    [cmdletbinding(SupportsShouldProcess,DefaultParametersetName="UserPassword")]
    param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [Alias("CN")]
            [string[]]$ComputerName,
        [Parameter(ParameterSetName="UserPassword",Mandatory=$true,Position=1)]
        [Alias("U")] 
            [string]$User,
        [Parameter(ParameterSetName="UserPassword",Mandatory=$true,Position=2)]
        [Alias("P")] 
            [string]$Password,
        [Parameter(ParameterSetName="Credential",Mandatory=$true,Position=1)]
        [Alias("C")]
            [PSCredential]$Credential,
        [Alias("A")]
            [switch]$Admin,
        [Alias("MM")]
            [switch]$MultiMon,
        [Alias("F")]
            [switch]$FullScreen,
        [Alias("Pu")]
            [switch]$Public,
        [Alias("W")]
            [int]$Width,
        [Alias("H")]
            [int]$Height
    )

    begin {
        [string]$MstscArguments = ''
        switch ($true) {
            {$Admin} {$MstscArguments += '/admin '}
            {$MultiMon} {$MstscArguments += '/multimon '}
            {$FullScreen} {$MstscArguments += '/f '}
            {$Public} {$MstscArguments += '/public '}
            {$Width} {$MstscArguments += "/w:$Width "}
            {$Height} {$MstscArguments += "/h:$Height "}
        }

        if ($Credential) {
            $User = $Credential.UserName
            $Password = $Credential.GetNetworkCredential().Password
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
            $Process = New-Object System.Diagnostics.Process
            
            # Remove the port number for CmdKey otherwise credentials are not entered correctly
            if ($Computer.Contains(':')) {
                $ComputerCmdkey = ($Computer -split ':')[0]
            } else {
                $ComputerCmdkey = $Computer
            }

            $ProcessInfo.FileName = "$($env:SystemRoot)\system32\cmdkey.exe"
            $ProcessInfo.Arguments = "/generic:TERMSRV/$ComputerCmdkey /user:$User /pass:$Password"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $Process.StartInfo = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($ComputerCmdkey,'Adding credentials to store')) {
                [void]$Process.Start()
            }

            $ProcessInfo.FileName = "$($env:SystemRoot)\system32\mstsc.exe"
            $ProcessInfo.Arguments = "$MstscArguments /v $Computer"
            $ProcessInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal
            $Process.StartInfo = $ProcessInfo
            if ($PSCmdlet.ShouldProcess($Computer,'Connecting mstsc')) {
                [void]$Process.Start()
            }
        }
    }
}
# SIG # Begin signature block
# MIIHfAYJKoZIhvcNAQcCoIIHbTCCB2kCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvuFrxJiJzHhQncZDUHndqMpt
# 7lSgggVmMIIFYjCCBEqgAwIBAgIKZrbuawAAAAAAwDANBgkqhkiG9w0BAQUFADBS
# MRMwEQYKCZImiZPyLGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJY2NtaGludHJh
# MSAwHgYDVQQDExdjY21oaW50cmEtTERDLUNBLTAwMy1DQTAeFw0xNTA4MDUxNDQ1
# MDJaFw0xNjA4MDQxNDQ1MDJaMIGaMRMwEQYKCZImiZPyLGQBGRYDY29tMRkwFwYK
# CZImiZPyLGQBGRYJY2NtaGludHJhMQ0wCwYDVQQLEwRDQ01IMQ4wDAYDVQQLEwVV
# c2VyczENMAsGA1UECxMERGVwdDELMAkGA1UECxMCSVMxEDAOBgNVBAsTB25vcnVs
# ZXMxGzAZBgNVBAMTEk1hc3RlcnNvbiwgTWljaGFlbDCBnzANBgkqhkiG9w0BAQEF
# AAOBjQAwgYkCgYEAzaF/2BXl3F582fjM3u2LAfJdXIx6adXb+BmrHtaainbSPbSC
# tKNxgzvcgxbiU7H3shzEVCVobx/PRjSXfT+C1yGlnldbHsRfCBqp8zN7fS49u/5g
# HFpsPwGD59kj3tRIPTAL2jr2r/C5uazCBi8OlEQ2VmQYJRZhKsWytP2vKWcCAwEA
# AaOCAnMwggJvMCUGCSsGAQQBgjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBuAGkAbgBn
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMAsGA1UdDwQEAwIHgDAdBgNVHQ4EFgQUHM22
# FTWJX/Hk1pJ70o1am3JZ5YwwHwYDVR0jBBgwFoAU5Hv+J7hsDEUBTtTfUSAMiBcj
# 4iEwgdoGA1UdHwSB0jCBzzCBzKCByaCBxoaBw2xkYXA6Ly8vQ049Y2NtaGludHJh
# LUxEQy1DQS0wMDMtQ0EsQ049TERDLUNBLTAwMyxDTj1DRFAsQ049UHVibGljJTIw
# S2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1j
# Y21oaW50cmEsREM9Y29tP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9v
# YmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDCBywYIKwYBBQUHAQEEgb4w
# gbswgbgGCCsGAQUFBzAChoGrbGRhcDovLy9DTj1jY21oaW50cmEtTERDLUNBLTAw
# My1DQSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2Vydmlj
# ZXMsQ049Q29uZmlndXJhdGlvbixEQz1jY21oaW50cmEsREM9Y29tP2NBQ2VydGlm
# aWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MDkG
# A1UdEQQyMDCgLgYKKwYBBAGCNxQCA6AgDB5taWNoYWVsbWFzdGVyc29uQGNjbWhp
# bnRyYS5jb20wDQYJKoZIhvcNAQEFBQADggEBAFLzV6sTY3tlhHBINpU38G8O1r/i
# N9iL1iOQuNbxWmODx/AImuCP5k6kqgeix+Uw/nq8Usm1VxW6m6YjD3inpPe9/lCR
# pm1OHfdBjjK0cq2aI9feLREIKR+j0cMZX4fWtM+fhKjjcYfjepoA7EyMHffet+dj
# EvxXvup6zrz1FRipN7YksL2QeTep1tRMMWrSw3SBinSHd9ntzpKTyPIW6C0ZQEB2
# KENQHnPxUtWdMco18cqxu0DSb0jhKO6xJpuXo1iPG0aJHUeWackWzhDFTFfYmGJO
# pP8GocwwxqpoR+7RhyihSMJBEE5GAgewLeD3FugLM0IHdI3xkC24/X/61cQxggGA
# MIIBfAIBATBgMFIxEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZ
# FgljY21oaW50cmExIDAeBgNVBAMTF2NjbWhpbnRyYS1MREMtQ0EtMDAzLUNBAgpm
# tu5rAAAAAADAMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAA
# MBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgor
# BgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQ/6qSQogZukeu5t/uFAEqryrxTPjAN
# BgkqhkiG9w0BAQEFAASBgJntpUPKwOxuP1i4zBfKQFE855CTUJubx67GZKctHq7W
# 8fh5x+B+EaN1Un3QCGTbseE6FJp5eLQL/vYuJOeQGC34YYFoECy+HV33AZtcAzVU
# cfMl62ossmcyois9jQt45xFv4uV7jjMrbf80g4gTTYpl70fJ0c3bp2QiS9xt8MQ3
# SIG # End signature block
