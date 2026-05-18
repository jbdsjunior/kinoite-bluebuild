# Configuration Catalog and Technical Rationale (2026)

This catalog documents **all current repository files** by purpose, system impact, and decision rationale.
It is the operational reference to keep architecture modular, auditable, and scalable.

## 1) Trust and top-level governance

### `cosign.pub`
- **Purpose:** Public key used to verify signed OCI artifacts.
- **System impact:** Prevents unsigned/tampered image adoption in supply-chain verification flows.
- **Decision rationale:** Sigstore/Cosign verification is a low-friction baseline control aligned with DevSecOps shift-left.

### `AGENTS.md`
- **Purpose:** Mandatory behavioral guardrails for automated maintainers.
- **System impact:** Reduces architectural drift and enforces AMD-only, immutable operations.
- **Decision rationale:** Codifies non-negotiable invariants close to code.

### `agent.md`
- **Purpose:** Lightweight policy mirror focused on organization/modularity as a foundational principle.
- **System impact:** Reinforces consistency during reviews and automated edits.
- **Decision rationale:** Keeps the requested “organization-first” principle explicit and easy to locate.

## 2) Documentation (`docs/`)

### `README.md`
- **Purpose:** User entrypoint and operational quickstart.
- **System impact:** Reduces adoption friction and mistakes.
- **Decision rationale:** Central, concise onboarding.

### `docs/POST_INSTALL.md`
- **Purpose:** Post-deployment runbook.
- **System impact:** Standardizes first-boot and operator steps.
- **Decision rationale:** Improves reproducibility.

### `docs/CI_CD.md`
- **Purpose:** CI/CD behavior and constraints.
- **System impact:** Sets expected build, scan, and delivery controls.
- **Decision rationale:** Makes pipeline policy auditable.

### `docs/HARDWARE_BASELINE.md`
- **Purpose:** Supported hardware assumptions.
- **System impact:** Prevents unsupported profile usage.
- **Decision rationale:** Protects stability and expectation management.

### `docs/PROJECT_STRUCTURE.md`
- **Purpose:** Canonical taxonomy and placement rules.
- **System impact:** Preserves modular boundaries/high cohesion.
- **Decision rationale:** Reduces entropy as the repository grows.

### `docs/CONFIG_CATALOG.md` (this file)
- **Purpose:** File-by-file rationale and impact map.
- **System impact:** Speeds maintenance and safer refactors.
- **Decision rationale:** Improves change review quality.

## 3) Image composition (`recipes/`)

- `recipes/recipe-amd.yml`: AMD single entrypoint profile.
- `recipes/common-base.yml`: module ordering/orchestration.
- `recipes/common-repos.yml`: repository setup modules.
- `recipes/common-drivers.yml`: driver/hardware package layer.
- `recipes/common-kvm.yml`: virtualization stack.
- `recipes/common-systemd.yml`: timers/services policy modules.
- `recipes/common-core.yml`: essential desktop/runtime baseline.
- `recipes/common-tools.yml`: operator/developer utilities.
- `recipes/common-fonts.yml`: font stack.
- `recipes/common-brew.yml`: Homebrew integration layer.
- `recipes/common-flatpaks.yml`: Flatpak application layer.
- `recipes/common-debloat.yml`: package exclusion/removal policy.

**Impact (all recipe files):** Define immutable image behavior; directly control installed surface area, attack surface, and operational capability.

**Rationale:** Split by responsibility (single-purpose modules) to maximize reviewability, selective updates, and rollback safety.

## 4) Host overlays (`files/system/`)

### Browser policies
- `files/system/etc/opt/chrome/policies/managed/chrome-policies.json`
- `files/system/etc/opt/edge/policies/managed/edge-policies.json`
- `files/system/etc/brave/policies/managed/brave-policies.json`

**Impact:** Applies hardened defaults while keeping sign-in/sync compatibility.

**Rationale:** Policy-as-code for repeatable security posture.

### Shell and environment
- `files/system/etc/profile.d/50-shell-env-overrides.sh`
- `files/system/etc/profile.d/kinoite-aliases.sh`
- `files/system/etc/containers/nodocker`

**Impact:** Standardizes shell UX and container command expectations.

**Rationale:** Operational consistency across endpoints.

### Kernel/runtime/system tuning
- `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf`
- `files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`
- `files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`
- `files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`
- `files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`
- `files/system/usr/lib/rpm-ostreed.conf.d/60-daemon-policy.conf`

**Impact:** Controls kernel behavior, memory pressure handling, DNS behavior, IO/runtime directories, and rpm-ostree daemon policy.

**Rationale:** Declarative performance and reliability tuning suitable for immutable hosts.

### Systemd units/timers
- System scope (`files/system/usr/lib/systemd/system/...`):
  - `flatpak-system-update.service`
  - `flatpak-system-update.timer`
  - `podman-prune-root.service`
  - `podman-prune-root.timer`
  - `podman-prune-root.service.d/override.conf`
  - `rpm-ostreed-automatic.service.d/override.conf`
  - `rpm-ostreed-automatic.timer.d/override.conf`
- User scope (`files/system/usr/lib/systemd/user/...`):
  - `flatpak-user-update.service`
  - `flatpak-user-update.timer`
  - `podman-prune-user.service`
  - `podman-prune-user.timer`
  - `podman-prune-user.service.d/override.conf`
  - `rclone@.service`

**Impact:** Enforces maintenance cadence and lifecycle behavior.

**Rationale:** Timers/units as code provide deterministic operations and quick rollback.

### Userland assets
- `files/system/usr/share/fontconfig/conf.d/60-font-rendering.conf`
- `files/system/usr/share/starship/starship.toml`

**Impact:** Consistent typography and prompt experience.

**Rationale:** Centralized UX defaults reduce per-user drift.

## 5) Optional repository definitions (`files/rpm-ostree/`)

- `brave-browser.repo`
- `google-chrome.repo`
- `microsoft-edge.repo`
- `terra.repo`
- `vscode.repo`

**Impact:** Controls third-party package trust/bootstrap sources.

**Rationale:** Keep optional sources isolated and explicitly versioned for trust review.

## 6) Executable helpers (`files/scripts/`)

### `files/scripts/setup-kvm.sh`
- **Purpose:** KVM/libvirt post-package host preparation.
- **System impact:** Enables/normalizes virtualization workflows.
- **Decision rationale:** Keeps imperative setup minimal and version-controlled.

## 7) Continuous improvement backlog (safe, low-risk)

1. Add CI lint jobs for YAML/JSON/Shell + dead-path checks.
2. Add a generated architecture index in CI to detect untracked files.
3. Introduce schema validation for policy/timer cadence assertions.
4. Add signed-release verification gate for third-party repo metadata review.
