# Hardware Baseline

**Disclaimer:** This image is optimized for high-performance workstations. Applying this image to low-spec hardware may cause instability or out-of-memory (OOM) issues.

## Minimum Requirements

- **Memory:** 64 GB RAM
- **GPU:** Dedicated AMD and/or NVIDIA GPUs
- **Network:** Trusted home/workstation network
- **Workload:** High-throughput networking, local AI/LLM inference, virtualization

## Recommendations for Standard Hardware

**If you are running on standard hardware:** Fork this repository and adjust the limits in these files before building:

- `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf` — Kernel and memory tuning
- `files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf` — ZRAM swap policy

### Suggested Values for Lower RAM Configurations

| Parameter | 64GB (Baseline) | 32GB | 16GB |
| :--- | :--- | :--- | :--- |
| `net.core.rmem_max` / `wmem_max` | 33554432 | 16777216 | 8388608 |
| `net.ipv4.tcp_rmem` (max) | 33554432 | 16777216 | 8388608 |
| `net.ipv4.tcp_wmem` (max) | 33554432 | 16777216 | 8388608 |
| ZRAM max | 16384 MB | 8192 MB | 4096 MB |
| `vm.swappiness` | 70 | 60 | 50 |
