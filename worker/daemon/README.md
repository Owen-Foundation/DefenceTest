# DefenceTest worker as a background service

Run the worker like **fishnet**: unattended, auto-restarting, logging to a file.
Scripts here cover Linux, macOS, and Windows.

| Platform | Foreground | Background | Service / auto-start |
| --- | --- | --- | --- |
| Linux | `python3 worker.py` | `./daemon/start_worker.sh` | `./daemon/install_service.sh` (systemd) |
| macOS | `python3 worker.py` | `./daemon/start_worker.sh` | `./daemon/install_service.sh` (launchd) |
| Windows | `python worker.py` | `daemon\start_worker.ps1` | `daemon\install_service.ps1` (Task Scheduler) |

All scripts resolve the worker directory relative to their own location, so you
can move the folder anywhere.

## First run (all platforms)

The worker needs your DefenceTest username/password once. Either:

```bash
cd worker
python3 worker.py <username> <password> --concurrency 4
```

or edit `worker/defencetest.cfg` after the first interactive run. The password is
stored encrypted. After that the daemon scripts can launch it unattended.

## Linux / macOS

```bash
cd worker
chmod +x daemon/*.sh
./daemon/start_worker.sh            # background, pid file in daemon/
./daemon/stop_worker.sh
./daemon/install_service.sh         # systemd (Linux) or launchd (macOS)
```

Logs default to `<worker>/daemon/worker.log`.

## Windows

```powershell
cd worker\daemon
powershell -ExecutionPolicy Bypass -File .\start_worker.ps1
powershell -ExecutionPolicy Bypass -File .\install_service.ps1 -Concurrency 4
powershell -ExecutionPolicy Bypass -File .\uninstall_service.ps1
```

Auto-start is implemented with **Task Scheduler** (no admin-only service
wrapper needed) and survives logoff/reboot. Logs go to
`<worker>\daemon\worker.log`.

## Notes

- Keep `--concurrency` at or below your physical core count.
- Budget machines: use `--concurrency 1` or `2`.
- Apple Silicon (M-chip) and Windows x86_64 are fully supported.
- To stop the worker cleanly on any OS, use the stop script or Ctrl-C; the
  worker releases its task back to the server.
