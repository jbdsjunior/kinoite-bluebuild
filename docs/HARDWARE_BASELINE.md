# Hardware Baseline & Tuning Rationale

## Target Hardware Profile

This repository is optimized for the following high-performance workstation configuration:

| Component           | Specification                    |
| ------------------- | -------------------------------- |
| **CPU**             | AMD Ryzen 9 5950X                |
| **GPU (Primary)**   | AMD RX 6600 XT (Wayland display) |
| **GPU (Secondary)** | NVIDIA RTX 3080 Ti (compute)     |
| **RAM**             | 64 GB                            |
| **Storage**         | 1 TB NVMe                        |
| **OS**              | Fedora Kinoite (stable)          |

## Operational Notes

- AMD GPU is intended for display/Wayland.
- NVIDIA GPU is intended for compute/CUDA workloads.
- Build pipelines and recipes stay separated by hardware profile (`amd` vs `nvidia`).
- Rechunk remains disabled by project constraint.
