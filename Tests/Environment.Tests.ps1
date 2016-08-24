Import-Module -Force $PSScriptRoot\..\Modules\Environment\Environment.psm1

Describe 'Set-EnvironmentVariable' {
    Context 'Adds Path' {
        It 'sets a variable' {
            Set-EnvironmentVariable -name "newenv" -Value "C:\somedir"
            (Compare-Object -ReferenceObject $env:newenv -DifferenceObject "C:\somedir").InputObject | Should beNullOrEmpty
        }
    }
}

Describe 'Add-Path' {
    Context 'SinglePath' {
        It 'prepends correctly' {
            $a = "C:\prepended"
            Add-Path -Name userenv -Prepend $a
            $b = ((Get-Item Env:\userenv).Value -split ';')[0]
            (Compare-Object $a $b).InputObject | Should BeNullOrEmpty
        }
        It 'appends correctly' {
            $a = "C:\appended"
            Add-Path -Name userenv -Append $a
            $b = ((Get-Item Env:\userenv).Value -split ';')[-1] 
            (Compare-Object $a $b).InputObject| Should BeNullorEmpty
        }
    }
    Context 'NoPath' {
        It 'keeps the same' {
            $a = ((Get-Item Env:userenv).Value -split ';')
            Add-Path -Name userenv
            $b = ((Get-Item Env:userenv).Value -split ';')
            (Compare-Object -ReferenceObject $a -DifferenceObject $b).InputObject | Should beNullOrEmpty
        }
    }
    Context 'PathArray' {
       it 'works with arrays' {
           $a = @("C:\path1","C:\path2")
           Add-Path -Name userenv -Append $a
           $b = ((Get-Item Env:userenv).Value -split ';')[-2,-1]
           (Compare-Object $b $a).InputObject | Should BeNullOrEmpty
       }
    }
}