# Security Audit Report — kinoite-bluebuild

**Last Audit:** April 2026
**Kernel Baseline:** 6.19 (Fedora 43)
**Reference Standards:** ANSSI-BP-028, Ubuntu Security, CIS Linux Benchmark, Fedora Hardening Guidelines

---

## 1. Scope

This document defines the security baseline for the `kinoite-bluebuild` Fedora Kinoite OCI image. It covers:

- `sysctl` kernel parameters (`files/system/usr/lib/sysctl.d/60-kernel-tuning.conf`)
- Kernel command-line arguments (`recipes/*.yml`)
- Filesystem hardening (BTRFS NoCOW, tmpfiles)
- Network stack security (IPv4/IPv6)
- Container security posture (Podman rootless, eBPF, user namespaces)

All LLM agents operating on this repository **must** reference this document when proposing configuration changes. Any deviation from the baselines below requires explicit justification and user approval.

---

## 2. Threat Model

| Threat Vector                                      | Mitigation                                          | Status      |
| -------------------------------------------------- | --------------------------------------------------- | ----------- |
| Local privilege escalation via /tmp exploits       | `fs.protected_*` sysctls                            | ✅ Enforced |
| Kernel information leakage (dmesg, /proc/kallsyms) | `kernel.dmesg_restrict=1`, `kernel.kptr_restrict=2` | ✅ Enforced |
| eBPF JIT privilege escalation                      | `kernel.unprivileged_bpf_disabled=1`                | ✅ Enforced |
| Container escape via user namespaces               | `kernel.unprivileged_userns_clone=0`                | ✅ Enforced |
| Process injection (ptrace)                         | `kernel.yama.ptrace_scope=1`                        | ✅ Enforced |
| SYN flood DoS                                      | `net.ipv4.tcp_syncookies=1`                         | ✅ Enforced |
| IP spoofing                                        | `rp_filter=1`                                       | ✅ Enforced |
| Route table poisoning (ICMP redirects)             | `accept_redirects=0`, `secure_redirects=0`          | ✅ Enforced |
| Rogue router advertisements (IPv6)                 | `accept_ra=0`                                       | ✅ Enforced |
| Address tracking (IPv6)                            | `use_tempaddr=2` (RFC 4941)                         | ✅ Enforced |
| Split-lock CPU DoS                                 | `kernel.split_lock_mitigate=1`                      | ✅ Enforced |
| Firewall bypass (source routing)                   | `accept_source_route=0`                             | ✅ Enforced |
| Smurf DoS amplification                            | `icmp_echo_ignore_broadcasts=1`                     | ✅ Enforced |
| Core dump data exposure (SUID binaries)            | `fs.suid_dumpable=0`                                | ✅ Enforced |
| OOM-based memory attacks                           | `vm.overcommit_memory=0`                            | ✅ Enforced |

---

## 3. Mandatory sysctl Parameters

The following table is the **authoritative reference** for all kernel parameters. LLM agents must verify every proposed change against this table.

### 3.1 Filesystem Protection

| Parameter                | Value | Rationale                                                                    | Risk if Removed                                  |
| ------------------------ | ----- | ---------------------------------------------------------------------------- | ------------------------------------------------ |
| `fs.protected_symlinks`  | `1`   | Prevents symlink following attacks in sticky-bit directories (e.g., `/tmp`)  | Local privilege escalation via symlink race      |
| `fs.protected_hardlinks` | `1`   | Prevents hardlink creation to files not owned by user in world-writable dirs | Privilege escalation via setuid binary hardlinks |
| `fs.protected_regular`   | `2`   | Prevents file creation in world-writable dirs unless owner of dir or file    | File creation attacks in /tmp, /var/tmp          |
| `fs.protected_fifos`     | `2`   | Prevents FIFO creation in world-writable dirs unless owner of dir or file    | FIFO-based DoS and data interception             |
| `fs.suid_dumpable`       | `0`   | Prevents core dumps from setuid/setgid binaries                              | Memory content exposure (credentials, keys)      |

### 3.2 Kernel Hardening

