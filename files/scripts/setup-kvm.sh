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

sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"

if systemctl list-unit-files --quiet virtqemud.socket 2>/dev/null; then
    sudo systemctl restart virtqemud.socket virtnetworkd.socket
fi

echo "KVM setup completed for user: $TARGET_USER"
echo "Note: Please log out and back in for group changes to take effect."
