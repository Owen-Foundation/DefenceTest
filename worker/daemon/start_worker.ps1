# Start the DefenceTest worker in the background on Windows (fishnet-style).
# Logs to daemon\worker.log; PID saved to daemon\worker.pid.
param(
    [string]$Python = "",
    [int]$Concurrency = 0,
    [string]$Arguments = ""
)

$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkerDir = Split-Path -Parent $Here
$PidFile = Join-Path $Here "worker.pid"
$LogFile = Join-Path $Here "worker.log"

if (-not $Python) {
    $Python = (Get-Command python -ErrorAction SilentlyContinue).Source
    if (-not $Python) { $Python = (Get-Command py -ErrorAction SilentlyContinue).Source }
}
if (-not $Python) { throw "Python not found on PATH. Install Python 3.9+ first." }

if (Test-Path $PidFile) {
    $old = Get-Content $PidFile
    if (Get-Process -Id $old -ErrorAction SilentlyContinue) {
        Write-Host "worker already running (pid $old)"
        exit 0
    }
}

$argList = @("worker.py")
if ($Concurrency -gt 0) { $argList += @("--concurrency", "$Concurrency") }
if ($Arguments) { $argList += $Arguments.Split(" ") }

$proc = Start-Process -FilePath $Python -ArgumentList $argList `
    -WorkingDirectory $WorkerDir -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput $LogFile -RedirectStandardError "$LogFile.err"

$proc.Id | Out-File -Encoding ascii $PidFile
Write-Host "worker started (pid $($proc.Id)) -> $LogFile"
