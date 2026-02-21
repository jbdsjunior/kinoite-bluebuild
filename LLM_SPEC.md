# LLM Specification - kinoite-bluebuild

Version: 2026-02-21
Scope: Entire repository (`recipes/`, `files/`, `scripts/`, `.github/workflows/`, `README.md`)

## 1) Objective

Define how LLM agents and maintainers should evolve this repository with:

- low regression risk,
- reproducible image behavior,
- secure-by-default delivery for rpm-ostree/bootc workflows,
- continuous improvement based on measurable quality gates.

## 1.1) Mandatory Global Directive

For every task, LLM agents must:

- always seek current best practices,
- always apply documentation best-practice recommendations,
- always verify conflicts, possible errors, and improvement opportunities before and after edits.

## 1.2) Maintainer Workstation Baseline (2026)

Treat this hardware/software profile as the primary optimization reference:

- CPU: AMD Ryzen 9 5959X
- Primary GPU: AMD Radeon RX 6600 XT
- Secondary GPU: NVIDIA RTX 3080 Ti
- RAM: 64 GB
- Storage: NVMe 1 TB
- Workload: heavy browser video usage (Chrome and Brave), local/containers LLM usage
- OS context: Fedora Linux and Fedora Linux Kinoite, continuously updated

## 2) Project Analysis (Current State)

### 2.1 Architecture Summary

- Two published image variants: `kinoite-amd` (`recipes/recipe-amd.yml`) and `kinoite-nvidia` (`recipes/recipe-nvidia.yml`).
- Shared configuration is centralized in `recipes/common.yml` plus modular includes (`common-*.yml`).
- Runtime behavior is mostly defined by versioned files under `files/system/...`.
- Build and publish happen via GitHub Actions (`.github/workflows/build-*.yml`).
- Upstream image digest monitoring and trigger logic exist in `.github/workflows/check-updates.yml`.
- Local validation exists in `scripts/validate-project.sh`.

### 2.2 Strengths

- Good modular recipe layout with reuse.
- Image signing module already present in both recipes.
- Timers and systemd services are versioned and reproducible.
- Local validation script checks references and syntax for several file types.

### 2.3 Gaps and Risks

- CI does not currently enforce `scripts/validate-project.sh` on every PR via a dedicated validation workflow.
- Workflows use tagged actions/versions (for example `blue-build/github-action@v1.11`) instead of full commit SHA pinning.
- `use_unstable_cli: true` in build workflows increases upgrade risk.
- `recipes/common-kargs.yml` contains AMD-specific tuning applied to all variants; this may be suboptimal for non-AMD hosts running `kinoite-nvidia`.
- Language and style are mixed across files (Portuguese/English), which increases maintenance cost over time.
- `systemd-analyze` and `yamllint` are optional locally; missing tools can hide quality issues until runtime.
- There is no explicit conflict-check matrix linking recipes, unit names, workflow references, and README commands.

## 3) Non-Negotiable Principles

1. Security first

- Never commit secrets, private keys, tokens, or host-specific credentials.
- Preserve signed-image flow; any change that weakens verification must be rejected.

1. Reproducibility first

- Prefer deterministic inputs and explicit behavior over implicit defaults.
- Keep configuration in repo-managed files/modules, not host-side manual drift.

1. Variant isolation

- AMD/NVIDIA specific behavior must remain explicit and easy to reason about.
- Shared modules should only contain truly shared logic.

1. Small blast radius

- Prefer small, isolated changes over broad refactors.
- Touch only the minimal set of files needed for each objective.

1. Documentation parity

- Any behavior change in recipes/workflows/systemd/files must be reflected in `README.md`.

1. Validation before merge

- Local and CI checks must pass before release/publish.
- New file formats require corresponding lint/validation coverage.

1. Backward safety

- Preserve rollback-friendly behavior (`rpm-ostree rollback`) and avoid disruptive migration steps without clear fallback.

1. Documentation quality and conflict detection

