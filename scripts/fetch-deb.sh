#!/usr/bin/env bash
# Downloads (or locates) the official Claude Desktop .deb package.
#
# Usage:
#   fetch-deb.sh --version VERSION [--url URL] [--out DIR]
#   fetch-deb.sh --deb-path /path/to/local/claude-desktop.deb
#
# Anthropic does not publish a stable, documented download URL for the
# Claude Desktop .deb. This script supports three ways to get the file,
# in order of preference:
#   1. --deb-path: use an already-downloaded .deb as-is (no network access)
#   2. --url: fetch from an explicit URL (use this once you've found the
#      current download link, e.g. from claude.ai/download)
#   3. --version + built-in candidate URL list: best-effort auto-discovery
#      that is expected to need updating whenever Anthropic changes their
#      distribution setup. If every candidate fails, the script exits with
#      a clear error rather than silently producing a bad artifact.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../dist/upstream"

VERSION=""
URL=""
DEB_PATH=""

usage() {
    echo "Usage: $0 --version VERSION [--url URL] [--out DIR]" >&2
    echo "       $0 --deb-path /path/to/claude-desktop.deb" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --url) URL="$2"; shift 2 ;;
        --out) OUT_DIR="$2"; shift 2 ;;
        --deb-path) DEB_PATH="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

mkdir -p "$OUT_DIR"

if [[ -n "$DEB_PATH" ]]; then
    if [[ ! -f "$DEB_PATH" ]]; then
        echo "error: --deb-path '$DEB_PATH' does not exist" >&2
        exit 1
    fi
    cp -f "$DEB_PATH" "$OUT_DIR/claude-desktop.deb"
    echo "$OUT_DIR/claude-desktop.deb"
    exit 0
fi

if [[ -z "$VERSION" && -z "$URL" ]]; then
    echo "error: provide --deb-path, --url, or --version" >&2
    usage
fi

# Known/likely candidate URL patterns for Anthropic's Claude Desktop .deb.
# NOTE: unverified — this list must be checked/updated before relying on
# auto-discovery. Kept as an ordered list so new patterns can be appended
# without touching the rest of the script.
CANDIDATE_URLS=()
if [[ -n "$URL" ]]; then
    CANDIDATE_URLS+=("$URL")
elif [[ -n "$VERSION" ]]; then
    CANDIDATE_URLS+=(
        "https://desktop.anthropic.com/linux/claude-desktop_${VERSION}_amd64.deb"
        "https://claude.ai/download/linux/claude-desktop_${VERSION}_amd64.deb"
    )
fi

DEST="$OUT_DIR/claude-desktop.deb"
DOWNLOADED=""

for candidate in "${CANDIDATE_URLS[@]}"; do
    echo "Trying: $candidate" >&2
    if curl -fSL --retry 2 -o "$DEST" "$candidate"; then
        DOWNLOADED="$candidate"
        break
    fi
done

if [[ -z "$DOWNLOADED" ]]; then
    cat >&2 <<EOF
error: could not download the official .deb from any known URL.

Anthropic's download URL is not documented/stable, so auto-discovery is
best-effort and will break when they change hosting. To unblock:
  1. Find the current Linux download link from https://claude.ai/download
  2. Re-run with:  fetch-deb.sh --url <the-link> --out "$OUT_DIR"
  or download it manually and run:
     fetch-deb.sh --deb-path /path/to/downloaded.deb
EOF
    exit 1
fi

echo "$DEST"
