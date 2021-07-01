<#
  .SYNOPSIS
  Delegating permissions in Active Directory.

  .DESCRIPTION
  The Set-DelegatePermission.ps1 script set permissions on a domain objects of Active Directory.
  This console variant of Delegate Control option from ADUC.
  For execute requere ActiveDirectory module (RSAT: Active Directory Domain
  Services and Lightweight Directory Services Tools).
  Script need import as module with cmdlet Import-Module
  (Import-Module .\Set-DelegatePermission.ps1).
  See examples for more detailed information for using.

  .PARAMETER ADObject
  Object of Active Directory on which setting permissions (format: DistinguishedName)

  .PARAMETER Principal
  Principal (generally group or user) to whom want to delegate control

  .PARAMETER Rights
  A combination of one or more of the ActiveDirectoryRights enumeration values
  that specifies the rights of the access rule

  .PARAMETER Type
  One of the AccessControlType enumeration values that specifies the access rule type

  .PARAMETER InheritanceType
  One of the ActiveDirectorySecurityInheritance enumeration values that
  specifies the inheritance type of the access rule

  .PARAMETER ObjectType
  The schema GUID of the object to which the access rule applies

  .PARAMETER InheritedObjectType
  The schema GUID of the child object type that can inherit this access rule

  .EXAMPLE
  # Granting Full Control permissions for group for children objects user class
  Set-DelegatePermission -ADObject <DN> -Principal <GROUP_NAME> -Rights GenericAll -InheritanceType Children -InheritedObjectType User

  .EXAMPLE
  # Granting permissions for group for delete and create computer accounts in <DN> and all his children
  Set-DelegatePermission -ADObject <DN> -Principal <GROUP_NAME> -Rights "CreateChild","DeleteChild" `
                         -ObjectType "Computer" -InheritanceType "All" -InheritedObjectType "OrganizationalUnit"

  .EXAMPLE
  # Granting permissions for group for change membership of groups in <DN> and all his children of group class
  Set-DelegatePermission -ADObject <DN> -Principal <GROUP_NAME> -Rights "WriteProperty" `
                         -ObjectType "Member" -InheritanceType "Descendents" -InheritedObjectType "Group"

  .EXAMPLE
  # Example of ACL settings for LAPS: granting for computer accounts for read and write to ms-MCS-AdmPwdExpirationTime self attribute
  Set-DelegatePermission -ADObject <DN> -Principal "SELF" -Rights "ReadProperty","WriteProperty" `
                         -ObjectType "ms-MCS-AdmPwdExpirationTime" -InheritanceType "Descendents" `
                         -InheritedObjectType "Computer"

  .EXAMPLE
  # Permission on changing userAccountControl attribute of <DN> for <PRINCIPAL>
  Set-DelegatePermission -ADObject <DN> -Principal <PRINCIPAL> -Rights "ReadProperty","WriteProperty" -ObjectType "userAccountControl" -InheritanceType "None"

  .LINK
  https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.activedirectoryaccessrule.-ctor

  .NOTES
  Author: Dorofeev Roman
  Date: 2021.06.10
#>
function Set-DelegatePermission {

    param (
        [Parameter (Mandatory=$true, Position=0)]
        [string]$ADObject,
        [Parameter (Mandatory=$true, Position=1)]
        [string]$Principal,
        [Parameter (Mandatory=$true, Position=2)]
        [ValidateSet ('CreateChild', 'DeleteChild', 
                      'ListChildren', 'Self',
                      'ReadProperty', 'WriteProperty',
                      'DeleteTree', 'ListObject',
                      'ExtendedRight', 'Delete',
                      'ReadControl', 'GenericExecute',
                      'GenericWrite', 'GenericRead',
                      'WriteDacl', 'WriteOwner',
                      'GenericAll', 'Synchronize',
                      'AccessSystemSecurity')]
        [array]$Rights,
        [ValidateSet ('Allow', 'Deny')]
        [string]$Type='Allow',
        [Parameter (Mandatory=$true, Position=3)]
        [ValidateSet ('All', 'Children', 'Descendents',
                      'None', 'SelfAndChildren')]
        [string]$InheritanceType,
        [string]$ObjectType,
        [string]$InheritedObjectType
    )

    Import-Module ActiveDirectory

    try {
        $acl = Get-Acl "AD:$ADObject"
    } catch {
        Write-Host $Error[0].Exception.Message -ForegroundColor Red
        break
    }

    if ($Principal -eq 'SELF') {
        $sid = [System.Security.Principal.SecurityIdentifier]'S-1-5-10'
    } else {
        try {
            $_principal = Get-ADObject -Filter { name -eq $Principal } -Properties objectSid
        } catch {
            Write-Host $Error[0].Exception.Message -ForegroundColor Red
            break
        }

        if ($_principal.ObjectClass -notin ('group', 'user', 'computer')) {
            Write-Host "Not supported class of object for Principal - $($_principal.ObjectClass)" -ForegroundColor Red
            break
        }

        $sid = [System.Security.Principal.SecurityIdentifier]$_principal.objectSid
    }

    $identity = [System.Security.Principal.IdentityReference]$sid
    $_rights = [System.DirectoryServices.ActiveDirectoryRights]($Rights -join ',')
    $_type = [System.Security.AccessControl.AccessControlType]$Type
    $_inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]$InheritanceType

    if ($ObjectType) {
        try {
            $_objectType = [guid](Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext `
                                               -Filter {ldapDisplayName -eq $ObjectType} `
                                               -Properties schemaIDGUID).schemaIDGUID
        } catch {
            Write-Host $Error[0].Exception.Message -ForegroundColor Red
            break
        }
    } else {
        $_objectType = '00000000-0000-0000-0000-000000000000'
    }

    if ($InheritedObjectType) {
        try {
            $_inheritedObjectType = [guid](Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext `
                                                        -Filter {ldapDisplayName -eq $InheritedObjectType} `
                                                        -Properties schemaIDGUID).schemaIDGUID
        } catch {
            Write-Host $Error[0].Exception.Message -ForegroundColor Red
            break
        }
    } else {
        $_inheritedObjectType = '00000000-0000-0000-0000-000000000000'
    }

    Write-Host
    Write-Host 'AD Object :', $ADObject -ForegroundColor Green
    Write-Host
    Write-Host '1. [System.Security.Principal.IdentityReference] : ', $identity
    Write-Host '2. [System.DirectoryServices.ActiveDirectoryRights] : ', $_rights
    Write-Host '3. [System.Security.AccessControl.AccessControlType] : ', $_type
    Write-Host '4. [ObjectType] : ', $_objectType
    Write-Host '5. [System.DirectoryServices.ActiveDirectorySecurityInheritance] : ', $InheritanceType
    Write-Host '6. [InheritedObjectType] : ', $_inheritedObjectType
    Write-Host

    $ace = [System.DirectoryServices.ActiveDirectoryAccessRule]::New($identity,
                                                                     $_rights,
                                                                     $_type,
                                                                     $_objectType,
                                                                     $_inheritanceType,
                                                                     $_inheritedObjectType)

    $acl.AddAccessRule($ace)
    Set-Acl -AclObject $acl "AD:$ADObject"

}
