#!/bin/bash
set -euo pipefail

readonly REQUIRED_GROUPS="libvirt,kvm"
# Accept explicit user as $1 (for systemd template %i), fall back to SUDO_USER, USER, or current user
readonly TARGET_USER="${1:-${SUDO_USER:-${USER:-$(id -un)}}}"

if [[ "$TARGET_USER" == "root" ]]; then
    echo "Error: Run as regular user, not root." >&2
    exit 1
fi

# This script must be executed via: sudo setup-kvm.sh
# It performs privileged operations on behalf of the invoking user.
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: This script must be run with sudo." >&2
    echo "Usage: sudo setup-kvm.sh" >&2
    exit 1
fi

for cmd in usermod systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: $cmd not found" >&2
        exit 1
    fi
done

# Add user to required groups
usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"

# Restart libvirt-related sockets/services if they exist
if systemctl is-active --quiet virtqemud.socket 2>/dev/null || \
   systemctl list-unit-files virtqemud.socket 2>/dev/null | grep -q "virtqemud.socket"; then
    systemctl restart virtqemud.socket virtnetworkd.socket 2>/dev/null || true
fi

echo "KVM setup completed for user: $TARGET_USER"
echo "Note: Please log out and back in for group changes to take effect."
