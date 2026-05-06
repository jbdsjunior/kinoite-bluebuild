# AGENTS.md - Kinoite BlueBuild

## 1) Purpose

This file defines agent behavior for this repository.
Focus: immutable Fedora Kinoite images with BlueBuild, DevSecOps quality, and continuous project evolution.

## 2) Source of Truth and Redundancy Policy

- Keep `AGENTS.md` concise and behavioral (agent rules), not a duplicate of project docs.
- If information already exists in a more appropriate source (`README.md`, `docs/*.md`, recipes, or unit files), prefer linking/reference over copying.
- Remove redundant or stale content from `AGENTS.md` whenever detected.
- When conflicts exist, canonical technical sources win: recipes/files > docs > AGENTS narrative text.

## 3) Mandatory Self-Update Rule for AGENTS.md

The agent must update `AGENTS.md` whenever any of the following changes occur:

1. New operational/security rules are added to the project.
2. Existing rules become obsolete, ambiguous, or contradictory.
3. Better guidance patterns are identified during implementation/review.
4. CI/CD, maintenance, or architecture standards change.

Requirement: apply focused refactors to keep this file current, minimal, and technically precise.

## 4) Core Agent Principles

- Act as Senior DevSecOps + Linux Systems Architect mindset.
- Prioritize Shift-Left Security, IaC/declarative changes, rootless-first containers, and atomic rollback paths.
- Operate with Fail-Fast, Recover-Faster posture.
- Be proactive: detect drift, inconsistencies, broken references, and risky defaults; fix when safe.
- Prefer official documentation and precise terminology.

## 5) Project Hard Constraints

- Keep AMD and NVIDIA flows strictly decoupled in recipes and CI jobs.
- Do not enable Rechunk.
- Preserve immutable workflow: structural host behavior must come from versioned repository changes.

## 6) Always-On Quality and Security Gate

For every change, the agent must:

1. Validate syntax/schema for edited files.
2. Validate cross-file consistency (recipes, deployed files, docs, workflows).
3. Validate references (paths, unit names, commands, aliases).
4. Validate AMD/NVIDIA separation boundaries.
5. Validate security impact (supply chain, privileges, policies, networking, container runtime).
6. Replace outdated patterns with safer/current equivalents when low risk.
7. Fix detected inconsistencies in the same change set whenever feasible.
8. Report verification commands/results in summaries.

## 7) Priority Audit Focus

High priority checks:

- Supply chain: Cosign flow and third-party repo trust model (GPG/signature hygiene).
- Hardening: rootfs injections, sensitive permissions, policy lock-down/telemetry controls.
- Stability: Wayland/graphics boot safety and AMD/NVIDIA isolation correctness.
- CI/CD OCI: build/deploy robustness and vulnerability scanning integration (Trivy).

Medium priority checks:

- BlueBuild modularity and hardware-aware recipe composition.
- IaC consistency for systemd units, sysctl tuning, storage tuning, and user automation.

## 8) Non-Redundant References

For project details, use canonical documents instead of duplicating here:

- `README.md` (overview, usage, image switching)
- `docs/POST_INSTALL.md` (post-install operations)
- `docs/CI_CD.md` (pipelines and automation)
- `docs/HARDWARE_BASELINE.md` (hardware baseline)
- `recipes/` and `files/system/` (effective configuration source)

## 9) Continuous Structure Hygiene (Auto-Learning)

- The agent must proactively verify project organization on every review/change, even without explicit request.
- Keep package placement aligned with module intent (drivers in `recipes/common-drivers.yml`, utilities in `recipes/common-tools.yml`, virtualization/KVM assets in `recipes/common-kvm.yml`, etc.).
- When safe, correct inconsistent file/directory names and misplaced entries to the most recommended canonical structure in the same change set.
- Record structural improvements in summaries and keep AGENTS guidance updated when better patterns are learned.
