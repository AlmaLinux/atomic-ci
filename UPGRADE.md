# Upgrade guide

What you need to change in your repository when you move to a new version. Each file links to
the version in [atomic-respin-template](https://github.com/AlmaLinux/atomic-respin-template),
which you can copy from. The [changelog](CHANGELOG.md) describes what changed and why.

## From v11 to v12

⚠️ Your workflows stop working until you make changes 1 to 4.

In the job that calls `build-iso.yml`
([build-iso.yml](https://github.com/AlmaLinux/atomic-respin-template/blob/main/.github/workflows/build-iso.yml)):

1. Add `permissions: { contents: read, packages: read, id-token: write }`.
2. Rename `update_origin_ref` to `update-origin-ref`, and `update_is_signed` to
   `update-is-signed`.
3. Remove `use_librepo`, if you set it.

In the job that calls `create-release.yml`
([build.yml](https://github.com/AlmaLinux/atomic-respin-template/blob/main/.github/workflows/build.yml)):

4. Remove `pretty-version`.

Not breaking, but do them soon:

5. Update [files/scripts/cleanup.sh](https://github.com/AlmaLinux/atomic-respin-template/blob/main/files/scripts/cleanup.sh).
   The old one breaks `/usr/local` in the image. CI works around it for now, with a warning.
6. Update the [Makefile](https://github.com/AlmaLinux/atomic-respin-template/blob/main/Makefile),
   if you build ISOs or disk images locally.
