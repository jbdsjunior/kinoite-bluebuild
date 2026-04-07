# Post-Installation Guide (All Variants)

This guide covers shared validation and operational checks for all users.

> **Note for NVIDIA/Hybrid users:** Complete this guide first, then follow [`POST_INSTALL_NVIDIA.md`](POST_INSTALL_NVIDIA.md).

## Post-Install Operations


### Virtualization (KVM/libvirt)

Configure KVM permissions:

### Run setup script from project files
```bash
./files/scripts/setup-kvm.sh
```

Log out and back in to refresh group membership.

Apply BTRFS `No_COW` attributes if needed:

```bash
sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/60-io-tuning-system.conf
```
```bash
systemd-tmpfiles --user --create /usr/share/user-tmpfiles.d/60-io-tuning-user.conf
```

### Rclone Mount (Optional)

### Configure remotes
```bash
rclone config
```
### Enable user service
```bash
systemctl --user enable --now rclone@gdrive.service
```
### Enable user service
```bash
systemctl --user enable --now rclone@onedrive.service
```

### Inspect Configuration Changes

View modified system config files:

```bash
sudo ostree admin config-diff
```
## Core Runtime Validation

```bash
# Update timers
systemctl --user status topgrade-system-update.timer
systemctl --user status topgrade-boot-update.timer
systemctl --user status topgrade-flatpak-update.timer

# Kernel boot arguments
rpm-ostree kargs 
sudo rpm-ostree kargs --editor
```
