<#
  .SYNOPSIS
  Output members of group local Administrators on current or remote computer.

  .DESCRIPTION
  The script use Get-LocalGroupMember cmdlet. Supported of Windows with Russian locale.
  Information from remote host is requested via WMI, therefore need administrative right
  and accessover network.
  Script need import as module with cmdlet Import-Module
  (Import-Module .\Get-LocalAdmins.ps1).

  .PARAMETER ComputerName
  Name of computer where will checking local Administrators group. If not defined will use
  local host

  .OUTPUTS
  List members of local Administrators group on specified computer or localhost

  .EXAMPLE
  Get-LocalAdmins

  .EXAMPLE
  Get-LocalAdmins <COMPUTER_NAME>

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-wmiobject?view=powershell-5.1
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localgroupmember?view=powershell-5.1

  .NOTES
  Author: Dorofeev Roman
  Date: 2020.08.03
#>

function Get-LocalAdmins { 

    param (
        [string]$ComputerName
    )

    if (!($ComputerName) -or ($env:computername -eq $ComputerName) -or ("$env:computername.$env:userdnsdomain" -eq $ComputerName)) {
        if ($([CultureInfo]::InstalleduICulture).Name -eq "ru-RU") {
            $admins = Get-LocalGroupMember -Group "Администраторы"
        } else {
            $admins = Get-LocalGroupMember -Group "Administrators"
        }
        return $admins
    }

    try {
        $admins = gwmi Win32_GroupUser -ComputerName $ComputerName -ErrorAction Stop | `
            ? { ($_.GroupComponent -like '*"Administrators"') -or ($_.GroupComponent -like '*"Администраторы"') }
    } catch {
        return $error[0].Exception
    }

    $admins = $admins | % {
        $_.PartComponent -match ".+Domain\=(.+)\,Name\=(.+)$" > $nul
        $matches[1].trim('"') + "\" + $matches[2].trim('"') 
    }

    return $admins

}
