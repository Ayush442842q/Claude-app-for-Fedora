#!/usr/bin/env bash
# Smoke-tests a built .rpm inside a clean Fedora container: installs it,
# checks expected files exist, and attempts a headless launch.
#
# Usage: verify-rpm.sh /path/to/claude-desktop-*.rpm
#
# Requires: podman (or docker, set CONTAINER_ENGINE=docker)

set -euo pipefail

RPM_PATH="${1:?Usage: $0 <path-to-rpm>}"
RPM_PATH="$(cd "$(dirname "$RPM_PATH")" && pwd)/$(basename "$RPM_PATH")"
ENGINE="${CONTAINER_ENGINE:-podman}"

command -v "$ENGINE" >/dev/null 2>&1 || { echo "error: '$ENGINE' is required" >&2; exit 1; }

"$ENGINE" run --rm -v "$RPM_PATH:/tmp/claude-desktop.rpm:Z" fedora:latest bash -c '
set -euo pipefail
dnf install -y /tmp/claude-desktop.rpm

test -x /usr/bin/claude-desktop || { echo "missing /usr/bin/claude-desktop"; exit 1; }
test -f /usr/share/applications/claude-desktop.desktop || { echo "missing .desktop file"; exit 1; }

dnf install -y xorg-x11-server-Xvfb
Xvfb :99 -screen 0 1280x1024x24 &
export DISPLAY=:99
sleep 2

timeout 15 /usr/bin/claude-desktop --no-sandbox &
APP_PID=$!
sleep 8
if ! kill -0 "$APP_PID" 2>/dev/null; then
    echo "app process exited early — check for missing libs / crash"
    exit 1
fi
kill "$APP_PID" 2>/dev/null || true

echo "verify-rpm: OK"
'
