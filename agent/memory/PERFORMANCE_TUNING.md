# Performance Tuning Log — kinoite-bluebuild

**Last Audit:** April 8, 2026 — `/evolve` Cycle
**Hardware Baseline:** AMD Ryzen 9 5950X / 64 GB RAM / 1 TB NVMe
**Previous Audit:** April 2026

---

## 1. Current Tuning Configuration — Verified

### 1.1 Memory & VM

| Setting | Value | Status |
|---|---|---|
| ZRAM size | `min(ram * 0.5, 32768)` (50% RAM, cap 32GB) | ✅ Optimal for 64GB |
| ZRAM compression | `zstd` | ✅ Best speed/ratio |
| ZRAM priority | `32767` | ✅ Highest priority |
| `vm.page-cluster` | `0` (single-page swap for NVMe) | ✅ Optimal |
| `vm.watermark_scale_factor` | `125` (3x default) | ✅ Good for high-throughput |
| `vm.dirty_background_ratio` | `2` (~1GB on 64GB) | ✅ Optimal |
| `vm.dirty_ratio` | `6` (~4GB on 64GB) | ✅ Optimal |
| `vm.vfs_cache_pressure` | `50` (retain caches) | ✅ Optimal |
| `vm.swappiness` | `60` (balanced with ZRAM) | ✅ Optimal |
| `vm.overcommit_memory` | `0` (heuristic, security) | ✅ Secure |
| `vm.max_map_count` | `16777216` (LLM/VM support) | ✅ Optimal |

### 1.2 Network Performance

| Setting | Value | Status |
|---|---|---|
| `default_qdisc` | `fq` (fair queue, low latency) | ✅ Optimal |
| `tcp_congestion_control` | `cubic` (Fedora default) | ✅ Fair, stable |
| `nf_conntrack_max` | `2,097,152` (P2P, containers) | ✅ Optimal |
| `nf_conntrack_tcp_timeout_established` | `7200` (2h) | ✅ Optimal |
| `netdev_max_backlog` | `16384` | ✅ Optimal |
| `somaxconn` | `8192` | ✅ Optimal |
| `rmem_max` / `wmem_max` | `33554432` (32MB) | ✅ Optimal |
| `tcp_rmem` / `tcp_wmem` | `4096 1048576 33554432` | ✅ Auto-tuned |
| `tcp_mtu_probing` | `1` (PLPMTUD) | ✅ Black hole detection |
| `tcp_keepalive_time` | `600` (10min) | ✅ Optimal |
| `udp_rmem_min` | `8192` (8KB) | ✅ QUIC/uTP performance |

### 1.3 I/O & Storage

| Setting | Value | Status |
|---|---|---|
| Dracut compression | `zstd` | ✅ 30-40% faster than gzip |
| Early microcode | `yes` | ✅ Critical for AMD Ryzen |
| Hostonly | `no` | ✅ Generic for ostree |
| Timeout | `15s` | ✅ NVMe-tuned |
| Composefs | `enabled = yes` + fs-verity | ✅ Image integrity |
| BTRFS NoCOW (system) | `/var/lib/libvirt/images`, `/var/lib/containers/storage/volumes` | ✅ Optimal |
| BTRFS NoCOW (user) | `~/.local/share/libvirt/images`, `~/.local/share/gnome-boxes/images`, `~/.local/share/containers/storage/volumes`, `~/.cache/rclone` | ✅ Optimal |

### 1.4 System Limits

| Setting | Value | Status |
|---|---|---|
| `fs.file-max` | `2097152` | ✅ Containers/DBs |
| `fs.inotify.max_user_instances` | `8192` | ✅ Dev containers |
| `fs.inotify.max_user_watches` | `1048576` | ✅ Large projects |

### 1.5 Journal

| Setting | Value | Status |
|---|---|---|
| SystemMaxUse | `500M` | ✅ Reasonable |
| SystemKeepFree | `2G` | ✅ Safe |
| MaxRetentionSec | `1month` | ✅ Adequate history |

---

## 2. Re-Evaluation Triggers

| Trigger | Action |
|---|---|
| BBRv3 lands in mainline kernel | Evaluate `tcp_congestion_control = bbr` with BBRv3 |
| Kernel 6.20+ releases | Re-evaluate all sysctl parameters against new defaults |
| ZSTD compression improvements | Review ZRAM compression algorithm choice |
| User workload changes | Adjust `vm.max_map_count`, dirty ratios accordingly |
| Hardware changes (RAM upgrade/downgrade) | Scale ZRAM cap, dirty ratios, swappiness |

---

## 3. Scaling for Lower-Spec Hardware

See `agent/context/ENVIRONMENT.md` §Hardware Target for minimum requirements.

**32 GB RAM override:**
```ini
vm.dirty_background_ratio = 3
vm.dirty_ratio = 10
vm.swappiness = 60
vm.vfs_cache_pressure = 100
```

**16 GB RAM (not recommended):**
```ini
vm.dirty_background_ratio = 5
vm.dirty_ratio = 15
vm.swappiness = 50
vm.vfs_cache_pressure = 150
# Reduce ZRAM cap: zram-size = min(ram * 0.5, 8192)
```
