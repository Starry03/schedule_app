#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SERVICE_NAME="schedule_app_pwa_server.service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SERVICE_PATH="$SYSTEMD_USER_DIR/$SERVICE_NAME"

mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Schedule App PWA static server

[Service]
Type=simple
WorkingDirectory=$REPO_ROOT/build/web
ExecStart=/usr/bin/env python3 -m http.server 9999 --bind 127.0.0.1
Restart=always

[Install]
WantedBy=default.target
EOF

echo "Reloading systemd user daemon and enabling service..."
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME"

echo "Service installed and started. Visit http://127.0.0.1:9999"
