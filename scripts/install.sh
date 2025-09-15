#!/usr/bin/env bash
set -euo pipefail

# Simple installer dispatcher.
# Usage: ./scripts/install.sh [--target web|native] [--os auto|macos|linux] [--uninstall]

TARGET="web"
OS_OVERRIDE="auto"
UNINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2;;
    --os) OS_OVERRIDE="$2"; shift 2;;
    --uninstall) UNINSTALL=1; shift;;
    -h|--help) echo "Usage: $0 [--target web|native] [--os auto|macos|linux] [--uninstall]"; exit 0;;
    *) echo "Unknown arg: $1"; exit 1;;
  esac
done

if [[ "$OS_OVERRIDE" == "auto" ]]; then
  UNAME=$(uname)
  if [[ "$UNAME" == "Darwin" ]]; then
    OS="macos"
  elif [[ "$UNAME" == "Linux" ]]; then
    OS="linux"
  else
    echo "Unsupported OS: $UNAME"; exit 1
  fi
else
  OS="$OS_OVERRIDE"
fi

echo "Installer dispatcher: OS=$OS TARGET=$TARGET UNINSTALL=$UNINSTALL"

case "$TARGET" in
  web)
    if [[ "$OS" == "macos" ]]; then
      if [[ $UNINSTALL -eq 1 ]]; then
        ./scripts/pwa/uninstall_macos.sh
      else
        ./scripts/pwa/install_macos.sh
      fi
    else
      if [[ $UNINSTALL -eq 1 ]]; then
        ./scripts/pwa/uninstall_linux.sh || true
      else
        ./scripts/pwa/install_linux.sh
      fi
    fi
    ;;
  native)
    if [[ "$OS" == "macos" ]]; then
      if [[ $UNINSTALL -eq 1 ]]; then
        ./scripts/native/uninstall_macos.sh
      else
        ./scripts/native/install_macos.sh
      fi
    else
      if [[ $UNINSTALL -eq 1 ]]; then
        ./scripts/native/uninstall_linux.sh
      else
        ./scripts/native/install_linux.sh
      fi
    fi
    ;;
  *) echo "Unknown target: $TARGET"; exit 1;;
esac
