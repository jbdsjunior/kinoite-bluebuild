#!/usr/bin/env bash
set -euo pipefail

# SECURITY: Require root privileges for system-level modifications
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: Execution requires sudo privileges." >&2
    exit 1
fi

TARGET_USER="${1:-${SUDO_USER:-${USER:-$(id -un)}}}"

# CRITICAL FLOW: Prevent root user assignment to unprivileged virtualization groups
if [[ "$TARGET_USER" == "root" ]]; then
    echo "Error: Target user cannot be root." >&2
    exit 1
fi

# CRITICAL FLOW: Fail fast if required binaries are missing
command -v usermod >/dev/null 2>&1 || { echo "Error: usermod not found"; exit 1; }
command -v systemctl >/dev/null 2>&1 || { echo "Error: systemctl not found"; exit 1; }

id "$TARGET_USER" >/dev/null 2>&1 || { echo "Error: User '$TARGET_USER' does not exist."; exit 1; }

usermod -aG libvirt,kvm "$TARGET_USER"

systemctl restart virtqemud.socket 2>/dev/null || true
systemctl restart virtnetworkd.socket 2>/dev/null || true

echo "KVM setup completed for user: $TARGET_USER"