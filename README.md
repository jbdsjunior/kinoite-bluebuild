<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable OCI images based on Fedora Kinoite (KDE Plasma), built with BlueBuild for desktop, virtualization, and local development workloads with a strong focus on reproducibility, security, and fast rollback.

---

## Overview

This repository publishes **one variant**:

| Variant       | Base Image                      | Target                                  | Use Case                      |
| :------------ | :------------------------------ | :-------------------------------------- | :---------------------------- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-amd:latest` | AMD systems (single variant). |

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

- image build (`build-amd.yml`) is manual (`workflow_dispatch`);
- `check-updates.yml` runs on schedule and can trigger builds when a new upstream digest is detected;
- each build workflow executes a Trivy security job before building, and only builds after security succeeds;
- `cleanup.yml` runs continuously for operational hygiene.

---

## Quick Start

### 1) Switch to the custom image

AMD

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
```


Reboot after completion.

### 2) Enforce signature policy during image switch

AMD

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest
```


### 4) Post-installation

Follow: [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

---

## Rollback and Disaster Recovery
1. Reboot and select the previous deployment (if needed).
2. Run atomic rollback:

```bash
sudo bootc rollback
```
### Revert to stock Fedora Kinoite

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## Repository Structure

| Path                        | Purpose                                                |
| :-------------------------- | :----------------------------------------------------- |
| `recipes/recipe-amd.yml`    | Main AMD recipe variant                                |
| `recipes/common-*.yml`      | Shared modules (packages, drivers, services, and more) |
| `files/system/`             | Immutable host overlays (policies, units, defaults)   |
| `files/scripts/`            | Executable provisioning helpers                        |
| `files/rpm-ostree/`         | Optional third-party RPM repo definitions              |
| `.github/workflows/`        | CI/CD pipelines and security gates                     |
| `docs/PROJECT_STRUCTURE.md` | Canonical taxonomy and placement rules                 |
| `cosign.pub`                | Public key for signature verification                  |

---

## Documentation

| Document                                                 | Purpose                                                 |
| :------------------------------------------------------- | :------------------------------------------------------ |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md)           | Post-install validation, operations, and maintenance    |
| [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) | Hardware baseline and operational limits                |
| [`docs/CI_CD.md`](docs/CI_CD.md)                         | GitHub Actions pipelines, triggers, and security checks |
| [`docs/PROJECT_STRUCTURE.md`](docs/PROJECT_STRUCTURE.md) | Repository taxonomy, grouping, and placement standards |

## License

This project is licensed under [`LICENSE`](LICENSE).
