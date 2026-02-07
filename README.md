<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Custom Fedora Kinoite (BlueBuild)

Immutable Fedora Kinoite images focused on performance, development workflow, and practical privacy defaults.

</div>

## Overview

This repository builds two signed Fedora Kinoite images with [BlueBuild](https://blue-build.org/):

- `kinoite-amd` based on `ghcr.io/ublue-os/kinoite-main`
- `kinoite-nvidia` based on `ghcr.io/ublue-os/kinoite-nvidia`

Both variants share a common module stack (`recipes/common.yml`) and include tuned kernel arguments, virtualization support, system updates via timers, and curated CLI tooling.

## What Is Included

### System and performance

- Kernel arguments for transparent huge pages and AMD P-State (`recipes/common-kargs.yml`)
- KVM/IOMMU kernel arguments and virtualization group (`recipes/common-kvm.yml`)
- BBR + TCP tuning and memory/sysctl tuning (`files/system/usr/lib/sysctl.d/60-kernel-tuning.conf`)
- ZRAM policy using zstd with size cap (`files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`)

### Networking and privacy defaults

- `systemd-resolved` enabled with:
  - Control D resolvers as primary
  - Cloudflare as fallback
  - `DNSSEC=yes`
  - `DNSOverTLS=opportunistic`
- NetworkManager privacy settings for MAC randomization and DHCP hostname suppression

### Packages and tooling

- Multimedia stack (GStreamer/FFmpeg and related codecs)
- Virtualization stack (`@virtualization` plus `libvirtd` service)
- CLI tools: `starship`, `topgrade`, `fastfetch`, `distrobox`
- Utility packages: `rclone`, `fuse3`, `lm_sensors`

### NVIDIA-specific additions

On `kinoite-nvidia`, this repo adds:

- `nvidia-container-toolkit`
- NVIDIA-related kernel arguments to blacklist Nouveau

The proprietary NVIDIA driver stack itself comes from the base image `ghcr.io/ublue-os/kinoite-nvidia`.

## Image Variants

| Image | Recommended for |
| :--- | :--- |
| `ghcr.io/jbdsjunior/kinoite-amd:latest` | AMD/Intel systems using the `kinoite-main` base |
| `ghcr.io/jbdsjunior/kinoite-nvidia:latest` | NVIDIA systems that need the Universal Blue NVIDIA base and CUDA container tooling |

## Installation

Use a two-step rebase flow so signing metadata is correctly established.

### 1. Initial rebase (unverified)

AMD/Intel:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest
```

NVIDIA:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot after this step.

### 2. Switch to signed updates

AMD/Intel:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
```

NVIDIA:

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot again to finalize.

## Post-install setup

### KVM and libvirt

Run:

```bash
kinoite-setup-kvm.sh
```

This helper adds your user to `libvirt,kvm`, prepares libvirt image paths, and restarts `libvirtd`.
A logout/restart is required for group changes to apply.

### NVIDIA containers (CUDA)

`kinoite-nvidia` includes `nvidia-container-toolkit` for Podman/Distrobox GPU workloads.

Example:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### NVIDIA + Secure Boot

If Secure Boot is enabled, enroll the Universal Blue MOK key on the host:

```bash
ujust enroll-secure-boot-key
```

Then reboot and complete the firmware MOK enrollment flow.

### Rclone user mount service

1. Configure remotes: `rclone config`
2. Enable mount service:

```bash
systemctl --user enable --now rclone-mount@<remote-name>.service
```

Mounted path: `~/Cloud/<remote-name>`.

## Troubleshooting

### Captive portals (hotels, airports, guest Wi-Fi)

Default DNS is privacy-focused and uses `DNSOverTLS=opportunistic`. Most networks work without changes, but some captive portals still fail.

Create a temporary relaxed override:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/permissive-dns.conf >/dev/null <<'CONF'
[Resolve]
DNSOverTLS=opportunistic
DNSSEC=allow-downgrade
CONF
sudo systemctl restart systemd-resolved
```

After leaving that network, remove it:

```bash
sudo rm /etc/systemd/resolved.conf.d/permissive-dns.conf
sudo systemctl restart systemd-resolved
```

## Local development

A Distrobox-based development environment is included in `bluebuild/`.

```bash
distrobox assemble create
distrobox enter bluebuild
bluebuild build recipes/recipe-amd.yml
# or
bluebuild build recipes/recipe-nvidia.yml
```

See `bluebuild/README.md` for details.

## License

Licensed under the Apache License 2.0. See `LICENSE`.
