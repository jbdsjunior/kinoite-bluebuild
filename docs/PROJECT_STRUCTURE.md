# Project Structure and Placement Standards

This document is the canonical taxonomy for repository organization. Keep it aligned with `recipes/`, `files/system/`, and workflow behavior.

## Repository layout

| Path | Ownership | Placement rule |
| :-- | :-- | :-- |
| `recipes/recipe-amd.yml` | Image entrypoint | Defines the single AMD image variant and imports shared module lists. |
| `recipes/common-base.yml` | Composition root | Orders shared modules and filesystem overlays. |
| `recipes/common-drivers.yml` | Hardware/media stack | AMD graphics, ROCm/HIP, multimedia, and hardware diagnostics packages. |
| `recipes/common-kvm.yml` | Virtualization | KVM/libvirt packages, setup helper installation, and AMD virtualization kernel arguments. |
| `recipes/common-tools.yml` | User and DevOps utilities | CLI tools, rootless container tooling, remote operations, and diagnostics. |
| `recipes/common-systemd.yml` | Declarative service enablement | System and user timers/services that must be enabled in the immutable image. |
| `files/system/` | Immutable host overlay | Files deployed into `/` by BlueBuild, including policies, systemd units, sysctl, tmpfiles, and shell defaults. |
| `files/scripts/` | Executable host helpers | Versioned helper scripts installed into the image by recipe modules. |
| `files/rpm-ostree/` | Optional RPM repository definitions | Third-party repo files for future opt-in rpm-ostree use; disabled unless intentionally wired into recipes. |
| `.github/workflows/` | CI/CD automation | Build, scan, update-check, ISO, and cleanup workflows. |
| `docs/` | Operator documentation | Usage, post-install operations, CI/CD, hardware baseline, structure, and configuration rationale. |

## Core rules

1. Keep the repository AMD-only unless the architecture is explicitly revised in canonical docs and workflows.
2. Do not enable Rechunk; `build_chunked_oci` must remain `false` for image builds.
3. Put structural host behavior in `files/system/`, not in ad-hoc post-install commands.
4. Put executable host helpers in `files/scripts/` and install them from a recipe.
5. Put packages in the module that owns their purpose:
   - drivers, multimedia, and AMD userspace: `recipes/common-drivers.yml`;
   - virtualization and KVM assets: `recipes/common-kvm.yml`;
   - CLI utilities and rootless container tooling: `recipes/common-tools.yml`;
   - service/timer enablement: `recipes/common-systemd.yml`.
6. Keep documentation references synchronized when renaming files, units, workflows, aliases, or helper scripts.
7. Preserve browser sign-in/sync compatibility; hardening policies must not set `BrowserSignin=0` or `SyncDisabled=true` without an approved documented exception.

## Maintenance timer policy

| Area | Units | Required cadence |
| :-- | :-- | :-- |
| Flatpak updates | `flatpak-system-update.timer`, `flatpak-user-update.timer` | Boot delay of 5 minutes, then every 15 minutes. |
| rpm-ostree staging | `rpm-ostreed-automatic.timer` | Boot delay of 10 minutes, then every 45 minutes. |
| Podman cleanup | `podman-system-prune.timer`, `podman-user-prune.timer` | Boot-triggered daily cleanup with low-impact scheduling. |

## Documentation update expectations

- Workflow changes must update `docs/CI_CD.md`.
- Hardware or tuning changes must update `docs/HARDWARE_BASELINE.md` and `docs/CONFIG_CATALOG.md` when behavior changes.
- File placement or module ownership changes must update this document and, when the agent operating rules change, `AGENTS.md`.
