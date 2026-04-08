# Security Model — kinoite-bluebuild

## Core Security Posture

### Image Integrity
- **Cosign signing:** All images must be signed; public key in `cosign.pub`
- **Composefs + fs-verity:** Enabled in `prepare-root.conf` for image integrity validation
- **No secrets in repo:** No passwords, API keys, private keys, or tokens in version control

### Kernel Hardening (sysctl)
All parameters in `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf` are mandatory.

**Threat Model Coverage:**
| Threat | Mitigation |
|---|---|
| Local privilege escalation (/tmp) | `fs.protected_symlinks=1`, `fs.protected_hardlinks=1`, `fs.protected_regular=2`, `fs.protected_fifos=2` |
| Kernel info leakage | `kernel.dmesg_restrict=1`, `kernel.kptr_restrict=2` |
| eBPF JIT escalation | `kernel.unprivileged_bpf_disabled=1`, `net.core.bpf_jit_harden=2` |
| Container escape | `kernel.unprivileged_userns_clone=0` |
| Process injection | `kernel.yama.ptrace_scope=1` |
| SYN flood | `net.ipv4.tcp_syncookies=1`, `tcp_max_syn_backlog=2048`, `tcp_synack_retries=2` |
| IP spoofing | `rp_filter=1` (strict mode) |
| Route poisoning | `accept_redirects=0`, `secure_redirects=0`, `accept_source_route=0` (IPv4 + IPv6) |
| IPv6 tracking | `use_tempaddr=2` (RFC 4941 privacy extensions) |
| Split-lock DoS | `kernel.split_lock_mitigate=1` |
| SUID dump | `fs.suid_dumpable=0` |
| OOM attacks | `vm.overcommit_memory=0` |
| ASLR bypass | `kernel.randomize_va_space=2` |
| Magic SysRq abuse | `kernel.sysrq=0` |
| Perf side-channel | `kernel.perf_event_paranoid=2` |

### Network Security
- **DNS over TLS:** Strict mode (`DNSOverTLS=yes`) with DNSSEC validation
- **Primary DNS:** Cloudflare (1.1.1.1, 1.0.0.1 + IPv6)
- **No fallback DNS configured** (all fallbacks commented out)
- **mDNS + LLMNR:** Enabled for local device discovery (home/workstation)
- **No BBRv1:** Excluded due to fairness issues; use `cubic`
- **No tcp_fastopen:** Client-side TFO removed (exposes data patterns)
- **No tcp_timestamps=0:** Forbidden — breaks PAWS; use kernel default (random offsets)

### Prohibited Configurations

The following are **explicitly forbidden**. Any change introducing these MUST be rejected:

| Configuration | Status |
|---|---|
| `net.ipv4.tcp_fastopen` | ❌ Removed |
| `tcp_congestion_control = bbr` (BBRv1) | ❌ Replaced with `cubic` |
| `net.ipv4.tcp_timestamps = 0` | ❌ Forbidden |
| `kernel.yama.ptrace_scope = 0` | ❌ Forbidden |
| `net.ipv4.ip_unprivileged_port_start = 0` | ❌ Forbidden |
| `kernel.dmesg_restrict = 0` | ❌ Forbidden |
| `kernel.kptr_restrict = 0` | ❌ Forbidden |
| `kernel.unprivileged_bpf_disabled = 0` | ❌ Forbidden |
| `kernel.unprivileged_userns_clone = 1` | ❌ Forbidden |
| `kernel.sysrq = 1` (or any non-zero) | ❌ Forbidden |
| `kernel.perf_event_paranoid < 2` | ❌ Forbidden |
| `net.core.bpf_jit_harden = 0` | ❌ Forbidden |
| `vm.overcommit_memory = 1` | ❌ Forbidden |
| `fs.suid_dumpable = 1` or `2` | ❌ Forbidden |
| `accept_redirects = 1` (any) | ❌ Forbidden |
| `accept_source_route = 1` (any) | ❌ Forbidden |
| `net.ipv4.ip_forward = 1` (desktop) | ❌ Forbidden |
| `net.ipv6.conf.all.forwarding = 1` (desktop) | ❌ Forbidden |
| `debugfs=off` (boot arg) | ⚠️ Not recommended |
| `kernel.split_lock_mitigate = 0` | ⚠️ Not recommended |

### Container Security
- **Rootless Podman:** Ports ≥ 1024 only; `ip_unprivileged_port_start=1024`
- **User namespaces:** Disabled system-wide; rootful Podman required for isolated namespaces
- **eBPF:** Unprivileged access disabled; privileged BPF requires root

### KVM/libvirt
- **AVIC (AMD):** Disabled (kernel instability for Windows VMs)
- **Nested virt:** Not enabled by default
- **Group permissions:** `libvirt`, `kvm` via `setup-kvm.sh`

### Re-Evaluation Triggers
This security model must be revisited when:
- BBRv3 lands in mainline kernel
- New eBPF CVEs emerge
- Kernel 6.20+ releases
- Fedora changes default sysctls
- CIS Benchmarks receive major updates
- User requests specific tooling requiring security trade-offs

### Reference Standards
- ANSSI-BP-028 (French ANSSI Linux Hardening Guide)
- CIS Linux Benchmark
- Fedora Security Guide
- Red Hat Enterprise Linux 10 — TCP Timestamps guidance
- RFC 4941 — IPv6 Privacy Extensions

Full security baseline: `docs/SECURITY_AUDIT.md`
