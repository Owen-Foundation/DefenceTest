# Commands — the total reference

Every command for running, operating and automating DefenceTest.
Replace `<server-host>` with the current test-server hostname (published in
the [Owen homepage](https://owen.hsrprojects.org) Testing section).

## 1. Worker: run games

```bash
git clone https://github.com/Owen-Foundation/DefenceTest.git
cd DefenceTest/worker
python3 worker.py USERNAME PASSWORD --host <server-host> --port 443
```

No `pip install` — pure Python 3.8+ stdlib. Needs a C++ compiler, `make`
and `cmake`. First run writes `defencetest.cfg`; later runs reuse it
(`USERNAME PASSWORD` then optional).

### All worker flags

| Flag | Short | Default | Meaning |
|------|-------|---------|---------|
| `--protocol` | `-P` | `https` | `http` or `https` |
| `--host` | `-n` | live server | Server hostname (or `DEFENCETEST_HOST` env) |
| `--port` | `-p` | `443` | Server port |
| `--concurrency` | `-c` | `max(1,min(3,MAX-1))` | Max cores (`MAX` = cpu_count) |
| `--max_memory` | `-m` | `MAX/2` | Max memory MiB (`MAX` = total RAM) |
| `--uuid_prefix` | `-u` | `_hw` | UUID prefix (`_hw` = hardware-derived) |
| `--min_threads` | `-t` | `1` | Reject tasks with fewer threads |
| `--fleet` | `-f` | `False` | Quit on error or empty queue |
| `--global_cache` | `-g` | (empty) | Shared cache dir for multi-worker setups |
| `--compiler` | `-C` | `g++` | `g++` or `clang++` for engine builds |
| `--only_config` | `-w` | flag | Write config + SRI hashes, then exit |
| `--no_validation` | | flag | Skip credential check (debugging) |

`worker_arch` is reported automatically (`x86_64`/`arm64` on every OS/CPU —
Linux, macOS incl. Tahoe, Windows).

### Run 24/7 (daemons)

```bash
# Linux systemd:  sudo ./daemon/install_service.sh
# macOS launchd:  ./daemon/install_service.sh
./daemon/start_worker.sh        # foreground start
./daemon/stop_worker.sh         # stop
```

```powershell
# Windows Task Scheduler (Administrator PowerShell):
.\daemon\install_service.ps1
.\daemon\start_worker.ps1
.\daemon\stop_worker.ps1
.\daemon\uninstall_service.ps1
```

## 2. Accounts

- Sign up at `https://<server-host>/signup`, solve the slider puzzle —
  approved instantly, log in right away.
- Your first test runs need one manual approval; after **500 contributed
  games** your runs start automatically (approvers always start instantly).

## 3. Server operator: systemd units

```bash
systemctl status defencetest-server.service   # web app (uvicorn, :8101)
systemctl status defencetest-tunnel.service   # public quick tunnel
systemctl status defencetest-stats.timer      # contributor stats, 15 min
docker ps | grep defencetest-mongo             # MongoDB (localhost only)
journalctl -u defencetest-server -f            # live logs
journalctl -u defencetest-tunnel -n 30 --no-pager   # current public URL
```

### Environment (`/etc/defencetest/env`)

| Variable | Meaning |
|----------|---------|
| `DEFENCETEST_AUTHENTICATION_SECRET` | Cookie signing secret (required) |
| `DEFENCETEST_URL` | Public server URL (required in prod) |
| `DEFENCETEST_NN_DIR` | Net `.gz` store (default `/var/www/defencetest/nn`) |
| `OPENAPI_URL` | Set to `/openapi.json` to expose the API schema |
| `GH_TOKEN` | GitHub PAT — raises API limit 60 → 5000/hr |

### MongoDB (localhost:27017, databases)

```bash
docker exec defencetest-mongo mongosh --quiet --eval "db.runCommand({ping:1})"
# app data: defencetest_new | test data: defencetest_tests
```

### Upload a network (as approver)

Web UI: `/upload` — file must be named `nn-<sha256[:12]>.o2nn`
(must match its own content hash). Workers fetch it via `/api/nn/<name>`.

### Contributor stats

Rebuilt by `server/utils/delta_update_users.py` (timer, 15 min). Only
accepted `wins+losses+draws` credit the worker's login username; crashes,
time-losses and rejected submissions never count.

## 4. Machine API (workers + scripts)

Base `https://<server-host>`; mutating worker calls send
`worker_info` + password. Full interactive reference with Scalar lives on
the [Owen docs site](https://owen.hsrprojects.org/docs/api.html).

| Method + path | Who | Purpose |
|---|---|---|
| `POST /api/request_task` | worker | fetch games to play |
| `POST /api/update_task` | worker | submit W/D/L batch |
| `POST /api/failed_task` | worker | report broken task |
| `POST /api/beat` | worker | heartbeat |
| `POST /api/request_version` | worker | credential + version check |
| `POST /api/request_spsa` | worker | next SPSA parameters |
| `POST /api/upload_pgn` | worker | upload game PGN |
| `POST /api/worker_log` | worker | remote log tail |
| `POST /api/stop_run` | worker | request run stop |
| `POST /api/actions` | user | event log query |
| `GET /api/active_runs` | user | live runs (JSON) |
| `GET /api/finished_runs` | user | finished runs (JSON) |
| `GET /api/get_run/{id}` | user | one run (JSON) |
| `GET /api/get_task/{id}/{task_id}` | user | one task (JSON) |
| `GET /api/get_elo/{id}` | user | Elo estimate |
| `GET /api/calc_elo` | user | Elo calculator |
| `GET /api/pgn/{id}` | user | run PGN download |
| `GET /api/run_pgns/{id}` | user | all PGNs of a run |
| `GET /api/nn/{name}` | worker | download network bytes |
| `GET /api/rate_limit` | user | GitHub API quota state |
| `GET /captcha-puzzle` | public | slider-puzzle challenge (JSON) |
| `GET /openapi.json` | public | machine-readable schema |

## 5. Run management (approvers)

- **Approve**: run page → Approve button (never your own — ask a second approver).
- **Auto-approve**: approvers + 500-game contributors start instantly.
- **Stop/purge**: run page actions (stopping needs contributed games).
- **Block worker/user**: Workers / user-management pages.
- **Read results**: run page (live Elo/SPRT gauges) → Finished list → Events log.

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| `Cannot reach …` at worker start | wrong `--host`; copy it from the Owen homepage |
| `Invalid or missing credentials` | create the account on the server first (`/signup`) |
| `No tasks available` | no approved runs, or a same-name worker already connected (one worker per folder; stale guards expire in ~2 min) |
| Task fails at engine build | install `cmake` (`brew install cmake` on macOS) |
| `Captcha incorrect` | drag the piece fully into the hole; ↻ for a fresh puzzle |
| `Invalid domain for site key` | gone — that was Google reCAPTCHA, replaced by the built-in slider |
| Empty Contributors page | `defencetest-stats.timer` must be active; names appear ≤15 min after accepted games |
| GitHub `rate limit` errors | set `GH_TOKEN` in server env and restart |
