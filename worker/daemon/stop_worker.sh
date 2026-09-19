#!/usr/bin/env bash
# Stop the background DefenceTest worker started by start_worker.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIDFILE="$HERE/worker.pid"
# The worker also exits on this marker file.
WORKER_DIR="$(cd "$HERE/.." && pwd)"

if [[ ! -f "$PIDFILE" ]]; then
  echo "no pid file ($PIDFILE); nothing to stop"
  # Clean up any stale fish.exit marker
  rm -f "$WORKER_DIR/fish.exit"
  exit 0
fi

PID="$(cat "$PIDFILE")"
if kill -0 "$PID" 2>/dev/null; then
  touch "$WORKER_DIR/fish.exit"
  kill "$PID" 2>/dev/null || true
  for _ in $(seq 1 100); do
    kill -0 "$PID" 2>/dev/null || break
    sleep 0.2
  done
  kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null || true
  echo "worker $PID stopped"
else
  echo "worker $PID not running"
fi
rm -f "$PIDFILE"
