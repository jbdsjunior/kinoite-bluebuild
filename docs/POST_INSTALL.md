# Post-Installation Guide (All Variants)

This guide covers shared validation and operational checks for all users.

> **Note for NVIDIA/Hybrid users:** Complete this guide first, then follow [`POST_INSTALL_NVIDIA.md`](POST_INSTALL_NVIDIA.md).

## 1. Confirm Installed Image Variant

Verify which image variant is active:

```bash
rpm-ostree status | grep -E "kinoite-(amd|nvidia)"
```

## 2. Core Runtime Validation

Run these checks after first boot:

```bash
# Update timers
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer

# Core services
systemctl status firewalld
systemctl status systemd-resolved

# Kernel/network tuning
sysctl vm.swappiness vm.max_map_count fs.inotify.max_user_watches net.ipv4.tcp_congestion_control net.ipv4.tcp_keepalive_time

# Kernel boot arguments
rpm-ostree kargs
```

## 3. Baseline GPU Validation (Mesa/AMD)

*NVIDIA users: run these commands for AMD GPU validation, then proceed to the NVIDIA guide.*

```bash
vainfo
vulkaninfo --summary
clinfo
```

## 4. Post-Install Operations

### Enable User Timers Without Active Session

```bash
sudo loginctl enable-linger "$USER"
```

### Virtualization (KVM/libvirt)

Configure KVM permissions:

```bash
# Run setup script from project files
./files/scripts/setup-kvm.sh
```

Log out and back in to refresh group membership.

Apply BTRFS `No_COW` attributes if needed:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

### Rclone Mount (Optional)

```bash
# Configure remotes
rclone config

# Enable user service
systemctl --user enable --now rclone@<remote-name>.service
```

## 5. Troubleshooting

### Captive Portal (Hotel/Airport Wi-Fi)

If captive portal doesn't open, temporarily disable DoT/DNSSEC:

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/90-captive-portal.conf >/dev/null <<'EOF'
[Resolve]
DNSOverTLS=no
DNSSEC=no
EOF
sudo systemctl restart systemd-resolved
```

Restore defaults after:

```bash
sudo rm -f /etc/systemd/resolved.conf.d/90-captive-portal.conf
sudo systemctl restart systemd-resolved
```

### Inspect Configuration Changes

View modified system config files:

```bash
sudo ostree admin config-diff
```
