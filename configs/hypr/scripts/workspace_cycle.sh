#!/bin/bash
# ~/.config/hypr/scripts/workspace_cycle.sh
#
# SUPER+left/right usava "workspace, e-1/e+1", que no Hyprland significa
# "relative OPEN workspace" — cicla por workspaces que EXISTEM, não pelos
# que têm janelas. Como todos os workspaces deste config são
# persistent:true, eles existem sempre, mesmo vazios, e por isso o e-1/e+1
# continuava a levar a workspaces vazios.
#
# Este script filtra pelos workspaces do monitor focado que têm pelo menos
# 1 janela (windows > 0) — o mesmo critério que o widget de Workspaces do
# AGS já usa (ws.get_clients().length > 0) — e cicla só entre esses.
#
# Uso: workspace_cycle.sh next|prev

DIR="$1"
if [[ "$DIR" != "next" && "$DIR" != "prev" ]]; then
    echo "Uso: $0 next|prev" >&2
    exit 1
fi

MONITORS_JSON=$(hyprctl monitors -j)
ACTIVE_MON=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused==true) | .id')
CURRENT_WS=$(echo "$MONITORS_JSON" | jq -r '.[] | select(.focused==true) | .activeWorkspace.id')

# Workspaces do monitor focado que têm janelas, ordenados por id
mapfile -t WS_IDS < <(hyprctl workspaces -j | jq -r --argjson mon "$ACTIVE_MON" \
    '[.[] | select(.monitorID==$mon and .windows>0) | .id] | sort | .[]')

COUNT=${#WS_IDS[@]}

# Nenhum workspace com janelas nesse monitor -> não faz nada
if [ "$COUNT" -eq 0 ]; then
    exit 0
fi

# Encontra o índice do workspace atual na lista (pode não estar lá, se o
# workspace atual estiver vazio no momento em que a tecla foi apertada)
IDX=-1
for i in "${!WS_IDS[@]}"; do
    if [ "${WS_IDS[$i]}" == "$CURRENT_WS" ]; then
        IDX=$i
        break
    fi
done

if [ "$IDX" -eq -1 ]; then
    # Workspace atual está vazio (ex: acabaste de fechar a última janela).
    # Vai para o workspace com janelas mais próximo, na direção pedida.
    if [ "$DIR" == "next" ]; then
        for id in "${WS_IDS[@]}"; do
            if [ "$id" -gt "$CURRENT_WS" ]; then
                hyprctl dispatch workspace "$id"
                exit 0
            fi
        done
        hyprctl dispatch workspace "${WS_IDS[0]}"
    else
        for ((i = COUNT - 1; i >= 0; i--)); do
            if [ "${WS_IDS[$i]}" -lt "$CURRENT_WS" ]; then
                hyprctl dispatch workspace "${WS_IDS[$i]}"
                exit 0
            fi
        done
        hyprctl dispatch workspace "${WS_IDS[$((COUNT - 1))]}"
    fi
    exit 0
fi

if [ "$DIR" == "next" ]; then
    NEW_IDX=$((((IDX + 1) % COUNT)))
else
    NEW_IDX=$((((IDX - 1 + COUNT) % COUNT)))
fi

hyprctl dispatch workspace "${WS_IDS[$NEW_IDX]}"