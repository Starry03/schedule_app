#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="schedule_app_pwa_server.service"
SERVICE_PATH="$HOME/.config/systemd/user/$SERVICE_NAME"

echo "Stopping and disabling user service..."
systemctl --user stop "$SERVICE_NAME" || true
systemctl --user disable "$SERVICE_NAME" || true
systemctl --user daemon-reload || true

if [[ -f "$SERVICE_PATH" ]]; then
  rm -f "$SERVICE_PATH"
  echo "Removed $SERVICE_PATH"
fi

echo "Uninstall complete."
