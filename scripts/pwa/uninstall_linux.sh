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

# Remove installed web files
INSTALL_WEB_DIR="$HOME/.local/share/schedule_app/web"
if [[ -d "$INSTALL_WEB_DIR" ]]; then
  echo "Removing installed web files at $INSTALL_WEB_DIR"
  rm -rf "$INSTALL_WEB_DIR"
  rmdir --ignore-fail-on-non-empty "$(dirname "$INSTALL_WEB_DIR")" 2>/dev/null || true
fi

echo "Uninstall complete."
