<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable Fedora Kinoite (KDE Plasma) image built with [BlueBuild](https://blue-build.org/), focused on performance, container-first workflows, automatic updates, and reproducible system tuning.

## Quick Overview

- Ready-to-use variants: `kinoite-amd` and `kinoite-nvidia`.
- Automated build and publishing with GitHub Actions.
- Automatic updates through `topgrade` user timers.
- Kernel/sysctl/network tuning versioned under `files/system`.
- Local development workflow with Distrobox + BlueBuild CLI.

## Image Variants

| Image | Base image | When to use |
| :--- | :--- | :--- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | AMD hosts without a dedicated NVIDIA GPU. |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | Hosts with an NVIDIA GPU (including AMD + NVIDIA hybrid setups). |

> ⚠️ **Important:** This image is heavily tuned for high-end workstations (64GB RAM) and local AI workloads. Please read the [Hardware Baseline & Warnings](HARDWARE_BASELINE.md) before installing on standard hardware or laptops.

## Quick Start (Install)

Recommended flow: **unverified rebase** (first boot) -> **signed rebase** (final state).

### Initial Rebase (Unverified)

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest
# or
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest
````

Reboot.

### Signed Rebase (Verified)

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
# or
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot again.

## Post-Installation, Validation, and Troubleshooting

All post-install configuration, runtime validation checks, and troubleshooting steps are consolidated in our guides.

**The general guide first:**

- [`POST_INSTALL.md`](POST_INSTALL.md) (General post-install operations, tuning, and validation for ALL variants)

**If you installed the NVIDIA variant, proceed to the specific guide afterward:**

- [`POST_INSTALL_NVIDIA.md`](POST_INSTALL_NVIDIA.md) (Container GPU access, Secure Boot, and NVIDIA-specific validation)

## Local Development

The Distrobox-based local development and build flow is documented in:

- [`bluebuild/README.md`](bluebuild/README.md)

## Repository Structure

- [`recipes/`](recipes/): BlueBuild recipes and shared modules.
- [`files/system/`](files/system/): system configuration copied into the final image.
- [`files/scripts/`](files/scripts/): utilities installed in the image.
- [`.github/workflows/`](.github/workflows/): build pipelines and automation.
