#!/bin/bash
# ~/.config/quickshell/scripts/launch.sh
#
# PEDIDO: usar o DarK-icons (já baixado/extraído em ~/.icons) como tema
# padrão. Como o "//@ pragma IconTheme" só aceita um valor ESTÁTICO,
# continuamos usando QS_ICON_THEME (mesma função, só que dinâmica),
# exportada por este script antes de abrir o `qs`.
#
# Ordem de prioridade: 1) DarK-icons detectado em ~/.icons (o que você
# pediu pra usar como padrão) — 2) nwg-look (gtk-3.0/settings.ini) — 3)
# gsettings — 4) Adwaita como último recurso.
#
# Uso: troca o "exec-once = qs" (ou "quickshell") no teu hyprland.conf por
# "exec-once = ~/.config/quickshell/scripts/launch.sh"

ICONS_DIR="$HOME/.icons"
GTK3_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS="$HOME/.config/gtk-4.0/settings.ini"

# Procura uma pasta de tema de ícone válida (tem index.theme) em ~/.icons
# cujo nome contenha "dark" (sem diferenciar maiúsculas/minúsculas) —
# cobre "DarK", "DarK-svg", "DarK-png", etc, sem depender de saber o nome
# exato da pasta depois da extração.
find_dark_icons() {
    [ -d "$ICONS_DIR" ] || return
    local dir
    for dir in "$ICONS_DIR"/*/; do
        local name
        name=$(basename "$dir")
        if [[ "${name,,}" == *dark* ]] && [ -f "${dir}index.theme" ]; then
            echo "$name"
            return
        fi
    done
}

get_icon_theme() {
    # 1) DarK-icons — prioridade, conforme pedido
    local dark
    dark=$(find_dark_icons)
    if [ -n "$dark" ]; then
        echo "$dark"
        return
    fi

    # 2) gtk-3.0/settings.ini — onde o nwg-look grava por padrão
    if [ -f "$GTK3_SETTINGS" ]; then
        local theme
        theme=$(grep -m1 '^gtk-icon-theme-name' "$GTK3_SETTINGS" | cut -d= -f2 | tr -d '[:space:]')
        if [ -n "$theme" ]; then
            echo "$theme"
            return
        fi
    fi

    # 3) gtk-4.0/settings.ini — fallback, caso só esse exista
    if [ -f "$GTK4_SETTINGS" ]; then
        local theme
        theme=$(grep -m1 '^gtk-icon-theme-name' "$GTK4_SETTINGS" | cut -d= -f2 | tr -d '[:space:]')
        if [ -n "$theme" ]; then
            echo "$theme"
            return
        fi
    fi

    # 4) gsettings — caso o dconf/gsettings-desktop-schemas esteja disponível
    if command -v gsettings &> /dev/null; then
        local theme
        theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'")
        if [ -n "$theme" ] && [ "$theme" != "" ]; then
            echo "$theme"
            return
        fi
    fi

    # 5) Último recurso: Adwaita.
    echo "Adwaita"
}

export QS_ICON_THEME="$(get_icon_theme)"
echo "Quickshell: usando tema de ícones '$QS_ICON_THEME' (via $(basename "$0"))" >&2

exec qs "$@"
