#!/bin/bash
# ~/.config/quickshell/scripts/wifi-status.sh
#
# Imprime o SSID da rede Wi-Fi conectada (ou nada, se desconectado).
# Tenta várias fontes em ordem, porque nem todo setup Hyprland usa
# NetworkManager — alguns usam iwd (iwctl) direto, sem nmcli nenhum.

# 1) NetworkManager — "device status" num único comando: já lista TYPE,
# STATE e CONNECTION por dispositivo de uma vez, sem precisar casar o tipo
# da CONEXÃO (que varia bastante entre versões/backends do NM).
if command -v nmcli >/dev/null 2>&1; then
    SSID=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null \
        | awk -F: '$2=="wifi" && $3=="connected" {print $4; exit}')
    if [ -n "$SSID" ]; then
        echo "$SSID"
        exit 0
    fi
fi

# 2) iwd (via iwctl) — comum em setups Hyprland minimalistas sem NetworkManager
if command -v iwctl >/dev/null 2>&1; then
    DEV=$(iwctl device list 2>/dev/null | awk '$0 ~ /station/ {print $2; exit}')
    if [ -n "$DEV" ]; then
        SSID=$(iwctl station "$DEV" show 2>/dev/null | awk -F '  +' '/Connected network/ {print $3}')
        if [ -n "$SSID" ]; then
            echo "$SSID"
            exit 0
        fi
    fi
fi

# 3) wireless-tools (iwgetid) — mais antigo, mas ainda presente em alguns setups
if command -v iwgetid >/dev/null 2>&1; then
    SSID=$(iwgetid -r 2>/dev/null)
    if [ -n "$SSID" ]; then
        echo "$SSID"
        exit 0
    fi
fi

# Nenhuma fonte encontrou uma rede conectada.
exit 0
