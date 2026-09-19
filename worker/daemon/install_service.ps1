# Install the DefenceTest worker as a Windows Scheduled Task that auto-starts
# at logon and restarts on failure. This is the recommended Windows equivalent
# of the Linux systemd unit (no admin-only service wrapper required).
param(
    [string]$TaskName = "DefenceTestWorker",
    [string]$Python = "",
    [int]$Concurrency = 0,
    [switch]$AtStartup
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkerDir = Split-Path -Parent $Here

if (-not $Python) {
    $Python = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $Python) { $Python = (Get-Command py -ErrorAction SilentlyContinue).Source }
}
if (-not $Python) { throw "Python not found on PATH. Install Python 3.9+ first." }

$argList = @("worker.py")
if ($Concurrency -gt 0) { $argList += @("--concurrency", "$Concurrency") }

$action = New-ScheduledTaskAction -Execute $Python `
    -Argument ($argList -join " ") -WorkingDirectory $WorkerDir

$trigger = if ($AtStartup) {
    New-ScheduledTaskTrigger -AtStartup
} else {
    New-ScheduledTaskTrigger -AtLogOn
}

$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger `
    -Settings $settings -Description "DefenceTest distributed worker" -Force | Out-Null

Write-Host "Scheduled task '$TaskName' installed."
Write-Host "Start now:  Start-ScheduledTask -TaskName $TaskName"
Write-Host "Status:     Get-ScheduledTask -TaskName $TaskName"
Write-Host "Logs:       $(Join-Path $Here 'worker.log')"
