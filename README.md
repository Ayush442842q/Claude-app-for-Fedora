<div align="center">

# Claude Desktop for Fedora

**Unofficial `.rpm` packaging of Claude Desktop for Fedora and other RPM-based Linux distributions.**

[![Build and release RPM](https://github.com/Ayush442842q/Claude-app-for-Fedora/actions/workflows/build-release.yml/badge.svg)](https://github.com/Ayush442842q/Claude-app-for-Fedora/actions/workflows/build-release.yml)
[![Latest release](https://img.shields.io/github/v/release/Ayush442842q/Claude-app-for-Fedora?label=latest%20release)](https://github.com/Ayush442842q/Claude-app-for-Fedora/releases/latest)
[![License: MIT](https://img.shields.io/github/license/Ayush442842q/Claude-app-for-Fedora)](LICENSE)
[![Fedora](https://img.shields.io/badge/Fedora-RPM--based-51A2DA?logo=fedora&logoColor=white)](https://fedoraproject.org)

</div>

> **Disclaimer:** this is an independent, community-maintained packaging
> project. It is **not affiliated with, endorsed by, or supported by
> Anthropic**. It repackages Anthropic's officially distributed Claude
> Desktop `.deb` build into an RPM — it does not modify, reverse-engineer,
> or redistribute any proprietary source code, only the official binary
> release. The bundled application remains Anthropic's property and is
> subject to Anthropic's own terms of use, not this project's license.

## Contents

- [Why this exists](#why-this-exists)
- [Install](#install)
- [Building it yourself](#building-it-yourself)
- [Verifying a build](#verifying-a-build)
- [How it works](#how-it-works)
- [Documentation](#documentation)
- [Reporting issues](#reporting-issues)
- [License](#license)

## Why this exists

Anthropic currently only publishes an official Linux build of Claude
Desktop through an apt repository (`.deb`), which leaves Fedora, RHEL,
and other RPM-based distro users without a native package. This project
downloads the official `.deb`, unpacks it, and repackages the same
binaries as a proper `.rpm` — so Fedora users get the real app through
their normal package manager instead of a manual workaround.

## Install

Download the latest `.rpm` from the [Releases](../../releases) page and
install it:

```sh
sudo dnf install ./claude-desktop-<version>.x86_64.rpm
```

## Building it yourself

**Requirements:** `rpm-build`, `ar` (from `binutils`), `tar`, `curl`.

Build the latest version automatically — this queries Anthropic's apt
repository index directly, per their
[official Linux docs](https://code.claude.com/docs/en/desktop-linux):

```sh
./scripts/build-rpm.sh
```

Pin a specific version or architecture:

```sh
./scripts/build-rpm.sh --version <upstream-version> --arch amd64
```

Or build from an already-downloaded `.deb`:

```sh
./scripts/build-rpm.sh --deb-path ./claude-desktop.deb
```

The built `.rpm` lands in `dist/`.

## Verifying a build

```sh
./scripts/verify-rpm.sh dist/claude-desktop-*.rpm
```

Installs the package inside a clean `fedora:latest` container and
confirms the binary, desktop entry, and icons are present, and that the
app launches under `Xvfb` without crashing.

## How it works

| Script | Role |
|---|---|
| `scripts/fetch-deb.sh` | Downloads the newest (or a pinned version of) the official `.deb` from Anthropic's apt repository, or accepts a local copy. |
| `scripts/extract-deb.sh` | Unpacks the `.deb` and locates the Electron app, icons, and `.desktop` file inside it. |
| `scripts/map-deps.sh` | Translates the Debian runtime dependency list to Fedora package names for the RPM `Requires:` list. |
| `scripts/build-rpm.sh` | Orchestrates the above, stages everything into the layout `packaging/claude-desktop.spec` expects, and runs `rpmbuild`. |
| `scripts/verify-rpm.sh` | Smoke-tests a built `.rpm` in a disposable container. |

See [docs/BUILD.md](docs/BUILD.md) for a full walkthrough of the pipeline
and the specific issues that came up building against the real package.

## Documentation

- [docs/BUILD.md](docs/BUILD.md) — how the build pipeline works, step by step
- [docs/VERSIONING.md](docs/VERSIONING.md) — how upstream version tracking works

## Reporting issues

Found a broken build, a missing dependency, or a crash on launch? See
[CONTRIBUTING.md](CONTRIBUTING.md) for how to file a good bug report, or
go straight to [opening an issue](../../issues/new/choose).

## License

The packaging scripts and spec file in this repository are MIT licensed —
see [LICENSE](LICENSE). This does **not** extend to the Claude Desktop
application itself, which remains Anthropic's proprietary software.