- Every change must include a documentation-quality check and a conflict/error scan.
- If a mismatch is found between implementation and docs/workflows, fix or explicitly document it in the same change.
- When no bug is found, still propose at least one concrete improvement for maintainability.

## 4) LLM Change Rules

### 4.1 Allowed Change Pattern

- Step 1: Read impacted recipe/module/workflow/files.
- Step 2: Run conflict scan (names, paths, references, behavior parity) before editing.
- Step 3: Implement smallest safe diff.
- Step 4: Run local validation (`./scripts/validate-project.sh`).
- Step 5: Update docs when behavior changed.
- Step 6: Re-run conflict scan after editing.
- Step 7: Summarize risks, checks, and improvement opportunities in PR/commit message.

### 4.2 Recipe Rules

- Keep `recipes/common.yml` as orchestrator only.
- Put variant-specific settings in variant modules (or recipe-specific includes).
- For kernel args, keep generic args in `common-kargs.yml`.
- For kernel args, move AMD-only args to an AMD-specific module when possible.

### 4.3 Workflow Rules

- Prefer least-privilege permissions in every job.
- Prefer stable/pinned actions and reviewed upgrades.
- Treat `use_unstable_cli` as temporary and documented exception.

### 4.4 System File Rules

- systemd unit/timer changes must keep clear unit descriptions and safe restart semantics.
- Network/security defaults must document compatibility tradeoffs.
- Scripts must keep `set -euo pipefail` and clear failure messages.

### 4.5 Shell Script Style Rules

- Prefer linear shell scripts with straightforward control flow.
- Avoid unnecessary comments.
- If comments are required, write comments in international English only.
- Keep scripts easy to diff and easy to debug in production logs.

### 4.6 Documentation Best-Practice Rules

- Keep docs close to executable reality (commands, service names, paths, image names).
- Prefer concise, task-oriented sections (install, operate, troubleshoot, recover).
- For every behavior change, include impact and rollback note.
- Prefer stable terminology for variants (`kinoite-amd`, `kinoite-nvidia`) across all files.

## 5) Quality Gates (Required)

Minimum required before publish:

```bash
./scripts/validate-project.sh
```

Recommended additional gates:

- `yamllint .`
- `systemd-analyze verify` for changed unit/timer files
- `shellcheck` for `*.sh`
- schema checks for BlueBuild recipes
- consistency checks between README commands and current recipes/workflows
- consistency checks between enabled timers in recipes and unit files in `files/system/...`

## 6) Continuous Improvement Backlog

### P0 (High Priority)

- Add a dedicated PR workflow to run `./scripts/validate-project.sh`.
- Add `yamllint` and `shellcheck` to CI so failures are not tool-availability dependent.
- Pin critical GitHub Actions to commit SHA.
- Add automated conflict checks for workflow names vs README badges/commands.
- Add automated conflict checks for recipe names vs published image names.
- Add automated conflict checks for enabled timers/services vs existing unit files.

### P1 (Medium Priority)

- Split AMD-specific kernel args into a dedicated AMD module.
- Standardize repository language (choose PT-BR or EN) for comments/docs/messages.
- Replace duplicated AMD/NVIDIA workflow logic with a reusable workflow or matrix strategy.

### P2 (Nice-to-have)

- Add automated checks ensuring `README.md` references match actual workflow/recipe names.
- Add release notes template for image behavior changes and rollback notes.
- Add a lightweight "performance profile" note per variant for the 5959X + 6600 XT + 3080 Ti baseline.

## 7) Gitignore Policy

Tracked by design:

- Source recipes/workflows/docs/scripts/configs required for reproducible builds.

Ignored by design:

- Secrets and signing private material.
- Local LLM/assistant state and temporary artifacts.
- Generated documentation output only (not documentation source).

Any ignore rule that hides source-of-truth project files must be rejected.

## 8) Editing and Evolution Model

To keep the spec maintainable over time:

- Keep rules atomic (one intent per bullet).
- Prefer adding new rules to the most specific section instead of broad rewrites.
- When changing a rule, update rationale in the same commit/PR description.
- Keep section numbering stable to reduce reference churn in issues/PRs.
