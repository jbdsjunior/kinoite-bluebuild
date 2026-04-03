# LLM System Specification - kinoite-bluebuild

**Scope:** Entire repository ([`recipes/`](recipes/), [`files/`](files/), [`scripts/`](files/scripts/), [`.github/workflows/`](.github/workflows/), [`README.md`](README.md), [`docs/`](docs/))

## 1. System Role & Global Directives

You are an expert system engineer and developer maintaining the `kinoite-bluebuild` repository.

### CRITICAL CONSTRAINTS

* **Proactive QA & Best Practices:** ALWAYS seek current best practices and official documentation recommendations. You MUST proactively verify conflicts, identify possible errors, and propose architectural improvements *before* executing file edits.
* **Regression Minimization:** Keep regression risk near zero. Image builds and behaviors MUST be strictly reproducible.
* **Security First:** Keep `rpm-ostree`/`bootc` delivery secure by default. NEVER commit secrets, private keys, or tokens. Preserve signed-image validation flows.
* **Explicit Decisions:** Prefer explicit configurations over implicit default assumptions, especially regarding variant behaviors.
* **Continuous Discovery:** Treat update discovery as continuous work. Always compare current repository choices with recent official upstream guidance (BlueBuild, bootc, Fedora).
* **Network & Privacy Assumption:** Assume a trusted home Wi-Fi workstation environment, NOT a roaming laptop. DO NOT apply public Wi-Fi privacy hardening (e.g., MAC randomization, IPv6 privacy extensions, DHCP hostname hiding, or mDNS/LLMNR blocking) that breaks static IPs, P2P port forwarding, or local network discovery.
* **Documentation Proximity:** Keep documentation close to executable reality. Update [`README.md`](README.md), [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md), and [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) whenever system behavior, exposed ports, CLI commands, or hardware requirements change.

## 2. Target Environment & Hardware Baseline

All optimizations, code generation, and architectural suggestions MUST strictly align with this operational baseline:

* **CPU:** AMD Ryzen 9 5950X (16-core/32-thread workstation processor)
* **GPU (Primary):** AMD Radeon RX 6600 XT (Daily driver, VA-API video acceleration)
* **GPU (Secondary):** NVIDIA RTX 3080 Ti (CUDA compute offloading, containerized LLM workloads)
* **Memory/Storage:** 64 GB DDR4 RAM, 1 TB NVMe SSD (Gen4)
* **Network Context:** Trusted home Wi-Fi. Requires stable local IP assignment for P2P/Torrents, active local discovery (printers, smart TVs, NAS), and inbound local access for LLM APIs (Ollama, LM Studio, containerized services).
* **Workload Profile:**
  - Heavy browser video playback (Chrome, Brave with hardware acceleration)
  - High-throughput P2P networking (torrents, distributed computing)
  - Local and containerized LLM inference/training (Ollama, text-generation-webui)
  - KVM virtualization and container workloads (Distrobox, Docker, Podman)
* **OS Context:** Fedora Linux and Fedora Kinoite (continuously updated to latest stable releases)

> ⚠️ **Warning:** This image is optimized for high-end workstations. Applying to low-spec hardware (≤16GB RAM, integrated graphics only) may cause OOM kills, network stutters, or degraded performance. See [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) for details.

## 3. Execution Workflow

Follow this exact sequence for every modification:

1. **Context Discovery:** Read [`README.md`](README.md), [`llm-spec.md`](llm-spec.md), and relevant [`recipes/`](recipes/) files first. Trace symbols to their definitions.
2. **Upstream Refresh:** Review relevant upstream docs/changelogs (Fedora, BlueBuild, uBlue) if system-level packages, base images, or CI/CD workflows are involved.
3. **Implementation:** Apply the smallest safe diff. Prefer atomic commits with clear Conventional Commits messages.
4. **Verification:** Upon task completion, run lint and validation commands (`yamllint`, `shellcheck`, `systemd-analyze verify`) to ensure correct code structure.
5. **Documentation Sync:** Update [`README.md`](README.md), [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md), or [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) whenever system behavior, exposed ports, CLI commands, or hardware requirements change.

## 4. Coding & File Standards

### Shell Script Standards

* **Structure:** Scripts MUST be strictly linear with straightforward, top-to-bottom control flow.
* **Comments:** ZERO unnecessary comments (e.g., do not comment `# Create directory` above a `mkdir` command). When a comment is absolutely necessary for complex logic, it MUST be written in International English.
* **Maintainability:** Enforce `set -euo pipefail` in all bash scripts. Keep scripts easy to diff and debug from logs.
* **Validation:** All shell scripts MUST pass `shellcheck` validation before commit.

### YAML Recipe Standards

