function Connect-RemoteDesktop {
<#
.SYNOPSIS 
    A utility function for connecting to remote desktop
.EXAMPLE
    Connect-RemoteDesktop 192.168.1.2
.PARAMETER machine
    The machine name or the ip address of the machine
#>

# this seems to be important when you need the common parametes to work with your modules
[CmdletBinding()]


param(
  $machine
)
  Assert-Mstsc
  
  if($machine -eq $null) {
    Write-Verbose "I: Getting available machines from history"
    $machine = (Get-AvailableMachines | Get-UserSelection)
  }

  if($machine -eq $null) {
    # mstsc
    return
  }

  Backup-Input $machine

  # mstsc /v:$machine
}

function Assert-Mstsc {
  $mstsc = $null
  ($mstsc = Get-Command mstsc -ErrorAction Continue) | Out-Null
  
  if ($mstsc -eq $null) {
    $nomstscerror = New-Object `
      'System.InvalidOperationException' `
      -ArgumentList 'mstsc not found'

    throw $nomstscerror
  }
}

function Get-AvailableMachines {
  [array] $availableMachines = @()

  if (!(Get-Command Get-IniContent -TotalCount 1 -ErrorAction SilentlyContinue)) {
    Write-Verbose "W: Get-IniContent not found. Connections history will not be available"
    return $availableMachines
  }
  
  $filepath = "$profilepath\.data\Connect-RemoteDesktop.ini"
  $fileExists = Test-Path $filepath
  
  if(-not $fileExists) {
    Write-Verbose "I: '$filepath' does not exists"
    return $availableMachines
  }

  $content = Get-IniContent $filepath
  
  $machines = $content["machines"]
  Write-Verbose "Machines found"

  $hashtableType = @{}.GetType()

  $machines | %{ 
    Write-Verbose "is item hashtable? "
    if($_.GetType() -eq $hashtableType) {
      Write-Verbose "yes"
      $_ | %{
        $mKey = $_.Key
        $mValue = $_.Value
        Write-Verbose "$mKey = $mValue"
      }
    } else {
      Write-Verbose "no"
      $mKey = $_.Key
      $mValue = $_.Value
      Write-Verbose "$mKey = $mValue" 
    }
  }
  Write-Verbose "=============="
  $aliases = $content["aliases"]
  Write-Verbose "Aliases found"
  $aliases | %{ Write-Verbose "$_.Key = $_.Value" }
  Write-Verbose "=============="

  $machines | % {
    $machine = New-Object PSObject
    $machine | Add-Member NoteProperty -Name ID -Value $_.Key
    $machine | Add-Member NoteProperty -Name IP -Value $_.Value
    $machine | Add-Member NoteProperty -Name Alias -Value $aliases[$_.Key]
   
    $availableMachines += $machine
  }

  
  return $availableMachines
}

function Get-UserSelection {
param(
  [array]$availableOptions
)
  $zero = 0

  if($availableOptions -le $zero) {
    return $null
  }


  Write-Host "Connections History:"
  $availableOptions | %{
    [Console]::WriteLine("{0:5} -> {1}({2})", $_.ID, $_.IP, $_.Alias)
  }
  $selection = Read-Host "Select: "

  $selectedIp = ($availableOptions | ? { `
                    $_.IP -eq $selection -or `
                    $_.Alias -eq $selection -or `
                    $_.ID -eq $selection
                  } | Select IP -First 1)

  return $selectedIp
}

function Backup-Input{
param (
  $machine
)
  $existingKey = Get-AvailableMachines | ? { $_.ID -eq $machine } | select -First 1
  if($existingKey) {
    return
  }

  if (!(Get-Command Out-IniFile -TotalCount 1 -ErrorAction SilentlyContinue)) {
    Write-Verbose "W: Out-IniFile not found. Connections history will not be available"
    return
  }
  
  $dataDirectory = "$profilepath\.data"
  $dataDirectoryExists = Test-Path $dataDirectory
  
  if(-not $dataDirectoryExists) {    
    Write-Verbose "I: '$dataDirectory' does not exists"
    md $dataDirectory
  }

  $filepath = "$profilepath\.data\Connect-RemoteDesktop.ini"
  $fileExists = Test-Path $filepath
  
  if(-not $fileExists) {    
    Write-Verbose "I: '$filepath' does not exists"
@"
[machines]

[aliases]

"@ | Out-File $filepath -Encoding ASCII
  }

  $ipPattern = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
  $entry = @{}
  switch -regex ($machine) {
    $ipPattern {
      $entry = @{ "$machine"="$machine" }
    }
    default {
      $ip = ping $machine -4 -a -n 1 |`
        sls -Pattern $ipPattern |`
        select Matches -First 1 |`
        %{ $_.Matches } | %{ $_.Value }

      $entry = @{ "$machine"="$ip" }
    }
  }

  Out-IniFile -InputObject @{ "machines"=$entry } -File $filepath -Append -Encoding ASCII
}


Set-Alias rdc Connect-RemoteDesktop

Export-ModuleMember -Function Connect-RemoteDesktop
Export-ModuleMember -Alias rdc

