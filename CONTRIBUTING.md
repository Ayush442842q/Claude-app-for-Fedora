# Contributing

Contributions are welcome — bug reports, dependency-mapping fixes, and
spec/script improvements especially.

## Local development

1. Build with a locally downloaded `.deb`:
   ```sh
   ./scripts/build-rpm.sh --version <version> --deb-path ./claude-desktop.deb
   ```
2. Verify the result:
   ```sh
   ./scripts/verify-rpm.sh dist/claude-desktop-*.rpm
   ```
3. Shellcheck any script changes:
   ```sh
   shellcheck scripts/*.sh
   ```

## Reporting a broken build

If `scripts/fetch-deb.sh` fails to auto-discover the current `.deb` URL,
please open an issue with the current working download URL from
https://claude.ai/download — Anthropic doesn't document a stable link, so
this needs periodic manual updates.

## Dependency mapping

If the built RPM fails to launch due to a missing library, check
`scripts/map-deps.sh` — it's a hand-maintained Debian→Fedora package name
table and may be missing an entry for a new upstream dependency.

## Version bumps

Version tracking is manual (see [docs/VERSIONING.md](docs/VERSIONING.md)).
When Anthropic ships a new Claude Desktop release, open a PR (or trigger
the `Build and release RPM` GitHub Action manually) with the new version
number.
