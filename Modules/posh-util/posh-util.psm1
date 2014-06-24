# powershell utility functions
#

$profilepath = Split-Path $PROFILE -parent

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
Push-Location $PSScriptRoot
. .\profile-util.ps1
. .\ini-files.ps1
Pop-Location

function Invoke-PreservingExitCode {
<#
.SYNOPSIS
    An utility function for executing a scriptblock while preserving the exit code.
.EXAMPLE
    Invoke-PreservingExitCode { param($p); cd ..\$p } -arguments $myarg
#>
param(
  [scriptblock] $script,
  [array] $arguments
)
  $realLASTEXITCODE = $LASTEXITCODE
  
  try {
    $result = Invoke-Command -scriptblock $script -argumentlist $arguments
  } finally {
    $Global:LASTEXITCODE = $realLASTEXITCODE
  }

  return $result
}


Set-Alias rc                  Restore-AllModules
Set-Alias rstcon              Restore-AllModules

Export-ModuleMember -Function Invoke-PreservingExitCode
Export-ModuleMember -Function Restore-AllModules
Export-ModuleMember -Function Restore-Profile
Export-ModuleMember -Function Update-Profile

Export-ModuleMember -Alias    rc
Export-ModuleMember -Alias    rstcon

Export-ModuleMember -Variable profilepath

