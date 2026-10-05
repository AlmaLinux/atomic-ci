# Changelog

## v12

⚠️ **This version has breaking changes.** Your workflows stop working until you make the
changes in the [upgrade guide](UPGRADE.md).

### What changed

- ISOs boot into a live session of your image, with an installer that doesn't need a network
  connection. Only the kickstart of the ISO configuration file is used.
- Images are rechunked with a different tool, so the first update to an image built with v12
  downloads the whole image again.
- Builds run on Ubuntu 26.04.
- New `hook-script` input for `build-iso.yml`, to customize the live environment of the ISO.

## v11

No changes required.
