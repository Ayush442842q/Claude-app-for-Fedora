# Versioning

This project tracks upstream Claude Desktop releases directly: the RPM
`Version:` matches the version of the Claude Desktop `.deb` it was built
from, with `Release:` incrementing for repackaging-only changes against
the same upstream version (e.g. a fix to `map-deps.sh`).

## Detecting new upstream versions

Anthropic does not publish a versions feed or changelog RSS for Claude
Desktop, so new releases currently have to be noticed manually (e.g. by
checking https://claude.ai/download periodically). The weekly scheduled
run of `.github/workflows/build-release.yml` is a placeholder for this —
today it re-triggers with whatever version input was last used; wiring up
real auto-detection is an open contribution area (see
[CONTRIBUTING.md](../CONTRIBUTING.md)).

## Manually triggering a build for a new version

1. Find the new version number and download URL from
   https://claude.ai/download.
2. Go to Actions → "Build and release RPM" → "Run workflow", and supply
   the version (and URL, if auto-discovery in `fetch-deb.sh` doesn't find
   it).
3. On success, the workflow publishes a GitHub Release with the built
   `.rpm` attached.
