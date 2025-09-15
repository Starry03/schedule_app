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

echo "Uninstall complete."
