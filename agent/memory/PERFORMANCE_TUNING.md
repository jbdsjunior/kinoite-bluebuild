# Performance Tuning Log — kinoite-bluebuild

**Last Audit:** April 2026
**Hardware Baseline:** AMD Ryzen 9 5950X / 64 GB RAM / 1 TB NVMe

> **Canonical report:** [`docs/PERFORMANCE_TUNING.md`](../../docs/PERFORMANCE_TUNING.md)
> **Architecture decisions:** [`agent/memory/ADRS.md`](./ADRS.md)

## Quick Reference

- **ZRAM:** 50% RAM capped at 32GB, zstd compression, priority 32767
- **Congestion Control:** cubic (BBRv1 excluded — fairness issues)
- **Initramfs:** zstd, early microcode enabled, hostonly=no, 15s timeout
- **Swappiness:** 60 (balance ZRAM + page cache for LLM workloads)
- **Dirty Ratios:** background=2, ratio=6 (~1GB/~4GB on 64GB)

## Change Log

| Date | Changes |
|---|---|
| April 2026 | Baseline established: ZRAM 32GB cap, zstd, cubic, BTRFS NoCOW for VM/container paths, dracut zstd compression |
