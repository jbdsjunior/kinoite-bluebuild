#!/usr/bin/env bash
set -euo pipefail

readonly REQUIRED_GROUPS="libvirt,kvm"
TARGET_USER="${1:-${SUDO_USER:-${USER:-$(id -un)}}}"

if [[ "$TARGET_USER" == "root" ]]; then
    echo "Error: Run as regular user, not root." >&2
    exit 1
fi

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

if ! id "$TARGET_USER" >/dev/null 2>&1; then
    echo "Error: User '$TARGET_USER' does not exist." >&2
    exit 1
fi
usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"

if systemctl is-active --quiet virtqemud.socket 2>/dev/null || \
   systemctl list-unit-files virtqemud.socket 2>/dev/null | grep -q "virtqemud.socket"; then
    systemctl restart virtqemud.socket virtnetworkd.socket 2>/dev/null || true
fi

echo "KVM setup completed for user: $TARGET_USER"
echo "Note: Please log out and back in for group changes to take effect."
