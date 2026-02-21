# LLM Specification - kinoite-bluebuild

Version: 2026-02-21
Scope: Entire repository (`recipes/`, `files/`, `scripts/`, `.github/workflows/`, `README.md`)

## Category: Mission

- Keep regression risk low.
- Keep image behavior reproducible.
- Keep rpm-ostree/bootc delivery secure by default.
- Drive continuous improvement through measurable quality gates.

## Category: Global Directives

- Always seek current best practices.
- Always apply documentation best-practice recommendations.
- Always verify conflicts, possible errors, and improvement opportunities before and after edits.
- Prefer explicit decisions over implicit assumptions, especially for variant behavior.
- Always research relevant upstream updates before proposing changes, prioritizing BlueBuild, bootc, Fedora, Linux kernel/systemd, rpm-ostree, and related tooling used in this repository.
- Treat update discovery as continuous work: compare current repo choices with recent official guidance and incorporate safe improvements when beneficial.

## Category: Maintainer Baseline

- CPU: AMD Ryzen 9 5959X.
- Primary GPU: AMD Radeon RX 6600 XT.
- Secondary GPU: NVIDIA RTX 3080 Ti.
- RAM: 64 GB.
- Storage: NVMe 1 TB.
- Workload: heavy browser video usage (Chrome and Brave), local/containers LLM usage.
- OS context: Fedora Linux and Fedora Linux Kinoite, continuously updated.

## Category: Project Snapshot

### Architecture

- Two published image variants: `kinoite-amd` (`recipes/recipe-amd.yml`) and `kinoite-nvidia` (`recipes/recipe-nvidia.yml`).
- `kinoite-amd` targets AMD-only hosts.
- `kinoite-nvidia` targets AMD + NVIDIA hybrid hosts, not NVIDIA-only assumptions.
- Shared configuration is centralized in `recipes/common.yml` plus modular includes (`common-*.yml`).
- Runtime behavior is mostly defined by versioned files under `files/system/...`.
- Build and publish happen via GitHub Actions (`.github/workflows/build-*.yml`).
- Upstream image digest monitoring and trigger logic exist in `.github/workflows/check-updates.yml`.
- Local validation exists in `scripts/validate-project.sh`.

### Strengths

- Modular recipe layout with reuse.
- Image signing module present in both recipes.
- Variant-specific kernel args are explicitly separated (`common-kargs.yml` + `common-kargs-amd.yml`).
- Timers and systemd services are versioned and reproducible.
- Local validation script includes cross-file consistency checks.
- CI validation workflow exists in `.github/workflows/validate.yml`.

### Gaps and Risks

- Workflows still use tagged actions/versions instead of full commit SHA pinning.
- Some quality gates remain optional locally when tools are missing (`systemd-analyze`, `yamllint`, `shellcheck`).
- Workflow duplication between AMD and AMD+NVIDIA paths can drift over time.

## Category: Core Principles

### Security

- Never commit secrets, private keys, tokens, or host-specific credentials.
- Preserve signed-image flow; reject changes that weaken verification.

### Reproducibility

- Prefer deterministic inputs and explicit behavior over implicit defaults.
- Keep configuration in repo-managed files/modules, not host-side drift.

### Variant Isolation

- Keep variant behavior explicit and easy to reason about.
- Treat `kinoite-amd` and `kinoite-nvidia` as distinct outputs with clear hardware intent.
- Keep shared modules truly shared.

### Blast Radius Control

- Prefer small, isolated changes over broad refactors.
- Touch the minimal set of files needed for each objective.

### Documentation Parity

- Reflect any behavior change in recipes/workflows/systemd/files in `README.md`.
- Keep wording aligned with real variant scope: AMD-only vs AMD + NVIDIA hybrid.

### Validation

- Require local and CI checks before release/publish.
- Add lint/validation coverage for every new file format introduced.

### Backward Safety

- Preserve rollback-friendly behavior (`rpm-ostree rollback`).
- Avoid disruptive migration steps without a clear fallback.

### Conflict and Quality Detection

- Include documentation-quality checks and conflict/error scans in every change.
- If implementation and docs/workflows diverge, fix or document the mismatch in the same change.
- If no bug is found, still propose at least one maintainability improvement.

## Category: LLM Change Workflow

