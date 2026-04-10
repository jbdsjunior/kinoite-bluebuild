<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable Fedora Kinoite (KDE Plasma) desktop built with [BlueBuild](https://blue-build.org/), focused on performance, automatic updates, and reproducible system tuning.

## Key Features

- **Two variants:** `kinoite-amd` (AMD only) and `kinoite-nvidia` (AMD + NVIDIA hybrid)
- **Cryptographic signing:** Images verified with Cosign
- **Automatic updates:** System, bootloader, and Flatpaks via user-level timers
- **System tuning:** Kernel, sysctl, network, and performance configs versioned under `files/system/`
- **Container-first:** Optimized for Podman, Distrobox, KVM, and local workloads

> ⚠️ **Warning:** This image is optimized for **high-performance workstations with 64 GB RAM**. Use on lower-spec hardware may cause instability. See [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md) for details.

## Image Variants

| Variant          | Base Image                        | Use Case                                                       |
| :--------------- | :-------------------------------- | :------------------------------------------------------------- |
| `kinoite-amd`    | `quay.io/fedora/fedora-kinoite`   | AMD systems without dedicated NVIDIA GPU                       |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | Systems with NVIDIA GPU (including AMD + NVIDIA hybrid setups) |

## Quick Start

### 1. Switch to Custom Image

**AMD variant:**

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest
```

**NVIDIA variant:**

```bash
sudo bootc switch ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot after the rebase completes.

### 2. Verify Signature (Recommended)

After confirming system stability, enable signature verification:

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest
```

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Public verification key is in [`cosign.pub`](cosign.pub).

### 3. Post-Installation

Complete validation steps:

- **All variants:** [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md)

## Emergency Rollback

### Revert to previous deployment

```bash
sudo bootc rollback
```

### Return to stock Fedora Kinoite

```bash
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

For signed rollback:

```bash
sudo bootc switch --enforce-container-sigpolicy quay.io/fedora/fedora-kinoite:latest
```

Reboot after any rollback.

## Security

- ✅ Images cryptographically signed with Cosign
- ✅ Kernel hardening: `ptrace_scope=1`, `split_lock_mitigate=1`, `kptr_restrict=2`, `dmesg_restrict=1`
- ✅ eBPF and user namespace restrictions: `unprivileged_bpf_disabled=1`, `unprivileged_userns_clone=0`
- ✅ Filesystem protection: `protected_symlinks`, `protected_hardlinks`, `protected_regular`, `protected_fifos`, `suid_dumpable=0`
- ✅ Network hardened: `tcp_syncookies`, `tcp_rfc1337`, `rp_filter`, `cubic` congestion (BBRv1 excluded), no ICMP redirects
- ✅ IPv6 privacy: `use_tempaddr=2` (RFC 4941), `accept_ra=0`
- ✅ DNS over TLS + DNSSEC enforced

Full security baseline: [`docs/SECURITY_AUDIT.md`](docs/SECURITY_AUDIT.md)

## Documentation

| Document                                                     | Purpose                                         |
| :----------------------------------------------------------- | :---------------------------------------------- |
| [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md)               | Post-install validation (all variants)          |
| [`docs/HARDWARE_BASELINE.md`](docs/HARDWARE_BASELINE.md)     | Hardware specs, tuning rationale, scaling       |
| [`docs/SECURITY_AUDIT.md`](docs/SECURITY_AUDIT.md)           | Security baseline, threat model, sysctl reference |

## License

This project is licensed under the terms found in [`LICENSE`](LICENSE).
