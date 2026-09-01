#!/bin/bash

# weather-set-city.sh
# Abre um prompt pra digitar a cidade correta na hora, sem editar nenhum
# arquivo. Chamado a partir do clique-direito no widget de clima.
#
# Ordem de preferência dos launchers:
#   1) zenity  -> caixa de diálogo simples, funciona sempre
#   2) wofi    -> precisa de --exec-search pra aceitar texto livre
#   3) rofi    -> modo -dmenu clássico

# CORRIGIDO: caminho atualizado de ~/.config/ags/scripts (não existe mais)
# pra ~/.config/quickshell/scripts, seguindo a migração pro Quickshell.
WEATHER_SCRIPT="$HOME/.config/quickshell/scripts/weather.sh"
PROMPT="Cidade (formato: Cidade,CC — ex: São Leopoldo,BR)"

if command -v zenity >/dev/null 2>&1; then
    CITY_INPUT=$(zenity --entry --title="Localização" --text="$PROMPT")
elif command -v wofi >/dev/null 2>&1; then
    CITY_INPUT=$(printf "" | wofi --dmenu --exec-search --prompt "$PROMPT")
elif command -v rofi >/dev/null 2>&1; then
    CITY_INPUT=$(rofi -dmenu -p "$PROMPT" -lines 0)
else
    notify-send "Weather" "Nenhum launcher (zenity/wofi/rofi) encontrado" 2>/dev/null
    exit 1
fi

if [ -z "$CITY_INPUT" ]; then
    exit 0
fi

bash "$WEATHER_SCRIPT" set "$CITY_INPUT"
