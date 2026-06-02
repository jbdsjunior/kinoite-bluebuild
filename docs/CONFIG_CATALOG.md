# Configuration Catalog

This catalog documents the operational impact of repository-managed configuration files. Effective configuration remains canonical in `recipes/` and `files/system/`.

## Image composition

| File | Purpose | Notes |
| :-- | :-- | :-- |
| `recipes/recipe-amd.yml` | Single AMD image entrypoint. | Uses Fedora Kinoite as the base image and imports `common-base.yml`. |
| `recipes/common-base.yml` | Shared module composition root. | Applies `files/system/` first, then repositories, package modules, and systemd enablement. |
| `recipes/common-repos.yml` | Repository source policy. | Enables RPM Fusion through BlueBuild `bling`; optional rpm-ostree repo files remain staged under `files/rpm-ostree/`. |
| `recipes/common-systemd.yml` | Declarative timer/service enablement. | Enables Flatpak, rpm-ostree, Podman, and rootless Podman timers. |

## System services and timers

| File | Impact |
| :-- | :-- |
| `files/system/usr/lib/systemd/system/flatpak-system-update.timer` | Runs system Flatpak updates 5 minutes after boot and every 15 minutes thereafter. |
| `files/system/usr/lib/systemd/user/flatpak-user-update.timer` | Runs user Flatpak updates 5 minutes after user manager start and every 15 minutes thereafter. |
| `files/system/usr/lib/systemd/system/rpm-ostreed-automatic.timer.d/override.conf` | Stages rpm-ostree updates 10 minutes after boot and every 45 minutes thereafter. |
| `files/system/usr/lib/systemd/system/podman-system-prune.timer` | Runs root-scope Podman cleanup daily after boot stabilization. |
| `files/system/usr/lib/systemd/user/podman-user-prune.timer` | Runs rootless Podman cleanup daily after user manager start. |
| `files/system/usr/lib/systemd/user/rclone@.service` | Provides optional user-scoped rclone FUSE mounts for cloud remotes. |

## Host defaults and hardening

| File | Impact |
| :-- | :-- |
| `files/system/etc/profile.d/kinoite-aliases.sh` | Provides global aliases for updates, rollback, kargs, service status, tmpfiles, and KVM setup. |
| `files/system/etc/profile.d/50-shell-env-overrides.sh` | Sets shell editor defaults, AMD ROCm/HIP environment hints, Starship prompt initialization, and one-time Fastfetch display. |
| `files/system/etc/opt/chrome/policies/managed/chrome-policies.json` | Applies Chrome hardening while preserving sign-in and sync compatibility. |
| `files/system/etc/brave/policies/managed/brave-policies.json` | Applies Brave hardening while preserving sign-in and sync compatibility. |
| `files/system/etc/opt/edge/policies/managed/edge-policies.json` | Applies Microsoft Edge hardening while preserving sign-in and sync compatibility. |
| `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf` | Applies kernel tuning shipped with the immutable image. |
| `files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf` | Creates system I/O-heavy directories with BTRFS NoCOW attributes where applicable. |
| `files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf` | Creates user I/O-heavy directories with BTRFS NoCOW attributes where applicable. |

## CI/CD controls

| Workflow | Control |
| :-- | :-- |
| `.github/workflows/build-amd.yml` | Mandatory Trivy filesystem security gate, SARIF upload, signed BlueBuild image publishing, and Rechunk disabled. |
| `.github/workflows/build-amd-iso.yml` | Mandatory Trivy filesystem security gate before ISO generation and short-retention artifact upload. |
| `.github/workflows/check-updates.yml` | Scheduled upstream digest check for the AMD base image and automatic build workflow dispatch when a new digest is detected. |
| `.github/workflows/cleanup.yml` | Removes old GHCR image versions and old workflow runs for operational hygiene. |
