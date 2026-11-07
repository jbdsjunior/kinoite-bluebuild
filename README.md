<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-Validate](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/validate.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-Dual](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-dual.yml/badge.svg)

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
> This profile is calibrated for workstations with **64 GB RAM** (32 GB ZRAM `zstd` swap, Btrfs NoCOW rules, and Zen 3/RDNA2 tuning). See [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

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
sys-optimize                    # full 8-phase maintenance (root)
sudo kinoite-optimize --audit   # read-only audit of the 6 engineering pillars
sudo kinoite-optimize --help    # usage, modes and safety notes
```

> [!NOTE]
> `sys-optimize` phase 7 sanitizes the host kernel arguments (removing non-upstream
> tuning kargs) and may require a reboot. Use `--audit` for a read-only check.

Full operational guide (partitioning, TPM 2.0 PCR 7 auto-unlock, Rclone FUSE, ROCm CDI, and recovery): [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

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
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Operational post-install guide (TPM 2.0, Rclone FUSE, maintenance, recovery, default behaviors) |
| [`SECURITY.md`](SECURITY.md) | Cosign signature verification policy, workflow permissions and vulnerability reporting |
| [`cosign.pub`](cosign.pub) | Public Cosign verification key (the signing key lives in `SIGNING_SECRET`) |
| [`recipes/`](recipes/) | Declarative BlueBuild OCI recipes (`recipe-amd.yml`, `recipe-dual.yml`, `common-*.yml` stages) |
| [`files/system/`](files/system/) | Host configuration overlays (sysctl, tmpfiles, systemd, udev, polkit) |
| [`files/system/usr/bin/`](files/system/usr/bin/) | In-image utilities (`kinoite-optimize`, `kinoite-setup-tpm`) |
| [`files/nvidia/`](files/nvidia/) | Dual-flavor NVIDIA overlays (MOK certificate, headless compute isolation guards) |
| [`files/dnf/`](files/dnf/) | External repository definitions (Tailscale, Terra) |
| [`.github/workflows/`](.github/workflows/) | Static validation, build (manual/update-triggered), update check and registry cleanup |
| [`.github/scripts/`](.github/scripts/) | Shared CI helpers (base image digest resolution) |
| [`Makefile`](Makefile) | Local entry points: `make lint`, `make validate`, `make check`, `make hooks` |

## Validation and Development

Every push and pull request runs a static validation workflow (`validate.yml`) that
lints shell scripts (`shellcheck`), YAML (`yamllint`), workflows (`actionlint`) and
validates both recipes with the BlueBuild CLI. It never builds or publishes images.

Image builds are intentionally **manual** (`workflow_dispatch` of `build-amd.yml` /
`build-dual.yml`) or triggered by `check-updates.yml` when the upstream base image
digest changes.

```bash
make check    # shellcheck + yamllint + actionlint + bluebuild validate
make hooks    # enable the repository commit-msg hook (Conventional Commits)
```

Convention: user-facing documentation in pt-BR, code/CI/assets in English.

## License

Licensed under [Apache License 2.0](LICENSE).
