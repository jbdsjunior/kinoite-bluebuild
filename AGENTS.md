# AGENTS.md - Kinoite BlueBuild

## Project Overview
Immutable Fedora Kinoite (KDE Plasma) desktop built with [BlueBuild](https://blue-build.org/). Two variants: AMD-only and NVIDIA hybrid.

## Instruction Architecture (to prevent drift)

This repository uses a modular instruction model:

- `/.agent/agent.md` → Canonical directive for agent operation (single active source in the repository).

### Maintenance rules
- Keep all persistent agent directives centralized in `/.agent/agent.md` to avoid drift.
- If modular files under `/.agents/` are reintroduced in the future, keep them synchronized with `/.agent/agent.md`.
- Keep instruction files concise, scan-friendly, and low-redundancy for LLM efficiency.

## Build System
- **Build tool**: BlueBuild (`blue-build/github-action@v1`)
- **Trigger builds**: Manual workflow dispatch via GitHub Actions (`.github/workflows/build-amd.yml`, `build-nvidia.yml`)
- **Recipe files**: `recipes/recipe-amd.yml`, `recipes/recipe-nvidia.yml`
- **Modules**: Shared configs in `recipes/common-*.yml` (packages, flatpaks, drivers, systemd, etc.)
- **Files deployed**: `files/system/` → `/` on image

## Build Commands
```bash
# Triggered via GitHub Actions workflow_dispatch
# Workflow timeout: 45 minutes
# No local build required - all builds run in CI
```

## Image Variants
| Variant | Base Image | Registry |
|---------|------------|----------|
| kinoite-amd | quay.io/fedora/fedora-kinoite | ghcr.io/jbdsjunior/kinoite-amd:latest |
| kinoite-nvidia | ghcr.io/ublue-os/kinoite-nvidia | ghcr.io/jbdsjunior/kinoite-nvidia:latest |

## Key Files
- `recipes/recipe-amd.yml` - AMD variant recipe
- `recipes/recipe-nvidia.yml` - NVIDIA variant recipe
- `recipes/common-*.yml` - Shared modules
- `files/system/` - System config files deployed to image
- `cosign.pub` - Public key for image verification

## Post-Install Aliases (defined in system)
| Alias | Command |
|-------|--------|
| `update` | topgrade |
| `rollback` | sudo bootc rollback |
| `kargs` | rpm-ostree kargs |
| `config-diff` | sudo ostree admin config-diff |
| `update-status` | systemctl --user status topgrade-update.timer |
| `tmpfiles-system` | systemd-tmpfiles --create (NoCOW BTRFS) |
| `kvm-setup` | sudo setup-kvm.sh |

## Hardware Baseline
Optimized for 64 GB RAM workstations. See `docs/HARDWARE_BASELINE.md`.
