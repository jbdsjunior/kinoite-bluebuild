#!/bin/bash
set -euo pipefail

CONFIG_PATH="/etc/rpm-ostreed.conf"
STAGE_UPDATE_POLICY="AutomaticUpdatePolicy=stage"
IDLE_EXIT_TIMEOUT_60S="IdleExitTimeout=60"

echo "Configuring rpm-ostreed..."

if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "Error: Configuration file $CONFIG_PATH does not exist."
    exit 1
fi

# Apply automatic update policy and idle timeout settings
sed -i "s/^#*AutomaticUpdatePolicy=.*\$/$STAGE_UPDATE_POLICY/" "$CONFIG_PATH"
sed -i "s/^#*IdleExitTimeout=.*\$/$IDLE_EXIT_TIMEOUT_60S/" "$CONFIG_PATH"

echo "rpm-ostreed configuration applied successfully."
echo "Please restart your system to apply the changes."