#!/bin/bash

# 1. Pede ao Hyprland para fechar todas as janelas ativas graciosamente
for window in $(hyprctl clients -j | jq -r '.[].address'); do
    hyprctl dispatch closewindow address:$window
done

# 2. Aguarda 2 segundos para dar tempo das animações terminarem 
# e dos programas salvarem seus dados/arquivos
sleep 2

# 3. Executa a ação solicitada
case "$1" in
    "poweroff")
        systemctl poweroff
        ;;
    "reboot")
        systemctl reboot
        ;;
    "logout")
        loginctl terminate-user $USER
        ;;
esac