| Parameter                          | Value | Rationale                                                          | Risk if Removed                                               |
| ---------------------------------- | ----- | ------------------------------------------------------------------ | ------------------------------------------------------------- |
| `kernel.kptr_restrict`             | `2`   | Always hide kernel pointers from non-root users                    | KASLR bypass, kernel exploitation                             |
| `kernel.dmesg_restrict`            | `1`   | Restrict kernel log access to privileged users only                | Hardware/kernel info leakage                                  |
| `kernel.unprivileged_bpf_disabled` | `1`   | Disable unprivileged eBPF program loading                          | eBPF JIT CVEs enable root escalation                          |
| `kernel.unprivileged_userns_clone` | `0`   | Disable unprivileged user namespace creation                       | Container escape, sandbox bypass                              |
| `kernel.split_lock_mitigate`       | `1`   | Mitigate split-lock CPU instruction DoS                            | Local DoS via malicious split-lock instructions               |
| `kernel.yama.ptrace_scope`         | `1`   | Restrict ptrace to parent processes only                           | Process injection, credential theft                           |
| `kernel.sysrq`                     | `0`   | Disable Magic SysRq key to prevent unauthorized low-level commands | Direct hardware access, filesystem remount, process signaling |
| `kernel.perf_event_paranoid`       | `2`   | Restrict performance events to privileged users only               | CPU performance counter side-channel attacks                  |
| `kernel.randomize_va_space`        | `2`   | Full ASLR randomization (64-bit)                                   | Predictable memory layout aids exploitation                   |
| `net.core.bpf_jit_harden`          | `2`   | Harden BPF JIT compiler against speculative execution              | Spectre-class attacks via BPF JIT spraying                    |

> ⚠️ **BBRv1 Congestion Control:** Excluded from the image. BBRv1 has documented fairness issues with mixed RTT flows and deep buffer environments. BBRv2/v3 are not yet in mainline kernel 6.19. **Use `cubic`** (Fedora default). Re-evaluate when BBRv3 is upstreamed to mainline.

### 3.3 Network Security (IPv4)

| Parameter                                    | Value  | Rationale                                              | Risk if Removed                        |
| -------------------------------------------- | ------ | ------------------------------------------------------ | -------------------------------------- |
| `net.ipv4.ip_forward`                        | `0`    | Disable IP packet forwarding (desktop is not a router) | Unintended routing, MITM               |
| `net.ipv4.tcp_syncookies`                    | `1`    | SYN flood mitigation via cryptographic cookies         | SYN flood DoS                          |
| `net.ipv4.tcp_max_syn_backlog`               | `2048` | Increase SYN backlog queue capacity                    | Legitimate connections dropped         |
| `net.ipv4.tcp_synack_retries`                | `2`    | Limit SYN-ACK retransmissions                          | Resource exhaustion via half-open conn |
| `net.ipv4.tcp_syn_retries`                   | `5`    | Kernel default; balance reachability                   | Excessive retries waste resources      |
| `net.ipv4.tcp_rfc1337`                       | `1`    | TIME_WAIT assassination fix (ignore RST in TIME_WAIT)  | Connection hijacking via RST injection |
| `net.ipv4.conf.all.accept_redirects`         | `0`    | Reject ICMP redirects                                  | Route table poisoning, MITM            |
| `net.ipv4.conf.default.accept_redirects`     | `0`    | Default for new interfaces                             | Same as above                          |
| `net.ipv4.conf.all.secure_redirects`         | `0`    | Reject redirects even from known gateways              | Trust boundary violation               |
| `net.ipv4.conf.default.secure_redirects`     | `0`    | Default for new interfaces                             | Same as above                          |
| `net.ipv4.conf.all.send_redirects`           | `0`    | Don't send redirects (desktop is not a router)         | Network topology disclosure            |
| `net.ipv4.conf.default.send_redirects`       | `0`    | Default for new interfaces                             | Same as above                          |
| `net.ipv4.conf.all.accept_source_route`      | `0`    | Reject source-routed packets                           | Firewall bypass                        |
| `net.ipv4.conf.default.accept_source_route`  | `0`    | Default for new interfaces                             | Same as above                          |
| `net.ipv4.conf.all.rp_filter`                | `1`    | Reverse path filtering (strict mode)                   | IP address spoofing                    |
| `net.ipv4.conf.default.rp_filter`            | `1`    | Default for new interfaces                             | Same as above                          |
| `net.ipv4.conf.all.log_martians`             | `1`    | Log packets with impossible addresses                  | Forensic visibility for attacks        |
| `net.ipv4.conf.default.log_martians`         | `1`    | Default for new interfaces                             | Same as above                          |
| `net.ipv4.icmp_echo_ignore_broadcasts`       | `1`    | Ignore broadcast pings                                 | Smurf DoS amplification                |
| `net.ipv4.icmp_ignore_bogus_error_responses` | `1`    | Ignore invalid ICMP errors                             | Log pollution, false diagnostics       |
| `net.ipv4.ip_unprivileged_port_start`        | `1024` | Minimum port for non-root binding                      | Privileged port hijacking              |

