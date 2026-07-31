# Versioning

This project tracks upstream Claude Desktop releases directly: the RPM
`Version:` matches the version of the Claude Desktop `.deb` it was built
from, with `Release:` incrementing for repackaging-only changes against
the same upstream version (e.g. a fix to `map-deps.sh`).

## Detecting new upstream versions

Anthropic publishes Claude Desktop through a standard apt repository at
`https://downloads.claude.ai/claude-desktop/apt/stable` (see the
[official Linux docs](https://code.claude.com/docs/en/desktop-linux)).
`scripts/fetch-deb.sh` reads that repo's `Packages` index directly and,
when no `--version` is given, picks the newest version listed — so
`./scripts/build-rpm.sh` with no arguments always builds the current
upstream release.

The weekly scheduled run of `.github/workflows/build-release.yml` uses
this same auto-detection, so it picks up new upstream releases on its
own; a manual `workflow_dispatch` run with an explicit version is only
needed to pin/re-build an older release.

## Manually building a specific version

```sh
./scripts/build-rpm.sh --version <version> --arch amd64
```

Available versions/architectures can be inspected directly from the repo
index:

```sh
curl -s https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages \
  | grep '^Filename: pool/main/c/claude-desktop/claude-desktop_'
```
