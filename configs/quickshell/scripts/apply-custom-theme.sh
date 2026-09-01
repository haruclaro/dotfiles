#!/bin/bash
# ~/.config/quickshell/scripts/apply-custom-theme.sh
#
# Generaliza a lógica do trocar_tema.sh (que só tinha "retro"/"doomer"
# fixos) pra aceitar QUALQUER esquema de cores + wallpaper, criado pelo
# módulo "criador de temas" do Quickshell.
#
# Uso:
#   apply-custom-theme.sh <nome> <fundo> <superficie> <base> <destaque1> <destaque2> <texto> <wallpaper>
#   (as 6 cores em hex SEM o "#", ex: 1E1726)
#
# Efeitos (iguais ao trocar_tema.sh original):
#   1. Escreve ~/.config/quickshell/theme-colors.json (o Colors.qml do
#      Quickshell lê e recarrega sozinho, sem precisar reiniciar nada).
#   2. Escreve ~/.config/hypr/colors.conf (pras cores do Hyprland).
#   3. Escreve ~/.config/hypr/hyprpaper.conf com o wallpaper escolhido,
#      pra TODOS os monitores conectados no momento (via hyprctl monitors).
#   4. Gera um tema do Vicinae com o mesmo esquema e ativa ele.

set -e

NAME="$1"
FUNDO="$2"
SUPERFICIE="$3"
BASE="$4"
DESTAQUE1="$5"
DESTAQUE2="$6"
TEXTO="$7"
WALLPAPER="$8"

if [ -z "$NAME" ] || [ -z "$FUNDO" ] || [ -z "$WALLPAPER" ]; then
    echo "Uso: $0 <nome> <fundo> <superficie> <base> <destaque1> <destaque2> <texto> <wallpaper>" >&2
    exit 1
fi

HYPR_COLORS="$HOME/.config/hypr/colors.conf"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
VICINAE_THEMES_DIR="$HOME/.local/share/vicinae/themes"
QUICKSHELL_COLORS="$HOME/.config/quickshell/theme-colors.json"

echo "Aplicando tema personalizado: $NAME"

# 1. JSON de cores do Quickshell
mkdir -p "$(dirname "$QUICKSHELL_COLORS")"
cat > "$QUICKSHELL_COLORS" <<EOF
{
  "fundo": "$FUNDO",
  "superficie": "$SUPERFICIE",
  "base": "$BASE",
  "destaque1": "$DESTAQUE1",
  "destaque2": "$DESTAQUE2",
  "texto": "$TEXTO"
}
EOF

# 2. Cores do Hyprland
cat > "$HYPR_COLORS" <<EOF
\$fundo = rgb($FUNDO)
\$superficie = rgb($SUPERFICIE)
\$base = rgb($BASE)
\$destaque1 = rgb($DESTAQUE1)
\$destaque2 = rgb($DESTAQUE2)
\$texto = rgb($TEXTO)
EOF

# 3. Hyprpaper — mesmo wallpaper em todos os monitores conectados agora
{
    echo "preload = $WALLPAPER"
    if command -v hyprctl &> /dev/null; then
        hyprctl monitors -j 2>/dev/null | grep -o '"name": *"[^"]*"' | cut -d'"' -f4 | while read -r mon; do
            echo "wallpaper = $mon,$WALLPAPER"
        done
    fi
    echo "splash = false"
} > "$HYPRPAPER_CONF"

# 4. Tema do Vicinae
mkdir -p "$VICINAE_THEMES_DIR"
SLUG=$(echo "$NAME" | tr '[:upper:] ' '[:lower:]-')
VICINAE_THEME_FILE="$VICINAE_THEMES_DIR/$SLUG.toml"

cat > "$VICINAE_THEME_FILE" <<EOF
[meta]
version = 1
name = "$NAME"
description = "Tema \"$NAME\" criado no módulo de temas do Quickshell"
variant = "dark"
inherits = "vicinae-dark"

[colors.core]
background = "#$FUNDO"
foreground = "#$TEXTO"
secondary_background = "#$SUPERFICIE"
border = "#$BASE"
accent = "#$DESTAQUE1"

[colors.accents]
red = "#$DESTAQUE2"
EOF

# 5. Recarrega o que dá pra recarregar sem reiniciar
if command -v hyprctl &> /dev/null; then
    hyprctl hyprpaper unload all 2>/dev/null || true
    hyprctl hyprpaper preload "$WALLPAPER" 2>/dev/null || true
    hyprctl monitors -j 2>/dev/null | grep -o '"name": *"[^"]*"' | cut -d'"' -f4 | while read -r mon; do
        hyprctl hyprpaper wallpaper "$mon,$WALLPAPER" 2>/dev/null || true
    done
fi

if command -v vicinae &> /dev/null; then
    vicinae theme set "$SLUG" 2>/dev/null || true
fi

echo "Tema \"$NAME\" aplicado."
