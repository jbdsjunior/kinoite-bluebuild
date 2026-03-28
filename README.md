<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable Fedora Kinoite (KDE Plasma) image built with [BlueBuild](https://blue-build.org/), focused on performance, container-first workflows, automatic updates, and reproducible system tuning.

## Hardware Baseline

**Disclaimer:** This image is heavily opinionated and optimized for a specific high-performance workstation baseline. Applying this image to low-spec hardware (e.g., laptops with 8GB/16GB RAM) may cause system instability, out-of-memory (OOM) kills, or network stutters.

The system tuning (sysctl, zram, and network buffers) assumes the following minimum operational context:

- **Memory:** 64 GB RAM (ZRAM is configured to scale up to 32GB, and TCP buffers are expanded for high-throughput P2P).
- **GPU:** Dedicated AMD and/or NVIDIA GPUs for hardware acceleration and containerized LLM compute offloading.
- **Environment:** Trusted home/workstation network (privacy extensions like MAC randomization are disabled in favor of static IPs and local network discovery).
- **Workload:** High-throughput networking, local AI/LLM inference, and heavy virtualization.

**If you are running on standard hardware:** We strongly recommend forking this repository and adjusting the limits in `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf` and `files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf` before building your own image.

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
