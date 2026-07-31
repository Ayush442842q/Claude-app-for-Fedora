# Contributing

This project accepts contributions in the form of **issue reports** —
bug reports and version/dependency-mapping problems. It does not accept
unsolicited pull requests.

## Before opening an issue

- Search [existing issues](../../issues) first — someone may have already
  reported it.
- Make sure it's about **this project** (the packaging, build scripts, or
  the built `.rpm`), not about Claude Desktop's chat behavior or your
  Anthropic account/subscription. Those go to
  [Anthropic's own support channels](https://claude.ai/download) instead.

## Opening a bug report

Use the [bug report template](../../issues/new/choose) — it asks for the
package version, distro version, and reproduction steps needed to
actually track the problem down. In particular, useful reports for the
most common failure modes:

**Broken build / can't fetch the `.deb`**
`scripts/fetch-deb.sh` reads Anthropic's apt repository index directly
(`downloads.claude.ai/claude-desktop/apt/stable`). If it stops finding
packages, include the output of:

```sh
curl -s https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages | head -50
```

and note whether the layout described in
[Anthropic's Linux docs](https://code.claude.com/docs/en/desktop-linux)
appears to have changed.

**App crashes on launch / missing library**
Include the exact error from running `claude-desktop` in a terminal, and
the output of `rpm -q --requires claude-desktop`. This usually points to
a missing entry in `scripts/map-deps.sh` (the Debian→Fedora dependency
name table) or `packaging/claude-desktop.spec`'s `Requires:`/
`Recommends:` lists.

**Version out of date**
Version tracking is manual — see [docs/VERSIONING.md](docs/VERSIONING.md).
If the latest upstream release isn't being picked up, include the
version you expected versus what `scripts/build-rpm.sh` actually fetched.
