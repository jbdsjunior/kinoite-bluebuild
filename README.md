<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-Build](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build.yml/badge.svg)

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
sudo kinoite-optimize           # full 8-phase maintenance (alias: sys-optimize)
sudo kinoite-optimize --audit   # read-only audit of the 6 engineering pillars
kinoite-optimize --help         # usage, modes and safety notes
```

> [!NOTE]
> `kinoite-optimize` phase 7 sanitizes the host kernel arguments (removing non-upstream
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
| [`AGENTS.md`](AGENTS.md) | Lean agent invariants, forbidden rules, pre-commit checks, and surgical index |
| [`PROJECTS.md`](PROJECTS.md) | Complete linear catalog of project architecture, hardware, and per-file directives |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md) | Operational post-install guide (TPM 2.0, Rclone FUSE, maintenance, recovery, default behaviors) |
| [`SECURITY.md`](SECURITY.md) | Cosign signature verification policy, workflow permissions and vulnerability reporting |
| [`cosign.pub`](cosign.pub) | Public Cosign verification key (the signing key lives in `SIGNING_SECRET`) |
| [`recipes/`](recipes/) | Declarative BlueBuild OCI recipes (`recipe-amd.yml`, `recipe-dual.yml`, `modules/common-*.yml`) |
| [`files/system/`](files/system/) | Host configuration overlays (sysctl, tmpfiles, systemd, udev, polkit) |
| [`files/system/usr/bin/`](files/system/usr/bin/) | In-image utilities (`kinoite-optimize`, `kinoite-setup-tpm`) |
| [`files/nvidia/`](files/nvidia/) | Dual-flavor NVIDIA overlays (MOK certificate, headless compute isolation guards) |
| [`files/dnf/`](files/dnf/) | External repository definitions (Tailscale, Terra) |
| [`.github/workflows/`](.github/workflows/) | Image build (manual/upstream-triggered), scheduled freshness check (every 2h) and registry cleanup |

## Builds

Image builds run manually (`workflow_dispatch` of `build.yml`, pick `all`, `amd`
or `dual`) or are dispatched by `check-updates.yml`. Every 2 hours the check
compares the base image digest declared in each recipe and the latest repository
input commit timestamp against the `org.opencontainers.image.base.digest` and
`org.opencontainers.image.created` labels published to GHCR, triggering a build
only when the published image is missing or stale.

Convention: user-facing documentation in pt-BR, code/CI/assets in English.

## License

Licensed under [Apache License 2.0](LICENSE).
