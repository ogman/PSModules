# TODO
#
# Create a runcom.cmd (like bashrc in linux)
# see http://superuser.com/questions/144347/is-there-windows-equivalent-of-the-bashrc-file-in-linux
#
# make cmd prompt nicer 
# http://www.hanselman.com/blog/ABetterPROMPTForCMDEXEOrCoolPromptEnvironmentVariablesAndANiceTransparentMultiprompt.aspx
#
# change background function that changes wallpaper and login screen
# http://www.techspot.com/guides/224-change-logon-screen-windows7/


[System.Reflection.Assembly]::`
  LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null

$profilepath = Split-Path $PROFILE -parent

function Extract-Zip {
param(
  [string] $zipfilename, 
  [string] $destination
)
    
$zipfilename = (Get-Item $zipfilename).FullName
if(-not (Test-Path $destination)) {
  mkdir $destination
}
$destination = (Get-Item $destination).FullName

if(test-path($zipfilename)) { 
  $shellApplication = new-object -com shell.application
  $zipPackage = $shellApplication.NameSpace($zipfilename)
  $destinationFolder = $shellApplication.NameSpace($destination)
  $items = $zipPackage.Items()
  $destinationFolder.CopyHere($items)
  return
}
Write-Host "Can't extract $zipfilename"
}

Function DownloadZippedProfile {
    # temporary redirect
    # $profilepath = ("{0}_tmp" -f $profilepath)
    # Write-Host $profilepath

    $tempPath = $env:TEMP

    $tempProfileZip = "$tempPath\PSProfile.zip"
    $tempProfileUnzip = "$tempPath\PSProfile"
    # Write-Host $tempProfileZip

    if(Test-Path $tempProfileZip) {
      Write-Warning "$tempProfileZip exixts and it will be removed"
      Remove-Item $tempProfileZip
    }

    # fetch profile
    Write-Host "Donwloading https://github.com/ogman/PSModules/archive/master.zip"
    Write-Host "         to $tempProfileZip"
    (New-Object System.Net.WebClient).`
      DownloadFile("https://github.com/ogman/PSModules/archive/master.zip", `
                 $tempProfileZip)
    Write-Host "Done"

    Write-Host "Unziping $tempProfileZip"
    Write-Host "      to $tempProfileUnzip"


    Remove-Item -Recurse -Force $tempProfileUnzip -ErrorAction SilentlyContinue
    Extract-Zip -zipfilename $tempProfileZip -destination $tempProfileUnzip
#    [System.IO.Compression.ZipFile]::`
#      ExtractToDirectory($tempProfileZip, $tempProfileUnzip)
    Write-Host "Done"

    Write-Host "Moving unziped content to $profilepath"
    Move-Item "$tempProfileUnzip\PSModules-master" $profilepath
    Write-Host "Done"
}

$gitExists = Get-Command git -ErrorAction SilentlyContinue
if(-not ($gitExists -eq $null)) {
  if(Test-Path $profilepath\.git) {
    Write-Host "profile is already a git repo. updating..."
    git pull
  } else {
    if(Test-Path $profilepath) {
      Write-Warning "$profilepath exists and it will be deleted"
      Remove-Item -Recurse -Force $profilepath
    }
    git clone https://github.com/ogman/PSModules.git $profilepath
  }
} else {
  if(Test-Path $profilepath) {
    Write-Warning "$profilepath exists and it will be deleted"
    Remove-Item -Recurse -Force $profilepath
  }
  DownloadZippedProfile
}

if(-not $env:Path.tolower().Contains("chocolatey")) {
  iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
  $env:PATH="{0};{1}\chocolatey\bin" -f $env:PATH,$env:SystemDrive
}

if(-not ((Get-Command vim -ErrorAction SilentlyContinue) -eq $null)) {
  cinst vim
}

Write-Host "Creating .vimrc softlink"
if(Test-Path "$env:USERPROFILE\.vimrc") {
  Remove-Item -Force "$env:USERPROFILE\.vimrc"
}

start cmd `
  -ArgumentList @("/c","mklink $env:USERPROFILE\.vimrc $profilepath\.vimrc") `
  -WindowStyle Hidden `
  -verb runas `
  -ErrorAction SilentlyContinue | Out-Host
Write-Host "Done"

Write-Host "Creating vimfiles junction"
if(Test-Path "$env:USERPROFILE\vimfiles") {
  $junction = Get-Item "$env:USERPROFILE\vimfiles"
  $junction.Delete()
}

cmd /c mklink /J $env:USERPROFILE\vimfiles $profilepath\vimfiles

Write-Host "Done"
Write-Host " "

#setup cmd.exe
$runcomcontent = @'
@echo off
SET PROMPT=$_%USERNAME%@%COMPUTERNAME%$S$P$_$$$G$S

IF EXIST %USERPROFILE%\runcom.cmd (
  %USERPROFILE%\runcom.cmd
)
'@

@'
@echo off

REM doskey ls=dir $*
REM doskey :q=exit
REM doskey clear=cls

'@ | Out-File $env:USERPROFILE\runcom.cmd -Encoding ASCII

$asAdminCommand = @"
Set-Location 'HKLM:\Software\Microsoft\Command Processor'; 
Set-ItemProperty . 'AutoRun' 'C:\Windows\runcom.cmd';
'$runcomcontent' | Out-File C:\Windows\runcom.cmd -Encoding ASCII
"@

start powershell `
  -WindowStyle Hidden `
  -verb runas `
  -ArgumentList "-Command",$asAdminCommand `
  | Out-Host

Write-Host "Restart your shells."
Write-Host " "

