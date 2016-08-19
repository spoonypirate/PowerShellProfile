##posh-git-vagrant-status

A set of PowerShell scripts which provide Git/PowerShell integration and provide the simple or detailed status of the vagrant machines in the current directory. This is a merge of the [posh-git](https://github.com/dahlbyk/posh-git) and [vagrant-status](https://github.com/n00bworks/vagrant-status) repositories

### Prompt for Git repositories and Vagrant status
   The prompt within Git repositories can show the current branch and the state of files (additions, modifications, deletions) within.

### Prompt for Vagrant folders
   The prompt is defined in the profile.base.ps1 which will output a working directory as well as a simple/detailed vagrant status indicator depending on your choice. profile.base.ps1 has two options which can be commented in or out. Don't leave both out or in.

#### Detailed

   A basic example layout of this status is [D:0 R:1].

   The D(own) or 'poweroff/aborted in vagrant status' collects the number of machines for the current directory (vagrant environment) that are in that state. This will be colored in gray

   The R(unning) or 'running in vagrant status' collects the number of machines for the current directory (vagrant environment) that are in that state. This will be colored in green

   If there is a vagrantfile but no (D)own or (R)unning aka 'not created in vagrant status' machines you will see [-] in grey. This is to convey that there is a dormant vagrant environment in the current directory.

#### Simple

   If there is an active Vagrant machine(s) you will see [^] the ^ is colorized in green. If there is a vagrantfile and/or folder but no Vagrant machine(s) active you will see [-].

### Tab completion
   Provides tab completion for common commands when using git.  
   E.g. `git ch<tab>` --> `git checkout`

Usage
-----

See [posh-git](https://github.com/dahlbyk/posh-git) for more information on the usage of tab completion and its setup in `profile.base.ps1`

Note on performance: displaying file status in the git prompt for a very large repo can be prohibitively slow. Rather than turn off file status entirely, you can disable it on a repo-by-repo basis by adding individual repository paths to $GitPromptSettings.RepositoriesInWhichToDisableFileStatus.

The Vagrant portion of this prompt was originally powered by Vagrant's "Vagrant Status" command however this has proven to be quite slow for use on a prompt. ~4-10 second rendering time between prompt display is a bit much. So for the time being that code has been left in but not used. If you want to try it out feel free to change "Write-VagrantStatus" to "Write-VagrantStatusVS" in profile.base.ps1

### Installing

1. Clone this repo
2. In PowerShell make sure that your ExecutionPolicy is Unrestricted
  * Get-ExecutionPolicy will show you current ExecutionPolicy.
  * Set-ExecutionPolicy Unrestricted will set your ExecutionPolicy to Unrestricted.
3. Run install.ps1 to install to your profile


### Contributing

 1. Fork it
 2. Create your feature branch (git checkout -b my-new-feature)
 3. Commit your changes (git commit -am 'Add some feature')
 4. Push to the branch (git push origin my-new-feature)
 5. Create a new Pull Request
