# AGENTS.md — Kinoite BlueBuild

## Purpose
- Define agent behavior for this repository.
- Focus: immutable Fedora Kinoite images with BlueBuild, DevSecOps quality, and continuous evolution.

## Rule Hierarchy
- Direct system/developer/user instructions override AGENTS rules.
- Canonical technical sources override AGENTS narrative: `recipes/` and `files/system/` > `docs/*.md` > `AGENTS.md`.
- Keep AGENTS concise, behavioral, and non-redundant.

## Canonical References (do not duplicate)
- `README.md` — overview, usage, image switching.
- `docs/POST_INSTALL.md` — post-install operations.
- `docs/CI_CD.md` — pipelines and automation.
- `docs/HARDWARE_BASELINE.md` — hardware baseline.
- `recipes/` and `files/system/` — effective configuration source.

## Mandatory AGENTS Self-Update
Update this file when any of the following changes:
1. New operational/security rules are introduced.
2. Existing rules become obsolete, ambiguous, or contradictory.
3. Better implementation/review guidance patterns are identified.
4. CI/CD, maintenance, or architecture standards change.

Requirement: apply focused refactors so AGENTS remains current, minimal, and technically precise.

## Operating Principles
- Act with Senior DevSecOps + Linux Systems Architect mindset.
- Prioritize Shift-Left Security, declarative IaC, rootless-first containers, and atomic rollback paths.
- Operate fail-fast/recover-faster.
- Proactively detect and fix safe-to-fix drift, inconsistencies, broken references, and risky defaults.
- Prefer official documentation and precise terminology.

## Hard Constraints
- Build workflows `build-amd.yml` and `build-nvidia.yml` must enforce mandatory pre-build security gate (Trivy + SARIF); image build runs only after successful gate.
- Maintain strict AMD/NVIDIA decoupling across recipes and CI jobs.
- Do not enable Rechunk.
- Preserve immutable workflow: structural host behavior must come from versioned repository changes.
- Enforce maintenance timers:
  - Flatpak: every 15 minutes.
  - rpm-ostree: every 45 minutes.
  - Podman prune: daily, boot-triggered, low-impact/idle-friendly semantics.
- Browser hardening must preserve sign-in/sync compatibility for Chrome, Edge, and Brave.
- Do not enforce sync-disabling policies (`BrowserSignin=0` or `SyncDisabled=true`) unless a documented security exception is approved in canonical docs.

## Always-On Quality & Security Gate (every change)
1. Validate syntax/schema for edited files.
2. Validate cross-file consistency (recipes, deployed files, docs, workflows).
3. Validate references (paths, unit names, commands, aliases).
4. Validate AMD/NVIDIA separation boundaries.
5. Validate security impact (supply chain, privileges, policies, networking, container runtime).
6. Replace obsolete patterns with safer/current equivalents when low risk.
7. Fix detected inconsistencies in the same change set whenever feasible.
8. Report verification commands/results in summaries.

## Priority Audit Focus
### High priority
- Supply chain: Cosign flow and third-party repo trust model (GPG/signature hygiene).
- Hardening: rootfs injections, sensitive permissions, policy lock-down/telemetry controls.
- Stability: Wayland/graphics boot safety and AMD/NVIDIA isolation correctness.
- CI/CD OCI: build/deploy robustness and Trivy vulnerability scan integration.

### Medium priority
- BlueBuild modularity and hardware-aware recipe composition.
- IaC consistency for systemd units, sysctl tuning, storage tuning, and user automation.

## Continuous Structure Hygiene (auto-learning)
- Verify project organization proactively on every review/change, even without explicit request.
- Keep package placement aligned with module intent:
  - drivers → `recipes/common-drivers.yml`
  - utilities → `recipes/common-tools.yml`
  - virtualization/KVM assets → `recipes/common-kvm.yml`
- When safe, correct inconsistent names/placement in the same change set.
- Record structural improvements in summaries and keep AGENTS guidance updated when better patterns are learned.
