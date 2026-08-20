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
- **Shift-left security:** run Trivy in CI to scan the final OCI image, upload SARIF reports, and sign images with Cosign in build pipelines.
- **Fail fast, recover faster:** use atomic rollback to the previous deployment when regressions occur.

> ⚠️ **Warning:** this profile is optimized for workstations with **64 GB RAM**. See [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md).

---

## CI/CD

Automation workflows (`.github/workflows/`):

- `build-amd.yml`: manual image build via `workflow_dispatch`;
- `check-updates.yml`: scheduled check that can trigger builds when a new upstream digest is detected;
- `cleanup.yml`: continuous operational hygiene.

Each build executes a Trivy security scan on the container image. The pipeline ensures security gates are passed before finalizing the deployment.

---

## Quick Start

### 1) Switch to the custom image

AMD

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
