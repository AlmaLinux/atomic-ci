# AlmaLinux Atomic CI

Reusable GitHub Actions workflows to build, sign and publish [bootc](https://github.com/bootc-dev/bootc)
images based on AlmaLinux, and installer ISOs for them. They are used by the AlmaLinux Atomic SIG
images and by respins of them.

| Workflow | What it does |
|---|---|
| [`build-image.yml`](#build-imageyml) | Builds a multi-platform image, rechunks it, pushes it and optionally signs it |
| [`build-iso.yml`](#build-isoyml) | Builds a live ISO with an installer for an image |
| [`retag-image.yml`](#retag-imageyml) | Adds tags to an image that is already in the registry |
| [`create-release.yml`](#create-releaseyml) | Creates a GitHub release with the changelog and SBOMs of an image |

## Getting started

The easiest way to use these workflows is to start from the
[atomic-respin-template](https://github.com/AlmaLinux/atomic-respin-template). It has everything set
up, and its `build.yml` and `build-iso.yml` are working examples of how the workflows fit together.

To call a workflow from your own repository:

```yaml
jobs:
  build-image:
    uses: AlmaLinux/atomic-ci/.github/workflows/build-image.yml@v12
    with:
      containerfile: Dockerfile
      image-name: my-image
      previous-image: ghcr.io/my-org/my-image:latest
    secrets:
      REGISTRY_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    permissions:
      contents: read
      packages: write
      id-token: write
```

The calling job has to grant the permissions listed for each workflow below. A workflow that asks
for more than its caller grants is rejected as invalid.

## Versions

Releases are tagged with a single number (`v11`, `v12`). A new version can require changes in the
repositories that use it. The [upgrade guide](UPGRADE.md) lists what you need to do, and the [changelog](CHANGELOG.md)
describes what changed. Dependabot includes both in the pull requests it opens to update the
version.

## Workflows

### `build-image.yml`

Builds the image for each platform on a native runner, then combines the results in a
multi-platform manifest. For each platform it:

1. Verifies the signature of the base image, if `upstream-public-key` is set.
2. Builds the Containerfile, passing the build arguments `IMAGE_NAME`, `IMAGE_REGISTRY` and
   `VARIANT`.
3. Rechunks the image with `bootc-base-imagectl rechunk`, so updates only download the layers that
   changed.
4. Generates a changelog with the commits and package changes since `previous-image`.
5. Pushes the image and signs it, if a signing key is configured. Builds of pull requests are not
   signed until they are merged.
6. Generates an SBOM on the default branch, if `generate-sbom` is set.

The image has to be based on an AlmaLinux bootc image.

The manifest is tagged with the name of the branch. Use [`retag-image.yml`](#retag-imageyml) to add
tags like `latest` once the image has been tested.

**Permissions:** `contents: read`, `packages: write`, `id-token: write`

| Input | Required | Default | Description |
|---|---|---|---|
| `containerfile` | yes | | Path to the Containerfile |
| `image-name` | yes | | Name of the image |
| `previous-image` | no | | Previous version of the image, used for the changelog and to avoid reusing a version number |
| `image-description` | no | `AlmaLinux image` | Description of the image |
| `image-path` | no | repository owner | Path of the image in the registry |
| `platforms` | no | `amd64,arm64` | Comma-separated list of platforms to build |
| `variant` | no | | Variant of the image, passed to the build as `VARIANT` |
| `upstream-public-key` | no | | Path to the public key of the base image. If set, its signature is verified before building |
| `generate-sbom` | no | `false` | Generate an SBOM of the image |
| `changelog-snippet` | no | kernel, systemd, glibc and bootc versions | Text to include in the changelog. `<version:PACKAGE>` and `<relver:PACKAGE>` are replaced with the version of a package, without and with its release |
| `docs-url` | no | repository URL | URL of the documentation of the image |
| `skip-maximize-build-space` | no | `false` | Don't remove unused software from the runner to make space |
| `REGISTRY` | no | `ghcr.io` | Registry to push the image to |
| `REGISTRY_USER` | no | `github.actor` | Username for the registry |
| `KMS_KEY_ALIAS` | no | | AWS KMS alias to sign the image with |
| `AWS_REGION` | no | | AWS region of the KMS key |

| Secret | Required | Description |
|---|---|---|
| `REGISTRY_TOKEN` | yes | Token for the registry |
| `SIGNING_SECRET` | no | Cosign private key to sign the image with |
| `AWS_ROLE_ARN` | no | AWS role to assume to sign the image with KMS |

| Output | Description |
|---|---|
| `image-ref` | Reference of the image, without tag or digest |
| `digest` | Digest of the multi-platform manifest |
| `version` | Version of the image |
| `redhat-version-id` | Version of AlmaLinux the image is based on (for example `10.2`) |
| `major-version` | Major version of AlmaLinux the image is based on (for example `10`) |

### `build-iso.yml`

Builds an ISO for each platform. The ISO boots into a live session of the image, with an installer
for it. The image is included in the ISO, so installing doesn't need a network connection.

The live environment is built on top of the image, and converted to an ISO with
[image-builder](https://github.com/osbuild/image-builder).

The installed system gets its updates from `update-origin-ref`. It verifies their signature if the
`/etc/containers/policy.json` of the image requires one for that image, which is what the template
sets up when the image is signed.

The installer doesn't need any configuration. To change the live environment or the installer, set
`hook-script` to a script in your repository. It runs at the end of the build of the live
environment, as root inside it. For example, to run your own steps during the installation, add
them to the kickstart of the installer:

```bash
cat >> /usr/share/anaconda/interactive-defaults.ks <<'EOF'
%post --erroronfail
echo "Installed from the ISO" > /etc/motd.d/installed
%end
EOF
```

**Permissions:** `contents: read`, `packages: read`, `id-token: write`

| Input | Required | Default | Description |
|---|---|---|---|
| `image` | yes | | Reference of the image to install, including tag or digest |
| `image-name` | yes | | Name of the image, used for the name of the ISO |
| `update-origin-ref` | no | | Image the installed system gets its updates from (for example `ghcr.io/my-org/my-image:latest`) |
| `hook-script` | no | | Path to a script that runs at the end of the build of the live environment, to customize it or the installer |
| `platforms` | no | `amd64,arm64` | Comma-separated list of platforms to build |
| `skip-maximize-build-space` | no | `false` | Don't remove unused software from the runner to make space |
| `REGISTRY` | no | `ghcr.io` | Registry the image is pulled from |
| `REGISTRY_USER` | no | `github.actor` | Username for the registry |
| `upload-to-github` | no | `true` | Upload the ISO as a workflow artifact |
| `upload-to-cloudflare` | no | `false` | Upload the ISO to Cloudflare R2 |
| `upload-to-s3` | no | `false` | Upload the ISO to AWS S3 |
| `bucket` | no | | R2 or S3 bucket to upload to |
| `s3-path` | no | | Path in the S3 bucket to upload to |
| `aws-default-region` | no | | AWS region of the S3 bucket |

| Secret | Required | Description |
|---|---|---|
| `REGISTRY_TOKEN` | yes | Token for the registry |
| `R2_ACCOUNT_ID` | no | Cloudflare R2 account ID |
| `ACCESS_KEY_ID` | no | Cloudflare R2 access key ID |
| `SECRET_ACCESS_KEY` | no | Cloudflare R2 secret access key |
| `AWS_ROLE_ARN` | no | AWS role to assume for the upload to S3 |

### `retag-image.yml`

Adds one or more tags to an image that is already in the registry, without pulling it. This is
meant to promote an image after it has been tested.

**Permissions:** `packages: write`

| Input | Required | Default | Description |
|---|---|---|---|
| `image` | yes | | Reference of the image, without tag or digest |
| `digest` | yes | | Digest of the image |
| `tag` | yes | | Tags to add, one per line |
| `REGISTRY` | no | `ghcr.io` | Registry of the image |
| `REGISTRY_USER` | no | `github.actor` | Username for the registry |

| Secret | Required | Description |
|---|---|---|
| `REGISTRY_TOKEN` | yes | Token for the registry |

### `create-release.yml`

Creates a GitHub release named after the version of the image. The release notes are the
changelogs generated by `build-image.yml`, followed by instructions to switch to the image. The
SBOMs are attached to the release.

It has to run in the same workflow run as `build-image.yml`, as it uses the artifacts of that job.

**Permissions:** `contents: write`

| Input | Required | Description |
|---|---|---|
| `image-name` | yes | Name of the image |
| `version` | yes | Version of the image, used as the tag of the release |
| `latest-image-ref` | yes | Reference to show in the instructions to switch to the image |

# Contributing

We welcome contributions to all parts of the AlmaLinux project. If you'd like to get involved, please feel free to reach out through [the chat](https://chat.almalinux.org/almalinux/channels/sigatomic)!

## Contributing - Code and Design

This project houses the GitHub Actions workflows that are used by other Atomic SIG projects to generate bootc images.

Before submitting code changes, please check if there are any open issues or pull requests that cover your proposal. If not, open an issue with a brief description and so you can discuss it with us first. This helps avoid duplicated work and ensures proposed changes align with project goals. This can be your anticipated workflow:

- Create an issue describing your changes.
- Await confirmation from contributors.
- Fork the project.
- Create a new branch for your feature or bug fix.
- Add your code, documentation, etc.
- Submit a pull request (PR). All PRs should target the `main` branch.

After review and approval, the changes will be merged and deployed.

Changes that require action from the repositories using these workflows have to be described in the [upgrade guide](UPGRADE.md), with the newest version first and within its first 50 lines, as that is what Dependabot shows. All changes go in the [changelog](CHANGELOG.md).

## Reporting a Bug

If you find a bug, please report it [here](issues)!

## Requesting a Feature

We're open to feature requests! Please follow this workflow:

1. [Search existing issues](issues) to see if the feature has already been requested. If so, give it a thumbs up, +1, or a comment on your use-case.
2. If no similar request exists, open a new issue. Please clearly explain why the feature is needed and provide a detailed use case.

## Change Approval Process

- Minor or cosmetic changes (typos, small style tweaks) can be reviewed and approved by any contributor with merge rights.
- Larger changes should be agreed on as a SIG.

# Getting help

This repo is managed by the Atomic SIG. You can see how best to contact us in the [AlmaLinux wiki](https://wiki.almalinux.org/sigs/Atomic.html).
