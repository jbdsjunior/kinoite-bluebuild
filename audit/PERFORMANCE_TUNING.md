# Performance Tuning Log — kinoite-bluebuild

**Last Audit:** April 2026
**Hardware Baseline:** AMD Ryzen 9 5950X / 64 GB RAM / 1 TB NVMe

---

## 1. Memory & VM Tuning

### 1.1 ZRAM Configuration

| Setting | Value | Rationale |
|---|---|---|
| ZRAM size | `min(ram * 0.5, 32GB)` | 50% of RAM capped at 32GB for 64GB+ systems |
| Compression | `zstd` | Best speed/compression ratio for modern CPUs |
| Swap priority | `32767` | Highest priority ensures ZRAM used before disk swap |

### 1.2 Dirty Page Writeback

| Setting | Value | Rationale |
|---|---|---|
| `vm.dirty_background_ratio` | `2` | ~1GB background writeback on 64GB |
| `vm.dirty_ratio` | `6` | ~4GB blocking writeback on 64GB |
| Ratios vs fixed | Ratios used | Scale automatically across RAM configurations |

### 1.3 Cache & Swappiness

| Setting | Value | Rationale |
|---|---|---|
| `vm.swappiness` | `60` | Balance between ZRAM usage and page cache retention |
| `vm.vfs_cache_pressure` | `50` | Retain inode/dentry caches longer (50% of default) |
| `vm.page-cluster` | `0` | Single-page swap I/O for NVMe latency optimization |
| `vm.watermark_scale_factor` | `125` | Page allocation watermark scaling (3x default) |
| `vm.max_map_count` | `16777216` | Support LLM, Java, VM workloads |

### 1.4 Scaling for Lower-Spec Hardware

See `docs/HARDWARE_BASELINE.md` §Scaling for lower-spec hardware.

---

## 2. Network Performance

### 2.1 Congestion & Queue

| Setting | Value | Rationale |
|---|---|---|
| `net.core.default_qdisc` | `fq` | Fair Queue for low-latency interactive traffic |
| `net.ipv4.tcp_congestion_control` | `cubic` | Fedora default; fair with mixed workloads |
| BBRv1 | Excluded | Known fairness issues; BBRv2/v3 not in mainline 6.19 |

### 2.2 Buffer Sizing

| Setting | Value | Rationale |
|---|---|---|
| `net.core.rmem_max` | 32 MB | High-throughput connections |
| `net.core.wmem_max` | 32 MB | High-throughput connections |
| `net.ipv4.tcp_rmem` | `4096 1048576 33554432` | Auto-tuned receive buffer |
| `net.ipv4.tcp_wmem` | `4096 1048576 33554432` | Auto-tuned send buffer |
| `net.core.netdev_max_backlog` | `16384` | Device queue for burst traffic |
| `net.core.somaxconn` | `8192` | Socket listen queue |

### 2.3 Connection Tracking

| Setting | Value | Rationale |
|---|---|---|
| `nf_conntrack_max` | `2,097,152` | Support P2P, containers, torrents |
| `nf_conntrack_tcp_timeout_established` | `7200` | 2h timeout for established connections |

### 2.4 Keepalive & MTU

| Setting | Value | Rationale |
|---|---|---|
| `tcp_mtu_probing` | `1` | PLPMTUD for black hole detection |
| `tcp_keepalive_time` | `600` | 10 min keepalive interval |
| `tcp_keepalive_intvl` | `30` | 30s retry interval |
| `tcp_keepalive_probes` | `5` | 5 probes (2.5 min total dead detection) |

---

## 3. I/O & Storage

### 3.1 BTRFS NoCOW

Applied via `tmpfiles.d` to VM images and container volumes:

| Path | Scope | Rationale |
|---|---|---|
| `/var/lib/libvirt/images` | System | KVM VM disk images |
| `/var/lib/containers/storage/volumes` | System | Podman/Docker volumes |
| `~/.local/share/libvirt/images` | User | User VM images |
| `~/.local/share/gnome-boxes/images` | User | GNOME Boxes images |
| `~/.local/share/containers/storage/volumes` | User | User Podman volumes |
| `~/.cache/rclone` | User | Rclone VFS cache |

### 3.2 Dracut Initramfs

| Setting | Value | Rationale |
|---|---|---|
| Compression | `zstd` | Best balance of speed and size (~30-40% vs gzip) |
| Early microcode | `yes` | CPU stability and security patches (critical for AMD Ryzen) |
| Hostonly | `no` | Generic mode for ostree/bare-metal deployments |
| Timeout | `15s` | Tuned for NVMe Gen4 SSDs |

---

## 4. System Limits

| Setting | Value | Rationale |
|---|---|---|
| `fs.file-max` | `2097152` | Max file handles for containers/DBs |
| `fs.inotify.max_user_instances` | `8192` | Max inotify instances per user |
| `fs.inotify.max_user_watches` | `1048576` | Max inotify watches per instance |

---

## 5. Kernel Command-Line Parameters

| Parameter | Value | Rationale |
|---|---|---|
| `transparent_hugepage` | `madvise` | Defer for better memory allocation latency |
| `mitigations` | `auto` | Balanced security/performance |
| `pcie_aspm` | `policy_performance` | Desktop/workstation stability |
| `init_on_alloc` | `1` | Memory allocator zeroing on allocation |
| `init_on_free` | `1` | Memory allocator zeroing on free |
| `slab_nomerge` | (present) | Prevent slab cache merging attacks |

---

## 6. Re-Evaluation Triggers

| Trigger | Action |
|---|---|
| BBRv3 lands in mainline kernel | Evaluate `tcp_congestion_control = bbr` with BBRv3 |
| Kernel 6.20+ releases | Re-evaluate all sysctl parameters against new defaults |
| ZSTD compression improvements | Review ZRAM compression algorithm choice |
| User workload changes | Adjust `vm.max_map_count`, dirty ratios accordingly |
