<div align="center">

![Status-Updates](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/check-updates.yml/badge.svg)
![Status-AMD](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-amd.yml/badge.svg)
![Status-NVIDIA](https://github.com/jbdsjunior/kinoite-bluebuild/actions/workflows/build-nvidia.yml/badge.svg)

# Fedora Kinoite Custom (BlueBuild)

</div>

Immutable Fedora Kinoite (KDE Plasma) image built with [BlueBuild](https://blue-build.org/), focused on performance, container-first workflows, automatic updates, and reproducible system tuning.

## Quick Overview

- Ready-to-use variants: `kinoite-amd` and `kinoite-nvidia`.
- Automated build and publishing with GitHub Actions.
- Automatic updates through `topgrade` user timers.
- Kernel/sysctl/network tuning versioned under `files/system`.
- Local development workflow with Distrobox + BlueBuild CLI.

## Image Variants

| Image | Base image | When to use |
| :--- | :--- | :--- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | AMD hosts without a dedicated NVIDIA GPU. |
| `kinoite-nvidia` | `ghcr.io/blue-build/base-images/fedora-kinoite-nvidia` | Hosts with NVIDIA GPU (including AMD + NVIDIA). |

---

## 1) Rebase and Installation

> Recommended flow: **unverified rebase** (first boot) -> **signed rebase** (final state).

### 1.1 Initial Rebase (Unverified)

**AMD**

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-amd:latest
```

**NVIDIA**

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot.

### 1.2 Signed Rebase (Verified)

**AMD**

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-amd:latest
```

**NVIDIA**

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/jbdsjunior/kinoite-nvidia:latest
```

Reboot again.

### 1.3 Operation Commands

```bash
sudo rpm-ostree upgrade
rpm-ostree status | grep -E "kinoite-(amd|nvidia)"
sudo rpm-ostree rollback
```

---

## 2) Quick System Validation (Post-Install)

Use this block to quickly verify expected runtime components:

```bash
# Update timers
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer

# Core host daemons
systemctl status firewalld
systemctl status systemd-resolved

# Kernel/swap/network tuning signals
sysctl vm.swappiness vm.max_map_count fs.inotify.max_user_watches net.ipv4.tcp_congestion_control
cat /sys/module/zswap/parameters/enabled 2>/dev/null || true
```

To keep user timers active even when no graphical session is open:

```bash
sudo loginctl enable-linger "$USER"
```

Optional manual updates:

```bash
topgrade -cy --skip-notify --only system
topgrade -cy --skip-notify --only flatpak
```

---

## 3) Scenario-Based Configuration

### 3.1 Virtualization (KVM/libvirt)

```bash
kinoite-setup-kvm.sh
```

Then log out and log back in to refresh group membership (`libvirt`, `kvm`).

Useful checks:

```bash
id | grep -E "libvirt|kvm"
lsmod | grep kvm
systemctl status libvirtd
```

### 3.2 NVIDIA for Containers (CUDA/CDI)

On `kinoite-nvidia`, generate CDI manually when needed:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### 3.3 NVIDIA + Secure Boot (MOK)

```bash
ujust enroll-secure-boot-key
```

Reboot and complete the MOK enrollment flow in firmware UI.

### 3.4 Rclone Mount as User Service

```bash
rclone config
systemctl --user enable --now rclone-mount@remote-name.service
systemctl --user status rclone-mount@remote-name.service
```

Expected mount path: `~/Cloud/remote-name`.

---

## 4) Quick Troubleshooting

### Captive Portal (Hotel/Airport)

If the portal does not open, temporarily disable DoT/DNSSEC:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/90-captive-portal.conf >/dev/null <<'EOF2'
[Resolve]
DNSOverTLS=no
DNSSEC=no
EOF2
sudo systemctl restart systemd-resolved
```

Restore image defaults:

```bash
sudo rm -f /etc/systemd/resolved.conf.d/90-captive-portal.conf
sudo systemctl restart systemd-resolved
```

---

## 5) Repository Validation (Before Commit/PR)

Local cross-check script (README/recipes/workflows/timers + lint/syntax checks):

```bash
bash scripts/validate-project.sh
```

Useful manual checks:

```bash
# Recipe/module references
rg -n "from-file:|source:" recipes/*.yml

# Versioned services and timers
rg --files files/system/usr/lib/systemd | sort

# sysctl and network tuning
rg -n "swappiness|max_map_count|inotify|tcp" files/system/usr/lib/sysctl.d/60-kernel-tuning.conf
rg -n "DNS|privacy|resolved" files/system/etc/systemd/resolved.conf.d/60-dns-overrides.conf files/system/usr/lib/NetworkManager/conf.d/60-privacy-hardening.conf
```

---

## 6) Local Development with Distrobox

From the repository root:

```bash
distrobox assemble create
distrobox enter bluebuild
```

Inside the `bluebuild` container:

```bash
bluebuild build recipes/recipe-amd.yml
bluebuild build recipes/recipe-nvidia.yml
```

---

## Repository Structure

- `recipes/`: BlueBuild recipes and shared modules.
- `files/system/`: system configuration copied into the final image.
- `files/scripts/`: utilities installed in the image.
- `scripts/validate-project.sh`: local project consistency validation.
- `.github/workflows/`: build pipelines and automation.

## License

Licensed under the **Apache License 2.0**.
