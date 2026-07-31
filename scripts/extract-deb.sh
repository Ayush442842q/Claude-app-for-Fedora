#!/usr/bin/env bash
# Extracts the payload of the official Claude Desktop .deb into a staging
# directory, ready for repackaging into an rpm.
#
# Usage: extract-deb.sh /path/to/claude-desktop.deb OUTPUT_DIR

set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <deb-path> <output-dir>" >&2
    exit 1
fi

DEB_PATH="$1"
OUT_DIR="$2"

for cmd in ar tar; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "error: '$cmd' is required" >&2; exit 1; }
done

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR/ar" "$OUT_DIR/payload"

# .deb files are 'ar' archives containing debian-binary, control.tar.*,
# and data.tar.* (the actual filesystem payload we want).
(cd "$OUT_DIR/ar" && ar x "$DEB_PATH")

DATA_TAR="$(find "$OUT_DIR/ar" -maxdepth 1 -name 'data.tar.*' | head -n1)"
if [[ -z "$DATA_TAR" ]]; then
    echo "error: no data.tar.* found inside $DEB_PATH" >&2
    exit 1
fi

tar -xf "$DATA_TAR" -C "$OUT_DIR/payload"

APP_DIR="$(find "$OUT_DIR/payload" -maxdepth 4 -type d -iname 'claude-desktop' | head -n1)"
if [[ -z "$APP_DIR" ]]; then
    APP_DIR="$(find "$OUT_DIR/payload/usr/lib" -maxdepth 1 -mindepth 1 -type d | head -n1)"
fi

DESKTOP_FILE="$(find "$OUT_DIR/payload" -name '*.desktop' | head -n1)"
ICON_DIR="$(find "$OUT_DIR/payload" -type d -path '*/icons/hicolor' | head -n1)"

echo "app dir:     ${APP_DIR:-NOT FOUND}"
echo "desktop file: ${DESKTOP_FILE:-NOT FOUND}"
echo "icon dir:    ${ICON_DIR:-NOT FOUND}"

if [[ -z "$APP_DIR" || -z "$DESKTOP_FILE" ]]; then
    cat >&2 <<'EOF'

warning: could not confidently locate the app directory and/or .desktop
file inside the extracted payload. Inspect "$OUT_DIR/payload" manually
and adjust the search paths in this script — upstream's internal layout
is not guaranteed to stay the same between releases.
EOF
fi

echo "$OUT_DIR/payload"
