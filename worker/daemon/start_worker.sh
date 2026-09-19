#!/usr/bin/env bash
# Start the DefenceTest worker in the background (Linux / macOS).
# fishnet-style: detached, survives logout, logs to daemon/worker.log.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER_DIR="$(cd "$HERE/.." && pwd)"
PIDFILE="$HERE/worker.pid"
LOGFILE="$HERE/worker.log"
PYTHON="${PYTHON:-python3}"
CONCURRENCY="${CONCURRENCY:-}"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "worker already running (pid $(cat "$PIDFILE"))"
  exit 0
fi

cd "$WORKER_DIR"
EXTRA=()
[[ -n "$CONCURRENCY" ]] && EXTRA+=(--concurrency "$CONCURRENCY")

nohup "$PYTHON" worker.py "${EXTRA[@]}" >>"$LOGFILE" 2>&1 &
echo $! >"$PIDFILE"
echo "worker started (pid $(cat "$PIDFILE")) -> $LOGFILE"
