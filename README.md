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
- **Local development:** Distrobox + BlueBuild CLI workflow

## Image Variants

| Image | Base Image | Use Case |
| :--- | :--- | :--- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | AMD hosts without dedicated NVIDIA GPU |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | Hosts with NVIDIA GPU (including AMD + NVIDIA hybrid setups) |

> ⚠️ **Important:** This image is heavily tuned for high-end workstations (64GB RAM) and local AI workloads. Please read the [Hardware Baseline & Warnings](docs/HARDWARE_BASELINE.md) before installing on standard hardware or laptops.

## Quick Start (Install)

Recommended flow: **unverified rebase** (first boot) -> **signed rebase** (final state).

### Initial Rebase (Unverified)

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest
```

Or for NVIDIA variant:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot after the rebase completes.

### Signed Rebase (Verified)

After confirming system stability, switch to the signed image:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
```

Or for NVIDIA variant:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot again to complete the transition.

## Post-Installation, Validation, and Troubleshooting

All post-install configuration, runtime validation checks, and troubleshooting steps are consolidated in our guides.

**Everyone must follow the general guide first:**

- [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) — General post-install operations, tuning, and validation for ALL variants

**If you installed the NVIDIA variant, proceed to the specific guide afterward:**

- [`docs/POST_INSTALL_NVIDIA.md`](docs/POST_INSTALL_NVIDIA.md) — Container GPU access, Secure Boot, and NVIDIA-specific validation

## Local Development

The Distrobox-based local development and build flow is documented in:

- [`bluebuild/README.md`](bluebuild/README.md)

## Repository Structure

| Directory | Purpose |
| :--- | :--- |
| [`recipes/`](recipes/) | BlueBuild recipes and shared modules |
| [`files/system/`](files/system/) | System configuration copied into the final image |
| [`files/scripts/`](files/scripts/) | Utilities installed in the image |
| [`.github/workflows/`](.github/workflows/) | Build pipelines and automation |

## Documentation Map

| Document | Description |
| :--- | :--- |
| [`README.md`](README.md) | Main project overview and install flow |
| [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) | Hardware assumptions and limits |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Shared post-install runtime validation |
| [`docs/POST_INSTALL_NVIDIA.md`](docs/POST_INSTALL_NVIDIA.md) | NVIDIA/hybrid post-install extensions |
| [`bluebuild/README.md`](bluebuild/README.md) | Local build workflow with Distrobox |
