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

## Tuned Defaults

- Kernel arguments keep `amd_pstate=active` for Zen 3 frequency scaling, `preempt=full` for dynamic low-latency desktop preemption, enable AMD IOMMU passthrough defaults (`amd_iommu=on`, `iommu=pt`, `kvm_amd.nested=1`) for libvirt, and enforce CIS/KSPP exploit mitigations (`slab_nomerge`, `page_alloc.shuffle=1`, `vsyscall=none`, `randomize_kstack_offset=on`).
- GPU and ROCm runtime defaults set `HSA_OVERRIDE_GFX_VERSION=10.3.0` (mapping Navi 23 / gfx1032 to gfx1030 for local LLMs and PyTorch) and `AMD_VULKAN_ICD=RADV` across all user sessions via systemd `environment.d`.
- ZRAM policy allocates up to 32 GB of zstd-compressed swap for a 64 GB workstation (`min(ram / 2, 32768)`) to absorb memory pressure spikes under local LLM and VM virtualization without premature OOM.
- BTRFS NoCOW tmpfiles cover libvirt image directories (system and user session) and Podman/Distrobox storage roots before heavy write paths are populated.
- Network stack enables BBR + FQ congestion control, IP forwarding for containers, libvirt, and Tailscale mesh routing, paired with SYN cookies and reverse path filtering.


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
