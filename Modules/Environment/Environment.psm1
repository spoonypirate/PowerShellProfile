# if you're running "elevated" we want to know that:
$global:PSProcessElevated = ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
                                    new-object Security.Principal.WindowsPrincipal (
                                    [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
                                ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$OFS = ';'

function LoadSpecialFolders {
    $Script:SpecialFolders = @{}

    foreach($name in [System.Environment+SpecialFolder].GetFields("Public,Static") | Sort-Object Name) { 
        $Script:SpecialFolders.($name.Name) = [int][System.Environment+SpecialFolder]$name.Name

        if($Name.Name.StartsWith("My")) {
            $Script:SpecialFolders.($name.Name.Substring(2)) = [int][System.Environment+SpecialFolder]$name.Name
        }
    }
    $Script:SpecialFolders.CommonModules = Join-Path $Env:ProgramFiles "WindowsPowerShell\Modules"
    $Script:SpecialFolders.CommonProfile = (Split-Path $Profile.AllUsersAllHosts)
    $Script:SpecialFolders.Modules = Join-Path (Split-Path $Profile.CurrentUserAllHosts) "Modules"
    $Script:SpecialFolders.Profile = (Split-Path $Profile.CurrentUserAllHosts)
    $Script:SpecialFolders.PSHome = $PSHome
    $Script:SpecialFolders.SystemModules = Join-Path (Split-Path $Profile.AllUsersAllHosts) "Modules"
}

$Script:SpecialFolders = [Ordered]@{}

function Get-SpecialFolder {
  #.Synopsis
  #   Gets the current value for a well known special folder
  [CmdletBinding()]
  param(
    # The name of the Path you want to fetch (supports wildcards).
    #  From the list:   AdminTools, ApplicationData, CDBurning, CommonAdminTools, CommonApplicationData, 
    #                   CommonDesktopDirectory, CommonDocuments, CommonMusic, CommonOemLinks, CommonPictures, 
    #                   CommonProgramFiles, CommonProgramFilesX86, CommonPrograms, CommonStartMenu, CommonStartup, 
    #                   CommonTemplates, CommonVideos, Cookies, Desktop, DesktopDirectory, Favorites, Fonts, 
    #                   History, InternetCache, LocalApplicationData, LocalizedResources, MyComputer, MyDocuments, 
    #                   MyMusic, MyPictures, MyVideos, NetworkShortcuts, Personal, PrinterShortcuts, ProgramFiles, 
    #                   ProgramFilesX86, Programs, PSHome, Recent, Resources, SendTo, StartMenu, Startup, System, 
    #                   SystemX86, Templates, UserProfile, Windows
    [ValidateScript({
        $Name = $_
        if(!$Script:SpecialFolders.Count -gt 0) { LoadSpecialFolders }
        if($Script:SpecialFolders.Keys -like $Name){
            return $true
        } else {
            throw "Cannot convert Path, with value: `"$Name`", to type `"System.Environment+SpecialFolder`": Error: `"The identifier name $Name is not one of $($Script:SpecialFolders.Keys -join ', ')"
        }
    })]
    [String]$Path = "*",

    # If not set, returns a hashtable of folder names to paths
    [Switch]$Value
  )

  $Names = $Script:SpecialFolders.Keys -like $Path
  if(!$Value) {
    $return = @{}
  }

  foreach($name in $Names) {
    $result = $(
      $id = $Script:SpecialFolders.$name
      if($Id -is [string]) {
        $Id
      } else {
        ($Script:SpecialFolders.$name = [Environment]::GetFolderPath([int]$Id))
      }
    )

    if($result) {
      if($Value) {
        Write-Output $result
      } else {
        $return.$name = $result
      }
    }
  }
  if(!$Value) {
    Write-Output $return
  }
}

function Set-EnvironmentVariable {
    #.Synopsis
    # Set an environment variable at the highest scope possible
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [String]$Name,

        [Parameter(Position=1)]
        [Array]$Value,

        [System.EnvironmentVariableTarget]
        $Scope="Machine",

        [Switch]$FailFast
    )

    Set-Content "ENV:$Name" $Value
    $Success = $False
    do {
        try {
            
            [System.Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
            Write-Verbose "Set $Scope environment variable $Name = $Value"
            $Success = $True
        }
        catch [System.Security.SecurityException] 
        {
            if($FailFast) {
                $PSCmdlet.ThrowTerminatingError( (New-Object System.Management.Automation.ErrorRecord (
                    New-Object AccessViolationException "Can't set environment variable in $Scope scope"
                ), "FailFast:$Scope", "PermissionDenied", $Scope) )
            } else {
                Write-Warning "Cannot set environment variables in the $Scope scope"
            }
            $Scope = [int]$Scope - 1
        }
    } while(!$Success -and $Scope -gt "Process")
}

function Add-Path {
    #.Synopsis
    #  Add a folder to a path environment variable
    #.Description
    #  Gets the existing content of the path variable, splits it with the PathSeparator,
    #  adds the specified paths, and then joins them and re-sets the EnvironmentVariable
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$True)]
        [String]$Name,

        [Parameter(Position=1)]
        [String[]]$Append = @(),

        [String[]]$Prepend = @(),

        [System.EnvironmentVariableTarget]
        $Scope="Machine",

        [Char]
        $Separator = [System.IO.Path]::PathSeparator
    )

    # Make the new thing as an array so we don't get duplicates
    $Path = @($Prepend -split "$Separator" | ForEach-Object{ $_.TrimEnd("\/") } | Where-Object { $_ })
    $Path += $OldPath = @([Environment]::GetEnvironmentVariable($Name, $Scope) -split "$Separator" | ForEach-Object { $_.TrimEnd("\/") }| Where-Object { $_ })
    $Path += @($Append -split "$Separator" | ForEach-Object { $_.TrimEnd("\/") }| Where-Object { $_ })

    # Dedup path
    # If the path actually exists, use the actual case of the folder
    $Path = $(foreach($Folder in $Path) {
                if(Test-Path $Folder) {
                    Get-Item ($Folder -replace '(?<!:)(\\|/)', '*$1') | Where-Object FullName -ieq $Folder | ForEach-Object FullName
                } else { $Folder }
            } ) | Select-Object -Unique

    # Turn them back into strings
    $Path = $Path -join "$Separator"
    $OldPath = $OldPath -join "$Separator"

    # Path environment variables are kind-of a pain:
    # The current value in the process scope is a combination of machine and user, with changes
    # We need to fix the CURRENT path instead of just setting it
    $OldEnvPath = @($(Get-Content "ENV:$Name") -split "$Separator" | ForEach-Object { $_.TrimEnd("\/") }) -join "$Separator"
    if("$OldPath".Trim().Length -gt 0) {
        Write-Verbose "Old $Name Path: $OldEnvPath"
        $OldEnvPath = $OldEnvPath -Replace ([regex]::escape($OldPath)), $Path
        Write-Verbose "New $Name Path: $OldEnvPath"
    } else {
        if($Append) {
            $OldEnvPath = $OldEnvPath + "$Separator" + $Path
        } else {
            $OldEnvPath = $Path + "$Separator" + $OldEnvPath
        }
    }

    Set-EnvironmentVariable $Name $($Path -join "$Separator") -Scope $Scope -FailFast
    if($?) {
        # Set the path back to the normalized value
        Set-Content "ENV:$Name" $OldEnvPath
    }
}

function Select-UniquePath {
    [CmdletBinding()]
    param(
        # If non-full, split path by the delimiter. Defaults to ';' so you can use this on $Env:Path
        [AllowNull()]
        [string]$Delimiter=';',

        # Paths to folders
        [Parameter(Position=1,Mandatory=$true,ValueFromRemainingArguments=$true)]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Path
    )
    begin {
        $Output = [string[]]@()
    }
    process {
        <#
            # This was the original code and it seems to 'eat' paths on me for some reason so I replaced it
            $Output += $(foreach($folderPath in $Path) {
            if($Delimiter) { 
                $folderPath = $folderPath -split $Delimiter
            }
            foreach($folder in @($folderPath)) {
                $folder = $folder.TrimEnd('\/')
                if($folderPath = $folder -replace '(?<!:)(\\|/)', '*$1') {
                    Get-Item $folderPath -ErrorAction Ignore | Where FullName -ieq $folder
                }
            }
        })#>
        $Output = @()
        foreach($folderPath in $Path) {
            if ($Delimiter) { 
                $folderPath = $folderPath -split $Delimiter
            }
            $folderPath = $folderPath | ForEach-Object {$_.TrimEnd('\/')} | Sort-Object | Select-Object -Unique
            $folderPath | ForEach-Object {
                if (Test-Path $_) {
                    $Output += Get-Item $_ 
                    Write-Verbose "Unique path added:: $($_)" 
                }
                else {
                    Write-Verbose "Path excluded because it doesn't exist: $($_)"
                }
            }
        }
    }
    end {
        if($Delimiter) {
            ($Output | Select-Object -Expand FullName -Unique) -join $Delimiter
        } else {
            $Output | Select-Object -Expand FullName -Unique
        }
    }
}

function Trace-Message {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$Message,
        [switch]$AsWarning,
        [switch]$ResetTimer,
        [switch]$KillTimer,
        [Diagnostics.Stopwatch]$Stopwatch
    )
    begin {
        if($Stopwatch) {
            $Script:TraceTimer = $Stopwatch    
            $Script:TraceTimer.Start()
        }
        if(-not $Script:TraceTimer) {
            $Script:TraceTimer = New-Object System.Diagnostics.Stopwatch
            $Script:TraceTimer.Start()
        }

        if($ResetTimer) {
            $Script:TraceTimer.Restart()
        }
    }

    process {
        $Message = "$Message - at {0} Line {1} | {2}" -f (Split-Path $MyInvocation.ScriptName -Leaf), $MyInvocation.ScriptLineNumber, $TraceTimer.Elapsed

        if($AsWarning) {
            Write-Warning $Message
        } else {
            Write-Verbose $Message
        }
    }

    end {
        if($KillTimer) {
            $Script:TraceTimer.Stop()
            $Script:TraceTimer = $null
        }
    }
}

function Set-AliasToFirst {
    param(
        [string[]]$Alias,
        [string[]]$Path,
        [string]$Description = "the app in $($Path[0])...",
        [switch]$Force,
        [switch]$Passthru
    )
    if($App = Resolve-Path $Path -EA Ignore | Sort-Object LastWriteTime -Desc | Select-Object -First 1 -Expand Path) {
        foreach($a in $Alias) {
            Set-Alias $a $App -Scope Global -Option Constant, ReadOnly, AllScope -Description $Description -Force:$Force
        }
        if($Passthru) {
            Split-Path $App
        }
    } else {
        Write-Warning "Could not find $Description"
    }
}
function Reset-Module ($ModuleName) {
    Remove-Module $ModuleName; Import-Module $ModuleName -Force -PassThru | Format-Table Name, Version, Path -AutoSize
}

function Get-Uptime {
    param([switch]$FromSleep)
    try {
        if (-not $FromSleep) {
            $os = Get-CimInstance win32_operatingsystem
            $uptime = (Get-Date) - ($os.lastbootuptime).ToDateTime($_)
        }
        else {
            $Uptime = (((Get-Date)- (Get-EventLog -LogName system -Source 'Microsoft-Windows-Power-Troubleshooter' -Newest 1).TimeGenerated))
        }
        $Display = "" + $Uptime.Days + " days,  " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes"

        Write-Output $Display
    }
    catch {Write-Error -Message 'An error occured.'}
}


function cpanel { Start-Process "explorer.exe" -ArgumentList "shell:::{ED7BA470-8E54-465E-825C-99712043E01C}" }

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
if (!(Get-Module -ListAvailable | Where-Object {$_.Name -eq "Connect-Mstsc"})) {
    Write-Output 'Connect-Mstsc module not found.'
    Write-Output "'rdp' function will not work. Please make sure the module is present."
    } else {
        #rdp quick~!
        Function rdp {
            Param([Parameter(Mandatory=$true)] $servername)
            switch ($servername) {
                127.0.0.1 { write-output "no no no!" }
                localhost { Write-Output "NO"}
                default { 
                    if (Get-Module BetterCredentials) {
                        Connect-Mstsc $servername (BetterCredentials\Get-Credential "$env:USERDOMAIN\$env:username") 
                    } else {
                        Connect-Mstsc $servername (Get-Credential "$env:USERDOMAIN\$env:username")
                    }
                }
            }
        }
    }

function cpanel { Start-Process "explorer.exe" -ArgumentList "shell:::{ED7BA470-8E54-465E-825C-99712043E01C}" }
