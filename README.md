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
- Automatic updates through `topgrade` user timers with serialized execution and frequent cadences (flatpak: 90 min, system: 3 h, misc/containers: 6 h).
- Kernel/sysctl/network tuning versioned under `files/system`.
- Local development workflow with Distrobox + BlueBuild CLI.

## Image Variants

| Image | Base image | When to use |
| :--- | :--- | :--- |
| `kinoite-amd` | `quay.io/fedora/fedora-kinoite` | AMD hosts without a dedicated NVIDIA GPU. |
| `kinoite-nvidia` | `ghcr.io/ublue-os/kinoite-nvidia` | Hosts with NVIDIA GPU (including AMD + NVIDIA). |

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

Before using signed rebases, ensure your host trust policy is configured for this repository signing key (`cosign.pub`).
If signature verification fails, keep using the unverified image temporarily and validate your host policy/key setup before retrying.

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

Use the common block first, then run only the variant-specific checks for your image.
You can detect your current image with:

```bash
rpm-ostree status | grep -E "kinoite-(amd|nvidia)"
```

### 2.1 Common checks

```bash
# Update timers
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer
systemctl --user list-timers "topgrade-*.timer"

# Core host daemons
systemctl status firewalld
systemctl status systemd-resolved

# Kernel/swap/network tuning signals (Updated for LLM/P2P performance)
sysctl vm.swappiness vm.max_map_count fs.inotify.max_user_watches net.ipv4.tcp_congestion_control net.ipv4.tcp_keepalive_time
cat /sys/module/zswap/parameters/enabled 2>/dev/null || true

# Kernel arguments baked into the deployment
rpm-ostree kargs | tr ' ' '\n' | grep -E "amd_pstate|transparent_hugepage|mitigations|pcie_aspm"

# NetworkManager profile shipped by the image (home-workstation defaults)
sudo sed -n '1,120p' /usr/lib/NetworkManager/conf.d/60-home-network.conf

# Rclone/FUSE dependencies expected by user services
rpm -q rclone fuse3
command -v fusermount3
```

### 2.2 AMD checks (`kinoite-amd`)

```bash
vainfo
vulkaninfo --summary
clinfo
```

### 2.3 NVIDIA checks (`kinoite-nvidia`)

```bash
nvidia-smi
sudo nvidia-ctk cdi list 2>/dev/null || echo "CDI not generated yet"
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

### 3.1 Virtualization (KVM/libvirt & GNOME Boxes)

Run the setup script to configure user groups:

```bash
kinoite-setup-kvm.sh
```

Then log out and log back in to refresh group membership (`libvirt`, `kvm`).

BTRFS `No_COW` (`+C`) attributes are automatically applied to VM image directories (`/var/lib/libvirt/images`, `~/.local/share/libvirt/images`, and `~/.local/share/gnome-boxes/images`) via `systemd-tmpfiles`.

To apply these attributes immediately without rebooting, run:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

Useful checks:

```bash
id | grep -E "libvirt|kvm"
lsmod | grep kvm
systemctl status libvirtd
lsattr -d ~/.local/share/gnome-boxes/images
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

O mapeamento utiliza um serviço unificado que permite a injeção de parâmetros via variáveis de ambiente.

```bash
# 1. Configurar os remotes (ex: 'gdrive_pessoal' ou 'onedrive_work')
rclone config
```

# 2. Opcional: Criar arquivo de ambiente para o OneDrive (otimização de chunks)

mkdir -p ~/.config/rclone/env/
echo 'RCLONE_EXTRA_OPTS="--vfs-read-chunk-size 128M --vfs-read-chunk-size-limit off"' > ~/.config/rclone/env/onedrive_work.env

# 3. Ativar os mapeamentos

systemctl --user enable --now <rclone@gdrive_pessoal.service>
systemctl --user enable --now <rclone@onedrive_work.service>

# Verificar status

systemctl --user status <rclone@gdrive_pessoal.service>

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

### Optional: Enable privacy-hardening profile (advanced)

`60-home-network.conf` is the default profile for stable LAN behavior.
If you need stricter privacy behavior, you can create a host override from the template below:

```bash
sudo install -d -m 0755 /etc/NetworkManager/conf.d
sudo cp /usr/lib/NetworkManager/conf.d/60-privacy-hardening.conf /etc/NetworkManager/conf.d/60-privacy-hardening.conf
sudoedit /etc/NetworkManager/conf.d/60-privacy-hardening.conf
sudo systemctl restart NetworkManager
```

Check active NetworkManager settings:

```bash
sudo NetworkManager --print-config | sed -n '/^\[device\]/,/^$/p;/^\[connection\]/,/^$/p'
```

Rollback to image defaults:

```bash
sudo rm -f /etc/NetworkManager/conf.d/60-privacy-hardening.conf
sudo systemctl restart NetworkManager
```

---

Useful manual checks:

```bash
# Recipe/module references
rg -n "from-file:|source:" recipes/*.yml

# Versioned services and timers
rg --files files/system/usr/lib/systemd | sort

# sysctl and network tuning
rg -n "swappiness|max_map_count|inotify|tcp" files/system/usr/lib/sysctl.d/60-kernel-tuning.conf
rg -n "DNS|privacy|resolved" files/system/usr/lib/systemd/resolved.conf.d/60-dns-overrides.conf files/system/usr/lib/NetworkManager/conf.d/60-home-network.conf files/system/usr/lib/NetworkManager/conf.d/60-privacy-hardening.conf
```

---

## 5) Local Development with Distrobox

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

For full local development and testing details, see `bluebuild/README.md`.

---

## Repository Structure

- `recipes/`: BlueBuild recipes and shared modules.
- `files/system/`: system configuration copied into the final image.
- `files/scripts/`: utilities installed in the image.
- `.github/workflows/`: build pipelines and automation.
