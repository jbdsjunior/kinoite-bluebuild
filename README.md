<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-Build](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build.yml/badge.svg)
![Status-Validate](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/validate.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable OCI image based on **Fedora Kinoite (latest stable / KDE Plasma 6 / Wayland)**, built with BlueBuild for AMD Zen 3 + RDNA2 workstations, virtualization (KVM), containerized ROCm/HIP AI inference, and DevSecOps workloads.

---

## Overview

| Variant        | Base Image                      | Target                                   | Hardware Baseline                                                    |
| :------------- | :------------------------------ | :--------------------------------------- | :------------------------------------------------------------------- |
| `kinoite-amd`  | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-amd:latest`  | AMD Ryzen 9 5950X + Radeon RX 6600 XT + 64 GB DDR4                   |
| `kinoite-dual` | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-dual:latest` | AMD display (RDNA2) + NVIDIA compute (CUDA/akmods) + 64 GB DDR4      |

> [!WARNING]
> This profile is calibrated for workstations with **32 GB+ RAM**: ZRAM is sized as `min(ram/2, 32 GB)` with `zstd`, plus Btrfs NoCOW rules and Zen 3/RDNA2 tuning. See [`AGENTS.md`](AGENTS.md) and [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

---

## Quick Start

The deployment uses a two-stage transition: the initial switch bootstraps the system and provisions the Cosign public keys embedded in the custom image; the post-boot switch locks signature verification (`--enforce-container-sigpolicy`) for all subsequent updates.

### 1) Initial Switch (From Stock Fedora Kinoite)

```bash
# AMD-only variant (default)
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest

# Dual-GPU variant (AMD display + NVIDIA compute)
sudo bootc switch ghcr.io/jbdsjunior/kinoite-dual:latest

systemctl reboot
```

### 2) Enforce Cryptographic Signature Verification (Post-Boot)

After booting into the custom image, lock updates to verified Cosign signatures:

```bash
# AMD-only variant
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest

# Dual-GPU variant
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-dual:latest
```

### 3) Post-installation & Maintenance

Run the unified maintenance utility after booting:

```bash
sudo kinoite-optimize --audit   # read-only audit of the 7 engineering pillars
sys-optimize                    # alias: full 7-phase maintenance (root)
```

Full operational guide (partitioning, TPM 2.0 PCR 7 auto-unlock, Rclone FUSE, ROCm CDI, and recovery): [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).
Simplification roadmap and pending decisions: [`docs/SIMPLIFICATION.md`](docs/SIMPLIFICATION.md).

---

## Rollback and Recovery

```bash
# Atomic rollback to previous deployment
sudo bootc rollback

# Revert to upstream stock Fedora Kinoite
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## Repository Structure

| Path | Purpose |
| :--- | :--- |
| [`AGENTS.md`](AGENTS.md) | Authoritative system invariants, hardware baseline, and subsystem/directory traceability (§6) |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Operational post-install guide (TPM 2.0, Rclone FUSE, maintenance, recovery) |
| [`docs/SIMPLIFICATION.md`](docs/SIMPLIFICATION.md) | Audit log, simplification decisions, pending package/config evaluations |
| [`SECURITY.md`](SECURITY.md) | Cosign signature verification policy and vulnerability reporting |
| [`recipes/`](recipes/) | Declarative BlueBuild OCI recipes (`recipe-amd.yml`, `recipe-dual.yml`, `common-*.yml`) |
| [`files/system/`](files/system/) | Host configuration overlays (sysctl, tmpfiles, systemd, udev, polkit) |
| [`files/nvidia/`](files/nvidia/) | Dual-flavor NVIDIA overlays (MOK certificate, headless compute isolation guards) |
| [`.github/workflows/`](.github/workflows/) | Autonomous CI/CD build, update check, and container registry cleanup pipelines |

> [!NOTE]
> For the comprehensive subsystem-by-subsystem file mapping and implementation details, refer to [`AGENTS.md §6`](AGENTS.md#6-rastreabilidade-de-arquivos).

## License

Licensed under [Apache License 2.0](LICENSE).