- Discovery: read impacted recipe/module/workflow/files before editing.
- Upstream refresh: review relevant upstream docs/changelogs for BlueBuild, bootc, Fedora/Linux stack, and tools touched by the change.
- Pre-change scan: verify names, paths, references, and behavior parity.
- Implementation: apply the smallest safe diff.
- Validation: run `./scripts/validate-project.sh`.
- Documentation sync: update docs when behavior changes.
- Post-change scan: re-check cross-file consistency after edits.
- Delivery: summarize risks, checks, and improvement opportunities in PR/commit description.

## Category: Recipe Standards

- Keep `recipes/common.yml` as orchestrator.
- Move variant-specific settings to variant modules or recipe-specific includes.
- Keep generic kernel args in `common-kargs.yml`.
- Keep AMD-only kernel args in AMD-specific modules.
- Avoid introducing NVIDIA-only assumptions in the hybrid (`kinoite-nvidia`) variant description.

## Category: Workflow Standards

- Use least-privilege permissions in every job.
- Prefer stable and pinned action versions with reviewed upgrades.
- Keep build and validation workflows aligned with repository checks.
- Keep AMD and AMD+NVIDIA workflows semantically equivalent where possible.

## Category: Update Intelligence and Source Priority

- Use official documentation as primary source of truth for design and operational decisions.
- Prioritize review of BlueBuild docs, bootc docs, Fedora docs, Linux kernel/systemd documentation, rpm-ostree guidance, and component-specific upstream references relevant to changed files.
- Prefer changes backed by upstream release notes, changelogs, or deprecation notices whenever available.
- When a recommendation is newer but risky for this project context, document tradeoffs and keep a rollback-safe path.
- Align updates with the maintainer baseline workload (desktop performance, containers, LLM usage, virtualization, and AMD + NVIDIA hybrid operation).

## Category: System File Standards

- Keep systemd unit/timer descriptions clear and restart behavior safe.
- Document network/security compatibility tradeoffs.
- Keep scripts and unit helpers explicit and failure-aware.

## Category: Shell Script Standards

- Prefer linear shell scripts with straightforward control flow.
- Avoid unnecessary comments.
- When comments are necessary, use international English.
- Keep scripts easy to diff and debug from logs.

## Category: Documentation Standards

- Keep docs close to executable reality (commands, service names, paths, image names).
- Prefer concise, task-oriented sections (install, operate, troubleshoot, recover).
- Include impact and rollback notes for behavior changes.
- Use stable terminology for variants (`kinoite-amd`, `kinoite-nvidia`) across all files.
- Never describe `kinoite-nvidia` as if it were a pure NVIDIA-only target.

## Category: Quality Gates

### Required Baseline

```bash
./scripts/validate-project.sh
```

### Recommended Tooling

- `yamllint .`
- `systemd-analyze verify` for changed unit/timer files.
- `shellcheck` for `*.sh`.
- Schema checks for BlueBuild recipes.
- Consistency checks between README commands and current recipes/workflows.
- Consistency checks between enabled timers in recipes and unit files in `files/system/...`.

## Category: Continuous Improvement

### High Priority

- Pin critical GitHub Actions to commit SHA.
- Expand automated consistency checks as workflows and variants evolve.

### Medium Priority

- Replace duplicated AMD/NVIDIA workflow logic with a reusable workflow or matrix strategy.
- Add a lightweight check to catch variant wording regressions in documentation.

### Nice to Have

- Add automated checks to verify README references against live workflow and recipe names.
- Add a release notes template for behavior changes and rollback notes.
- Add a lightweight performance profile note per variant for the 5959X + 6600 XT + 3080 Ti baseline.

## Category: Gitignore Policy

### Must Be Tracked

- Source recipes/workflows/docs/scripts/configs required for reproducible builds.

### Must Be Ignored

- Secrets and signing private material.
- Local LLM/assistant state and temporary artifacts.
- Generated documentation output only, not documentation source.

### Rejection Rule

- Reject any ignore rule that hides source-of-truth project files.

## Category: Spec Evolution

- Keep rules atomic, one intent per bullet.
- Add new rules in the most specific category instead of broad rewrites.
- When changing a rule, update rationale in the same commit or PR description.
- Preserve stable category names to reduce churn in references.
