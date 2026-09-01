#!/bin/bash
sleep 1

# 1. Mata qualquer portal travado no sistema
killall -q xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal

# 2. Injeta as variáveis de tela na marra
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# 3. Liga os motores manualmente (Bypass do Systemd)
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal-gtk &
sleep 1
/usr/lib/xdg-desktop-portal &