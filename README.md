<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)
![Status-Security](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/security-scan.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable OCI images based on Fedora Kinoite (KDE Plasma), built with BlueBuild for desktop, virtualization, and local development workloads with a strong focus on reproducibility, security, and fast rollback.

---

## Overview

This repository publishes **two variants**:

| Variant | Base Image | Target | Use Case |
| :-- | :-- | :-- | :-- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-amd:latest` | AMD systems without a dedicated NVIDIA GPU |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | `ghcr.io/jbdsjunior/kinoite-nvidia:latest` | Systems with NVIDIA GPU support (including AMD+NVIDIA hybrid setups) |

### Project Principles

- **Immutable-first:** apply customizations through `recipes/*.yml` + `files/system/`, not direct `dnf install` on the host.
- **OCI-native:** switch/update images with `bootc switch` and rollback with `bootc rollback`.
- **Shift-left security:** run Trivy in CI, upload SARIF reports, and sign images with Cosign in build pipelines.
- **Fail fast, recover faster:** use atomic rollback to the previous deployment when regressions occur.

> ⚠️ **Warning:** this profile is optimized for workstations with **64 GB RAM**. See [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md).

---

## CI/CD

Detailed automation documentation is available in [`docs/CI_CD.md`](docs/CI_CD.md).

Quick summary:
- image builds (`build-amd.yml`, `build-nvidia.yml`) are manual (`workflow_dispatch`);
- `check-updates.yml` runs on schedule and can trigger builds when a new upstream digest is detected;
- security scanning (`security-scan.yml`) and cleanup (`cleanup.yml`) run continuously.

---

## Quick Start

## 1) Switch to the custom image

```bash
# AMD
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest

# NVIDIA
sudo bootc switch ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot after completion.

## 2) Verify Cosign signature (recommended)

Project public key: [`cosign.pub`](cosign.pub).

```bash
# Example (AMD)
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-amd:latest

# Example (NVIDIA)
cosign verify --key cosign.pub ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

## 3) (Optional) Enforce signature policy during image switch

```bash
# AMD
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest

# NVIDIA
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

## 4) Post-installation

Follow: [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

---

## Rollback and Disaster Recovery

### Common scenarios

- Kernel panic after update
- Wayland session failure
- Driver regression (for example, NVIDIA stack)

### Recommended procedure (Fail Fast, Recover Faster)

1. Reboot and select the previous deployment (if needed).
2. Run atomic rollback:

```bash
sudo bootc rollback
```

3. Reboot and validate essential services:

```bash
systemctl --user status topgrade-update.timer
sudo systemctl status firewalld
```

### Revert to stock Fedora Kinoite

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## Repository Structure

| Path | Purpose |
| :-- | :-- |
| `recipes/recipe-amd.yml` | Main AMD variant recipe |
| `recipes/recipe-nvidia.yml` | Main NVIDIA variant recipe |
| `recipes/common-*.yml` | Shared modules (packages, drivers, services, and more) |
| `files/system/` | Files applied to the image filesystem |
| `.github/workflows/` | CI/CD pipelines |
| `cosign.pub` | Public key for signature verification |

---

## Documentation

| Document | Purpose |
| :-- | :-- |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Post-install validation, operations, and maintenance |
| [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) | Hardware baseline and operational limits |
| [`docs/CI_CD.md`](docs/CI_CD.md) | GitHub Actions pipelines, triggers, and security checks |
| [`docs/PROJECT_OVERVIEW.md`](docs/PROJECT_OVERVIEW.md) | Declarative architecture and technical project view |
| [`docs/EVOLUTION_LOG.md`](docs/EVOLUTION_LOG.md) | Short history of `/evolve` cycles and improvements |

## License

This project is licensed under [`LICENSE`](LICENSE).
