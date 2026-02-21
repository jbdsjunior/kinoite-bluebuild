# LLM Specification - kinoite-bluebuild

Version: 2026-02-21
Scope: Entire repository (`recipes/`, `files/`, `scripts/`, `.github/workflows/`, `README.md`)

## 1. Mission & Global Directives

* Keep regression risk low and image behavior reproducible.
* Keep rpm-ostree/bootc delivery secure by default.
* Always seek current best practices and apply documentation recommendations.
* Always verify conflicts, possible errors, and improvement opportunities before and after edits.
* Prefer explicit decisions over implicit assumptions, especially for variant behavior.
* Treat update discovery as continuous work: compare current repo choices with recent official guidance.

## 2. Maintainer Baseline

* CPU: AMD Ryzen 9 5959X.
* Primary GPU: AMD Radeon RX 6600 XT.
* Secondary GPU: NVIDIA RTX 3080 Ti.
* RAM: 64 GB.
* Storage: NVMe 1 TB.
* Workload: heavy browser video usage (Chrome and Brave), local/containers LLM usage.
* OS context: Fedora Linux and Fedora Linux Kinoite, continuously updated.

## 3. LLM Behavior & Communication

* **Tone and Style:** Be concise, direct, and to the point. Answer concisely unless the user asks for detail. Do not use unnecessary preambles or postambles (e.g., avoid "Here is the content of the file..." or summarizing actions unless requested).
* **Proactiveness vs. Asking:** Strive to strike a balance between taking autonomous actions to solve the problem and not surprising the user with unrequested system changes.
* **Task Management:** For complex tasks, frequently use planning or To-Do tracking tools to break down the work into smaller steps. Always mark tasks as completed immediately after finishing them. Use these tools proactively throughout the coding session.

## 4. Workflow & Context Understanding

* **Maximize Context:** Be thorough when gathering information before making changes. Trace symbols back to their definitions and explore alternative implementations or edge cases to ensure comprehensive coverage of the topic.
* **Change Workflow:**

1. *Discovery:* Read impacted files and use semantic search tools to understand the broader context.
2. *Upstream Refresh:* Review relevant upstream docs/changelogs (BlueBuild, bootc, Fedora).
3. *Implementation:* Apply the smallest safe diff. Never commit changes unless explicitly asked.
4. *Verification:* When a task is completed, always run lint and typecheck commands (e.g., `yamllint`, `shellcheck`, `systemd-analyze`) if available to ensure correct code.
5. *Documentation Sync:* Update docs when behavior changes.

## 5. Project Snapshot & Architecture

* **Variants:** Two published image variants: `kinoite-amd` (AMD-only hosts) and `kinoite-nvidia` (AMD + NVIDIA hybrid hosts). Do not treat `kinoite-nvidia` as a pure NVIDIA-only target.
* **Modularity:** Shared configuration is centralized (`recipes/common.yml`). Variant-specific kernel args are explicitly separated.
* **Security:** Never commit secrets, private keys, or tokens. Preserve signed-image flows.

## 6. Coding & File Standards

### Code Citations and Modifications

* When citing existing code from the codebase, use the explicit format `startLine:endLine:filepath` without language tags (e.g., ````12:14:app/script.sh`).
* When proposing new code not yet in the codebase, use standard markdown code blocks with the correct language tag.

### Shell Script Standards

* Scripts must be linear with straightforward control flow.
* Avoid unnecessary comments.
* When comments are necessary, they must strictly be in international English.
* Keep scripts easy to diff and debug from logs.

### Recipe & System File Standards

* Keep `recipes/common.yml` as orchestrator. Move variant-specific settings to variant modules.
* Keep systemd unit/timer descriptions clear and restart behavior safe.
* Keep shared modules truly shared and variant behavior explicit.

### Workflow Standards

* Use least-privilege permissions in every job.
* Prefer stable and pinned action versions to commit SHA.
* Keep AMD and AMD+NVIDIA workflows semantically equivalent where possible.

## 7. Documentation Parity

* Keep docs close to executable reality (commands, service names, paths, image names).
* Reflect any behavior change in recipes/workflows/systemd/files in `README.md`.
* Include impact and rollback notes for behavior changes.

## 8. Continuous Improvement & Updates

* Use official documentation as the primary source of truth.
* Align updates with the maintainer baseline workload (AMD + NVIDIA hybrid operation, containers, LLM).
* **High Priority:** Pin critical GitHub Actions to commit SHA; expand automated consistency checks.
* **Medium Priority:** Replace duplicated AMD/NVIDIA workflow logic with a reusable matrix strategy.

## 9. Repository Policies

* **Gitignore:** Track source recipes/workflows/docs required for builds. Ignore secrets, local LLM state, and generated output. Reject rules that hide source-of-truth files.
* **Spec Evolution:** Keep rules atomic (one intent per bullet). Add new rules in the most specific category. Preserve stable category names.
