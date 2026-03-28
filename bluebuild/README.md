# Test and Validation Environment with Distrobox

This directory contains the canonical workflow for local development and testing using [Distrobox](https://distrobox.it/).

The `distrobox.ini` file defines a container with the `ghcr.io/blue-build/cli:latest-distrobox` image, which includes the `bluebuild` CLI and dependencies needed to build the custom OCI image locally.

## Requirements

- **Distrobox** installed on the host.
- **Podman** or **Docker** runtime available.

## Environment Configuration

### 1. Create the Container

From the project root:

```bash
distrobox assemble create
````

This downloads the BlueBuild image, creates the `bluebuild` container, and applies the declared config.

### 2\. Enter the Container

```bash
distrobox enter bluebuild
```

You will enter a shell where `bluebuild` CLI is available.

## Build Images Locally

Inside the `bluebuild` environment:

### Build AMD Recipe

```bash
bluebuild build recipes/recipe-amd.yml
```

### Build NVIDIA Recipe

```bash
bluebuild build recipes/recipe-nvidia.yml
```

For NVIDIA builds, the recipe uses `ghcr.io/ublue-os/kinoite-nvidia` as the base and composes shared modules from this repository.

After compilation, the OCI image is available in local container storage. You can list images with `podman images`.

## Local Rebase Test

Use local image output to validate changes before publishing:

```bash
rpm-ostree rebase ostree-unverified-image:oci-archive:/path/to/your/repo/build/image.oci
```

## Related Documents

- Project overview and install quickstart: [`../README.md`](../README.md)
- Post-install common guide: [`../docs/POST_INSTALL.md`](../docs/POST_INSTALL.md)
- NVIDIA/hybrid-specific guide: [`../docs/POST_INSTALL_NVIDIA.md`](../docs/POST_INSTALL_NVIDIA.md)
