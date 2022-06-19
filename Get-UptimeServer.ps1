<#
  .SYNOPSIS
  Uptime windows server.

  .DESCRIPTION
  The script get uptime from locally or remote host.

  .PARAMETER ComputerName
  Name of computer where will checking local Administrators group. If not defined will use
  local host

  .EXAMPLE
  .\Get-UptimeServer.ps1

  .EXAMPLE
  .\Get-UptimeServer.ps1 -Computer <NAME>

  .LINK
  https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-wmiobject?view=powershell-5.1

  .NOTES
  Author: Dorofeev Roman
  Date: 2019.07.03
#>


param (
    [Parameter (Position=1)]
    [string]$Computer = $env:computername
)

$wmio = Get-WmiObject win32_operatingsystem -ComputerName $Computer

$LocalTime = [datetime]::ParseExact($($wmio.localdatetime).split('.')[0],'yyyyMMddHHmmss',$null)

$LastBootUptime = [datetime]::ParseExact($($wmio.lastbootuptime).split('.')[0],'yyyyMMddHHmmss',$null)

$timespan = $localTime - $lastBootUptime

Write-Host "`n", "Local time on host", $Computer -ForegroundColor Green
Write-Host $LocalTime.ToString("dd.MM.yyyy HH:mm")

Write-Host "`n", "Startup time" -ForegroundColor Green
Write-Host $LastBootUptime.ToString("dd.MM.yyyy HH:mm")

Write-Host "`n", "Uptime" -ForegroundColor Green
Write-Host $timespan
$timespan  | select Days,Hours,Minutes,Seconds
Write-Host
