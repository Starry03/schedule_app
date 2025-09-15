# script to install the PWA on macOS

#!/bin/bash

# Check if the script is run on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is only for macOS."
    exit 1
fi

echo "Setting up the PWA to run on startup (macOS)..."

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB_BUILD_DIR="$REPO_ROOT/build/web"
INSTALL_DIR="$HOME/Library/Application Support/schedule_app"
INSTALL_WEB_DIR="$INSTALL_DIR/web"

if [[ ! -d "${WEB_BUILD_DIR}" ]]; then
    echo "Building the Flutter web app..."
    (cd "${REPO_ROOT}" && flutter build web --release) || { echo "Flutter build failed"; exit 1; }
fi

echo "Creating install directory: ${INSTALL_WEB_DIR}"
mkdir -p "${INSTALL_WEB_DIR}"

echo "Copying web assets to ${INSTALL_WEB_DIR}"
rm -rf "${INSTALL_WEB_DIR:?}/*" || true
cp -a "${WEB_BUILD_DIR}/." "${INSTALL_WEB_DIR}/"

LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
PLIST_LABEL="com.schedule_app.pwa-server"
PLIST_PATH="$LAUNCH_AGENT_DIR/${PLIST_LABEL}.plist"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/run_pwa_server.sh"

mkdir -p "$LAUNCH_AGENT_DIR"

echo "Making helper script executable: $SCRIPT_PATH"
chmod +x "$SCRIPT_PATH"

echo "Writing LaunchAgent plist to $PLIST_PATH"
cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>${PLIST_LABEL}</string>
        <key>ProgramArguments</key>
        <array>
            <string>/bin/bash</string>
            <string>${SCRIPT_PATH}</string>
        </array>
        <key>EnvironmentVariables</key>
        <dict>
            <key>SCHEDULE_APP_WEB_DIR</key>
            <string>${INSTALL_WEB_DIR}</string>
        </dict>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
        <key>StandardOutPath</key>
        <string>$HOME/Library/Logs/${PLIST_LABEL}.log</string>
        <key>StandardErrorPath</key>
        <string>$HOME/Library/Logs/${PLIST_LABEL}.err</string>
    </dict>
</plist>
EOF

echo "Loading LaunchAgent (will start server now)"
launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
launchctl load --user "$PLIST_PATH"

echo "Installed. Server should be available at http://localhost:9999"

echo "To uninstall, run: $0 --uninstall or run the uninstall script: scripts/pwa/uninstall_macos.sh"
