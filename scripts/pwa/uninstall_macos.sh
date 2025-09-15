#!/usr/bin/env bash
set -euo pipefail

LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_LABEL="com.schedule_app.pwa-server"
PLIST_PATH="$LAUNCH_AGENT_DIR/${PLIST_LABEL}.plist"

echo "Uninstalling PWA LaunchAgent: ${PLIST_PATH}"

if [[ -f "$PLIST_PATH" ]]; then
  echo "Unloading LaunchAgent..."
  launchctl unload "$PLIST_PATH" || true
  echo "Removing plist..."
  rm -f "$PLIST_PATH"
else
  echo "No LaunchAgent plist found at $PLIST_PATH"
fi

echo "Removing log files..."
rm -f "$HOME/Library/Logs/${PLIST_LABEL}.log" || true
rm -f "$HOME/Library/Logs/${PLIST_LABEL}.err" || true

# Remove installed web files if present
INSTALL_WEB_DIR="$HOME/Library/Application Support/schedule_app/web"
if [[ -d "$INSTALL_WEB_DIR" ]]; then
  echo "Removing installed web files at $INSTALL_WEB_DIR"
  rm -rf "$INSTALL_WEB_DIR"
  # remove parent dir if empty
  rmdir --ignore-fail-on-non-empty "$(dirname "$INSTALL_WEB_DIR")" 2>/dev/null || true
fi

echo "Uninstall complete."
