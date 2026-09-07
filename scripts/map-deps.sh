#!/usr/bin/env bash
# Prints the RPM Requires: list corresponding to Claude Desktop's Debian
# runtime dependencies (from the upstream .deb's control file Depends:
# field). Sourced by build-rpm.sh, or run standalone to print the
# mapping for inspection.
#
# Usage: map-deps.sh

set -euo pipefail

# deb package -> rpm (Fedora) package. Extend this table as upstream's
# dependency list changes; there's no reliable automatic translation
# between the two naming schemes.
declare -A DEB_TO_RPM=(
    [libgtk-3-0]=gtk3
    [libnotify4]=libnotify
    [libnss3]=nss
    [xdg-utils]=xdg-utils
    [libatspi2.0-0]=at-spi2-core
    [libdrm2]=libdrm
    [libgbm1]=mesa-libgbm
    [libxcb-dri3-0]=libxcb
    [libsecret-1-0]=libsecret
    [gvfs]=gvfs
    [libxtst6]=libXtst
    [libuuid1]=libuuid
    [xdg-desktop-portal]=xdg-desktop-portal
    [xdg-desktop-portal-gtk]=xdg-desktop-portal-gtk
)

for deb_name in "${!DEB_TO_RPM[@]}"; do
    echo "${DEB_TO_RPM[$deb_name]}"
done | sort -u
