#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB_BUILD_DIR="$REPO_ROOT/build/web"
INSTALL_DIR="$HOME/.local/share/schedule_app"
INSTALL_WEB_DIR="$INSTALL_DIR/web"
SERVICE_NAME="schedule_app_pwa_server.service"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
SERVICE_PATH="$SYSTEMD_USER_DIR/$SERVICE_NAME"

mkdir -p "$SYSTEMD_USER_DIR"

# Check if the build/web directory exists and build if needed
if [[ ! -d "${WEB_BUILD_DIR}" ]]; then
    echo "Building the Flutter web app..."
    (cd "${REPO_ROOT}" && flutter build web --release) || { echo "Flutter build failed"; exit 1; }
fi

echo "Copying web assets to ${INSTALL_WEB_DIR}"
mkdir -p "${INSTALL_WEB_DIR}"
rm -rf "${INSTALL_WEB_DIR:?}/*" || true
cp -a "${WEB_BUILD_DIR}/." "${INSTALL_WEB_DIR}/"

# Copy runner into install dir so the service doesn't depend on the repo
REPO_RUNNER="$(cd "$(dirname "$0")" && pwd)/run_pwa_server.sh"
INSTALLED_RUNNER="$INSTALL_DIR/run_pwa_server.sh"
if [[ -f "${REPO_RUNNER}" ]]; then
    mkdir -p "$INSTALL_DIR"
    cp "$REPO_RUNNER" "$INSTALLED_RUNNER"
    chmod +x "$INSTALLED_RUNNER"
else
    echo "Warning: repo runner not found at ${REPO_RUNNER}; service ExecStart will point to ${INSTALLED_RUNNER} and may fail."
fi

cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=Schedule App PWA static server

[Service]
Type=simple
WorkingDirectory=${INSTALL_WEB_DIR}
ExecStart=${INSTALLED_RUNNER}
Restart=always

[Install]
WantedBy=default.target
EOF

echo "Reloading systemd user daemon and enabling service..."
systemctl --user daemon-reload
systemctl --user enable --now "$SERVICE_NAME"

echo "Service installed and started. Visit http://127.0.0.1:9999"
