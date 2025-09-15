# script to install the PWA on macOS

#!/bin/bash

# Check if the script is run on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "This script is only for macOS."
    exit 1
fi

# Check if the build/web directory exists
if [[ ! -d "build/web" ]]; then
    echo "Building the Flutter web app..."
    flutter build web --release || { echo "Flutter build failed"; exit 1; }
fi

# set the server as startup process

echo "Setting up the PWA to run on startup..."

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
            <string>${SCRIPT_PATH}</string>
        </array>
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

echo "To uninstall, run: launchctl unload '$PLIST_PATH' && rm -f '$PLIST_PATH'"
