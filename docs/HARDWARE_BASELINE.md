# Hardware Baseline & Tuning Rationale

## Target Hardware Profile

This repository is optimized for the following high-performance workstation configuration:

| Component           | Specification                          |
| ------------------- | -------------------------------------- |
| **CPU**             | AMD Ryzen 9 5950X                      |
| **GPU (Primary)**   | AMD RX 6600 XT (Wayland display)       |
| **GPU (Secondary)** | NVIDIA RTX 3080 Ti (Compute only)      |
| **RAM**             | 64 GB                                  |
| **Storage**         | 1 TB NVMe                              |
| **OS**              | Fedora Kinoite (Latest Stable Release) |

## Variant Isolation

Maintain strict separation between GPU variants. Never collapse variant logic.

| Variant          | Base Image                        | Purpose                                       |
| ---------------- | --------------------------------- | --------------------------------------------- |
| `kinoite-amd`    | `quay.io/fedora/fedora-kinoite`   | AMD-only systems                              |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | AMD + NVIDIA hybrid systems with CUDA support |

