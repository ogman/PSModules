﻿$PSM = (Split-Path $PROFILE -Parent)
$PSM = "$PSM\Modules"
if (-not ($env:PSModulePath -like "*$PSM*")) {
  $env:PSModulePath = "$($env:PSModulePath);$PSM"
}

Import-Module posh-util
Import-Module vcs-commands

Update-Profile
Register-PoshGit

function Global:prompt {
  # Set up a simple prompt, adding the git prompt parts inside git repos
  # try {
  $vcsStatus = Get-VcsStatus
  # } catch {
  #   "$error"
  # }
  return $vcsStatus
}

function vs10cmd {
  & $env:comspec /k '"C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat"' x86
}

function vs12cmd {
  & $env:comspec /k '"C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\Tools\VsDevCmd.bat"'
}

# function to help binding exit keyword to an alias
function ex{exit}

#######################################################################################
##################### Variables #######################################################
#######################################################################################
$notepad    = "C:\Program Files (x86)\Notepad++\notepad++.exe"

$devenv10   = "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe"
$devenv11   = "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\devenv.exe"
$devenv12   = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\devenv.exe"
$devenv     = $devenv12

$mstest11   = "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\mstest.exe"
$mstest12   = "C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\mstest.exe"
$mstest     = $mstest12

$msbuild3_5 = "C:\Windows\Microsoft.NET\Framework64\v3.5\MSBuild.exe"
$msbuild4   = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe"
$msbuild    = $msbuild4

$procex     = "C:\Chocolatey\lib\procexp.15.13\tools\procexp.exe"
$hosts      = "C:\Windows\System32\drivers\etc\hosts"

#######################################################################################
##################### Aliasses ########################################################
#######################################################################################
Set-Alias notepad  "C:\Program Files (x86)\Notepad++\notepad++.exe"
Set-Alias devenv   "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe"
Set-Alias devenv10 "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe"
Set-Alias devenv11 "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\devenv.exe"
Set-Alias msbuild  "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe"
Set-Alias mstest   "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\mstest.exe"
Set-Alias procex   "C:\ProgramData\chocolatey\bin\procexp.exe"
Set-Alias remote   "mstsc"
Set-Alias :q       ex
Set-Alias ^Q       ex
Set-Alias l        ls


# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

Set-ExecutionPolicy RemoteSigned  -Scope Process -Confirm:$false
