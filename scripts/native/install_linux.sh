#!/usr/bin/env bash
set -euo pipefail

# Simple AppImage packager for the Flutter Linux release bundle.
# Usage: ./scripts/native/install_linux.sh
# Requirements: flutter, curl or wget (to fetch appimagetool if missing)

if [[ "$(uname -s)" != "Linux" ]]; then
	echo "This installer must be run on Linux"
	exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/build/linux/x64/release/bundle"
OUT_DIR="$REPO_ROOT/build/appimage"
INSTALL_DEST="$HOME/Applications"   # final AppImage target
TMPDIR="$(mktemp -d)"
APPIMAGETOOL="${TMPDIR}/appimagetool.AppImage"

# Build flutter linux bundle if missing
if [[ ! -d "$BUILD_DIR" || -z "$(ls -A "$BUILD_DIR" 2>/dev/null)" ]]; then
	echo "Building Flutter linux release..."
	(cd "$REPO_ROOT" && flutter build linux --release) || { echo "Flutter build failed"; exit 1; }
fi

# Find the built executable inside the bundle
BINARY_PATH="$(find "$BUILD_DIR" -maxdepth 2 -type f -executable -print -quit || true)"
if [[ -z "$BINARY_PATH" ]]; then
	echo "Cannot find built executable under $BUILD_DIR"
	exit 1
fi
APP_NAME="$(basename "${BINARY_PATH}")"
APP_DIR_NAME="${APP_NAME}.AppDir"
APPDIR="$OUT_DIR/$APP_DIR_NAME"

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy binary and bundled files
echo "Copying bundle to AppDir..."
cp -a "${BUILD_DIR}/." "$APPDIR/usr/bin/" || true

# Ensure the main executable is at usr/bin/<APP_NAME> and is executable
if [[ ! -x "$APPDIR/usr/bin/$APP_NAME" ]]; then
	# try to find executable in usr/bin and make it primary
	FOUND_BIN="$(find "$APPDIR/usr/bin" -maxdepth 1 -type f -executable -print -quit || true)"
	if [[ -n "$FOUND_BIN" ]]; then
		mv "$FOUND_BIN" "$APPDIR/usr/bin/$APP_NAME"
		chmod +x "$APPDIR/usr/bin/$APP_NAME"
	fi
fi

# Create AppRun
cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/bin:${LD_LIBRARY_PATH-}"
exec "${HERE}/usr/bin/$(basename "$0" .AppRun)" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Try to find an icon (png) in common project locations
ICON_SRC="$(find "$REPO_ROOT" -type f \( -iname '*icon*.png' -o -iname '*logo*.png' \) -print -quit || true)"
if [[ -n "$ICON_SRC" ]]; then
	echo "Using icon: $ICON_SRC"
	cp "$ICON_SRC" "$APPDIR/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png"
	ICON_NAME="${APP_NAME}.png"
else
	ICON_NAME=""
fi

# Create .desktop
cat > "$APPDIR/${APP_NAME}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${APP_NAME}
Exec=${APP_NAME}
Comment=Schedule App (AppImage)
Categories=Utility;
Terminal=false
EOF
if [[ -n "$ICON_NAME" ]]; then
	echo "Icon=${ICON_NAME}" >> "$APPDIR/${APP_NAME}.desktop"
fi
mkdir -p "$APPDIR/usr/share/applications"
mv "$APPDIR/${APP_NAME}.desktop" "$APPDIR/usr/share/applications/"

# Ensure out dir exists
mkdir -p "$OUT_DIR"

# Allow user to override appimagetool path via env for debugging
if [[ -n "${APPIMAGETOOL_PATH-}" && -x "${APPIMAGETOOL_PATH}" ]]; then
	APPIMAGETOOL="${APPIMAGETOOL_PATH}"
