# Hardware Baseline & Tuning Rationale

## Minimum Hardware Requirements

| Component        | Minimum                         | Recommended                       |
| ---------------- | ------------------------------- | --------------------------------- |
| **RAM**          | 32 GB                           | 64 GB+                            |
| **Storage**      | 256 GB NVMe                     | 1 TB NVMe Gen4+                   |
| **CPU**          | AMD Ryzen 5000 / Intel 12th Gen | AMD Ryzen 7000+ / Intel 14th Gen+ |
| **GPU (AMD)**    | RX 6000 series                  | RX 7000 series                    |
| **GPU (NVIDIA)** | RTX 3000 series                 | RTX 4000 series                   |

> ⚠️ **Warning:** This image is optimized for high-performance workstations with **64 GB RAM**. Use on lower-spec hardware may cause instability.

## Tuning Rationale

### Memory & Swap

| Setting                     | Value                  | Rationale                                                       |
| --------------------------- | ---------------------- | --------------------------------------------------------------- |
| `vm.swappiness`             | 60                     | Balanced page cache retention with ZRAM usage for 64GB systems  |
| `vm.dirty_background_ratio` | 2                      | ~1GB background writeback on 64GB RAM                           |
| `vm.dirty_ratio`            | 6                      | ~4GB blocking writeback on 64GB RAM                             |
| `vm.page-cluster`           | 0                      | Single-page swap I/O for lower latency on NVMe                  |
| ZRAM size                   | `min(ram * 0.5, 32GB)` | 32GB cap prevents excessive memory compression overhead         |

Full memory/VM tuning rationale: [`SECURITY_AUDIT.md` §3.5](SECURITY_AUDIT.md#35-memory--vm)

### Network

| Setting                  | Value     | Rationale                                                   |
| ------------------------ | --------- | ----------------------------------------------------------- |
| `tcp_congestion_control` | cubic     | Fedora default; fair with mixed workloads (BBRv1 excluded)  |
| `nf_conntrack_max`       | 2,097,152 | Supports P2P, torrents, and container workloads             |
| `ping_group_range`       | 0–65534   | Rootless container support without global raw socket access |

Full network tuning rationale: [`SECURITY_AUDIT.md` §3.6](SECURITY_AUDIT.md#36-network-performance-non-security)

### Security

All kernel hardening, filesystem protection, and network security parameters are defined in
[`SECURITY_AUDIT.md` §3](SECURITY_AUDIT.md#3-mandatory-sysctl-parameters). That document is the
authoritative reference for all sysctl values, including threat model coverage, prohibited
configurations, and re-evaluation triggers.

### Scaling for Lower-Spec Hardware

If using **32 GB RAM** instead of 64 GB:

```ini
# Override in /etc/sysctl.d/99-local.conf
vm.dirty_background_ratio = 3
vm.dirty_ratio = 10
vm.swappiness = 60
vm.vfs_cache_pressure = 100
```

If using **16 GB RAM** (not recommended):

```ini
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.swappiness = 50
vm.vfs_cache_pressure = 150
# Reduce ZRAM cap to avoid compression overhead
# Edit zram-generator: zram-size = min(ram * 0.5, 8192)
```
