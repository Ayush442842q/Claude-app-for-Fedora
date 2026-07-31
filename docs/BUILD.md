# How this package is built

This document walks through the full pipeline `scripts/build-rpm.sh`
runs, why each step exists, and the specific problems that came up while
getting a real Fedora `.rpm` out of Anthropic's official `.deb`.

## Overview

```
fetch-deb.sh  -->  extract-deb.sh  -->  stage  -->  rpmbuild
(get the .deb)     (unpack it)         (arrange   (package it,
                                        for the     using
                                        spec)       claude-desktop.spec)
```

`build-rpm.sh` orchestrates all four stages and is the only script most
people need to run directly.

## 1. Getting the `.deb` (`scripts/fetch-deb.sh`)

Anthropic distributes Claude Desktop for Linux through a standard apt
repository at `https://downloads.claude.ai/claude-desktop/apt/stable`
(documented at [code.claude.com/docs/en/desktop-linux](https://code.claude.com/docs/en/desktop-linux)).
Rather than guessing a download URL, `fetch-deb.sh` reads the repo's
`Packages` index directly:

```
https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-<arch>/Packages
```

Each entry has a `Filename:` field pointing at the actual `.deb` under
`pool/main/c/claude-desktop/`. With no `--version` given, the script
picks the newest one (`sort -V`); with `--version`, it looks for that
exact one. This means running `build-rpm.sh` with no arguments always
grabs whatever Anthropic currently ships, with no hardcoded/stale URLs
to maintain.

## 2. Unpacking it (`scripts/extract-deb.sh`)

A `.deb` is an `ar` archive containing `debian-binary`, `control.tar.*`
(package metadata, maintainer scripts) and `data.tar.*` (the actual
filesystem payload). `extract-deb.sh` runs `ar x`, then extracts
`data.tar.*`, and reports where it found:

- the app directory — `usr/lib/claude-desktop/` (the whole Electron/Chromium
  runtime plus the app itself, no `asar` unpacking needed since upstream
  doesn't ship one)
- the desktop entry — `usr/share/applications/com.anthropic.Claude.desktop`
- the icon set — `usr/share/icons/hicolor/*/apps/claude-desktop.png`

**Symlinks and filesystem support:** the payload contains real symlinks
(e.g. `usr/bin/claude-desktop -> ../lib/claude-desktop/claude-desktop`).
Extracting onto a filesystem that can't represent symlinks (exFAT, some
network/removable mounts) fails outright. For that reason `build-rpm.sh`
never extracts inside the repo checkout — it does all of this in a
`mktemp -d` work directory and only copies the finished `.rpm` back.

## 3. Staging (`build-rpm.sh`)

The extracted payload is rearranged into the layout
`packaging/claude-desktop.spec` expects:

```
claude-desktop-<version>/
├── app/                      # usr/lib/claude-desktop/* from the payload
├── icons/hicolor/            # usr/share/icons/hicolor/* from the payload
└── claude-desktop.desktop    # the upstream .desktop file (or packaging/claude-desktop.desktop as a fallback)
```

This directory is tarred up as `claude-desktop-payload.tar.gz` — the
spec's `Source0`. It's not a normal upstream release tarball (there isn't
one), just a staging artifact the spec knows how to unpack.

**Version handling:** if `--version` isn't given, `build-rpm.sh` reads it
straight out of the `.deb`'s `control` file (`Version:` field) after
extraction, so the built `.rpm`'s version always matches what was
actually downloaded. Debian versions can contain a `-N` revision suffix,
which isn't legal in an rpm `Version:` field — that suffix is split off
into the rpm `Release:` instead (`scripts/build-rpm.sh` computes
`RPM_VERSION`/`RPM_RELEASE`).

## 4. Packaging (`packaging/claude-desktop.spec`)

A few things in the spec are non-obvious and worth calling out:

- **`%setup -q` (no `-c`).** The staged tarball already has a top-level
  `claude-desktop-<version>/` directory matching `%{name}-%{version}`,
  which is exactly what plain `%setup -q` expects. Adding `-c` extracts
  it a second directory level too deep and breaks `%install`'s relative
  paths — this was a real bug caught by actually running the build, not
  just reading the spec.
- **`chrome-sandbox` needs `%attr(4755,root,root)`.** Upstream ships this
  setuid so Chromium's SUID sandbox works. Non-root `tar`/`ar` extraction
  (which is how this is normally built — no root needed) silently strips
  the setuid bit; the spec restores it explicitly in `%files`, which is
  what actually lets the app run without `--no-sandbox`. rpm will print a
  harmless `warning: File listed twice` because the file is also covered
  by the blanket `/usr/lib/claude-desktop` directory entry below it —
  that's expected, the more specific `%attr` line wins.
- **`Requires:`/`Recommends:`** mirror the upstream `.deb`'s `Depends:`/
  `Recommends:` fields, translated to Fedora package names by
  `scripts/map-deps.sh` (e.g. `libgtk-3-0` → `gtk3`, `libnotify4` →
  `libnotify`). rpm's automatic ELF dependency scanner adds the specific
  shared-library `Requires:` on top of these at build time.
- **`%changelog` is left empty.** A placeholder changelog entry with an
  invalid date caused `rpmbuild` to error outright on some rpm versions;
  an empty section is accepted (with a harmless warning) and there's
  nothing meaningful to put there for a packaging-only repo.
- **`BuildArch`** is templated (`app_rpm_arch`, passed in by
  `build-rpm.sh` as `x86_64` or `aarch64`) rather than hardcoded, since
  the same spec is used for both `--arch amd64` and `--arch arm64`
  builds.

## 5. Verifying (`scripts/verify-rpm.sh`)

Installs the freshly built `.rpm` inside a clean `fedora:latest`
container (via `podman`/`docker`), confirms `/usr/bin/claude-desktop`
and the `.desktop` file exist, then launches the app under `Xvfb` and
checks the process is still alive a few seconds later. This is what
actually caught the `%setup -c` and setuid bugs above — none of them
were visible just from reading the spec or running `rpmbuild` in
isolation.

**A note on bind-mounting the `.rpm` into the container:** if your build
output lives on a filesystem podman can't properly set ownership/xattrs
on (again, exFAT and similar), the bind-mount can fail with a bare
`Permission denied` even though the file is readable locally. Copy the
`.rpm` to a normal filesystem (e.g. under `/tmp`) before running
`verify-rpm.sh` if you hit that.

## End-to-end

```sh
./scripts/build-rpm.sh              # fetch latest + build
./scripts/verify-rpm.sh dist/*.rpm  # smoke-test in a container
sudo dnf install ./dist/*.rpm       # install for real
```

See [VERSIONING.md](VERSIONING.md) for how upstream version tracking
works, and the main [README](../README.md) for install instructions.
