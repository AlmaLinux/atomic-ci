# Upgrade guide

What you need to change in your repository when you move to a new version. Each file links to
the version in [atomic-respin-template](https://github.com/AlmaLinux/atomic-respin-template),
which you can copy from. The [changelog](CHANGELOG.md) describes what changed and why.

## From v11 to v12

⚠️ Your workflows stop working until you make changes 1 to 5.

In the job that calls `build-iso.yml`
([build-iso.yml](https://github.com/AlmaLinux/atomic-respin-template/blob/main/.github/workflows/build-iso.yml)):

1. Add `permissions: { contents: read, packages: read, id-token: write }`.
2. Rename `update_origin_ref` to `update-origin-ref`.
3. Remove `update_is_signed` and `use_librepo`.
4. Remove `config-file` and delete `iso.toml`: the installer sets up updates by itself now. If
   you added your own steps to its kickstart, move them to a script and pass it as `hook-script`
   ([how](README.md#build-isoyml)).

In the job that calls `create-release.yml`
([build.yml](https://github.com/AlmaLinux/atomic-respin-template/blob/main/.github/workflows/build.yml)):

5. Remove `pretty-version`.

Not breaking, but do them soon:

6. Update [files/scripts/cleanup.sh](https://github.com/AlmaLinux/atomic-respin-template/blob/main/files/scripts/cleanup.sh).
   The old one breaks `/usr/local` in the image. CI works around it for now, with a warning.
7. Update the [Makefile](https://github.com/AlmaLinux/atomic-respin-template/blob/main/Makefile),
   if you build ISOs or disk images locally.
