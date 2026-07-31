#!/usr/bin/env bash
# Downloads (or locates) the official Claude Desktop .deb package from
# Anthropic's apt repository.
#
# Usage:
#   fetch-deb.sh [--version VERSION] [--arch amd64|arm64] [--out DIR]
#   fetch-deb.sh --url URL [--out DIR]
#   fetch-deb.sh --deb-path /path/to/local/claude-desktop.deb
#
# With no --version, the newest package listed in the repo's Packages
# index is used. Source: https://code.claude.com/docs/en/desktop-linux

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../dist/upstream"

APT_BASE="https://downloads.claude.ai/claude-desktop/apt/stable"

VERSION=""
URL=""
DEB_PATH=""
ARCH="amd64"

usage() {
    echo "Usage: $0 [--version VERSION] [--arch amd64|arm64] [--out DIR]" >&2
    echo "       $0 --url URL [--out DIR]" >&2
    echo "       $0 --deb-path /path/to/claude-desktop.deb" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --arch) ARCH="$2"; shift 2 ;;
        --url) URL="$2"; shift 2 ;;
        --out) OUT_DIR="$2"; shift 2 ;;
        --deb-path) DEB_PATH="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

mkdir -p "$OUT_DIR"
DEST="$OUT_DIR/claude-desktop.deb"

if [[ -n "$DEB_PATH" ]]; then
    if [[ ! -f "$DEB_PATH" ]]; then
        echo "error: --deb-path '$DEB_PATH' does not exist" >&2
        exit 1
    fi
    cp -f "$DEB_PATH" "$DEST"
    echo "$DEST"
    exit 0
fi

if [[ -n "$URL" ]]; then
    curl -fSL --retry 2 -o "$DEST" "$URL"
    echo "$DEST"
    exit 0
fi

if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
    echo "error: --arch must be amd64 or arm64" >&2
    exit 1
fi

# Look up the package path from the repo's index, matching how the
# official docs' "install from a downloaded file" method works:
# https://code.claude.com/docs/en/desktop-linux
PACKAGES_URL="$APT_BASE/dists/stable/main/binary-${ARCH}/Packages"

PACKAGES_INDEX="$(curl -fsSL "$PACKAGES_URL")" || {
    echo "error: could not fetch $PACKAGES_URL" >&2
    exit 1
}

if [[ -n "$VERSION" ]]; then
    FILENAME="$(echo "$PACKAGES_INDEX" | grep "^Filename: pool/main/c/claude-desktop/claude-desktop_${VERSION}_" | tail -n1 | cut -d' ' -f2)"
    if [[ -z "$FILENAME" ]]; then
        echo "error: version '$VERSION' not found for arch '$ARCH' in $PACKAGES_URL" >&2
        exit 1
    fi
else
    FILENAME="$(echo "$PACKAGES_INDEX" | grep '^Filename: pool/main/c/claude-desktop/claude-desktop_' | sort -V | tail -n1 | cut -d' ' -f2)"
    if [[ -z "$FILENAME" ]]; then
        echo "error: no claude-desktop package found for arch '$ARCH' in $PACKAGES_URL" >&2
        exit 1
    fi
fi

curl -fSL --retry 2 -o "$DEST" "$APT_BASE/$FILENAME"
echo "$DEST"
