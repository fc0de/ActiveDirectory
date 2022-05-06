<#
  .SYNOPSIS
  Сhecking if the object belongs to the group.

  .DESCRIPTION
  The Test-ADGroupMember.ps1 script recursive search AD object (user, group, computer, etc)
  in the AD group by samaccountname attribute (i.e. login).
  May be use for check exist principal in the group.
  For execute requere ActiveDirectory module (RSAT: Active Directory Domain
  Services and Lightweight Directory Services Tools).
  Script need import as module with cmdlet Import-Module
  (Import-Module .\Test-ADGroupMember.ps1).
  Note what samaccountname of computer always contains "$" symbol in the end name.

  .PARAMETER ADObject
  Object of Active Directory for search in the group (format: samAccountName)

  .PARAMETER Group
  Name of group for check

  .OUTPUTS
  True if object find in the group or False if not.

  .EXAMPLE
  Test-ADGroupMember -ADObject <LOGIN> -Group <GROUP_NAME>

  .EXAMPLE
  Test-ADGroupMember -ADObject <LOGIN> -Group <GROUP_NAME>

  .EXAMPLE
  $groupmembers = Get-ADGroupMember -Identity <GROUP_NAME1> | % { "$($_.samAccountName)" }
  $groupmembers | % { Test-ADGroupMember $_ <GROUP_NAME2> }

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/activedirectory/get-adobject?view=windowsserver2022-ps

  .NOTES
  Author: Dorofeev Roman
  Date: 2020.05.24
#>

Import-Module ActiveDirectory

Function Test-ADGroupMember {

    param (
        [Parameter (Mandatory=$true, Position=0)]
        [string]$ADObject,
        [Parameter (Mandatory=$true, Position=1)]
        [string]$Group
    )

    Trap { Return $Error }

    try {
        $grp = Get-ADGroup -Identity $Group
    } catch {
        Write-Host "Group $Group not found in AD" -ForegroundColor Yellow
        return
    }

    $getObj = Get-ADObject -Filter "samAccountName -eq '$ADObject'"

    if ($getObj -eq $null) {
        Write-Host "samAccountName $ADObject not found in AD" -ForegroundColor Yellow
        return
    }

    if (Get-ADObject -Filter "memberOf -RecursiveMatch '$($grp.DistinguishedName)'" -SearchBase $($getObj.DistinguishedName)) {
        $true
    } else {
        $false
    }

}
