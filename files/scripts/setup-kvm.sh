#!/bin/bash
set -euo pipefail

readonly REQUIRED_GROUPS="libvirt,kvm"
readonly TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

for cmd in sudo usermod stat chattr lsattr systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd not found"; exit 1; }
done

if [ "$TARGET_USER" = "root" ]; then
    echo "Error: Run as regular user, not root."
    exit 1
fi

sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"

if systemctl list-unit-files --quiet virtqemud.socket 2>/dev/null; then
    sudo systemctl restart virtqemud.socket virtnetworkd.socket
fi

echo "KVM setup completed for user: $TARGET_USER"
echo "Note: Please log out and back in for group changes to take effect."
