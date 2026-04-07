<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable Fedora Kinoite (KDE Plasma) image built with [BlueBuild](https://blue-build.org/), focused on performance, container-first workflows, automatic updates, and reproducible system tuning.

## Quick Overview

- **Ready-to-use variants:** `kinoite-amd` and `kinoite-nvidia`
- **Automated builds:** Publishing via GitHub Actions
- **Automatic updates:** Managed through `topgrade` user timers
- **System tuning:** Kernel/sysctl/network configuration versioned under `files/system/`
- **Local development:** BlueBuild CLI with Distrobox

## Image Variants

| Image | Base Image | Use Case |
| :--- | :--- | :--- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | AMD hosts without dedicated NVIDIA GPU |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | Hosts with NVIDIA GPU (including AMD + NVIDIA hybrid setups) |

> ⚠️ **Important:** This image is heavily tuned for high-performance workstations (64GB RAM). Read the [Hardware Baseline](docs/HARDWARE_BASELINE.md) before installing.

## Quick Start

### Initial Rebase (Unverified)

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
```

Or for NVIDIA variant:

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot after the rebase completes.

### Signed Rebase (Verified)

After confirming system stability, switch to the signed image:

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest
```

Or for NVIDIA variant:

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

## Post-Installation

Complete the post-install steps for your variant:

- **All variants:** [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md)
- **NVIDIA variant:** [`docs/POST_INSTALL_NVIDIA.md`](docs/POST_INSTALL_NVIDIA.md) (after general guide)

## Emergency Rollback

```bash
# Revert to previous deployment
sudo bootc rollback

# Revert to stock Fedora Kinoite
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
sudo bootc switch --enforce-container-sigpolicy quay.io/fedora/fedora-kinoite:latest

```

Reboot after any rollback.
