<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-Dual](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-dual.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable OCI image based on **Fedora Kinoite (latest stable / KDE Plasma 6 / Wayland)**, built with BlueBuild for AMD Zen 3 + RDNA2 workstations, virtualization (KVM), containerized ROCm/HIP AI inference, and DevSecOps workloads.

---

## Overview

| Variant        | Base Image                      | Target                                   | Hardware Baseline                                                    |
| :------------- | :------------------------------ | :--------------------------------------- | :------------------------------------------------------------------- |
| `kinoite-amd`  | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-amd:latest`  | AMD Ryzen 9 5950X + Radeon RX 6600 XT + 64 GB DDR4                   |
| `kinoite-dual` | `quay.io/fedora/fedora-kinoite` | `ghcr.io/jbdsjunior/kinoite-dual:latest` | AMD display (RDNA2) + NVIDIA compute (CUDA/akmods) + 64 GB DDR4      |

> [!WARNING]
> This profile is calibrated for workstations with **64 GB RAM** (32 GB ZRAM `zstd` swap, Btrfs NoCOW rules, and Zen 3/RDNA2 tuning). See [`AGENTS.md`](AGENTS.md) and [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

---

## Quick Start

The deployment uses a two-stage transition: the initial switch bootstraps the system and provisions the Cosign public keys embedded in the custom image; the post-boot switch locks signature verification (`--enforce-container-sigpolicy`) for all subsequent updates.

### 1) Initial Switch (From Stock Fedora Kinoite)

```bash
# AMD-only variant (default)
sudo bootc switch ghcr.io/jbdsjunior/kinoite-amd:latest

# Dual-GPU variant (AMD display + NVIDIA compute)
sudo bootc switch ghcr.io/jbdsjunior/kinoite-dual:latest

systemctl reboot
```

### 2) Enforce Cryptographic Signature Verification (Post-Boot)

After booting into the custom image, lock updates to verified Cosign signatures:

```bash
# AMD-only variant
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-amd:latest

# Dual-GPU variant
sudo bootc switch --enforce-container-sigpolicy ghcr.io/jbdsjunior/kinoite-dual:latest
```

### 3) Post-installation & Maintenance

Run the unified maintenance utility after booting:

```bash
sys-optimize                    # full 8-phase maintenance (root)
sudo kinoite-optimize --audit   # read-only audit of the 7 engineering pillars
```

Full operational guide (partitioning, TPM 2.0 PCR 7 auto-unlock, Rclone FUSE + Google Drive OAuth 2.0, ROCm CDI, and Gigabyte X570 BIOS F39 calibration): [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md).

---

## Rollback and Recovery

```bash
# Atomic rollback to previous deployment
sudo bootc rollback

# Revert to upstream stock Fedora Kinoite
sudo bootc switch quay.io/fedora/fedora-kinoite:latest
```

---

## File Traceability

| Subsystem | Key Files & Implementation Paths | Purpose |
| :--- | :--- | :--- |
| **Recipes & Repositories** | [`recipes/recipe-amd.yml`](recipes/recipe-amd.yml), [`recipes/recipe-dual.yml`](recipes/recipe-dual.yml), [`recipes/common-kargs.yml`](recipes/common-kargs.yml), [`recipes/common-*.yml`](recipes/), [`files/dnf/`](files/dnf/) | BlueBuild OCI recipe orchestrators, declarative bootc kargs, and third-party `.repo` sources (Terra, Tailscale). |
| **Sysctl, ZRAM & TuneD** | [`files/system/usr/lib/sysctl.d/`](files/system/usr/lib/sysctl.d/), [`files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf`](files/system/usr/lib/systemd/zram-generator.conf.d/60-zram-policy.conf), [`files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf`](files/system/usr/lib/tmpfiles.d/60-sysctl-protection.conf), [`files/system/usr/lib/modules-load.d/60-bbr.conf`](files/system/usr/lib/modules-load.d/60-bbr.conf) | TCP BBR congestion control, 32 GB ZRAM `zstd`, kernel panics/REISUB, and TuneD override protection symlinks. |
| **Systemd, Boot & Timers** | [`files/system/usr/lib/systemd/system/`](files/system/usr/lib/systemd/system/), [`files/system/usr/lib/systemd/user/`](files/system/usr/lib/systemd/user/), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-boot-quiet.conf), [`files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf`](files/system/usr/lib/systemd/journald.conf.d/60-journald-resilience.conf) | Idle-priority monotonic update timers, journald flush resilience (30s), silent boot Plymouth handoff, and provisioning. |
| **Storage (Btrfs NoCOW) & Flatpak** | [`files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf`](files/system/usr/lib/tmpfiles.d/60-io-tuning-system.conf), [`files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf`](files/system/usr/share/user-tmpfiles.d/60-io-tuning-user.conf), [`files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf`](files/system/usr/lib/tmpfiles.d/60-flatpak-overrides.conf), [`files/system/usr/share/flatpak/overrides/`](files/system/usr/share/flatpak/overrides/) | Strict non-recursive NoCOW (`+C`) tmpfiles directives for VMs/containers, Rclone cache, WirePlumber state, and Flatpak overrides. |
| **Rclone FUSE & Cloud Storage** | [`files/system/usr/lib/systemd/user/rclone@.service`](files/system/usr/lib/systemd/user/rclone@.service), [`files/system/usr/share/rclone/env/`](files/system/usr/share/rclone/env/), [`files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf`](files/system/usr/share/user-tmpfiles.d/70-rclone-env.conf), [`files/system/etc/xdg/baloofilerc`](files/system/etc/xdg/baloofilerc) | Hardened template unit for Google Drive/OneDrive mounts, VFS full caching, network guards, and Baloo exclusion (`[$ei]`). |
| **Audio PipeWire & Bluetooth** | Native upstream stack, [`recipes/common-drivers.yml`](recipes/common-drivers.yml) (`pipewire-codec-aptx`) | Fedora Kinoite native PipeWire/WirePlumber dynamic quantum graph (32–8192), auto-switching, aptX codec, and SCO Bluetooth call profiles. |
| **GPU IA, Headless Isolation & Limits** | [`files/system/etc/cdi/amdgpu.yaml`](files/system/etc/cdi/amdgpu.yaml), [`files/nvidia/etc/pki/akmods/certs/akmods-ublue.der`](files/nvidia/etc/pki/akmods/certs/akmods-ublue.der), [`files/nvidia/etc/modprobe.d/blacklist-nouveau.conf`](files/nvidia/etc/modprobe.d/blacklist-nouveau.conf), [`files/nvidia/etc/modprobe.d/60-nvidia-headless.conf`](files/nvidia/etc/modprobe.d/60-nvidia-headless.conf), [`files/nvidia/etc/dracut.conf.d/99-nvidia-headless.conf`](files/nvidia/etc/dracut.conf.d/99-nvidia-headless.conf), [`recipes/common-drivers-nvidia.yml`](recipes/common-drivers-nvidia.yml), [`files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf`](files/system/usr/lib/systemd/system.conf.d/60-kinoite-limits.conf), [`files/system/usr/share/browser-configs/chromium-flags.conf`](files/system/usr/share/browser-configs/chromium-flags.conf) | AMD RX 6600 XT primary Wayland/VM display with deterministic CDI; headless NVIDIA compute isolation (`install nvidia_drm /usr/bin/true`, dracut omit) preventing GNOME Boxes EGL collisions; `DefaultLimitMEMLOCK=infinity` for GGUF model mlock. |
| **CLI, Session & Maintenance** | [`files/system/usr/bin/kinoite-optimize`](files/system/usr/bin/kinoite-optimize), [`files/system/usr/bin/kinoite-setup-tpm`](files/system/usr/bin/kinoite-setup-tpm), [`files/system/usr/lib/environment.d/60-kinoite-environment.conf`](files/system/usr/lib/environment.d/60-kinoite-environment.conf), [`files/system/etc/fonts/conf.d/64-font-rendering.conf`](files/system/etc/fonts/conf.d/64-font-rendering.conf), [`files/system/usr/share/starship/starship.toml`](files/system/usr/share/starship/starship.toml) | Canonical 7-pillar audit & optimization CLI (`sys-optimize`), 2FA TPM 2.0 PIN binding (`PCR 7 + 14`), LCD subpixel RGB font rendering, and Fish/Starship prompt. |
| **Security, Polkit & Networking** | [`files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf`](files/system/etc/ssh/sshd_config.d/50-kinoite-hardening.conf), [`files/system/usr/lib/modprobe.d/60-security-blacklist.conf`](files/system/usr/lib/modprobe.d/60-security-blacklist.conf), [`files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf`](files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf), [`files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules`](files/system/usr/share/polkit-1/rules.d/51-kinoite-libvirt.rules), [`files/system/usr/lib/udev/rules.d/70-peripherals.rules`](files/system/usr/lib/udev/rules.d/70-peripherals.rules), [`files/system/usr/lib/firewalld/zones/tailscale.xml`](files/system/usr/lib/firewalld/zones/tailscale.xml) | SSH key-only hardening, CIS kernel module blacklist, DNS-over-TLS (Control D primary + Cloudflare fallback), passwordless libvirt group, and peripheral uaccess rules. |
| **Documentation & CI/CD** | [`AGENTS.md`](AGENTS.md), [`docs/POST_INSTALL.md`](docs/POST_INSTALL.md), [`README.md`](README.md), [`SECURITY.md`](SECURITY.md), [`.github/workflows/`](.github/workflows/), [`.github/dependabot.yml`](.github/dependabot.yml), [`.githooks/commit-msg`](.githooks/commit-msg) | Authoritative invariants, operational post-install manual, Cosign security policy, matrix CI pipelines, weekly Dependabot, and Conventional Commit hook. |

## License

Licensed under [Apache License 2.0](LICENSE).
