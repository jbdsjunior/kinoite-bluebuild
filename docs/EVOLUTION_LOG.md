# Evolution Log (`/evolve`)

Short record of repository evolution cycles, focused on traceability.

## 2026-04-29 — Instruction Governance Alignment (`/evolve`)

### Detect / Diagnose
- Inconsistency detected between governance documentation (`AGENTS.md`) and actual repository structure: only `/.agent/agent.md` exists.
- Identified risk: external agents could try to load non-existent `/.agents/*` files and miss critical directives.

### Propose / Apply
- Updated the "Instruction Architecture" section in `AGENTS.md` to reflect the actual canonical source (`/.agent/agent.md`).
- Revised maintenance rules to prioritize a single source of truth and avoid documentation drift.

### Verify
- Text search confirmed no remaining references to `/.agents/*` after the update.

### Impact
- Reduces operational ambiguity for agents and contributors.
- Improves `/evolve` flow predictability by pointing to the active directive source.

## 2026-04-29 — CI Consistency and Documentation Fixes

### Detect / Diagnose
- Identified build failure risk due to incorrect/unstable recipe references in workflows.
- Identified operational documentation gap for quick pre-PR validation.

### Propose / Apply
- Corrected build workflow recipe paths:
  - `recipe: recipes/recipe-amd.yml`
  - `recipe: recipes/recipe-nvidia.yml`
- Updated `docs/CI_CD.md` with:
  - variant-specific recipe paths;
  - minimum sanity checklist for YAML, recipe paths, and `build_chunked_oci: false`.

### Verify
- YAML parsing for `recipes/*.yml` and `.github/workflows/*.yml` using Ruby (`YAML.load_file`) completed successfully.
- Regex checks (`rg`) confirmed recipe paths and the rechunk-disabled restriction.

### Impact
- Reduces failure risk in `workflow_dispatch` runs.
- Improves predictability and standardization of pre-merge validations.

## 2026-04-30 — `/evolve` DevSecOps Consolidation Cycle

### Detect / Diagnose
- Parsed episodic memory (`.agents/memory/execution.jsonl`) and reviewed recent mutation history.
- Recurrent friction point identified: local lint tool availability (`shellcheck`, `yamllint`) is environment-dependent.
- Confirmed immutable runtime policy baseline remains staged (`rpm-ostreed`) and topgrade cadence is explicitly constrained at 45 minutes in state memory.

### Propose / Apply
- Consolidated deterministic state baseline in `.agents/projeto.md` for execution constraints and rollback discipline.
- Kept lint enforcement delegated to CI workflow to avoid host-environment drift.
- Added this evolution checkpoint to preserve traceability and reduce future decision entropy.

### Verify
- Structural checks completed:
  - `bash -n` on maintained shell scripts.
  - `rg` consistency checks for topgrade cadence and alias/doc alignment.
- No breaking mutations introduced in this cycle.

### Impact
- Improves repeatability of autonomous operations.
- Reduces oscillation between local-tool variance and CI source-of-truth validation.
- Strengthens `/evolve` auditability with explicit memory-backed checkpoints.
