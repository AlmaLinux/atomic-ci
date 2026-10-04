# Changelog

Changes that need action from repositories using these workflows are listed under
"Required changes". The matching changes in
[atomic-respin-template](https://github.com/AlmaLinux/atomic-respin-template) are linked,
so you can apply them to your own repository.

## v12

### Required changes

- **Grant permissions to the `build-iso` job.** The job that calls `build-iso.yml` has to
  declare the permissions the workflow needs, otherwise the workflow is rejected as invalid:

  ```yaml
  permissions:
    contents: read
    packages: read
    id-token: write
  ```

  Template change: https://github.com/AlmaLinux/atomic-respin-template/commit/73429a61

- **Fix `files/scripts/cleanup.sh`.** The script turned `/var/usrlocal` into a symlink to
  itself, which breaks `/usr/local` in the image. CI now detects this, removes the symlink
  and prints a warning, but that workaround will be removed in a future version and local
  builds are not covered by it.

  Template change: https://github.com/AlmaLinux/atomic-respin-template/commit/396969c4

- **Update the `Makefile`** if you build ISOs or disk images locally. `make iso` and
  `make qcow2` used bootc-image-builder, which no longer builds ISOs.

  Template change: https://github.com/AlmaLinux/atomic-respin-template/commit/810966f2

### Changed

- **ISOs are now live images.** They boot into a live session of your image, with an
  installer for it. The image is included in the ISO, so installing doesn't need a network
  connection. ISOs are built with [image-builder](https://github.com/osbuild/image-builder)
  instead of bootc-image-builder.
  - Only the kickstart (`[customizations.installer.kickstart]`) of the ISO configuration
    file is used. Other customizations are ignored, with a warning.
  - `config-file` is now optional.
  - `use_librepo` is deprecated and has no effect.
- **Images are rechunked with `bootc-base-imagectl rechunk`** instead of `hhd-dev/rechunk`.
  The layers of the image are split differently, so the first update after this change
  downloads the whole image again.
- `build-iso.yml` only needs `packages: read`.

### Added

- `hook-script` input for `build-iso.yml`: a script from your repository that runs at the
  end of the live image build, to customize the live environment.
- `skip-maximize-build-space` input for `build-iso.yml`.

## v11

No changes required.
