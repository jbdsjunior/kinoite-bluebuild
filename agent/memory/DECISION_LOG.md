# Decision Log — kinoite-bluebuild

**Last Updated:** April 8, 2026 — `/evolve` Cycle

---

## 1. Architecture Decisions

### ADR-001: Dual Variant Isolation
**Date:** April 2026 (inherited)
**Decision:** Maintain separate `recipe-amd.yml` and `recipe-nvidia.yml` with shared `common-base.yml`
**Rationale:** NVIDIA variant requires proprietary drivers and uBlue base; merging would create conflicts
**Status:** ✅ Active — Never merge workflows

### ADR-002: BlueBuild Modular Architecture
**Date:** April 2026 (inherited)
**Decision:** 10 sub-modules for independent configuration domains
**Rationale:** Enables targeted changes without affecting unrelated systems
**Status:** ✅ Active

### ADR-003: Cosign Image Signing
**Date:** April 2026 (inherited)
**Decision:** All images signed with Cosign; public key in `cosign.pub`
**Rationale:** Ensures image integrity and provenance for bootc switch operations
**Status:** ✅ Active

### ADR-004: Composefs + fs-verity
**Date:** April 2026 (inherited)
**Decision:** Enable composefs in `prepare-root.conf`
**Rationale:** Cryptographic verification of root filesystem at boot time
**Status:** ✅ Active

### ADR-005: Aggressive Sysctl Hardening
**Date:** April 2026
**Decision:** ~70+ sysctl parameters covering security, performance, and privacy
**Rationale:** Zero-trust desktop posture for high-value workstation
**Status:** ✅ Active — verified against ANSSI-BP-028, CIS Benchmark

### ADR-006: Topgrade User-Level Timers
**Date:** April 2026 (inherited)
**Decision:** 3 staggered user timers for automatic updates (boot, system, flatpak)
**Rationale:** User-space execution with low priority; avoids root-level update risks
**Status:** ✅ Active

### ADR-007: Agent Memory Structure
**Date:** April 8, 2026
**Decision:** Created `agent/` directory structure (`context/`, `rules/`, `memory/`)
**Rationale:** AGENTS.md referenced these directories but they didn't exist; required for proper agent operation
**Status:** ✅ Active — newly created

### ADR-008: Documentation Deduplication
**Date:** April 8, 2026
**Decision:** `docs/` = user-facing authoritative; `agent/` = agent enforcement; `audit/` = legacy (consider deprecation)
**Rationale:** `audit/SECURITY_AUDIT.md` and `docs/SECURITY_AUDIT.md` overlap; `audit/PERFORMANCE_TUNING.md` and `docs/HARDWARE_BASELINE.md` overlap
**Status:** ⏳ Pending — `audit/` directory not yet deprecated

---

## 2. Rejected Decisions

### RJD-001: Enable AVIC (AMD Virtual Interrupt Controller)
**Date:** April 2026 (inherited)
**Decision:** Keep `kvm_amd.avic=1` commented out
**Rationale:** Kernel 6.16+ still unstable for Windows VMs
**Status:** ✅ Rejected — re-evaluate on kernel 6.20+

### RJD-002: Enable BBRv1 Congestion Control
**Date:** April 2026 (inherited)
**Decision:** Use `cubic` (Fedora default), exclude BBRv1
**Rationale:** BBRv1 has documented fairness issues with mixed RTT flows
**Status:** ✅ Rejected — re-evaluate when BBRv3 upstreamed

### RJD-003: Disable debugfs via Boot Parameter
**Date:** April 2026
**Decision:** Reject `debugfs=off` boot parameter
**Rationale:** Breaks GPU debugging tools (radeontool, nvtop) on desktop
**Status:** ✅ Rejected — desktop use case requires GPU debugging

### RJD-004: Disable CPU Trust for Random Number Generator
**Date:** April 2026
**Decision:** Reject `random.trust_cpu=off`
**Rationale:** Increases boot time significantly; marginal security benefit for desktop
**Status:** ✅ Rejected — boot time impact exceeds benefit
