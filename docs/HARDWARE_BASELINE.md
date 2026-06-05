# Hardware Baseline and Tuning Rationale

## Target Profile

This project is optimized for a high-capacity workstation profile focused on KDE Plasma, virtualization, containers, and development workloads.

| Component | Reference Specification |
| :-- | :-- |
| **CPU** | AMD Ryzen 9 5950X |
| **Primary GPU (display/Wayland)** | AMD RX 6600 XT |
| **RAM** | 64 GB |
| **Storage** | 1 TB NVMe |
| **Base OS** | Fedora Kinoite |

---

## Technical Rationale

- This baseline prioritizes stability for heavy multitasking, VMs, containers, and local compilation.
- This baseline targets AMD graphics for desktop rendering and general development workloads.
- I/O and service tuning is versioned to ensure predictable behavior on immutable systems.

---

## Expected Operational Limits

On hardware below this baseline, you may observe:

- higher graphical session latency under load;
- degraded local build and virtualization performance;
- memory contention under parallel workloads.

> ⚠️ **Warning:** the project does not block execution on lower-end hardware, but it is validated and tuned for the baseline above.

---

## Relationship to Recipes and Variants

| Variant | Pipeline | Profile |
| :-- | :-- | :-- |
| `amd` | `.github/workflows/build-amd.yml` | AMD-only systems |

- Main recipe: `recipes/recipe-amd.yml`.
- Shared modules: `recipes/common-*.yml`.
