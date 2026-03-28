# Post-Installation, Validation, and Troubleshooting Guide

> Last reviewed: 2026-03-28

Use this runbook after installing the image, after major updates, and whenever runtime troubleshooting is needed.

## Detect Current Image Variant

```bash
rpm-ostree status | grep -E "kinoite-(amd|nvidia)"
```

## Runtime Validation (Common Checks)

```bash
# Update timers
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer
systemctl --user list-timers "topgrade-*.timer"

# Core host daemons
systemctl status firewalld
systemctl status systemd-resolved

# Kernel/swap/network tuning signals
sysctl vm.swappiness vm.max_map_count fs.inotify.max_user_watches net.ipv4.tcp_congestion_control net.ipv4.tcp_keepalive_time
cat /sys/module/zswap/parameters/enabled 2>/dev/null || true

# Kernel arguments baked into deployment
rpm-ostree kargs | tr ' ' '\n' | grep -E "amd_pstate|transparent_hugepage|mitigations|pcie_aspm"

# NetworkManager profile shipped by the image
sudo sed -n '1,120p' /usr/lib/NetworkManager/conf.d/60-home-network.conf

# Rclone/FUSE dependencies expected by user services
rpm -q rclone fuse3
command -v fusermount3
```

## Runtime Validation (Variant-Specific)

### `kinoite-amd`

```bash
vainfo
vulkaninfo --summary
clinfo
```

### `kinoite-nvidia`

```bash
nvidia-smi
sudo nvidia-ctk cdi list 2>/dev/null || echo "CDI not generated yet"
```

## Post-Install Configuration

### Keep User Timers Active Without Graphical Session

```bash
sudo loginctl enable-linger "$USER"
```

### Virtualization (KVM/libvirt and GNOME Boxes)

Run the setup script to configure user groups:

```bash
kinoite-setup-kvm.sh
```

Log out and log back in to refresh `libvirt` and `kvm` group membership.

BTRFS `No_COW` (`+C`) attributes are applied via `systemd-tmpfiles` for:

- `/var/lib/libvirt/images`
- `~/.local/share/libvirt/images`
- `~/.local/share/gnome-boxes/images`

To apply immediately:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

Validation helpers:

```bash
id | grep -E "libvirt|kvm"
lsmod | grep kvm
systemctl status libvirtd
lsattr -d ~/.local/share/gnome-boxes/images
```

### NVIDIA for Containers (CUDA/CDI)

On `kinoite-nvidia`, generate CDI when needed:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
podman run --rm --device nvidia.com/gpu=all nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
```

### NVIDIA and Secure Boot (MOK)

```bash
ujust enroll-secure-boot-key
```

Reboot and complete the MOK enrollment flow in firmware UI.

### Rclone Mount as User Service

The mapping uses a single templated user service with optional environment-specific overrides.

```bash
# 1. Configure remotes (for example: gdrive_personal or onedrive_work)
rclone config

# 2. Optional: create environment file for a specific remote
mkdir -p ~/.config/rclone/env/
echo 'RCLONE_EXTRA_OPTS="--vfs-read-chunk-size 128M --vfs-read-chunk-size-limit off"' > ~/.config/rclone/env/onedrive_work.env

# 3. Enable mappings
systemctl --user enable --now rclone@gdrive_personal.service
systemctl --user enable --now rclone@onedrive_work.service

# Verify status
systemctl --user status rclone@gdrive_personal.service
```

Expected mount path: `~/Cloud/remote-name`.

## Troubleshooting

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

### Optional: Privacy-Hardening Profile (Advanced)

`60-home-network.conf` is the default profile for stable LAN behavior.

If stricter privacy behavior is needed, create a host override:

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

## Optional Manual Update Triggers

```bash
topgrade -cy --skip-notify --only system
topgrade -cy --skip-notify --only flatpak
```
