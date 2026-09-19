#!/usr/bin/env bash
# Install the DefenceTest worker as a system service (systemd on Linux,
# launchd on macOS). Re-run to update; keep the same working directory.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKER_DIR="$(cd "$HERE/.." && pwd)"
PYTHON="$(command -v "${PYTHON:-python3}")"
CONCURRENCY="${CONCURRENCY:-}"
ARGS="worker.py"
[[ -n "$CONCURRENCY" ]] && ARGS="$ARGS --concurrency $CONCURRENCY"
OS="$(uname -s)"

case "$OS" in
Linux)
  UNIT="/etc/systemd/system/defencetest-worker.service"
  echo "Installing systemd unit: $UNIT"
  sudo tee "$UNIT" >/dev/null <<EOF
[Unit]
Description=DefenceTest Worker
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$WORKER_DIR
ExecStart=$PYTHON $ARGS
Restart=always
RestartSec=30
Nice=10
# Store config/logs with the worker instead of in /root:
Environment=HOME=$WORKER_DIR

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now defencetest-worker.service
  echo "Started. Status:  systemctl status defencetest-worker"
  echo "Logs:            journalctl -u defencetest-worker -f"
  ;;
Darwin)
  LABEL="org.owen.defencetest.worker"
  PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
  mkdir -p "$HOME/Library/LaunchAgents" "$HERE/logs"
  cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$PYTHON</string>
    <string>$WORKER_DIR/worker.py</string>
  </array>
  <key>WorkingDirectory</key><string>$WORKER_DIR</string>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$HERE/logs/worker.log</string>
  <key>StandardErrorPath</key><string>$HERE/logs/worker.log</string>
  <key>ProcessType</key><string>Background</string>
</dict></plist>
EOF
  launchctl unload "$PLIST" 2>/dev/null || true
  launchctl load "$PLIST"
  echo "Loaded launchd agent: $LABEL"
  echo "Logs: $HERE/logs/worker.log"
  ;;
*)
  echo "Unsupported OS: $OS (use start_worker.sh for a plain background run)" >&2
  exit 1
  ;;
esac
