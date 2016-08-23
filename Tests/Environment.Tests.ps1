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
            Add-Path -Name userenv -Prepend "C:\prepended"
            ((Get-Item Env:\userenv).Value -split ';')[0] | Should Be "C:\prepended"
        }
        It 'appends correctly' {
            Add-Path -Name userenv -Append "C:\appended"
            ((Get-Item Env:\userenv).Value -split ';')[-1] | Should Be "C:\appended"
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

       }
    }
}