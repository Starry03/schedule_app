#!/usr/bin/env bash
# Helper script to serve build/web via python3 http.server on port 9999

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB_DIR="${REPO_ROOT}/build/web"
PORT=9999

if [[ ! -d "${WEB_DIR}" ]]; then
  echo "build/web not found. Building Flutter web..."
  (cd "${REPO_ROOT}" && flutter build web --release)
fi

echo "Serving ${WEB_DIR} on port ${PORT} (bound to 127.0.0.1)"
cd "${WEB_DIR}"
exec python3 -m http.server ${PORT} --bind 127.0.0.1 || {
  echo "Failed to start server. Check ${PORT} and python3 installation."
  exit 1
}
