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
REPO_RUNNER="$(cd "$(dirname "$0")" && pwd)/run_pwa_server.sh"
INSTALLED_RUNNER="$INSTALL_DIR/run_pwa_server.sh"

mkdir -p "$LAUNCH_AGENT_DIR"

echo "Installing helper script to ${INSTALLED_RUNNER}"
if [[ -f "${REPO_RUNNER}" ]]; then
    mkdir -p "$INSTALL_DIR"
    cp "$REPO_RUNNER" "$INSTALLED_RUNNER"
    chmod +x "$INSTALLED_RUNNER"
else
    echo "Warning: repo runner not found at ${REPO_RUNNER}; the service will call the installed runner path and may fail until the runner is placed there."
fi

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
                <string>${INSTALLED_RUNNER}</string>
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
# Use modern launchctl bootstrap/bootout if available, otherwise fall back to load/unload for compatibility
if launchctl help | grep -q bootout; then
    # Unload previous instance if present
    launchctl bootout gui/$(id -u) "$PLIST_PATH" >/dev/null 2>&1 || true
    # Bootstrap the plist into the user's domain
    launchctl bootstrap gui/$(id -u) "$PLIST_PATH" || {
        echo "launchctl bootstrap failed; attempting legacy load as fallback"
        launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
        launchctl load --user "$PLIST_PATH" || true
    }
else
    # Legacy macOS where bootstrap isn't available
    launchctl unload "$PLIST_PATH" >/dev/null 2>&1 || true
    launchctl load --user "$PLIST_PATH" || true
fi

echo "Installed. Server should be available at http://localhost:9999"

echo "To uninstall, run: $0 --uninstall or run the uninstall script: scripts/pwa/uninstall_macos.sh"
