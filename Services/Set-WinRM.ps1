<#
  .SYNOPSIS
  Example of setting WinRM service for HTTPS Listener.

  .DESCRIPTION
  Issuing computer certificate and installing on WinRM service.

  .LINK
  https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html
  https://docs.microsoft.com/en-us/powershell/module/pki/get-certificate?view=windowsserver2022-ps

  .NOTES
  Author: Dorofeev Roman
  Date: 2022.05.18
#>

Write-Host

# set WinRM service
Write-Host "Start WinRM service" -ForegroundColor Green
Get-Service -Name WinRM | Set-Service -Status Running -StartupType Automatic

# issuing certificate for WinRM HTTPS from local CA
Write-Host "Setting certificate" -ForegroundColor Green
$winrmCert = Get-Certificate -Template Machine -DnsName "$env:computername.$env:userdnsdomain" -Url ldap: -CertStoreLocation cert:\LocalMachine\My
(Get-ChildItem -Path "cert:\LocalMachine\My\$($winrmCert.Certificate.Thumbprint)").FriendlyName = "WinRM-$env:computername"

# setting of WinRM HTTPS listener
Write-Host "Setting WinRM HTTPS" -ForegroundColor Green
$selector_set = @{
    Address = "*"
    Transport = "HTTPS"
}
$value_set = @{
    CertificateThumbprint = "$($winrmCert.Certificate.Thumbprint)"
}
New-WSManInstance -ResourceURI "winrm/config/Listener" -SelectorSet $selector_set -ValueSet $value_set

# view current WinRM parameters
winrm get winrm/config/Service
winrm enumerate winrm/config/Listener
# Get-WSManInstance -ResourceURI winrm/config/listener -SelectorSet @{Address="*";Transport="http"}

# setting HTTP service for fix kerberos max token size issue (optional)
Write-Host "Setting HTTP-service" -ForegroundColor Green
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\HTTP\Parameters" /v MaxFieldLength /t REG_DWORD /d 0x0000ffff /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\HTTP\Parameters" /v MaxRequestBytes /t REG_DWORD /d 0x0000ffff /f
Get-Service -Name WinRM | Restart-Service

<#
Optional
# remove HTTPS listener if he exist
Get-ChildItem -Path WSMan:\localhost\Listener | Where-Object { $_.Keys -contains "Transport=HTTPS" } | Remove-Item -Recurse -Force

# remove all listeners
Remove-Item -Path WSMan:\localhost\Listener\* -Recurse -Force
#>
