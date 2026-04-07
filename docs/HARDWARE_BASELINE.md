# Hardware Baseline

**Disclaimer:** This image is heavily opinionated and optimized for a specific high-performance workstation baseline. Applying this image to low-spec hardware (e.g., laptops with 8GB/16GB RAM) may cause system instability, out-of-memory (OOM) kills, or network stutters.

The system tuning (sysctl, zram, and network buffers) assumes the following minimum operational context:

## Minimum Requirements

- **Memory:** 64 GB RAM (ZRAM configured to 16GB max with zstd compression; TCP buffers expanded for high-throughput P2P)
- **GPU:** Dedicated AMD and/or NVIDIA GPUs for hardware acceleration and containerized LLM compute offloading
- **Environment:** Trusted home/workstation network (privacy extensions like MAC randomization are disabled in favor of static IPs and local network discovery)
- **Workload:** High-throughput networking, local AI/LLM inference, and heavy virtualization

## Security Considerations

This image makes specific security trade-offs optimized for a **trusted home workstation**:

| Setting | Value | Rationale |
|---------|-------|-----------|
| **DNSOverTLS** | `yes` (strict) | Enforces encrypted DNS transport with no plaintext fallback |
| **LLMNR** | `yes` | Required for legacy Windows/IoT device discovery on home networks |
| **MAC Randomization** | Disabled | Required for stable IP assignment and P2P port forwarding |
| **TCP Fast Open** | `3` (client+server) | Reduced latency for repeat connections; acceptable on trusted networks |
| **ping_group_range** | `0 2147483647` | Required for rootless container networking (Podman/Distrobox) |

**For high-security environments** (public Wi-Fi, hostile networks), consider:
1. Relaxing DNSOverTLS for unstable networks: create `/etc/systemd/resolved.conf.d/90-local-dns.conf` with `DNSOverTLS=opportunistic`
2. Enabling MAC randomization: `nmcli connection modify <id> wifi.cloned-mac-address random`
3. Disabling TCP Fast Open: Add `net.ipv4.tcp_fastopen = 0` to `/etc/sysctl.d/local.conf`
4. Using a VPN for all traffic
5. Disabling LLMNR: Edit `/etc/systemd/resolved.conf.d/local.conf` → `LLMNR=no`

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
| ZRAM max (zram-generator) | 16384 MB | 8192 MB | 4096 MB |
| `vm.swappiness` | 70 | 60 | 50 |

Reduce TCP buffer sizes, ZRAM allocation, and swappiness values to match your available RAM.
