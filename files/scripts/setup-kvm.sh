#!/bin/bash
set -euo pipefail

readonly REQUIRED_GROUPS="libvirt,kvm"
readonly SYSTEM_IMAGES_DIR="/var/lib/libvirt/images"
readonly TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

for cmd in sudo usermod stat chattr lsattr systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd not found"; exit 1; }
done

[ "$TARGET_USER" = "root" ] && { echo "Error: Run as regular user, not root."; exit 1; }

sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"
sudo mkdir -p "$SYSTEM_IMAGES_DIR"

if [ "$(stat -f -c %T "$SYSTEM_IMAGES_DIR")" = "btrfs" ]; then
    if ! lsattr -d "$SYSTEM_IMAGES_DIR" 2>/dev/null | grep -q 'C'; then
        sudo chattr +C "$SYSTEM_IMAGES_DIR" || echo "Warning: No_COW failed on $SYSTEM_IMAGES_DIR"
    fi
fi

if systemctl list-unit-files --quiet virtqemud.socket 2>/dev/null; then
    sudo systemctl restart virtqemud.socket virtnetworkd.socket
fi

echo "KVM setup completed for user: $TARGET_USER"