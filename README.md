# Hyprland Dotfiles & Setup Scripts

This repository contains backup and restore scripts for my Arch Linux Hyprland setup.

## Folders
- `scripts/`: Contains `backup.sh` (run on your current system to update configs) and `install.sh` (run on a fresh Arch installation).
- `configs/`: Contains user-level configurations (copied to `~/.config/`).
- `system/`: Contains system-level themes and settings for GRUB, Plymouth, and SDDM (copied to `/etc/` and `/usr/share/`).

## Installation
1. Install Arch Linux (with git).
2. Clone this repository:
   ```bash
   git clone https://github.com/YOUR-USERNAME/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```
3. Run the installation script:
   ```bash
   ./scripts/install.sh
   ```

## Special Notes
- **Affinity Photo/Designer**: These are Windows-only apps. Consider checking the [AffinityOnLinux project](https://github.com/ryzendew/Linux-Affinity-Installer) for a setup script using Wine.
- **Radmin VPN**: Officially Windows only. For Linux, you could use alternatives like `zerotier` or `tailscale`.
- **Foundry VTT**: Requires a manual installation with your licensed ZIP file. You can use the `foundryvtt` package from the AUR once you download the ZIP.
