<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable Fedora Kinoite (KDE Plasma) image built with [BlueBuild](https://blue-build.org/), focused on performance, container-first workflows, and simple day-2 operations in 2026.

## Current Status (2026)

- Two separate images: `kinoite-amd` and `kinoite-nvidia`.
- Automated build and publishing with GitHub Actions.
- Daily updates via `topgrade` (system + flatpak) through user timers.
- Kernel/sysctl tuning for heavy desktop usage, development, and virtualization.
- Network privacy defaults with `systemd-resolved` and NetworkManager hardening.

## Image Variants

| Image | Base image | When to use |
| :--- | :--- | :--- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | AMD-only hosts (no dedicated NVIDIA GPU). |
| `kinoite-nvidia` | `ghcr.io/blue-build/base-images/fedora-kinoite-nvidia` | Hosts with NVIDIA GPU (including AMD + NVIDIA setups). |

## Included

- Recipe-level kernel args: shared `transparent_hugepage=madvise` + BTRFS rootflags for all variants, and `amd_pstate=active` only on `kinoite-amd`.
- System tuning: BBR, high swappiness for ZRAM, increased inotify limits, and `vm.max_map_count`.
- Extra base packages: `topgrade`, `starship`, `fastfetch`, `distrobox`, multimedia stack (GStreamer/FFmpeg), KVM/libvirt, `rclone`.
- Default services: `firewalld`, `systemd-resolved`, and update timers guarded by `flock`.
- Versioned system files in this repo (`files/system/...`) for reproducible behavior.

## Installation (Recommended Flow)

Always use two stages: first unverified rebase, then signed rebase.

### 1) Initial Rebase (Unverified)

AMD:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest
```

NVIDIA:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot.

### 2) Signed Rebase (Verified)

AMD:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
```

NVIDIA:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot again.

### 3) Daily Operation

Timers used on host:

- `topgrade-system-update.timer` (daily)
- `topgrade-boot-update.timer` (after boot)
- `topgrade-flatpak-update.timer` (every 6 hours)

```bash
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer
```

To keep user timers active even without an open graphical session:

```bash
sudo loginctl enable-linger "$USER"
```

Manual execution (optional):

```bash
topgrade -cy --skip-notify --only system
topgrade -cy --skip-notify --only flatpak
```

Quick rollback if needed:

```bash
sudo rpm-ostree rollback
```

Quick check for current image:

```bash
rpm-ostree status | grep -E "kinoite-(amd|nvidia)"
```

## Post-Installation

### Virtualization (KVM/libvirt)

```bash
kinoite-setup-kvm.sh
```

Then log out and log in again to reload group membership (`libvirt`, `kvm`).

### NVIDIA for Containers (CUDA/CDI)

On `kinoite-nvidia`, generate CDI manually if needed:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### NVIDIA + Secure Boot (MOK)

If Secure Boot is enabled:

```bash
ujust enroll-secure-boot-key
```

Reboot and complete the MOK enrollment flow in firmware UI.

### Rclone Mount as User Service

```bash
rclone config
systemctl --user enable --now rclone-mount@remote-name.service
```

The mount will be available at `~/Cloud/remote-name`.

## Quick Troubleshooting

### Captive Portal (Hotel/Airport)

If the portal does not open, temporarily disable DoT/DNSSEC:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/90-captive-portal.conf >/dev/null <<'EOF'
[Resolve]
DNSOverTLS=no
DNSSEC=no
EOF
sudo systemctl restart systemd-resolved
```

To return to the image defaults:

```bash
sudo rm -f /etc/systemd/resolved.conf.d/90-captive-portal.conf
sudo systemctl restart systemd-resolved
```

## Local Development

```bash
distrobox assemble create
distrobox enter bluebuild
bluebuild build recipes/recipe-amd.yml
bluebuild build recipes/recipe-nvidia.yml
```

## Repository Structure

- `recipes/`: BlueBuild recipes and shared modules.
- `files/system/`: system configuration copied into the final image.
- `files/scripts/`: utilities installed in the image (for example KVM setup).
- `.github/workflows/`: AMD/NVIDIA builds, base update checks, and cleanup.

## License

Licensed under the **Apache License 2.0**.