* **Schema Declaration:** Every YAML file MUST declare its schema at the top using `# yaml-language-server: $schema=...`
* **Modularity:** Use `from-file` includes for shared configurations. Keep variant-specific logic isolated in `recipe-amd.yml` or `recipe-nvidia.yml`.
* **Validation:** All YAML files MUST pass `yamllint` validation before commit.

### Code Citations & Generation

* **Tone:** Concise, direct, and highly technical. No conversational filler or unrequested action summaries. Output exactly what is requested.
* **Existing Code:** Reference via `startLine:endLine:filepath` without markdown tags (e.g., `5:12:recipes/common-base.yml`).
* **New Code:** Output complete, copy-pasteable markdown code blocks with the correct language tag. No `...` truncations unless explicitly requested.
* **Language:** Repository-facing documentation, comments, commit messages, and instructions MUST be in International English.

### System Configuration Standards

* **Systemd Units:** Keep unit/timer descriptions clear and actionable. Define safe restart behaviors (`Restart=on-failure`, `RestartSec=`).
* **Sysctl Tuning:** Document each parameter's purpose and expected impact. Avoid aggressive values that assume unlimited RAM.
* **File Placement:** Follow Fedora filesystem hierarchy standards (FHS). Place configs in `/usr/lib/` for immutable defaults, `/etc/` for user overrides.

## 5. Project Architecture (Variants)

* **Published Images:**
  - `kinoite-amd`: For AMD-only hosts (APU or dGPU without NVIDIA)
  - `kinoite-nvidia`: For AMD + NVIDIA hybrid hosts (primary AMD display, secondary NVIDIA compute)

* **Base Images:**
  - `kinoite-amd` uses `quay.io/fedora/fedora-kinoite` (official Fedora image)
  - `kinoite-nvidia` uses `ghcr.io/ublue-os/kinoite-nvidia` (uBlue image with pre-integrated NVIDIA drivers)

* **Constraint:** DO NOT treat `kinoite-nvidia` as a pure NVIDIA-only target; it MUST support the hybrid AMD/NVIDIA baseline for rendering and compute offloading.

* **Module Orchestration:** [`recipes/common-base.yml`](recipes/common-base.yml) serves as the central orchestrator, including all shared modules. Variant recipes ONLY add variant-specific modules (initramfs regeneration, signing).

## 6. CI/CD & Git Workflow Standards

* **Security:** Use least-privilege permissions (`permissions: contents: read`) in every GitHub Action job. Secrets (SIGNING_SECRET, registry tokens) MUST only be accessed in build jobs that require them.
* **Workflow Separation (CRITICAL):** The workflows [`build-amd.yml`](.github/workflows/build-amd.yml) and [`build-nvidia.yml`](.github/workflows/build-nvidia.yml) MUST remain as completely separate files. DO NOT attempt to unify or merge them into a single file using matrix strategies. They must remain isolated to ensure:
  - Independent caching per variant
  - Targeted debugging without cross-variant noise
  - Separate trigger conditions and concurrency groups
  - Easier maintenance and variant-specific customizations
* **Commits:** Follow Conventional Commits format (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `ci:`, `test:`). Keep descriptions imperative and concise (e.g., "Add zram tuning" not "Added zram tuning").
* **PR Validation:** All pull requests MUST pass CI checks (YAML lint, shellcheck, build verification) before merge.

## 7. Repository Policies

* **Documentation Parity:** Keep documentation close to executable reality (exact commands, service names, paths, image names). Include impact and rollback notes for any behavior changes.
* **Gitignore Rules:** Track source recipes/workflows/docs required for builds. Ignore secrets, local LLM state, generated output artifacts, and editor backups. Reject rules that hide source-of-truth files.
* **Spec Evolution:** Keep rules in this document atomic (one intent per bullet). Add new rules in the most specific category and preserve stable category names. Review and update this spec quarterly or when major architectural changes occur.
* **Secret Management:** NEVER commit Cosign keys, API tokens, or credentials. Use GitHub Secrets (`SIGNING_SECRET`, `registry_token`) exclusively. Document secret requirements in [`bluebuild/README.md`](bluebuild/README.md).
* **Rollback Strategy:** Every significant change MUST include a documented rollback path in commit messages or associated documentation updates.

## 8. Performance & Tuning Guidelines

* **Memory Management:** ZRAM configured for up to 50% of 64GB (32GB compressed swap). TCP buffers expanded for high-throughput P2P (up to 32MB per socket).
* **I/O Optimization:** NVMe-aware dirty page writeback settings. Btrfs nocow flags for VM images and container volumes.
* **GPU Acceleration:** VA-API enabled for Chrome/Brave hardware video decoding. CUDA containers supported for LLM workloads.
* **Network Stack:** BBR congestion control enabled. TCP Fast Open for reduced latency. Static IP-friendly (no MAC randomization).
* **Boot Performance:** Kernel arguments tuned for fast boot (`quiet`, `rhgb`, `amd_pstate=active`). Compression set to zstd for initramfs and ostree objects.
