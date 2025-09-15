#!/usr/bin/env bash
# Helper script to serve a Flutter build/web directory via python3 http.server on port 9999
# The script prefers an installed web dir (via SCHEDULE_APP_WEB_DIR), then user install locations,
# then falls back to the repo's build/web for development.

set -euo pipefail

PORT=9999

# Priority order for WEB_DIR:
# 1. SCHEDULE_APP_WEB_DIR environment variable (set by installer wrapper)
# 2. macOS install dir: $HOME/Library/Application Support/schedule_app/web
# 3. Linux install dir: $HOME/.local/share/schedule_app/web
# 4. Repo build/web (development)

if [[ -n "${SCHEDULE_APP_WEB_DIR-}" ]]; then
  WEB_DIR="${SCHEDULE_APP_WEB_DIR}"
else
  if [[ -d "$HOME/Library/Application Support/schedule_app/web" ]]; then
    WEB_DIR="$HOME/Library/Application Support/schedule_app/web"
  elif [[ -d "$HOME/.local/share/schedule_app/web" ]]; then
    WEB_DIR="$HOME/.local/share/schedule_app/web"
  else
    # fallback to repo build/web for dev convenience
    REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
    WEB_DIR="${REPO_ROOT}/build/web"
    if [[ ! -d "${WEB_DIR}" ]]; then
      echo "build/web not found. Building Flutter web..."
      (cd "${REPO_ROOT}" && flutter build web --release)
    fi
  fi
fi

if [[ ! -d "${WEB_DIR}" ]]; then
  echo "Web directory not found: ${WEB_DIR}"
  exit 1
fi

echo "Serving ${WEB_DIR} on port ${PORT} (bound to 127.0.0.1)"
cd "${WEB_DIR}"
exec python3 -m http.server ${PORT} --bind 127.0.0.1 || {
  echo "Failed to start server. Check ${PORT} and python3 installation."
  exit 1
}
