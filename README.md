<div align="center">

![Status-Validate](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/validate.yml/badge.svg)
![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-Build](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable OCI image based on **Fedora Kinoite (latest stable / Fedora 45+ / KDE Plasma 6 / Wayland)**, built with BlueBuild for AMD Zen 3 + RDNA2 workstations, lean KVM virtualization, containerized CUDA/AI compute, and DevSecOps workflows.

---

## Overview

| Variant        | Base Image                      | Target                                   | Hardware Baseline                                                    |
| :------------- | :------------------------------ | :--------------------------------------- | :------------------------------------------------------------------- |
| `kinoite-amd`  | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-amd:latest`  | AMD Ryzen 9 5950X + Radeon RX 6600 XT + 64 GB DDR4                   |
| `kinoite-cuda` | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-cuda:latest` | AMD display (RDNA2) + NVIDIA compute (CUDA/akmods) + 64 GB DDR4      |

> [!WARNING]
> This profile is calibrated for workstations with **64 GB RAM** (32 GB ZRAM `zstd` swap, Btrfs NoCOW rules, NVMe byte-capped dirty writeback, and Zen 3/RDNA2 tuning). See [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

---

## Quick Start

The deployment uses a two-stage transition: the initial switch bootstraps the system and provisions the Cosign public keys embedded in the custom image; the post-boot switch locks signature verification (`--enforce-container-sigpolicy`) for all subsequent updates.

### 1) Initial Switch (From Stock Fedora Kinoite)

```bash
# AMD-only variant (default)
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest

# CUDA variant (AMD display + headless NVIDIA compute)
sudo bootc switch ghcr.io/jbdsjunior/kinoite-cuda:latest

systemctl reboot
```

### 2) Enforce Cryptographic Signature Verification (Post-Boot)

After booting into the custom image, lock updates to verified Cosign signatures:

```bash
# AMD-only variant
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest

# CUDA variant
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-cuda:latest
```

### 3) Post-installation & Maintenance

Run the unified maintenance utility after booting:

```bash
sudo kinoite-optimize           # safe 5-phase maintenance (alias: sys-optimize)
sudo kinoite-optimize --audit   # read-only audit of the 5 engineering pillars
kinoite-optimize --help         # usage and safety notes
```

Full operational guide (partitioning, TPM 2.0 PCR 7+14 auto-unlock, Gigabyte X570 BIOS CPPC, Rclone FUSE, legacy residue cleanup, and recovery): [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

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
| [`AGENTS.md`](AGENTS.md) | Lean agent invariants, forbidden rules, pre-commit checks, and surgical index |
| [`PROJECTS.md`](PROJECTS.md) | Complete linear catalog of project architecture, hardware, and per-file directives |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Operational post-install guide (TPM 2.0, BIOS CPPC, Rclone FUSE, maintenance, recovery, default behaviors) |
| [`SECURITY.md`](SECURITY.md) | Cosign signature verification policy, workflow permissions, and vulnerability reporting |
| [`cosign.pub`](cosign.pub) | Public Cosign verification key (the signing key lives in `SIGNING_SECRET`) |
| [`recipes/`](recipes/) | Declarative BlueBuild OCI recipes (`recipe-amd.yml`, `recipe-cuda.yml`, `modules/{base,desktop,nvidia}-*.yml`) |
| [`files/base/`](files/base/) | Core OS overlays (sysctl, zram, timers, udev, polkit, security) and utilities (`kinoite-optimize`, `kinoite-setup-tpm`) |
| [`files/desktop/`](files/desktop/) | KDE Plasma `/etc/xdg`, KWin, Konsole, fonts, Starship/Fastfetch/Topgrade, and minimal Flatpak overrides |
| [`files/cloud/`](files/cloud/) | Rclone user mount service and Google Drive / OneDrive templates |
| [`files/nvidia/`](files/nvidia/) | CUDA-flavor NVIDIA overlays (MOK certificate, headless compute isolation guards) |
| [`files/dnf/`](files/dnf/) | External repository definitions (Tailscale, Terra) |
| [`.github/workflows/`](.github/workflows/) | Validation gate (`validate.yml`), image build (`build.yml`), scheduled freshness check (`check-updates.yml`), and cleanup (`cleanup.yml`) |

## Builds & Validation

Every `push` and `pull_request` on `main` runs `validate.yml` (shell syntax, YAML/TOML/XML/JSON/JSONC parsing, `bluebuild validate`, and `PROJECTS.md` 100% coverage check). Image builds run manually (`workflow_dispatch` of `build.yml`, pick `all`, `amd` or `cuda`) or are dispatched every 2 hours by `check-updates.yml` when the upstream base digest or repository inputs are newer than the published GHCR image. Recurring host updates (`bootc` staged without auto-reboot and Flatpak system/user) run every 4 hours on AC power.

Convention: user-facing documentation in pt-BR, code/CI/assets in English.

## License

Licensed under [Apache License 2.0](LICENSE).
