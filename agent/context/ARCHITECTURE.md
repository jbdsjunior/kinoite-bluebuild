# Architecture — kinoite-bluebuild

## Project Overview

Immutable Fedora Kinoite (KDE Plasma) desktop built with BlueBuild framework. Generates two OCI image variants (AMD, NVIDIA) with cryptographic signing, automatic updates via user-level systemd timers, and comprehensive system tuning.

## Module Dependency Graph

```
recipe-amd.yml ──┐
                 ├── common-base.yml ──┬── files (system/)
recipe-nvidia.yml┘                     ├── common-repos.yml
                                       ├── common-debloat.yml
                                       ├── common-drivers.yml
                                       ├── common-fonts.yml
                                       ├── common-packages.yml
                                       ├── common-tools.yml
                                       ├── common-kvm.yml (+ kvm_amd.*, iommu=pt kargs)
                                       ├── common-systemd.yml
                                       ├── common-kargs.yml
                                       ├── AMD CPU kargs (amd_iommu=on)
                                       └── common-flatpaks.yml
```

## Build Pipeline

1. **Trigger:** `check-updates.yml` (cron every 2h) detects base image digest change via skopeo
2. **Dispatch:** Auto-triggers `build-amd.yml` and/or `build-nvidia.yml` via `gh workflow run`
3. **Build:** `blue-build/github-action@v1` constructs OCI image from recipe
4. **Sign:** Cosign signs image with `secrets.SIGNING_SECRET`
5. **Publish:** Image pushed to GHCR (`ghcr.io/jbdsjunior/kinoite-{amd|nvidia}:latest`)
6. **Cleanup:** `cleanup.yml` (daily 00:00 UTC) removes old images (keeps ≥7) and workflow runs (keeps 3 days, ≥3 runs)

## Key Design Decisions

### Variant Isolation
- AMD and NVIDIA recipes are separate, each inheriting from `common-base.yml`
- NVIDIA uses `ghcr.io/ublue-os/kinoite-nvidia` as base (pre-configured NVIDIA drivers)
- Never merge workflows; maintain strict separation

### Modularity
- 10 sub-modules under `common-*.yml` for independent configuration
- Each module handles one domain: repos, packages, drivers, fonts, kvm, systemd, kargs, flatpaks, tools, debloat

### Debloat Strategy
- Remove: `firefox`, `plasma-discover-rpm-ostree`, `plasma-welcome-fedora`, `fedora-flathub-remote`, `fedora-third-party`, `fedora-workstation-repositories`
- Rationale: Replace with custom alternatives, reduce attack surface, avoid redundant update mechanisms

### Update Strategy
- **rpm-ostree:** `AutomaticUpdatePolicy=stage` (stages updates, applies on next reboot)
- **Topgrade timers:** 3 user-level timers with **separate lock files** per service (system, flatpak, boot) — allows concurrent updates of different subsystems
  - `topgrade-boot-update.timer`: 30min after boot, every 6h + 10m random (misc/containers)
  - `topgrade-system-update.timer`: 15min after boot, every 2h + 5m random (system only)
  - `topgrade-flatpak-update.timer`: 5min after boot, every 1h + 5m random (flatpak only)
  - Lock files: `%t/topgrade-boot.lock`, `%t/topgrade-system.lock`, `%t/topgrade-flatpak.lock`
- All timers use low priority (Nice=19, IOSchedulingClass=idle)

### Flatpak Strategy
- System scope only (user scope disabled by default)
- Only ffmpeg-full runtime + adw-gtk3 themes installed
- All other flatpaks commented out (user enables as needed)

### Package Strategy
- Most packages commented out in `common-packages.yml` (user enables as needed)
- Core: langpacks-pt_BR, plasma-firewall, kf6-kimageformats, kio-admin, ksshaskpass, qt6-qtimageformats, flatpak-spawn, adw-gtk3-theme, lm_sensors, rclone
- Native browser packages (Brave, Chrome, Edge, VS Code) commented — repos registered but packages not installed by default

## File Structure

```
files/
├── rpm-ostree/          # RPM repo files (.repo)
├── scripts/             # Setup scripts (setup-kvm.sh)
└── system/              # Overlayed to / during build
    ├── etc/             # Shell profiles, flatpak overrides
    └── usr/lib/         # sysctl, systemd confs, dracut, ostree, rpm-ostree
```

## System Tuning Categories

| Category | Files | Purpose |
|---|---|---|
| Memory/VM | sysctl.d, zram-generator, tmpfiles.d | ZRAM 50%/32GB cap, dirty ratios, swappiness, BTRFS NoCOW |
| Network | sysctl.d, resolved.conf.d | conntrack 2M, fq qdisc, 32MB buffers, DoT + DNSSEC |
| Security | sysctl.d, kargs | ~70+ sysctls, ptrace_scope, bpf, userns, mitigations |
| Storage | dracut, ostree, tmpfiles.d | zstd initramfs, composefs, NoCOW VM/container paths |
| Journal | journald.conf.d | 500M max, 1 month retention |
| Font | fontconfig | antialias, hintslight, rgb, lcdfilter |
| Shell | profile.d | Starship prompt, fastfetch, aliases (update, rollback, etc.) |

## Version Pinning Policy

- GitHub Actions: Use major version tags (`@v6`, `@v5`, `@v4`) — Dependabot manages updates
- BlueBuild action: `@v1` (includes v1.11.1 latest)
- Base images: `:latest` tag (digest checked every 2h by `check-updates.yml`)
- DNF packages: Latest from repos at build time (no version pinning)
- Flatpaks: Pinned to runtime version (`//24.08`)