elif ! command -v appimagetool >/dev/null 2>&1; then
	echo "appimagetool not found in PATH — attempting to download the official AppImage from GitHub releases..."
	# Try to resolve latest release asset URL via GitHub API (no jq required)
	if command -v curl >/dev/null 2>&1; then
		GH_JSON="$(curl -sS "https://api.github.com/repos/AppImage/AppImageKit/releases/latest")" || GH_JSON=""
		DOWNLOAD_URL="$(echo "$GH_JSON" | grep -E 'browser_download_url.*appimagetool-x86_64.AppImage' | head -n1 | sed -E 's/.*"(https:[^"]+)".*/\1/')"
		if [[ -z "$DOWNLOAD_URL" ]]; then
			echo "Could not determine download URL from GitHub API. Falling back to known redirect URL."
			DOWNLOAD_URL="https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage"
		fi
			echo "Downloading appimagetool from: $DOWNLOAD_URL"
			# Basic sanity check of URL
			if [[ ! "$DOWNLOAD_URL" =~ ^https?:// ]]; then
				echo "Resolved download URL doesn't look like an http(s) URL: $DOWNLOAD_URL"
				echo "Aborting. You can set APPIMAGETOOL_PATH to a local appimagetool binary to skip download."
				exit 1
			fi
			curl -fL --retry 3 --retry-delay 2 -o "$APPIMAGETOOL" "$DOWNLOAD_URL" || {
				echo "Failed to download appimagetool via curl"
				rm -f "$APPIMAGETOOL" || true
			}
	elif command -v wget >/dev/null 2>&1; then
		# Try direct redirect URL with retries
		DOWNLOAD_URL="https://github.com/AppImage/AppImageKit/releases/latest/download/appimagetool-x86_64.AppImage"
		echo "Downloading appimagetool from: $DOWNLOAD_URL"
		wget -O "$APPIMAGETOOL" --tries=3 --timeout=20 "$DOWNLOAD_URL" || {
			echo "Failed to download appimagetool via wget"
			rm -f "$APPIMAGETOOL" || true
		}
	else
		echo "curl or wget required to fetch appimagetool"
		exit 1
	fi

		# Validate the downloaded file looks like an AppImage / ELF and is executable
		if [[ -f "$APPIMAGETOOL" ]]; then
		chmod +x "$APPIMAGETOOL"
		# quick size sanity check — the official appimagetool is > 200KB; HTML error pages are tiny
		FILESIZE=$(stat -c%s "$APPIMAGETOOL" || echo 0)
		if [[ $FILESIZE -lt 16000 ]]; then
			echo "Downloaded appimagetool seems too small (${FILESIZE} bytes). Likely a HTML error page or redirect. Contents:" 
			echo "---- head of $APPIMAGETOOL ----"
			head -n 40 "$APPIMAGETOOL" || true
			echo "---- end ----"
			echo "Remove $APPIMAGETOOL and either install appimagetool locally or ensure network access to GitHub releases."
			rm -f "$APPIMAGETOOL" || true
			exit 1
		fi
		# Prefer running --version or --help to validate; some builds exit non-zero, so also check 'file' output
		VALID=0
		if "$APPIMAGETOOL" --version >/dev/null 2>&1 || "$APPIMAGETOOL" --help >/dev/null 2>&1; then
			VALID=1
		else
			# check magic
			if command -v file >/dev/null 2>&1; then
				FILEOUT="$(file -b "$APPIMAGETOOL" || true)"
				if echo "$FILEOUT" | grep -q -i "ELF\|gzip\|AppImage"; then
					VALID=1
				fi
			fi
		fi
		if [[ "$VALID" -ne 1 ]]; then
			echo "Downloaded appimagetool does not appear to be a valid AppImage. Removing and aborting."
			rm -f "$APPIMAGETOOL" || true
			echo "You can install appimagetool manually (e.g. from https://github.com/AppImage/AppImageKit/releases) and re-run this script."
			exit 1
		fi
		APPIMAGETOOL="$APPIMAGETOOL"
	else
		echo "appimagetool not downloaded. Install appimagetool manually and re-run the script."
		exit 1
	fi
else
	APPIMAGETOOL="$(command -v appimagetool)"
fi

# Create AppImage
echo "Creating AppImage..."
pushd "$OUT_DIR" >/dev/null
"$APPIMAGETOOL" "$APPDIR"
popd >/dev/null

# Move AppImage to user Applications
mkdir -p "$INSTALL_DEST"
APPIMAGE_CREATED="$(ls -1 "$OUT_DIR"/*.AppImage 2>/dev/null | tail -n1 || true)"
if [[ -n "$APPIMAGE_CREATED" ]]; then
	mv -f "$APPIMAGE_CREATED" "$INSTALL_DEST/"
	chmod +x "$INSTALL_DEST/$(basename "$APPIMAGE_CREATED")"
	echo "AppImage created and moved to: $INSTALL_DEST/$(basename "$APPIMAGE_CREATED")"
else
	echo "AppImage creation failed or no AppImage found in $OUT_DIR"
	exit 1
fi

# Cleanup
rm -rf "$TMPDIR"
echo "Done. You can run the app at: $INSTALL_DEST/$(basename "$APPIMAGE_CREATED")"
