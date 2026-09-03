#!/bin/bash
# Script to install packages and restore dotfiles/customizations
# Run this on the new system AFTER cloning your dotfiles repository.

# Make sure we stop on errors
set -e

DOTFILES_DIR="$(dirname "$(realpath "$0")")/.."
CONFIG_DIR="$DOTFILES_DIR/configs"
SYSTEM_DIR="$DOTFILES_DIR/system"

echo "========================================="
echo " Starting Hyprland Post-Install Setup... "
echo "========================================="

# 1. Update system and install base packages
echo "Updating system..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

# 2. Install AUR helper (yay) if not installed
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

# 3. Install required packages
echo "Installing official packages..."
sudo pacman -S --needed --noconfirm discord kdenlive solaar fish plymouth sddm thunar networkmanager network-manager-applet nm-connection-editor bluez bluez-utils blueman linux-headers

echo "Installing AUR packages..."
# Note: foundryvtt requires the license and zip file. It is omitted from the automated list to prevent failure.
# Note: Radmin VPN is not natively available on Linux. Consider alternatives like ZeroTier or Tailscale, or the community wine script (radmin-vpn-linux).
yay -S --needed --noconfirm stremio-enhanced-bin zen-browser-bin spotify vicinae-bin ghostty-git quickshell-git xpadneo-dkms-git

# 4. Restore user dotfiles
echo "Restoring user configurations..."
mkdir -p "$HOME/.config"

for conf in hypr quickshell Thunar vicinae ghostty; do
    if [ -d "$CONFIG_DIR/$conf" ]; then
        echo "Restoring $conf..."
        cp -r "$CONFIG_DIR/$conf" "$HOME/.config/"
    else
        echo "Warning: $conf config not found in backup."
    fi
done

# 5. Restore system customizations
echo "Restoring system customizations (requires sudo)..."

# GRUB
if [ -d "$SYSTEM_DIR/grub" ]; then
    echo "Restoring GRUB config and theme..."
    sudo cp "$SYSTEM_DIR/grub/grub" "/etc/default/grub" 2>/dev/null || true
    
    # Copy any theme directories
    for theme_dir in "$SYSTEM_DIR/grub"/*/; do
        if [ -d "$theme_dir" ]; then
            theme_name=$(basename "$theme_dir")
            sudo mkdir -p "/usr/share/grub/themes"
            sudo cp -r "$theme_dir" "/usr/share/grub/themes/"
        fi
    done
    # Update GRUB
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# Plymouth
if [ -d "$SYSTEM_DIR/plymouth" ]; then
    echo "Restoring Plymouth config and theme..."
    if [ -f "$SYSTEM_DIR/plymouth/plymouthd.conf" ]; then
        sudo cp "$SYSTEM_DIR/plymouth/plymouthd.conf" "/etc/plymouth/"
    fi
    for theme_dir in "$SYSTEM_DIR/plymouth"/*/; do
        if [ -d "$theme_dir" ]; then
            sudo cp -r "$theme_dir" "/usr/share/plymouth/themes/"
        fi
    done
    # Apply plymouth theme changes
    sudo plymouth-set-default-theme -R $(grep "^Theme=" "$SYSTEM_DIR/plymouth/plymouthd.conf" | cut -d'=' -f2) || echo "Plymouth theme update skipped or failed."
fi

# SDDM
if [ -d "$SYSTEM_DIR/sddm" ]; then
    echo "Restoring SDDM config and theme..."
    if [ -f "$SYSTEM_DIR/sddm/sddm.conf" ]; then
        sudo cp "$SYSTEM_DIR/sddm/sddm.conf" "/etc/"
    fi
    if [ -d "$SYSTEM_DIR/sddm/sddm.conf.d" ]; then
        sudo cp -r "$SYSTEM_DIR/sddm/sddm.conf.d" "/etc/"
    fi
    for theme_dir in "$SYSTEM_DIR/sddm"/*/; do
        if [ -d "$theme_dir" ]; then
            sudo cp -r "$theme_dir" "/usr/share/sddm/themes/"
        fi
    done
    
    # Enable SDDM service if not enabled
    sudo systemctl enable sddm.service
fi

echo "Enabling Network and Bluetooth services..."
sudo systemctl enable NetworkManager.service
sudo systemctl enable bluetooth.service

echo "========================================="
echo " Setup complete! "
echo " Please note: "
echo " - Foundry VTT requires manual installation with your licensed zip file."
echo " - Radmin VPN is Windows only. A community port exists but it's recommended to use ZeroTier/Tailscale."
echo " - Affinity Photo/Designer require Wine and manual setup (Check AffinityOnLinux project)."
echo "========================================="
