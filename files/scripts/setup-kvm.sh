#!/bin/bash
set -euo pipefail

readonly REQUIRED_GROUPS="libvirt,kvm"
readonly TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

# Error handling function
error_exit() {
    echo "Error: $1" >&2
    exit "${2:-1}"
}

# Trap for cleanup on error
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "Script failed at line $1 with exit code $exit_code" >&2
    fi
}
trap 'cleanup ${LINENO}' ERR

if [[ "$TARGET_USER" == "root" ]]; then
    error_exit "Run as regular user, not root." 1
fi

for cmd in usermod systemctl; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        error_exit "$cmd not found" 1
    fi
done

# Verify required groups exist
for group in libvirt kvm; do
    if ! getent group "$group" >/dev/null 2>&1; then
        error_exit "Group '$group' does not exist. Ensure libvirt is installed first." 1
    fi
done

# Add user to groups with error checking
if ! sudo usermod -aG "$REQUIRED_GROUPS" "$TARGET_USER"; then
    error_exit "Failed to add user to groups: $REQUIRED_GROUPS" 1
fi

# Restart libvirt sockets if available
if systemctl list-unit-files --quiet virtqemud.socket 2>/dev/null; then
    if ! sudo systemctl restart virtqemud.socket virtnetworkd.socket; then
        echo "Warning: Failed to restart libvirt sockets" >&2
    fi
fi

echo "KVM setup completed for user: $TARGET_USER"
echo "Note: Please log out and back in for group changes to take effect."
