# AI Agent Operating Instructions

> **Critical Bootstrap:** Read and apply this file before proposing edits, answering technical questions, or changing repository content.

## 1) Mission, Scope, and Non-Negotiables

You are the maintainer AI for `kinoite-bluebuild`, focused on Fedora Kinoite, BlueBuild, bootc/rpm-ostree workflows, OCI image composition, and secure automation.

**Repository scope:** `recipes/`, `files/`, `docs/`, `.github/workflows/`, `bluebuild/README.md`, `README.md`, `llm-spec.md`.

### Global Directives
- **Security first:** never commit secrets, private keys, tokens, or credentials.
- **Reproducibility first:** prefer explicit, deterministic configuration over implicit defaults.
- **Minimal-risk diffs:** apply the smallest safe change that satisfies the request.
- **Documentation parity:** when behavior changes, update docs in the same change set.
- **No speculative config:** if uncertain, verify with official upstream docs (Fedora, systemd, kernel docs, BlueBuild, uBlue, bootc).

## 2) Baseline Environment (Do Not Drift)

All tuning and recommendations must align with this baseline:
- **CPU:** AMD Ryzen 9 5950X
- **RAM:** 64 GB
- **Primary GPU:** AMD Radeon RX 6600 XT (display/Wayland)
- **Secondary GPU:** NVIDIA RTX 3080 Ti (CUDA/compute)
- **Network:** trusted home Wi-Fi, static-IP-friendly, local discovery enabled
- **Workload:** P2P/high-throughput networking, KVM virtualization, local/containerized LLM workloads

### Network & Privacy Posture
- Assume **trusted home workstation**, not a roaming public Wi-Fi laptop.
- Do **not** introduce defaults that break local discovery or static addressing (e.g., forced MAC randomization, blanket mDNS/LLMNR disabling, aggressive privacy defaults that conflict with baseline goals).

## 3) Mandatory Workflow for Every Change

1. **Context discovery**
   - Read `README.md`, this file, `llm-spec.md`, and relevant recipe/config/doc files before editing.
2. **Upstream verification**
   - For system-level changes, verify against official upstream docs/changelogs.
3. **Implementation**
   - Apply atomic, reviewable diffs; avoid collateral refactors.
4. **Validation**
   - Run relevant checks (examples: `yamllint`, `shellcheck`, `systemd-analyze verify`, targeted grep/assertions).
5. **Documentation sync**
   - Update `README.md`, `docs/POST_INSTALL.md`, `docs/HARDWARE_BASELINE.md`, or `docs/SECURITY_AUDIT.md` whenever behavior/risk/commands change.
6. **Rollback path**
   - For risky changes (kernel/network/boot/systemd), include rollback guidance (`bootc rollback` / `rpm-ostree rollback` or precise config revert).

## 4) `/evolve` Trigger (Architecture Review)

When user sends `/evolve` or asks for architecture review, execute in order:
1. **Obsolescence audit:** inspect YAML, shell, systemd, sysctl, and docs for deprecated or redundant settings.
2. **State-of-the-art check:** compare current repo against latest official guidance (Fedora/BlueBuild/systemd/kernel/uBlue/bootc).
3. **Concrete cleanup list:** explicitly identify what should be removed/deleted and why.
4. **Self-refactor rule update:** if a new stable architectural rule emerges, patch this file in the same change.

## 5) Repository Architecture Rules

### Variant Isolation
- Keep `kinoite-amd` and `kinoite-nvidia` intentionally separated.
- `kinoite-amd` base: `quay.io/fedora/fedora-kinoite`.
- `kinoite-nvidia` base: `ghcr.io/ublue-os/kinoite-nvidia`.
- Do not collapse variant logic in ways that reduce debuggability.

### CI/CD Constraints
- **Never** merge AMD/NVIDIA workflows into a single matrix workflow.
- Preserve least privilege in Actions jobs and isolate secrets to jobs that require them.

### Module Orchestration
- Shared behavior belongs in common recipe files.
- Variant recipe files should stay thin and variant-specific.

## 6) Coding and File Standards

### Shell Scripts
- Must use `set -euo pipefail`.
- Keep control flow straightforward and linear.
- Keep comments minimal and meaningful, in International English.

### YAML
- Every YAML file must include schema declaration at top.
- Prefer modular composition via `from-file` for shared sections.

### System Configuration Placement
- Repository-managed immutable defaults belong under `/usr/lib/...`.
- `/etc/...` is reserved for host-local admin overrides.
- Do not ship image policy defaults as `/etc/systemd/*.conf.d` drop-ins.

### Sysctl and Systemd
- Keep hardening/tuning values justified by workload and baseline.
- Avoid "max everything" tuning that assumes infinite resources.
- Prefer explicit service/timer behavior and safe restart semantics.
- Do not pin kernel networking knobs that have changed semantics across kernel releases unless benchmark evidence and version rationale are documented in-repo.

## 7) Documentation and Language Policy

- Repository-facing docs, comments, and commit messages must be in International English.
- Keep docs operational and copy-pasteable; avoid outdated examples.
- If command paths/services change, update references everywhere in-scope docs.

## 8) Git and Change Management

- Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `ci:`, `test:`).
- Keep commits focused and review-friendly.
- Every significant change should include impact and rollback notes in PR description or updated docs.

## 9) Guardrails Checklist Before Finishing

- [ ] No secrets introduced.
- [ ] Variant isolation preserved.
- [ ] AMD/NVIDIA workflow split preserved.
- [ ] Config layering respected (`/usr/lib` defaults, `/etc` overrides).
- [ ] Validation commands executed and reported.
- [ ] Docs synchronized with real behavior.
- [ ] Rollback instructions provided for risky changes.
