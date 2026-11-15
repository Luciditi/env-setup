#!/usr/bin/env bash
set -euo pipefail

############################################################################
# PUSH ANDROID AVF IMAGE TO DEVICE
############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=scripts/_common
source "$REPO_DIR/scripts/_common"

usage() {
    cat << EOF
Usage: $(basename "$0") [images.tar.gz]

Push a custom Android AVF Debian image archive to a connected device at
/sdcard/linux/images.tar.gz via adb.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

ARCHIVE_PATH="${1:-images.tar.gz}"
REMOTE_DEST="${ANDROID_IMAGE_DEST:-/sdcard/linux/images.tar.gz}"

if [[ ! -f "$ARCHIVE_PATH" ]]; then
    echo -e "${C_ERR}Archive not found: ${ARCHIVE_PATH}${C_RES}" >&2
    exit 1
fi

if ! command -v adb >/dev/null 2>&1; then
    echo -e "${C_ERR}adb is required! Install Android Platform Tools first.${C_RES}" >&2
    exit 1
fi

echo -e "${C_HIL}Checking adb device connection...${C_RES}"
adb get-state >/dev/null

REMOTE_DIR="$(dirname "$REMOTE_DEST")"
echo -e "${C_HIL}Pushing ${ARCHIVE_PATH} to ${REMOTE_DEST}...${C_RES}"
adb shell mkdir -p "$REMOTE_DIR"
adb push "$ARCHIVE_PATH" "$REMOTE_DEST"
echo -e "${C_SUC}Pushed ${ARCHIVE_PATH} to ${REMOTE_DEST}.${C_RES}"
echo -e "Open the Android Linux Terminal app (resetting VM data if previously initialized) to provision from ${REMOTE_DEST}."
