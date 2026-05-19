#!/usr/bin/env bash
set -euo pipefail

# TARGET: Directory structure in your BlueBuild repository
# INFO: This matches the 'files/system' mapping to '/' in common-base.yml
DEST_SKEL="files/system/etc/skel"

# SAFETY: Ensure script is run from the repository root
if [ ! -d "recipes" ]; then
    echo "Error: Run this script from the root of your kinoite-bluebuild repository." >&2
    exit 1
fi

# PREPARATION: Create destination directories for KDE Plasma configs
mkdir -p "$DEST_SKEL/.config"
mkdir -p "$DEST_SKEL/.local/share/plasma"
mkdir -p "$DEST_SKEL/.local/share/konsole"

# CORE: Copy specific configuration files managed by KDE System Settings
# kdeglobals: Colors, fonts, and icons
cp "$HOME/.config/kdeglobals" "$DEST_SKEL/.config/"
# plasmarc: Panel positions and general plasma behavior
cp "$HOME/.config/plasmarc" "$DEST_SKEL/.config/"
# kwinrc: Window manager effects and behavior
cp "$HOME/.config/kwinrc" "$DEST_SKEL/.config/"
# kglobalshortcutsrc: Keyboard shortcuts
cp "$HOME/.config/kglobalshortcutsrc" "$DEST_SKEL/.config/"
# plasmashellrc: Backgrounds and shell configuration
cp "$HOME/.config/plasmashellrc" "$DEST_SKEL/.config/"
# kcminputrc: Mouse and keyboard hardware settings
cp "$HOME/.config/kcminputrc" "$DEST_SKEL/.config/"
# kscreenlockerrc: Lock screen settings
cp "$HOME/.config/kscreenlockerrc" "$DEST_SKEL/.config/"
# plasma-org.kde.plasma.desktop-appletsrc: Widget and Panel layout (Critical)
cp "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$DEST_SKEL/.config/"

# ASSETS: Copy custom layouts and themes if they exist
[ -d "$HOME/.local/share/plasma/layout-templates" ] && cp -r "$HOME/.local/share/plasma/layout-templates" "$DEST_SKEL/.local/share/plasma/"
[ -d "$HOME/.local/share/konsole" ] && cp -r "$HOME/.local/share/konsole/." "$DEST_SKEL/.local/share/konsole/"

# SANITIZATION: Remove absolute paths and personal user identification
# INFO: Replacing specific home paths with generic markers to ensure compatibility
find "$DEST_SKEL/.config" -type f -exec sed -i "s|$HOME|/home/USER_PLACEHOLDER|g" {} +
find "$DEST_SKEL/.config" -type f -exec sed -i "s|$(id -un)|USER_PLACEHOLDER|g" {} +

echo "KDE Plasma configurations successfully exported to $DEST_SKEL"
echo "Review the files in $DEST_SKEL/.config for any remaining sensitive data before committing."