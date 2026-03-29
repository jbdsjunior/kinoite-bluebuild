# Post-Installation Guide (All Variants)

This guide is the canonical post-installation reference for the project.
It covers shared validation, operational checks, and baseline post-install tasks for all users.

> **Note for NVIDIA/Hybrid users:** Please complete this general guide first, then apply the specific steps in [`POST_INSTALL_NVIDIA.md`](POST_INSTALL_NVIDIA.md).

## 1) Confirm Installed Image Variant

```bash
rpm-ostree status | grep -E "kinoite-(amd|nvidia)"
```

## 2) Core Runtime Validation

Run this block after first boot and after major updates.

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
```

## 3) Baseline GPU Validation (Mesa/AMD)

*NVIDIA users should run these to validate the integrated/primary AMD GPU, then proceed to the NVIDIA guide for discrete GPU validation.*

```bash
vainfo
vulkaninfo --summary
clinfo
```

## 4) Post-Install Operational Steps

### Keep User Timers Active Without Graphical Session

```bash
sudo loginctl enable-linger "$USER"
```

### Virtualization (KVM/libvirt and GNOME Boxes)

Configure groups:

```bash
kinoite-setup-kvm.sh
```

Log out and log back in to refresh `libvirt` and `kvm` membership.

Apply BTRFS `No_COW` (`+C`) attributes immediately if needed:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

### Rclone Mount as User Service

```bash
# 1. Configure remotes
rclone config

# 2. Optional per-remote environment tuning
mkdir -p ~/.config/rclone/env/
echo 'RCLONE_EXTRA_OPTS="--vfs-read-chunk-size 128M --vfs-read-chunk-size-limit off"' > ~/.config/rclone/env/onedrive_work.env

# 3. Enable mappings
systemctl --user enable --now rclone@onedrive_work.service
```

## 5) Troubleshooting

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

Restore defaults:

```bash
sudo rm -f /etc/systemd/resolved.conf.d/90-captive-portal.conf
sudo systemctl restart systemd-resolved
```
### Inspecting Configuration Changes (`/etc`)

To see which system configuration files have been locally modified or differ from the default base image state, use:

```bash
sudo ostree admin config-diff
