# Stop the background DefenceTest worker started by start_worker.ps1.
$ErrorActionPreference = "SilentlyContinue"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkerDir = Split-Path -Parent $Here
$PidFile = Join-Path $Here "worker.pid"

# Ask the worker to exit cleanly.
New-Item -ItemType File -Force -Path (Join-Path $WorkerDir "fish.exit") | Out-Null

if (Test-Path $PidFile) {
    $pidValue = [int](Get-Content $PidFile)
    $p = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
    if ($p) {
        Stop-Process -Id $pidValue -Force
        Write-Host "worker $pidValue stopped"
    } else {
        Write-Host "worker $pidValue not running"
    }
    Remove-Item $PidFile -Force
} else {
    Write-Host "no pid file; nothing to stop"
}