### 3.4 Network Security (IPv6)

| Parameter                                   | Value | Rationale                             | Risk if Removed                 |
| ------------------------------------------- | ----- | ------------------------------------- | ------------------------------- |
| `net.ipv6.conf.all.forwarding`              | `0`   | Disable IPv6 forwarding (desktop)     | Unintended routing, MITM        |
| `net.ipv6.conf.all.use_tempaddr`            | `2`   | Prefer temporary addresses (RFC 4941) | Address tracking/fingerprinting |
| `net.ipv6.conf.default.use_tempaddr`        | `2`   | Default for new interfaces            | Same as above                   |
| `net.ipv6.conf.all.accept_ra`               | `0`   | Reject router advertisements          | Rogue RA attacks                |
| `net.ipv6.conf.default.accept_ra`           | `0`   | Default for new interfaces            | Same as above                   |
| `net.ipv6.conf.all.accept_redirects`        | `0`   | Reject ICMPv6 redirects               | Route table poisoning           |
| `net.ipv6.conf.default.accept_redirects`    | `0`   | Default for new interfaces            | Same as above                   |
| `net.ipv6.conf.all.accept_source_route`     | `0`   | Reject IPv6 source-routed packets     | Firewall bypass                 |
| `net.ipv6.conf.default.accept_source_route` | `0`   | Default for new interfaces            | Same as above                   |

### 3.5 Memory & VM

| Parameter                   | Value      | Rationale                             | Risk if Removed                    |
| --------------------------- | ---------- | ------------------------------------- | ---------------------------------- |
| `vm.overcommit_memory`      | `0`        | Heuristic overcommit (kernel default) | OOM-based DoS attacks              |
| `vm.swappiness`             | `60`       | Balanced for 64GB + ZRAM              | Aggressive swap or cache eviction  |
| `vm.page-cluster`           | `0`        | Single-page swap for NVMe latency     | Increased swap latency             |
| `vm.watermark_scale_factor` | `125`      | Page allocation watermark scaling     | kswapd thrashing under load        |
| `vm.dirty_background_ratio` | `2`        | ~1GB background writeback (64GB)      | Excessive dirty memory, I/O stalls |
| `vm.dirty_ratio`            | `6`        | ~4GB blocking writeback (64GB)        | Process blocking on writeback      |
| `vm.vfs_cache_pressure`     | `50`       | Retain inode/dentry caches longer     | Excessive inode cache eviction     |
| `vm.max_map_count`          | `16777216` | Support LLM/Java/VM workloads         | Memory mapping exhaustion          |

### 3.6 Network Performance (Non-Security)

| Parameter                                            | Value                   | Rationale                                      | Notes                                 |
| ---------------------------------------------------- | ----------------------- | ---------------------------------------------- | ------------------------------------- |
| `net.core.default_qdisc`                             | `fq`                    | Fair Queue for low-latency interactive traffic | Compatible with Wayland, gaming       |
| `net.ipv4.tcp_congestion_control`                    | `cubic`                 | Fedora default; fair with mixed workloads      | BBRv1 excluded (fairness issues)      |
| `net.netfilter.nf_conntrack_max`                     | `2097152`               | Support P2P, containers, torrents              | Scales for 64GB RAM                   |
| `net.netfilter.nf_conntrack_tcp_timeout_established` | `7200`                  | 2h timeout for established connections         | Prevents premature conntrack eviction |
| `net.core.netdev_max_backlog`                        | `16384`                 | Device queue for burst traffic                 | Prevents packet drops under load      |
| `net.core.somaxconn`                                 | `8192`                  | Socket listen queue                            | Prevents connection drops under load  |
| `net.core.rmem_max`                                  | `33554432`              | 32MB max receive buffer                        | High-throughput connections           |
| `net.core.wmem_max`                                  | `33554432`              | 32MB max send buffer                           | High-throughput connections           |
| `net.core.optmem_max`                                | `1048576`               | 1MB socket option memory                       | Socket ancillary data                 |
| `net.ipv4.tcp_rmem`                                  | `4096 1048576 33554432` | Auto-tuned receive buffer                      | Scales from 4KB to 32MB               |
| `net.ipv4.tcp_wmem`                                  | `4096 1048576 33554432` | Auto-tuned send buffer                         | Scales from 4KB to 32MB               |
| `net.ipv4.tcp_mtu_probing`                           | `1`                     | PLPMTUD for black hole detection               | Fixes PMTUD black holes               |
| `net.ipv4.tcp_keepalive_time`                        | `600`                   | 10min keepalive interval                       | Detect dead connections               |
| `net.ipv4.tcp_keepalive_intvl`                       | `30`                    | 30s keepalive retry interval                   | Fast dead connection cleanup          |
| `net.ipv4.tcp_keepalive_probes`                      | `5`                     | 5 probes before drop                           | 2.5min total dead detection           |
| `net.ipv4.udp_rmem_min`                              | `8192`                  | 8KB min UDP receive buffer                     | uTP/QUIC performance                  |

