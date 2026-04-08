# Security Audit Log — kinoite-bluebuild

**Last Audit:** April 2026
**Kernel Baseline:** 6.19 (Fedora 43)

---

## 1. Changes Applied — April 2026 `/evolve` Cycle

### 1.1 New Sysctl Parameters Added

| Parameter | Value | Source | Rationale |
|---|---|---|---|
| `kernel.sysrq` | `0` | ANSSI-BP-028, CIS Benchmark | Disable Magic SysRq key to prevent unauthorized low-level commands |
| `kernel.perf_event_paranoid` | `2` | CIS Benchmark | Restrict performance events to privileged users (side-channel mitigation) |
| `kernel.randomize_va_space` | `2` | Kernel default, explicit | Full ASLR randomization declaration for audit clarity |
| `net.core.bpf_jit_harden` | `2` | Kernel hardening best practice | Harden BPF JIT against speculative execution attacks |
| `net.ipv4.ip_forward` | `0` | CIS Benchmark | Explicit IP forwarding disable (desktop is not a router) |
| `net.ipv6.conf.all.forwarding` | `0` | CIS Benchmark | Explicit IPv6 forwarding disable |
| `net.ipv6.conf.all.accept_source_route` | `0` | ANSSI-BP-028 | IPv6 source routing firewall bypass prevention |
| `net.ipv6.conf.default.accept_source_route` | `0` | ANSSI-BP-028 | IPv6 source routing default for new interfaces |
| `net.ipv4.tcp_max_syn_backlog` | `2048` | Red Hat networking guide | Increase SYN backlog queue capacity |
| `net.ipv4.tcp_synack_retries` | `2` | Red Hat networking guide | Limit SYN-ACK retransmissions to prevent resource exhaustion |

### 1.2 New Kernel Command-Line Parameters

| Parameter | Source | Rationale |
|---|---|---|
| `init_on_alloc=1` | Kernel hardening best practice | Zero memory on allocation (default in modern kernels, explicit for audit) |
| `init_on_free=1` | Kernel hardening best practice | Zero memory on free (prevents data leakage) |
| `slab_nomerge` | Kernel hardening best practice | Prevent slab cache merging attacks |

### 1.3 Security Documentation Updates

- `docs/SECURITY_AUDIT.md` §3.2: Added `kernel.sysrq`, `kernel.perf_event_paranoid`, `kernel.randomize_va_space`, `net.core.bpf_jit_harden`
- `docs/SECURITY_AUDIT.md` §3.3: Added `net.ipv4.ip_forward`, `tcp_max_syn_backlog`, `tcp_synack_retries`, `tcp_syn_retries`
- `docs/SECURITY_AUDIT.md` §3.4: Added `net.ipv6.conf.all.forwarding`, `accept_source_route` entries
- `docs/SECURITY_AUDIT.md` §4: Updated prohibited configurations with 8 new entries; elevated `tcp_timestamps=0` from "not recommended" to "forbidden" per Red Hat guidance
- `tcp_timestamps` status: Changed to ❌ Forbidden based on Red Hat Enterprise Linux 10 official guidance (PAWS protection, random offset mode `1` recommended)

### 1.4 Findings — No Issues Detected

- No prohibited configurations found in any sysctl, systemd, or YAML files
- All existing security parameters verified against ANSSI-BP-028 and CIS Linux Benchmark
- `debugfs=off` boot parameter explicitly rejected (breaks GPU debugging tools on desktop)
- `random.trust_cpu=off` rejected (increases boot time significantly; marginal security benefit for desktop)

---

## 2. Prohibited Configurations Verification

Scan result: **CLEAN** — No prohibited configurations detected in:
- `files/system/usr/lib/sysctl.d/60-kernel-tuning.conf`
- `recipes/common-kargs.yml`
- `recipes/common-systemd.yml`
- All systemd service/timer files
- All shell scripts

Full prohibited configurations list: `docs/SECURITY_AUDIT.md` §4

---

## 3. Re-Evaluation History

| Date | Trigger | Action Taken |
|---|---|---|
| April 2026 | `/evolve` command | Added 10 new sysctl parameters; added 3 kernel boot args; updated tcp_timestamps posture |
