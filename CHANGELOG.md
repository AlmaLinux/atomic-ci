# Changelog

## v13

⚠️ **This version has breaking changes.** Your workflows stop working until you make the
changes in the [upgrade guide](UPGRADE.md).

### What changed

- Images are rechunked with a different tool (`bootc-base-imagectl rechunk`), so the first update to an image built with v13
  downloads the whole image again.
- ISO images are now built with [`image-builder`](https://osbuild.org/docs/developer-guide/projects/image-builder/).
- ISOs boot into a live session of your image, with an installer that doesn't need a network
  connection. The installer needs no configuration, so `iso.toml` is gone.
- ISOs can be built for arm64.
- Images built from any branch are signed, not only the ones from the default branch. Builds of
  pull requests are still not signed until they are merged.
- Builds run on Ubuntu 26.04.
- New `hook-script` input for `build-iso.yml`, to customize the live environment of the ISO and
  its installer.

## v11

No changes required.
