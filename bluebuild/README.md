# Test and Validation Environment with Distrobox

This directory contains the configuration for a local development and testing environment using [Distrobox](https://distrobox.it/).

The `distrobox.ini` file defines a container with the `ghcr.io/blue-build/cli:latest-distrobox` image, which includes the `bluebuild` CLI and all necessary dependencies to build the custom OCI image locally.

## Requirements

- **Distrobox**: Ensure Distrobox is installed on your system.
- **Podman** or **Docker**: A container runtime is required.

## ⚙️ Environment Configuration

### 1. Create the Container

`distrobox` uses the `distrobox.ini` file to configure and create the environment. To do this, run the following command in the project root:

```bash
distrobox assemble create

```

This command will download the `bluebuild` image, create the container named `bluebuild`, and configure it.

### 2. Enter the Container

After creation, access the `distrobox` environment with the command:

```bash
distrobox enter bluebuild

```

You will be directed to the shell inside the container, where the `bluebuild` CLI is available.

## 🛠️ Building the Image Locally

Inside the `bluebuild` environment, you can compile the recipes to generate OCI images.

### Compile AMD Recipe

```bash
bluebuild build recipes/images/amd.yml

```

### Compile Nvidia Recipe

```bash
bluebuild build recipes/images/nvidia.yml

```

For Secure Boot signing in local builds, set `NVIDIA_SIGNING_KEY` and `NVIDIA_SIGNING_CERT` in the shell before running the Nvidia build.

After compilation, the OCI image will be available locally in your container storage (Podman/Docker). You can list it with `podman images`.

## ✅ Local Image Testing

After building the image, you can rebase your system to the local version to test changes before pushing them to the remote registry.

Use the following command to rebase to the local image:

```bash
rpm-ostree rebase ostree-unverified-image:oci-archive:/path/to/your/repo/build/image.oci

```

---
