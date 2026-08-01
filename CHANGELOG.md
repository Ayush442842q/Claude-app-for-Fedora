# Changelog

## v1.24012.9 — 2026-07-31

- First release: fetch/extract/build/verify scripts, RPM spec, and CI
  workflows for repackaging Claude Desktop as an `.rpm`, built and
  verified against upstream version `1.24012.9`.
- Build and install verified end-to-end on Fedora: installs cleanly via
  `dnf`, launches, and the Chromium sandbox works (`chrome-sandbox`
  correctly ships setuid).
