# Security Audit

## Image Security Posture

### ✅ Strengths

| Area | Status | Details |
|---|---|---|
| **Image Signing** | ✅ Enabled | Cosign signing with key in `cosign.pub` |
| **Composefs** | ✅ Enabled | fs-verity validation in `prepare-root.conf` |
| **SELinux** | ✅ Enforcing | Default on Fedora Atomic |
| **Automatic Updates** | ✅ Configured | Topgrade timers for system, flatpak, bootc |
| **Network Hardening** | ✅ Applied | SYN cookies, no ICMP redirects, IPv6 privacy |
| **Kernel Hardening** | ✅ Applied | ptrace_scope=1, split_lock_mitigate=1 |
| **DNS Security** | ✅ DoT + DNSSEC | Cloudflare with DNS-over-TLS strict mode |
| **No Secrets in Repo** | ✅ Clean | `.gitignore` covers keys, PEM files |

### ⚠️ Accepted Risks (Home Workstation)

| Area | Risk | Rationale |
|---|---|---|
| **Flatpak global overrides** | GPU + IPC access to all flatpaks | Required for multimedia apps; acceptable on trusted workstation |
| **ping_group_range 0-65534** | Broad raw socket access | Needed for rootless containers; restricted from global (0–2³¹) |
| **TCP FastOpen client** | TFO cookie leakage risk | Client-only mode (`tcp_fastopen=1`) mitigates server-side injection |
| **Firewalld** | Default zone may be permissive | Relies on user configuration; consider `FedoraWorkstation` zone |
| **systemd-resolved stub on :53** | Local DNS exposed | Required for system-wide resolution; protected by localhost binding |
| **Rogue RA acceptance** | `accept_ra=0` | Disabled to prevent rogue router advertisement attacks |

### 🔴 Previously Fixed Issues

| Issue | Status | Fix Applied |
|---|---|---|
| `accept_ra = 1` | ✅ Fixed | Changed to `0` (reject unsolicited RAs) |
| `ping_group_range` global | ✅ Fixed | Restricted to `0–65534` from `0–2147483647` |
| `tcp_fastopen = 3` | ✅ Fixed | Changed to `1` (client only) |
| Topgrade timer collisions | ✅ Fixed | Staggered startup times (5m, 15m, 30m) |
| `sudo` in setup-kvm.sh | ✅ Fixed | Script now requires sudo; systemd template service passes `%i` as argument |
| profile.d `return` in `/bin/sh` | ✅ Fixed | Uses `return 0` only (no `exit 0` fallback that could kill parent shell) |

## Audit Checklist

### Image Build

- [x] No hardcoded secrets or credentials
- [x] Repository GPG keys from official sources
- [x] Cosign signing enabled
- [x] Composefs + fs-verity enabled
- [x] Minimal package surface (debloat module)

### Runtime Security

- [x] SELinux enforcing (Fedora default)
- [x] firewalld enabled and active
- [x] Kernel hardening parameters applied
- [x] DNS-over-TLS strict mode
- [x] DNSSEC validation enabled
- [x] ptrace restricted (`yama.ptrace_scope=1`)
- [x] Split-lock mitigation enabled

### Update Security

- [x] Image signature verification available (`--enforce-container-sigpolicy`)
- [x] bootc rollback supported
- [x] Automatic updates staged (not auto-applied)
- [x] Topgrade updates run at low priority with retry logic

## Recommendations for Harder Security Posture

1. **Enable RPMFusion tainted repos** only when needed (currently using negativo17)
2. **Restrict Flatpak overrides** to per-app basis instead of global
3. **Enable `mitigations=auto,nosmt`** if hyperthreading isn't needed
4. **Configure firewalld zone** to `drop` or `block` for external interfaces
5. **Add `auditd`** for syscall monitoring
6. **Enable `systemd.journald` forward to remote syslog** for audit trail
7. **Consider `kernel.dmesg_restrict=1`** to prevent info leakage
