# Uninstall the DefenceTest Windows Scheduled Task.
param([string]$TaskName = "DefenceTestWorker")

$ErrorActionPreference = "SilentlyContinue"
Stop-ScheduledTask -TaskName $TaskName
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
Write-Host "Scheduled task '$TaskName' removed."
