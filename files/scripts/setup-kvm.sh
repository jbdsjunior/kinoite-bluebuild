#!/bin/bash
set -euo pipefail

REQUIRED_GROUPS="libvirt,kvm"
SYSTEM_IMAGES_DIR="/var/lib/libvirt/images"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

command -v sudo >/dev/null 2>&1 || exit 1
command -v usermod >/dev/null 2>&1 || exit 1
command -v stat >/dev/null 2>&1 || exit 1
command -v chattr >/dev/null 2>&1 || exit 1
command -v lsattr >/dev/null 2>&1 || exit 1

[ "$TARGET_USER" = "root" ] && { echo "Error: Run as regular user, not root."; exit 1; }

sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"
sudo mkdir -p "$SYSTEM_IMAGES_DIR"

FS_TYPE=$(stat -f -c %T "$SYSTEM_IMAGES_DIR")
if [ "$FS_TYPE" = "btrfs" ]; then
    if ! lsattr -d "$SYSTEM_IMAGES_DIR" 2>/dev/null | grep -q 'C'; then
        sudo chattr +C "$SYSTEM_IMAGES_DIR" || echo "Warning: No_COW failed on $SYSTEM_IMAGES_DIR"
    fi
fi

systemctl list-unit-files | grep -q '^virtqemud\.socket' && sudo systemctl restart virtqemud.socket virtnetworkd.socket || true

echo "KVM setup completed for user: $TARGET_USER"