#!/bin/bash

# Necessita do pacote 'jq' instalado (sudo pacman -S jq)
# Descobre a classe da janela que está focada agora
ACTIVE_CLASS=$(hyprctl activewindow -j | jq -r '.class')

if [[ "$ACTIVE_CLASS" == "Spotify" ]]; then
    # Se for o Spotify, envia silenciosamente para um workspace especial
    hyprctl dispatch movetoworkspacesilent special:spotify
else
    # Se não for, usa o comando padrão de fechar janela
    hyprctl dispatch killactive
fi