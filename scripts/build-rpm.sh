#!/usr/bin/env bash
# Orchestrates: fetch upstream .deb -> extract -> stage -> rpmbuild.
#
# Usage:
#   build-rpm.sh [--version VERSION] [--arch amd64|arm64]
#   build-rpm.sh --url URL
#   build-rpm.sh --deb-path /path/to/claude-desktop.deb [--version VERSION]
#
# If --version is omitted (and no --deb-path/--url is given), the newest
# version in Anthropic's apt repository is used automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"

# The upstream payload contains symlinks (e.g. /usr/bin/claude-desktop),
# which fail to extract on filesystems that don't support them (exFAT,
# some network/removable mounts). Do the actual extraction/staging/build
# in a proper temp directory, and only copy the final .rpm(s) into
# DIST_DIR at the end.
WORK_DIR="$(mktemp -d -t claude-desktop-rpm-build.XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

VERSION=""
URL=""
DEB_PATH=""
ARCH="amd64"

usage() {
    echo "Usage: $0 [--version VERSION] [--arch amd64|arm64] [--url URL] [--deb-path PATH]" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --arch) ARCH="$2"; shift 2 ;;
        --url) URL="$2"; shift 2 ;;
        --deb-path) DEB_PATH="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

for cmd in rpmbuild tar ar; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "error: '$cmd' is required (install rpm-build, binutils)" >&2; exit 1; }
done

mkdir -p "$DIST_DIR"
mkdir -p "$WORK_DIR/upstream" "$WORK_DIR/stage" "$WORK_DIR/rpmbuild"/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

FETCH_ARGS=(--out "$WORK_DIR/upstream" --arch "$ARCH")
if [[ -n "$DEB_PATH" ]]; then
    FETCH_ARGS=(--out "$WORK_DIR/upstream" --deb-path "$DEB_PATH")
elif [[ -n "$URL" ]]; then
    FETCH_ARGS=(--out "$WORK_DIR/upstream" --url "$URL")
else
    [[ -n "$VERSION" ]] && FETCH_ARGS+=(--version "$VERSION")
fi

DEB_FILE="$("$SCRIPT_DIR/fetch-deb.sh" "${FETCH_ARGS[@]}")"
PAYLOAD_DIR="$("$SCRIPT_DIR/extract-deb.sh" "$DEB_FILE" "$WORK_DIR/extracted")"

if [[ -z "$VERSION" ]]; then
    CTRL_DIR="$(mktemp -d)"
    (cd "$CTRL_DIR" && ar x "$DEB_FILE")
    CONTROL_TAR="$(find "$CTRL_DIR" -maxdepth 1 -name 'control.tar.*' | head -n1)"
    tar -xf "$CONTROL_TAR" -C "$CTRL_DIR" ./control
    VERSION="$(awk -F': ' '/^Version:/{print $2}' "$CTRL_DIR/control")"
    rm -rf "$CTRL_DIR"
    [[ -n "$VERSION" ]] || { echo "error: could not determine version from $DEB_FILE" >&2; exit 1; }
    echo "Detected upstream version: $VERSION" >&2
fi

# rpm Version: fields can't contain '-'; Debian versions often do (e.g. a
# "-1" revision suffix). Fold any such suffix into the rpm Release instead.
RPM_VERSION="${VERSION%%-*}"
RPM_RELEASE="1"
if [[ "$VERSION" == *-* ]]; then
    RPM_RELEASE="${VERSION#*-}"
fi

RPM_ARCH="x86_64"
[[ "$ARCH" == "arm64" ]] && RPM_ARCH="aarch64"

# --- Stage the layout expected by packaging/claude-desktop.spec ---
STAGE="$WORK_DIR/stage/claude-desktop-$RPM_VERSION"
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

# --- Build the source tarball rpmbuild expects (Source0) ---
tar -czf "$WORK_DIR/rpmbuild/SOURCES/claude-desktop-payload.tar.gz" \
    -C "$WORK_DIR/stage" "claude-desktop-$RPM_VERSION"

cp "$ROOT_DIR/packaging/claude-desktop.spec" "$WORK_DIR/rpmbuild/SPECS/"

rpmbuild --define "_topdir $WORK_DIR/rpmbuild" \
          --define "app_version $RPM_VERSION" \
          --define "app_release $RPM_RELEASE" \
          --define "app_rpm_arch $RPM_ARCH" \
          --target "$RPM_ARCH" \
          -bb "$WORK_DIR/rpmbuild/SPECS/claude-desktop.spec"

find "$WORK_DIR/rpmbuild/RPMS" -name '*.rpm' -exec cp {} "$DIST_DIR/" \;
echo "Built RPM(s) in $DIST_DIR"
find "$DIST_DIR" -maxdepth 1 -name '*.rpm'
