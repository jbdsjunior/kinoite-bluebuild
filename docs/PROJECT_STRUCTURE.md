# Project Structure and File Taxonomy (2026)

This document defines the canonical repository organization model for this project.
It complements `AGENTS.md` and keeps structure decisions explicit, reviewable, and consistent.

## Top-level taxonomy

| Path | Category | Responsibility |
|---|---|---|
| `.github/workflows/` | CI/CD | Build, scan, release, cleanup, automation gates |
| `recipes/` | Image composition IaC | BlueBuild modules and variant definitions |
| `files/system/` | Immutable host overlays | Versioned system files injected into image rootfs |
| `files/scripts/` | Provisioning/runtime scripts | Host tools installed by recipes |
| `files/rpm-ostree/` | Optional third-party repos | Repository definitions consumed only when enabled |
| `docs/` | Human operational docs | Runbooks, architecture and policy guidance |
| `cosign.pub` | Supply-chain trust anchor | Cosign public key for image signature verification |

## `recipes/` categorization

- `recipe-amd.yml`: single AMD variant entrypoint.
- `common-base.yml`: orchestration/order layer.
- `common-repos.yml`: repository modules (including optional third-party repo hooks).
- `common-drivers.yml`: hardware/driver stack.
- `common-kvm.yml`: virtualization stack (packages + kargs + setup script deployment).
- `common-systemd.yml`: service/timer policy.
- `common-core.yml`, `common-tools.yml`, `common-fonts.yml`, `common-brew.yml`, `common-flatpaks.yml`: user-space capability layers.
- `common-debloat.yml`: removal/exclusion policy.

## `files/system/` categorization

- `etc/`: system policy and runtime config
  - browser policies
  - shell environment defaults
  - containers defaults
- `usr/lib/systemd/`: system and user units/timers + overrides
- `usr/lib/sysctl.d/`: kernel runtime tuning
- `usr/lib/tmpfiles.d/` and `usr/share/user-tmpfiles.d/`: temp/runtime file policy
- `usr/lib/rpm-ostreed.conf.d/`: rpm-ostree daemon policy
- `usr/share/`: userland config assets (fontconfig, starship)

## Placement rules

1. **Drivers/hardware** additions go to `recipes/common-drivers.yml`.
2. **Virtualization/KVM** assets go to `recipes/common-kvm.yml` and `files/scripts/setup-kvm.sh` when executable support is needed.
3. **General CLI/system tools** go to `recipes/common-tools.yml`.
4. **System behavior** must be encoded under `files/system/` (not manual post-install mutations).
5. **New docs** must be placed in `docs/` and linked from `README.md` if user-facing.

## Review checklist for structure changes

- Ensure AMD-only scope remains intact.
- Ensure no duplicate responsibility across recipe modules.
- Ensure new files are referenced by a recipe/workflow when required.
- Ensure docs and paths remain in sync.


## Naming and consistency conventions

1. Prefer `common-<domain>.yml` for reusable recipe modules and keep one responsibility per file.
2. Use numeric prefixes in tunables/policies (e.g., `60-...`) to make precedence explicit and deterministic.
3. Use `kebab-case` for file names and keep suffixes semantically meaningful (`-policy`, `-override`, `-update`, `-prune`).
4. Place executable helpers only in `files/scripts/`; avoid executable logic in docs or ad-hoc locations.
5. Avoid duplicate configuration ownership: each behavior should have one canonical file path.

## Documentation baseline per change

For every structural or configuration change:
- update the relevant doc in `docs/`;
- record system impact and rationale;
- validate path references and unit names;
- preserve AMD-only scope and immutable-host principles.
