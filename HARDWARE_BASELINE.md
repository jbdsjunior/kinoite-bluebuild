# Target Audience & Hardware Baseline

**Disclaimer:** This image is heavily opinionated and optimized for a specific high-performance workstation baseline. Applying this image to low-spec hardware (e.g., laptops with 8GB/16GB RAM) may cause system instability, out-of-memory (OOM) kills, or network stutters.

The system tuning (sysctl, zram, and network buffers) assumes the following minimum operational context:

- **Memory:** 64 GB RAM (ZRAM is configured to scale up to 32GB, and TCP buffers are expanded for high-throughput P2P).
- **GPU:** Dedicated AMD and/or NVIDIA GPUs for hardware acceleration and containerized LLM compute offloading.
- **Environment:** Trusted home/workstation network (privacy extensions like MAC randomization are disabled in favor of static IPs and local network discovery).
- **Workload:** High-throughput networking, local AI/LLM inference, and heavy virtualization.

**If you are running on standard hardware:** We strongly recommend forking this repository and adjusting the limits in `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf` and `files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf` before building your own image.
