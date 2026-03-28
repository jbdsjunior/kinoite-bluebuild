# Post-Installation Guide: NVIDIA / Hybrid (`kinoite-nvidia`)

This guide complements [`POST_INSTALL.md`](POST_INSTALL.md) with NVIDIA-specific runtime validation, container integration, and Secure Boot considerations.

## 1) Validate NVIDIA Stack

```bash
nvidia-smi
sudo nvidia-ctk cdi list 2>/dev/null || echo "CDI not generated yet"
````

## 2\) Enable GPU Access for Containers (CDI)

Generate CDI definition when needed:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

Validate with a CUDA container:

```bash
podman run --rm --device [nvidia.com/gpu=all](https://nvidia.com/gpu=all) nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

## 3\) Secure Boot (MOK Enrollment)

If Secure Boot is enabled, enroll the key:

```bash
ujust enroll-secure-boot-key
```

Reboot and finish the MOK enrollment flow in firmware UI.

## 4\) Operational Validation Checklist

```bash
# KVM/libvirt availability
id | grep -E "libvirt|kvm"
lsmod | grep kvm
systemctl status libvirtd

# User timers and update cadence signals
systemctl --user list-timers "topgrade-*.timer"

# Kernel args relevant to this image profile
rpm-ostree kargs | tr ' ' '\n' | grep -E "amd_pstate|transparent_hugepage|mitigations|pcie_aspm"
```

## 5\) Cloud Mount (Rclone) Example for Workflows

```bash
rclone config
mkdir -p ~/.config/rclone/env/
echo 'RCLONE_EXTRA_OPTS="--vfs-read-chunk-size 128M --vfs-read-chunk-size-limit off"' > ~/.config/rclone/env/onedrive_work.env
systemctl --user enable --now rclone@onedrive_work.service
systemctl --user status rclone@onedrive_work.service
```

Expected mount path: `~/Cloud/remote-name`.

## 6\) When to Return to the Common Guide

Use [`POST_INSTALL.md`](https://www.google.com/search?q=POST_INSTALL.md) for:

- shared troubleshooting (captive portal and NetworkManager profile overrides),
- cross-variant baseline checks,
- common post-install operations.

<!-- end list -->

````

***

### `bluebuild/README.md`
```markdown
# Test and Validation Environment with Distrobox

> Last reviewed: 2026-03-28

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

- Project overview and install quickstart: [`../README.md`](https://www.google.com/search?q=../README.md)
- Post-install common guide: [`../POST_INSTALL.md`](https://www.google.com/search?q=../POST_INSTALL.md)
- NVIDIA/hybrid-specific guide: [`../POST_INSTALL_NVIDIA.md`](https://www.google.com/search?q=../POST_INSTALL_NVIDIA.md)
