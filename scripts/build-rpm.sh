#!/usr/bin/env bash
# Orchestrates: fetch upstream .deb -> extract -> stage -> rpmbuild.
#
# Usage:
#   build-rpm.sh --version VERSION [--url URL]
#   build-rpm.sh --deb-path /path/to/claude-desktop.deb --version VERSION

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"

VERSION=""
URL=""
DEB_PATH=""

usage() {
    echo "Usage: $0 --version VERSION [--url URL] [--deb-path PATH]" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --url) URL="$2"; shift 2 ;;
        --deb-path) DEB_PATH="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

[[ -n "$VERSION" ]] || usage

for cmd in rpmbuild tar; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "error: '$cmd' is required (install rpm-build)" >&2; exit 1; }
done

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/upstream" "$DIST_DIR/stage" "$DIST_DIR/rpmbuild"/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

FETCH_ARGS=(--out "$DIST_DIR/upstream")
if [[ -n "$DEB_PATH" ]]; then
    FETCH_ARGS+=(--deb-path "$DEB_PATH")
else
    FETCH_ARGS+=(--version "$VERSION")
    [[ -n "$URL" ]] && FETCH_ARGS+=(--url "$URL")
fi

DEB_FILE="$("$SCRIPT_DIR/fetch-deb.sh" "${FETCH_ARGS[@]}")"
PAYLOAD_DIR="$("$SCRIPT_DIR/extract-deb.sh" "$DEB_FILE" "$DIST_DIR/extracted")"

# --- Stage the layout expected by packaging/claude-desktop.spec ---
STAGE="$DIST_DIR/stage/claude-desktop-$VERSION"
mkdir -p "$STAGE/app" "$STAGE/icons"

APP_SRC="$(find "$PAYLOAD_DIR/usr/lib" -maxdepth 1 -mindepth 1 -type d | head -n1)"
if [[ -z "$APP_SRC" ]]; then
    echo "error: could not find app directory under $PAYLOAD_DIR/usr/lib" >&2
    exit 1
fi
cp -a "$APP_SRC/." "$STAGE/app/"

DESKTOP_SRC="$(find "$PAYLOAD_DIR" -name '*.desktop' | head -n1)"
if [[ -n "$DESKTOP_SRC" ]]; then
    cp "$DESKTOP_SRC" "$STAGE/claude-desktop.desktop"
else
    cp "$ROOT_DIR/packaging/claude-desktop.desktop" "$STAGE/claude-desktop.desktop"
fi

if [[ -d "$PAYLOAD_DIR/usr/share/icons/hicolor" ]]; then
    mkdir -p "$STAGE/icons/hicolor"
    cp -a "$PAYLOAD_DIR/usr/share/icons/hicolor/." "$STAGE/icons/hicolor/"
fi

cat > "$STAGE/claude-desktop.sh" <<'LAUNCHER'
#!/usr/bin/env bash
exec /usr/lib/claude-desktop/claude-desktop "$@"
LAUNCHER
chmod +x "$STAGE/claude-desktop.sh"

# --- Build the source tarball rpmbuild expects (Source0) ---
tar -czf "$DIST_DIR/rpmbuild/SOURCES/claude-desktop-payload.tar.gz" \
    -C "$DIST_DIR/stage" "claude-desktop-$VERSION"

cp "$ROOT_DIR/packaging/claude-desktop.spec" "$DIST_DIR/rpmbuild/SPECS/"

rpmbuild --define "_topdir $DIST_DIR/rpmbuild" \
          --define "app_version $VERSION" \
          -bb "$DIST_DIR/rpmbuild/SPECS/claude-desktop.spec"

find "$DIST_DIR/rpmbuild/RPMS" -name '*.rpm' -exec cp {} "$DIST_DIR/" \;
echo "Built RPM(s) in $DIST_DIR"
find "$DIST_DIR" -maxdepth 1 -name '*.rpm'
