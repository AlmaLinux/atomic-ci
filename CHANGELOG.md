# Changelog

## v12

⚠️ **This version has breaking changes.** Your workflows stop working until you make the
changes in the [upgrade guide](UPGRADE.md).

### What changed

- ISOs boot into a live session of your image, with an installer that doesn't need a network
  connection. The installer needs no configuration, so `iso.toml` is gone.
- ISOs can be built for arm64.
- Images are rechunked with a different tool, so the first update to an image built with v12
  downloads the whole image again.
- Images built from any branch are signed, not only the ones from the default branch. Builds of
  pull requests are still not signed until they are merged.
- Builds run on Ubuntu 26.04.
- New `hook-script` input for `build-iso.yml`, to customize the live environment of the ISO and
  its installer.

## v11

No changes required.
