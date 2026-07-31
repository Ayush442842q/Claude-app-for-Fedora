# claude-desktop-fedora

Unofficial packaging of Claude Desktop as an `.rpm` for Fedora and other
RPM-based Linux distributions.

> **Disclaimer:** this is an independent, community-maintained packaging
> project. It is **not affiliated with, endorsed by, or supported by
> Anthropic**. It repackages Anthropic's officially distributed Claude
> Desktop `.deb` build into an RPM — it does not modify, reverse-engineer,
> or redistribute any proprietary source code, only the official binary
> release. The bundled application remains Anthropic's property and is
> subject to Anthropic's own terms of use, not this project's license.

## Why

Anthropic currently only publishes an official Linux build of Claude
Desktop as a `.deb`, which leaves Fedora, RHEL, and other RPM-based distro
users without a native package. This project automates extracting the
official `.deb` payload and repackaging it as an `.rpm`.

## Install

Download the latest `.rpm` from the [Releases](../../releases) page and
install it with:

```sh
sudo dnf install ./claude-desktop-<version>.x86_64.rpm
```

## Building it yourself

Requirements: `rpm-build`, `ar` (from `binutils`), `tar`, `curl`.

Build the latest version automatically (queries Anthropic's apt repo
index directly, per their [official Linux docs](https://code.claude.com/docs/en/desktop-linux)):

```sh
./scripts/build-rpm.sh
```

Or pin a specific version / architecture:

```sh
./scripts/build-rpm.sh --version <upstream-version> --arch amd64
```

You can also build from an already-downloaded `.deb`:

```sh
./scripts/build-rpm.sh --deb-path ./claude-desktop.deb
```

The built `.rpm` is written to `dist/`.

## Verifying a build

```sh
./scripts/verify-rpm.sh dist/claude-desktop-*.rpm
```

Installs the package inside a clean `fedora:latest` container and checks
that the binary, desktop entry, and icons are present, and that the app
launches under Xvfb without crashing.

## How it works

1. `scripts/fetch-deb.sh` — downloads the newest (or a pinned version of)
   the official Claude Desktop `.deb` from Anthropic's apt repository
   (`downloads.claude.ai/claude-desktop/apt/stable`), or accepts a local
   copy.
2. `scripts/extract-deb.sh` — unpacks the `.deb` and locates the Electron
   application, icons, and `.desktop` file inside it.
3. `scripts/map-deps.sh` — translates the Debian runtime dependency list
   to Fedora package names for the RPM `Requires:` list.
4. `scripts/build-rpm.sh` — stages everything into the layout expected by
   `packaging/claude-desktop.spec` and runs `rpmbuild`.

See [docs/VERSIONING.md](docs/VERSIONING.md) for how upstream version
tracking works, and [CONTRIBUTING.md](CONTRIBUTING.md) for how to submit
changes.

## License

The packaging scripts and spec file in this repository are MIT licensed —
see [LICENSE](LICENSE). This does **not** extend to the Claude Desktop
application itself, which remains Anthropic's proprietary software.
