#!/bin/bash
# Script to backup current dotfiles and customizations

BACKUP_DIR="$(dirname "$(realpath "$0")")/.."
CONFIG_DIR="$BACKUP_DIR/configs"
SYSTEM_DIR="$BACKUP_DIR/system"

echo "Backing up to $BACKUP_DIR"

# Ensure directories exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$SYSTEM_DIR/grub"
mkdir -p "$SYSTEM_DIR/plymouth"
mkdir -p "$SYSTEM_DIR/sddm"

# Backup user configs
echo "Backing up user configs..."
[ -d "$HOME/.config/hypr" ] && cp -r "$HOME/.config/hypr" "$CONFIG_DIR/" || echo "Hyprland config not found."
[ -d "$HOME/.config/quickshell" ] && cp -r "$HOME/.config/quickshell" "$CONFIG_DIR/" || echo "Quickshell config not found."
[ -d "$HOME/.config/Thunar" ] && cp -r "$HOME/.config/Thunar" "$CONFIG_DIR/" || echo "Thunar config not found."
[ -d "$HOME/.config/vicinae" ] && cp -r "$HOME/.config/vicinae" "$CONFIG_DIR/" || echo "Vicinae config not found."
[ -d "$HOME/.config/ghostty" ] && cp -r "$HOME/.config/ghostty" "$CONFIG_DIR/" || echo "Ghostty config not found."

# Backup system customizations (requires sudo for read if permissions are strict, but usually readable)
echo "Backing up system customizations..."

# GRUB
if [ -f "/etc/default/grub" ]; then
    cp "/etc/default/grub" "$SYSTEM_DIR/grub/"
    # Try to find the theme
    THEME_PATH=$(grep "^GRUB_THEME=" "/etc/default/grub" | cut -d'"' -f2)
    if [ -n "$THEME_PATH" ]; then
        THEME_DIR=$(dirname "$THEME_PATH")
        if [ -d "$THEME_DIR" ]; then
            cp -r "$THEME_DIR" "$SYSTEM_DIR/grub/"
            echo "Backed up GRUB theme from $THEME_DIR"
        fi
    fi
fi

# Plymouth
if [ -f "/etc/plymouth/plymouthd.conf" ]; then
    cp "/etc/plymouth/plymouthd.conf" "$SYSTEM_DIR/plymouth/"
    THEME_NAME=$(grep "^Theme=" "/etc/plymouth/plymouthd.conf" | cut -d'=' -f2)
    if [ -n "$THEME_NAME" ]; then
        THEME_DIR="/usr/share/plymouth/themes/$THEME_NAME"
        if [ -d "$THEME_DIR" ]; then
            cp -r "$THEME_DIR" "$SYSTEM_DIR/plymouth/"
            echo "Backed up Plymouth theme $THEME_NAME"
        fi
    fi
fi

# SDDM
if [ -f "/etc/sddm.conf" ]; then
    cp "/etc/sddm.conf" "$SYSTEM_DIR/sddm/"
fi
if [ -d "/etc/sddm.conf.d" ]; then
    cp -r "/etc/sddm.conf.d" "$SYSTEM_DIR/sddm/"
fi

# Try to find SDDM themes in conf files
SDDM_THEMES=$(grep -h "^Current=" "$SYSTEM_DIR/sddm/"sddm.conf "$SYSTEM_DIR/sddm/"sddm.conf.d/* 2>/dev/null | cut -d'=' -f2)
for theme in $SDDM_THEMES; do
    THEME_DIR="/usr/share/sddm/themes/$theme"
    if [ -d "$THEME_DIR" ]; then
        cp -r "$THEME_DIR" "$SYSTEM_DIR/sddm/"
        echo "Backed up SDDM theme $theme"
    fi
done

echo "Backup complete! You can now commit this directory to a git repository."