### 3.7 System Limits

| Parameter                       | Value     | Rationale                           | Notes                          |
| ------------------------------- | --------- | ----------------------------------- | ------------------------------ |
| `fs.file-max`                   | `2097152` | Max file handles for containers/DBs | Prevents fd exhaustion         |
| `fs.inotify.max_user_instances` | `8192`    | Max inotify instances per user      | File watching (dev containers) |
| `fs.inotify.max_user_watches`   | `1048576` | Max inotify watches per instance    | Large project tree monitoring  |

---

## 4. Prohibited Configurations

The following configurations are **explicitly forbidden** in this repository. LLM agents must reject and remove them if encountered:

| Configuration                                   | Status                   | Reason                                                                 |
| ----------------------------------------------- | ------------------------ | ---------------------------------------------------------------------- |
| `net.ipv4.tcp_fastopen`                         | ❌ Removed               | Client-side TFO exposes data patterns on untrusted networks            |
| `net.ipv4.tcp_congestion_control = bbr` (BBRv1) | ❌ Replaced with `cubic` | Known fairness issues; BBRv2/v3 not in mainline 6.19                   |
| `net.ipv4.tcp_timestamps = 0`                   | ❌ Forbidden             | Breaks PAWS; Red Hat recommends `1` (default with random offsets)      |
| `kernel.yama.ptrace_scope = 0`                  | ❌ Forbidden             | Allows unrestricted process injection                                  |
| `net.ipv4.ip_unprivileged_port_start = 0`       | ❌ Forbidden             | Allows non-root binding to privileged ports                            |
| `kernel.dmesg_restrict = 0`                     | ❌ Forbidden             | Exposes kernel internals to unprivileged users                         |
| `kernel.kptr_restrict = 0`                      | ❌ Forbidden             | Exposes kernel pointers (KASLR bypass)                                 |
| `kernel.unprivileged_bpf_disabled = 0`          | ❌ Forbidden             | Enables eBPF privilege escalation vectors                              |
| `kernel.unprivileged_userns_clone = 1`          | ❌ Forbidden             | Enables container escape via user namespaces                           |
| `kernel.sysrq = 1` (or any non-zero)            | ❌ Forbidden             | Enables Magic SysRq direct hardware access                             |
| `kernel.perf_event_paranoid < 2`                | ❌ Forbidden             | Exposes CPU performance counters to side-channel attacks               |
| `net.core.bpf_jit_harden = 0`                   | ❌ Forbidden             | BPF JIT vulnerable to speculative execution attacks                    |
| `vm.overcommit_memory = 1`                      | ❌ Forbidden             | Allows unlimited memory allocation (DoS vector)                        |
| `fs.suid_dumpable = 1` or `2`                   | ❌ Forbidden             | Enables SUID core dumps (credential exposure)                          |
| `net.ipv4.conf.*.accept_redirects = 1`          | ❌ Forbidden             | Enables route table poisoning                                          |
| `net.ipv4.conf.*.accept_source_route = 1`       | ❌ Forbidden             | Enables firewall bypass                                                |
| `net.ipv6.conf.*.accept_source_route = 1`       | ❌ Forbidden             | Enables IPv6 firewall bypass                                           |
| `net.ipv4.ip_forward = 1` (desktop)             | ❌ Forbidden             | Unintended routing on non-router systems                               |
| `net.ipv6.conf.all.forwarding = 1` (desktop)    | ❌ Forbidden             | Unintended IPv6 routing on non-router systems                          |
| `debugfs=off` (boot arg)                        | ⚠️ Not recommended       | Breaks GPU debugging tools (radeontool, nvtop) on desktop              |
| Disabling `kernel.split_lock_mitigate`          | ⚠️ Not recommended       | ~10ms gaming penalty is acceptable; zero-trust requires DoS prevention |

