#!/usr/bin/env bash
# Prints the RPM Requires: list corresponding to Claude Desktop's Debian
# runtime dependencies. Sourced by build-rpm.sh, or run standalone to
# print the mapping for inspection.
#
# Usage: map-deps.sh

set -euo pipefail

# deb package -> rpm (Fedora) package. Extend this table as upstream's
# dependency list changes; there's no reliable automatic translation
# between the two naming schemes.
declare -A DEB_TO_RPM=(
    [libnotify4]=libnotify
    [libnss3]=nss
    [libxss1]=libXScrnSaver
    [libxtst6]=libXtst
    [libatspi2.0-0]=at-spi2-core
    [libsecret-1-0]=libsecret
    [libgtk-3-0]=gtk3
    [libasound2]=alsa-lib
    [libgbm1]=mesa-libgbm
    [libx11-6]=libX11
    [libxcomposite1]=libXcomposite
    [libxdamage1]=libXdamage
    [libxfixes3]=libXfixes
    [libxrandr2]=libXrandr
    [libdrm2]=libdrm
)

for deb_name in "${!DEB_TO_RPM[@]}"; do
    echo "${DEB_TO_RPM[$deb_name]}"
done | sort -u
