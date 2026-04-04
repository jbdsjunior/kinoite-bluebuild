# Hardware Baseline

**Disclaimer:** This image is heavily opinionated and optimized for a specific high-performance workstation baseline. Applying this image to low-spec hardware (e.g., laptops with 8GB/16GB RAM) may cause system instability, out-of-memory (OOM) kills, or network stutters.

The system tuning (sysctl, zram, and network buffers) assumes the following minimum operational context:

## Minimum Requirements

- **Memory:** 64 GB RAM (ZRAM is configured to scale up to 32GB, and TCP buffers are expanded for high-throughput P2P)
- **GPU:** Dedicated AMD and/or NVIDIA GPUs for hardware acceleration and containerized LLM compute offloading
- **Environment:** Trusted home/workstation network (privacy extensions like MAC randomization are disabled in favor of static IPs and local network discovery)
- **Workload:** High-throughput networking, local AI/LLM inference, and heavy virtualization

## Recommendations for Standard Hardware

**If you are running on standard hardware:** We strongly recommend forking this repository and adjusting the limits in the following files before building your own image:

- `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf` — Kernel and memory tuning parameters
- `files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf` — ZRAM compression swap policy

### Suggested Values for Lower RAM Configurations

| Parameter | 64GB (Baseline) | 32GB | 16GB |
| :--- | :--- | :--- | :--- |
| `net.core.rmem_max` / `wmem_max` | 33554432 | 16777216 | 8388608 |
| `net.ipv4.tcp_rmem` (max) | 33554432 | 16777216 | 8388608 |
| `net.ipv4.tcp_wmem` (max) | 33554432 | 16777216 | 8388608 |
| ZRAM max (zram-generator) | 32768 MB | 16384 MB | 8192 MB |
| `vm.swappiness` | 10 | 20 | 40 |

Reduce TCP buffer sizes, ZRAM allocation, and swappiness values to match your available RAM.
