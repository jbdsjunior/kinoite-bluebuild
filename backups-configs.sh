#!/usr/bin/env bash
set -euo pipefail

# TARGET: Directory structure in your BlueBuild repository
# INFO: This matches the 'files/system' mapping to '/' in common-base.yml
DEST_SKEL="files/system/etc/skel"
DEST_CONFIG_DIR="$DEST_SKEL/.config"
DEST_LOCAL_SHARE_DIR="$DEST_SKEL/.local/share"

# SAFETY: Ensure script is run from the repository root
if [ ! -d "recipes" ]; then
    echo "Error: run this script from the root of your kinoite-bluebuild repository." >&2
    exit 1
fi

# SAFETY: Ensure HOME has a valid KDE config directory
if [ ! -d "$HOME/.config" ]; then
    echo "Error: ~/.config was not found for user '$(id -un)'." >&2
    exit 1
fi

# PREPARATION: Create destination directories for KDE Plasma configs
mkdir -p "$DEST_CONFIG_DIR"
mkdir -p "$DEST_LOCAL_SHARE_DIR/plasma"
mkdir -p "$DEST_LOCAL_SHARE_DIR/konsole"
mkdir -p "$DEST_LOCAL_SHARE_DIR/dolphin"
mkdir -p "$DEST_LOCAL_SHARE_DIR/kxmlgui5"

# CORE: Copy key KDE/Plasma user preferences (KCM + app settings)
# NOTE: This list intentionally includes core Plasma, KWin, input, display,
#       theme/UI behavior, Dolphin and common KDE app preferences.
CONFIG_FILES=(
    # Plasma shell / workspace
    "kdeglobals"
    "plasmarc"
    "plasma-org.kde.plasma.desktop-appletsrc"
    "plasmashellrc"
    "kscreenlockerrc"
    "powermanagementprofilesrc"

    # KWin / compositor / animation behavior
    "kwinrc"
    "kwinrulesrc"

    # Input + keyboard/shortcuts + locale/region
    "kcminputrc"
    "kglobalshortcutsrc"
    "kxkbrc"
    "kcminfo"
    "plasma-localerc"

    # Display and monitor/KScreen state
    "kcmshell5rc"
    "kscreenrc"

    # Dolphin + file manager behavior
    "dolphinrc"
    "baloofilerc"

    # KDE apps and shell integration
    "konsolerc"
    "systemsettingsrc"
    "gtkrc"
)

COPIED_FILES=0
MISSING_FILES=0

for config_file in "${CONFIG_FILES[@]}"; do
    src="$HOME/.config/$config_file"
    dest="$DEST_CONFIG_DIR/$config_file"

    if [ -f "$src" ]; then
        install -m 0644 "$src" "$dest"
        COPIED_FILES=$((COPIED_FILES + 1))
    else
        echo "Notice: skipped missing file $src"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

# ASSETS: Copy custom layouts and theme/app data if they exist
if [ -d "$HOME/.local/share/plasma/layout-templates" ]; then
    rm -rf "$DEST_LOCAL_SHARE_DIR/plasma/layout-templates"
    cp -a "$HOME/.local/share/plasma/layout-templates" "$DEST_LOCAL_SHARE_DIR/plasma/"
fi

if [ -d "$HOME/.local/share/konsole" ]; then
    cp -a "$HOME/.local/share/konsole/." "$DEST_LOCAL_SHARE_DIR/konsole/"
fi

if [ -d "$HOME/.local/share/dolphin" ]; then
    cp -a "$HOME/.local/share/dolphin/." "$DEST_LOCAL_SHARE_DIR/dolphin/"
fi

if [ -d "$HOME/.local/share/kxmlgui5" ]; then
    cp -a "$HOME/.local/share/kxmlgui5/." "$DEST_LOCAL_SHARE_DIR/kxmlgui5/"
fi

# SANITIZATION: Remove absolute paths and user identification
# INFO: Replacing specific home paths with generic markers to improve portability
find "$DEST_CONFIG_DIR" -type f -exec sed -i "s|$HOME|/home/USER_PLACEHOLDER|g" {} +
find "$DEST_CONFIG_DIR" -type f -exec sed -i "s|$(id -un)|USER_PLACEHOLDER|g" {} +

# SUMMARY

echo "KDE Plasma configurations exported to $DEST_SKEL"
echo "Copied files: $COPIED_FILES"
echo "Missing optional files: $MISSING_FILES"
echo "Review $DEST_CONFIG_DIR for sensitive data before committing."
