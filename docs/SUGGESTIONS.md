# Architectural Improvement Proposals (Future Roadmap)

This document tracks evaluated system enhancements, architectural trade-offs, and future improvements for maintainer decision.

---

## 1. Local LLM & ROCm Runtime Architecture

### Context
Workloads include local LLM inference and PyTorch workflows on an AMD RX 6600 XT (Navi 23 / `gfx1032`) paired with an AMD Ryzen 9 5950X and 64 GB RAM.

### Options
1. **Containerized Execution via Podman / Distrobox (Recommended Baseline):**
   - Run Ollama (`ollama/ollama:rocm`) or PyTorch containers passing `/dev/kfd` and `/dev/dri`.
   - Propagate `HSA_OVERRIDE_GFX_VERSION=10.3.0` to container environments.
   - **Pros:** Keeps base OCI image lightweight (< 4 GB compressed), isolates heavy ROCm libraries (~12-15 GB uncompressed), prevents layer churn and slow image deployment.
   - **Cons:** Requires container wrapper for CLI tools.

2. **Base Image Package Layering (Kept Commented in `recipes/common-drivers.yml`):**
   - Layer `rocm-hip`, `rocm-opencl`, `rocm-runtime`, `rocblas`, `rocm-smi` into the base image.
   - **Pros:** Direct host CLI access to `hipcc` and host OpenCL runtimes.
   - **Cons:** Significantly increases base image build time, network transfer, and storage requirements.

### Recommendation
Maintain containerized execution as the primary path and keep base image package layering commented out in `recipes/common-drivers.yml` for future opt-in evaluation.

---

## 2. Transparent Hugepages Tuning (`transparent_hugepage=madvise`)

### Context
On systems with 64 GB RAM executing compilation, virtualization, and LLM inference, default kernel hugepage defragmentation (`transparent_hugepage=always`) can induce memory allocation latency spikes under high page turnover.

### Proposed Improvement
Add `transparent_hugepage=madvise` to `recipes/common-kargs.yml`.

### Impact
- Allocations only use hugepages when explicitly requested via `madvise()` (utilized by QEMU, PyTorch, Ollama, and jemalloc).
- Eliminates background `khugepaged` compaction stalls on general desktop processes.

---

## 3. Systemd Unit Sandboxing Hardening

### Context
Update timers and background maintenance services currently run with `ProtectSystem=full` or default privileges.

### Proposed Improvement
Evaluate progressive systemd unit sandboxing for update services:
- `ProtectSystem=strict` with explicit `ReadWritePaths=` for `/var/lib/flatpak` and `/var/lib/containers`.
- `CapabilityBoundingSet=` restricting unnecessary Linux capabilities.
- `ProtectControlGroups=true` and `ProtectKernelModules=true`.

---

## 4. KDE Plasma 6 Wayland Color Management & HDR

### Context
KDE Plasma 6 provides initial Wayland color management protocols and HDR display pipeline support.

### Proposed Improvement
When paired with wide-gamut or HDR displays:
- Implement declarative ICC profile enrollment via `/usr/share/color/icc/`.
- Validate colord integration with Wayland compositor color pipelines.
