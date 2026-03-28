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
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | Hosts with NVIDIA GPU (including AMD + NVIDIA). |

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

Before using signed rebases, ensure your host trust policy is configured for this repository signing key (`cosign.pub`).

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
# or
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot again.

## Post-Installation, Validation, and Troubleshooting

All post-install configuration, runtime validation checks, and troubleshooting steps are consolidated in:

- [`POST_INSTALL.md`](POST_INSTALL.md) (common post-install, validation, and troubleshooting)
- [`POST_INSTALL_NVIDIA.md`](POST_INSTALL_NVIDIA.md) (NVIDIA/hybrid-specific complement)

## Local Development

The Distrobox-based local development and build flow is documented in:

- [`bluebuild/README.md`](bluebuild/README.md)

## Repository Structure

- [`recipes/`](recipes/): BlueBuild recipes and shared modules.
- [`files/system/`](files/system/): system configuration copied into the final image.
- [`files/scripts/`](files/scripts/): utilities installed in the image.
- [`.github/workflows/`](.github/workflows/): build pipelines and automation.
