<#
  .SYNOPSIS
  Adding or remove members of group local Administrators on remote computer (or specified list of computers).

  .DESCRIPTION
  The script use ADSI API. Supported of Windows with Russian locale.
  Information from remote host is requested via Registry, therefore need administrative right
  and access over network (including runned RemoteRegistry service).
  Script need import as module with cmdlet Import-Module
  (Import-Module .\Set-LocalAdmins.ps1).
  By default script adding security principal in group. For remove from group must set Operation
  parameter (see examples).

  .PARAMETER ComputerName
  Name of computer where will changed local Administrators group. May be specified several computers

  .PARAMETER Principal
  Object of Active Directory for adding to the group (format: SamAccountName)

  .PARAMETER Operation
  Type change of group - Add or Remove (Add by default)

  .PARAMETER Domain
  Domain where located principal

  .OUTPUTS
  Information messages or detail of errors when operations ended failure

  .EXAMPLE
  Set-LocalAdmins -ComputerName <COMPUTERNAME> -Principal <USER>

  .EXAMPLE
  Set-LocalAdmins -ComputerName <COMPUTERNAME1>,<COMPUTERNAME2>,<COMPUTERNAME3> -Principal <GROUP> -Domain <DOMAINNAME>

  .EXAMPLE
  Set-LocalAdmins -ComputerName <COMPUTERNAME> -Principal <GROUP> -Operation Remove

  .LINK
  https://docs.microsoft.com/en-us/windows/win32/adsi/using-adsi

  .NOTES
  Author: Dorofeev Roman
  Date: 2020.03.11
#>

function Set-LocalAdmins {

    param (
        [Parameter (Mandatory=$true, Position=0)]
        [string[]]$ComputerName,
        [Parameter (Mandatory=$true, Position=1)]
        [string]$Principal,
        [Parameter (Mandatory=$false)]
        [ValidateSet ('Add', 'Remove')]
        [string]$Operation = 'Add',
        [Parameter (Mandatory=$false)]
        [string]$Domain = $env:userdomain
    )

    $_Principal = [ADSI]"WinNT://$($Domain)/$($Principal)"

    if (!$_Principal.Path) {
        Write-Host "Principal $Principal not found in $Domain domain" -ForegroundColor Red
        return
    }

    Write-Host "Principal : ", $_Principal.Path -ForegroundColor Yellow
    Write-Host "Operation : ", $Operation
    Write-Host

    foreach ($comp in $ComputerName) {

        Write-Host $comp -ForegroundColor Green

        $rLanguage = reg query "\\$comp\HKLM\SYSTEM\CurrentControlSet\Control\Nls\Language" /v "InstallLanguage" | Select-String -Pattern "0419"

        if ($rLanguage) {
            $AdminsGroup = [ADSI]"WinNT://$comp/Администраторы,group"
        } else {
            $AdminsGroup = [ADSI]"WinNT://$comp/Administrators,group"
        }

        try {
            if ($Operation -eq "Add") {
                $AdminsGroup.Add($_Principal.Path)
            } elseif ($Operation -eq "Remove") {
                $AdminsGroup.Remove($_Principal.Path)
            }
        } catch {
            $Error[0].Exception
        }

    }

}
