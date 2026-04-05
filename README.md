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

Recommended flow: apply the custom image via `bootc switch`.

### System Switch

For the AMD variant:

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
````

For the NVIDIA variant:

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot after the process completes. Cryptographic signatures are validated automatically via container policies injected by the image.

## Post-Installation, Validation, and Troubleshooting

All post-install configuration, runtime validation checks, and troubleshooting steps are consolidated in our guides.

**Everyone must follow the general guide first:**

  - [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) — General post-install operations, tuning, and validation for ALL variants

**If you installed the NVIDIA variant, proceed to the specific guide afterward:**

  - [`docs/POST_INSTALL_NVIDIA.md`](docs/POST_INSTALL_NVIDIA.md) — Container GPU access, Secure Boot, and NVIDIA-specific validation

## Local Development

The Distrobox-based local development and build flow is documented in:

  - [`bluebuild/README.md`](bluebuild/README.md)

## Emergency Rollback

If a switch causes boot failures or instability, rollback immediately:

## Boot into the previous deployment from GRUB menu, OR
### From a working system, revert to the last known good state:
```bash
sudo bootc rollback
```
### To revert to Fedora's official Kinoite image:
```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

After rollback, reboot and verify stability before attempting another switch.

## Documentation Map

| Document | Description |
| :--- | :--- |
| [`README.md`](README.md) | Main project overview and install flow |
| [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) | Hardware assumptions and limits |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Shared post-install runtime validation |
| [`docs/POST_INSTALL_NVIDIA.md`](docs/POST_INSTALL_NVIDIA.md) | NVIDIA/hybrid post-install extensions |
| [`docs/OPTIONAL_PACKAGES.md`](docs/OPTIONAL_PACKAGES.md) | Guide for optional packages and Flatpaks |
| [`bluebuild/README.md`](bluebuild/README.md) | Local build workflow with Distrobox |

