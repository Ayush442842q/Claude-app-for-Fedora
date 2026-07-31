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

`scripts/fetch-deb.sh` reads Anthropic's apt repository index directly
(`downloads.claude.ai/claude-desktop/apt/stable`). If it stops finding
packages, check whether the repo layout described in
https://code.claude.com/docs/en/desktop-linux has changed, and open an
issue with what you find.

## Dependency mapping

If the built RPM fails to launch due to a missing library, check
`scripts/map-deps.sh` — it's a hand-maintained Debian→Fedora package name
table and may be missing an entry for a new upstream dependency.

## Version bumps

Version tracking is manual (see [docs/VERSIONING.md](docs/VERSIONING.md)).
When Anthropic ships a new Claude Desktop release, open a PR (or trigger
the `Build and release RPM` GitHub Action manually) with the new version
number.
