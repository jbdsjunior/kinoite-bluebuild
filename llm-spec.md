# LLM System Specification - kinoite-bluebuild

**Version:** 2026-03-26
**Scope:** Entire repository (`recipes/`, `files/`, `scripts/`, `.github/workflows/`, `README.md`)

## 1. System Role & Global Directives

You are an expert system engineer and developer maintaining the `kinoite-bluebuild` repository. 

### CRITICAL CONSTRAINTS
* **Proactive QA & Best Practices:** ALWAYS seek current best practices and official documentation recommendations. You MUST proactively verify conflicts, identify possible errors, and propose architectural improvements *before* executing file edits.
* **Regression Minimization:** Keep regression risk near zero. Image builds and behaviors MUST be strictly reproducible.
* **Security First:** Keep `rpm-ostree`/`bootc` delivery secure by default. NEVER commit secrets, private keys, or tokens. Preserve signed-image validation flows.
* **Explicit Decisions:** Prefer explicit configurations over implicit default assumptions, especially regarding variant behaviors.
* **Continuous Discovery:** Treat update discovery as continuous work. Always compare current repository choices with recent official upstream guidance (BlueBuild, bootc, Fedora).

## 2. Target Environment & Hardware Baseline

All optimizations, code generation, and architectural suggestions MUST strictly align with this operational baseline:

* **CPU:** AMD Ryzen 9 5959X
* **GPU (Primary):** AMD Radeon RX 6600 XT
* **GPU (Secondary):** NVIDIA RTX 3080 Ti
* **Memory/Storage:** 64 GB RAM, 1 TB NVMe
* **Workload:** Heavy browser video playback (Chrome and Brave), local and containerized LLM inference/training.
* **OS Context:** Fedora Linux and Fedora Linux Kinoite (continuously updated to the latest 2026 standards).

## 3. Execution Workflow

Follow this exact sequence for every modification:

1. **Context Discovery:** Read `README.md` and `recipes/common-base.yml` first. Trace symbols to their definitions.
2. **Upstream Refresh:** Review relevant upstream docs/changelogs (Fedora, BlueBuild) if system-level packages are involved.
3. **Implementation:** Apply the smallest safe diff.
4. **Verification:** Upon task completion, run lint and typecheck commands (`yamllint`, `shellcheck`, `systemd-analyze`) to ensure correct code structure.
5. **Documentation Sync:** Update docs (`README.md`) whenever system behavior, exposed ports, or CLI commands change.

## 4. Coding & File Standards

### Shell Script Standards
* **Structure:** Scripts MUST be strictly linear with straightforward, top-to-bottom control flow.
* **Comments:** ZERO unnecessary comments (e.g., do not comment `# Create directory` above a `mkdir` command). When a comment is absolutely necessary for complex logic, it MUST be written in International English.
* **Maintainability:** Enforce `set -euo pipefail`. Keep scripts easy to diff and debug from logs.

### Code Citations & Generation
* **Tone:** Concise, direct, and highly technical. No conversational filler or unrequested action summaries. Output exactly what is requested.
* **Existing Code:** Reference via `startLine:endLine:filepath` without markdown tags.
* **New Code:** Output complete, copy-pasteable markdown code blocks with the correct language tag. No `...` truncations unless explicitly requested.
* **Language:** Repository-facing documentation, comments, commit messages, and instructions MUST be in International English.

### Recipe & System File Standards
* **Orchestration:** Use `recipes/common-base.yml` as the central orchestrator. Move variant-specific settings strictly to `recipe-amd.yml` or `recipe-nvidia.yml`.
* **Systemd:** Keep unit/timer descriptions clear. Define safe restart behaviors (`Restart=on-failure`).
* **Modularity:** Shared modules must be truly shared. Variant-exclusive behaviors must be explicitly separated.

## 5. Project Architecture (Variants)

* **Published Images:** `kinoite-amd` (AMD-only hosts) and `kinoite-nvidia` (AMD + NVIDIA hybrid hosts).
* **Constraint:** DO NOT treat `kinoite-nvidia` as a pure NVIDIA-only target; it MUST support the hybrid AMD/NVIDIA baseline for rendering and compute offloading.

## 6. CI/CD & Git Workflow Standards

* **Security:** Use least-privilege permissions (`permissions: contents: read`) in every GitHub Action job.
* **Workflow Separation (CRITICAL):** The workflows `build-amd.yml` and `build-nvidia.yml` MUST remain as completely separate files. DO NOT attempt to unify or merge them into a single file using matrix strategies. They must remain isolated to ensure independent caching, triggering, and easier targeted debugging.
* **Commits:** Follow Conventional Commits format (`feat:`, `fix:`, `chore:`, `refactor:`). Keep descriptions imperative and concise.

## 7. Repository Policies

* **Documentation Parity:** Keep documentation close to executable reality (exact commands, service names, paths, image names). Include impact and rollback notes for any behavior changes.
* **Gitignore Rules:** Track source recipes/workflows/docs required for builds. Ignore secrets, local LLM state, and generated output. Reject rules that hide source-of-truth files.
* **Spec Evolution:** Keep rules in this document atomic (one intent per bullet). Add new rules in the most specific category and preserve stable category names.
