# Security Audit & Hardening Decisions

This document tracks all security-related configuration decisions, trade-offs, and accepted risks for the kinoite-bluebuild project.

**Last Updated:** 2026-04-05  
**Context:** Trusted home workstation (not roaming laptop, not hostile network environment)

---

## Accepted Risks (Trusted Home Workstation Context)

| Setting | Value | Risk | Justification | Mitigation |
|---------|-------|------|---------------|------------|
| `net.ipv4.ping_group_range` | `0 2147483647` | Any UID can create ICMP raw sockets | Required for rootless container networking (Podman/Distrobox) without sudo | Acceptable for trusted home environment; restrict to specific GID (e.g., `998 998`) in high-security deployments |
| `net.ipv4.tcp_fastopen` | `3` (client+server) | Potential data injection on untrusted networks | Reduced latency for repeat connections; beneficial for LLM API calls and P2P | Disable (`value=0`) when using public Wi-Fi or untrusted networks |
| `LLMNR` | `yes` | LLMNR/NBNS spoofing attacks possible on compromised LAN | Required by spec for "active local discovery (printers, smart TVs, NAS)" | mDNS preferred for modern devices; LLMNR only for legacy Windows/IoT compatibility |
| MAC Randomization | Disabled | Device tracking on public networks | Required for static IP assignment and P2P port forwarding on home network | Enable manually via NetworkManager when traveling: `nmcli connection modify <id> wifi.cloned-mac-address random` |
| DNSOverTLS | `yes` (strict) | DNS resolution can fail if encrypted DNS endpoints are unreachable | Enforces encrypted DNS transport and prevents plaintext fallback | Revert to `opportunistic` only in host-local override under `/etc/systemd/resolved.conf.d/` if reliability issues occur |
| ZRAM Size | 16GB max (25% of 64GB RAM) | Less swap headroom than original 32GB spec | Reduces CPU overhead from zstd compression during LLM workloads | Monitor swap usage; increase if OOM issues occur with large models |

---

## Security Mitigations Enabled

| Feature | Implementation | Coverage | Status |
|---------|----------------|----------|--------|
| **Image Signing** | Cosign + ostree fs-verity | All published images | ✅ Enabled |
| **Kernel Hardening** | `yama.ptrace_scope=1`, `split_lock_mitigate=1` | Runtime process isolation, DoS prevention | ✅ Enabled |
| **Network Hardening** | `tcp_syncookies=1`, `accept_redirects=0` (IPv4/IPv6) | DDoS mitigation, redirect attack prevention | ✅ Enabled |
| **DNS Security** | DNSSEC=yes, DNSOverTLS=yes (strict) | DNS integrity and encrypted transport | ✅ Enabled |
| **DNS Cache Policy** | `Cache=yes`, `MaxCacheSize=16M` | Improves resolver performance while keeping cache growth bounded | ✅ Enabled |
| **Workflow Security** | Least-privilege permissions (`contents: read`), no committed secrets | CI/CD pipeline | ✅ Enabled |
| **Secret Management** | GitHub Secrets only (`SIGNING_SECRET`, registry tokens) | Build-time credentials | ✅ No secrets in repo |
| **ICMP Rate Limiting** | `icmp_ratelimit` (kernel default) | Ping flood mitigation | ✅ Default kernel behavior |
| **Connection Tracking** | `nf_conntrack_max=2097152` | High-connection workload support (P2P, containers) | ✅ Tuned for workload |
| **TIME-WAIT Reuse Policy** | Kernel default (not forced in sysctl) | Avoids cross-version semantic drift in TCP reuse behavior | ✅ Explicitly kept at kernel-managed default |
| **UDP Global Memory Policy** | Kernel default (`udp_mem` not pinned) | Avoids freezing RAM-scaled defaults into static values | ✅ Explicitly kept at kernel-managed default |
| **UDP TX Minimum Knob** | Not set (`udp_wmem_min` omitted) | Avoids carrying no-op sysctls across kernel releases | ✅ Removed (documented upstream as no effect) |

---

## Configuration File Inventory

| File | Purpose | Security Impact |
|------|---------|-----------------|
| `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf` | Kernel parameter tuning | Network hardening, container support |
| `files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf` | DNS configuration | DNSSEC, DoT, local discovery |
| `files/system/usr/lib/dracut/dracut.conf.d/10-compression.conf` | Initramfs configuration | Microcode updates, compression |
| `files/system/usr/lib/ostree/prepare-root.conf` | OSTree composefs validation | Image integrity verification |
| `.github/workflows/*.yml` | CI/CD pipelines | Secret handling, build security |

---

## Rollback Procedures

If a security update causes issues:

### Immediate Rollback (Boot Time)
1. Reboot system
2. Select previous deployment from GRUB menu
3. System boots into last known-good state

### Programmatic Rollback
```bash
# Rollback to previous ostree deployment
sudo bootc rollback

# Or using rpm-ostree (older systems)
sudo rpm-ostree rollback

# Verify rollback status
rpm-ostree status --verbose
```

### Configuration Rollback
```bash
# Restore specific config file from git
cd /var/home/<user>/kinoite-bluebuild
git checkout HEAD -- files/system/usr/lib/sysctl.d/60-kernel-tuning.conf

# Rebuild image or apply config manually
# For sysctl: sudo sysctl -p /usr/lib/sysctl.d/60-kernel-tuning.conf
```

### Report Issues
When reporting security-related issues, include:
- `rpm-ostree status --verbose` output
- Journal logs: `journalctl -b -1` (previous boot) or `journalctl -b` (current)
- Specific configuration file causing issues
- Hardware baseline confirmation (see [`docs/HARDWARE_BASELINE.md`](HARDWARE_BASELINE.md))

---

## Review Schedule

This document MUST be reviewed and updated:
- **Quarterly** (every 3 months) regardless of changes
- **Immediately** when any security-relevant configuration is modified
- **Before** major version bumps or base image changes

Next scheduled review: **2026-07-05**

---

## References

- [Fedora Security Guidelines](https://docs.fedoraproject.org/en-US/fedora/latest/security/)
- [BlueBuild Security Best Practices](https://blue-build.org/learn/security/)
- [systemd-resolved Documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd-resolved.service.html)
- [Kernel Sysctl Parameters](https://www.kernel.org/doc/html/latest/admin-guide/sysctl/)
- [Linux Kernel IP Sysctl Reference](https://docs.kernel.org/networking/ip-sysctl.html)
- [RPM Fusion Repository](https://rpmfusion.org/)

---

## Third-Party Repositories

This project uses **RPM Fusion** (free and non-free) as the primary third-party repository for multimedia codecs, proprietary drivers, and additional packages. The RPM Fusion repositories are enabled by default in `recipes/common-repos.yml`.
