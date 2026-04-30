# Hardware Baseline and Tuning Rationale

## Target Profile

This project is optimized for a high-capacity workstation profile focused on KDE Plasma, virtualization, containers, and development workloads.

| Component | Reference Specification |
| :-- | :-- |
| **CPU** | AMD Ryzen 9 5950X |
| **Primary GPU (display/Wayland)** | AMD RX 6600 XT |
| **Secondary GPU (compute)** | NVIDIA RTX 3080 Ti |
| **RAM** | 64 GB |
| **Storage** | 1 TB NVMe |
| **Base OS** | Fedora Kinoite |

---

## Technical Rationale

- This baseline prioritizes stability for heavy multitasking, VMs, containers, and local compilation.
- The AMD+NVIDIA hybrid architecture separates desktop rendering (AMD) from CUDA/compute workloads (NVIDIA).
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
| `amd` | `.github/workflows/build-amd.yml` | systems without NVIDIA stack dependency |
| `nvidia` | `.github/workflows/build-nvidia.yml` | systems with NVIDIA GPU and compute requirements |

- Main recipes: `recipes/recipe-amd.yml` and `recipes/recipe-nvidia.yml`.
- Shared modules: `recipes/common-*.yml`.
- In the current CI configuration, `build_chunked_oci` remains **disabled** (`false`).