---

## 5. Container Security Posture

### 5.1 Rootless Podman

| Aspect          | Configuration        | Notes                                                                          |
| --------------- | -------------------- | ------------------------------------------------------------------------------ |
| Port binding    | Ports ≥ 1024 only    | `ip_unprivileged_port_start=1024` enforced                                     |
| User namespaces | Disabled system-wide | `unprivileged_userns_clone=0`; rootful Podman required for isolated namespaces |
| Network         | slirp4netns or pasta | No raw socket access required                                                  |

### 5.2 eBPF Restriction

| Aspect           | Configuration                                    | Notes                                                |
| ---------------- | ------------------------------------------------ | ---------------------------------------------------- |
| Unprivileged BPF | Disabled                                         | `unprivileged_bpf_disabled=1`                        |
| Privileged BPF   | Root only                                        | Required for Cilium, Tetragon, network observability |
| Impact           | Some sandbox tools may require rootful execution | Acceptable trade-off for zero-trust                  |

### 5.3 KVM/libvirt

| Aspect            | Configuration          | Notes                                       |
| ----------------- | ---------------------- | ------------------------------------------- |
| AVIC (AMD)        | Disabled               | Kernel 6.16+ still unstable for Windows VMs |
| Group permissions | `libvirt`, `kvm`       | Applied via `setup-kvm.sh`                  |
| Nested virt       | Not enabled by default | Enable only if required                     |

---

## 6. Re-Evaluation Triggers

This document must be revisited when:

| Trigger                        | Action                                             |
| ------------------------------ | -------------------------------------------------- |
| BBRv3 lands in mainline kernel | Evaluate `tcp_congestion_control = bbr` with BBRv3 |
| Kernel 6.18+ releases          | Re-evaluate KVM AVIC stability                     |
| New eBPF CVEs emerge           | Review `unprivileged_bpf_disabled` posture         |
| Fedora changes default sysctls | Align with upstream baseline                       |
| User requests specific tooling | Evaluate security trade-offs case-by-case          |

---

## 7. References

| Source                                                | URL                                                                                                                                                 |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| ANSSI-BP-028 (French ANSSI Linux Hardening Guide)     | https://cyber.gouv.fr/publications/anssi-bp-028                                                                                                     |
| Ubuntu Security — Sysctl Parameters                   | https://documentation.ubuntu.com/security/                                                                                                          |
| Ubuntu Networking Kernel Security Settings            | https://wiki.ubuntu.com/ImprovedNetworking/KernelSecuritySettings                                                                                   |
| Debian Security — Protecting Against Targeted Attacks | https://wiki.debian.org/Security/ProtectingAgainstTargetedAttacks/SecurityConfigsAndLogs                                                            |
| CIS Linux Benchmark                                   | https://www.cisecurity.org/benchmark/distribution_independent_linux                                                                                 |
| Fedora Security Guide                                 | https://docs.fedoraproject.org/en-US/quick-docs/security/                                                                                           |
| Red Hat Enterprise Linux 10 — TCP Timestamps          | https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/network_troubleshooting_and_performance_tuning/benefits-of-tcp-timestamps |
| RFC 4941 — IPv6 Privacy Extensions                    | https://datatracker.ietf.org/doc/html/rfc4941                                                                                                       |
| RFC 1337 — TIME_WAIT Assassination                    | https://datatracker.ietf.org/doc/html/rfc1337                                                                                                       |
| Kernel Documentation (ip-sysctl)                      | https://mjmwired.net/kernel/Documentation/networking/ip-sysctl.rst                                                                                  |
| BBR Congestion Control — ACM Survey 2026              | https://dl.acm.org/doi/10.1145/3793537                                                                                                              |
| BlueBuild Official Documentation                      | https://blue-build.org/                                                                                                                             |
