#!/bin/bash
set -euo pipefail

readonly REQUIRED_GROUPS="libvirt,kvm"
readonly TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

if [[ "$TARGET_USER" == "root" ]]; then
    echo "Error: Run as regular user, not root." >&2
    exit 1
fi

for cmd in usermod systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd not found" >&2
        exit 1
    fi
done

# Add user to required groups
sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"

# Restart libvirt-related sockets/services if they exist
# Use systemctl is-active to check for loaded units
if systemctl is-active --quiet virtqemud.socket 2>/dev/null || \
   systemctl list-unit-files virtqemud.socket 2>/dev/null | grep -q "virtqemud.socket"; then
    sudo systemctl restart virtqemud.socket virtnetworkd.socket 2>/dev/null || true
fi

echo "KVM setup completed for user: $TARGET_USER"
echo "Note: Please log out and back in for group changes to take effect."
