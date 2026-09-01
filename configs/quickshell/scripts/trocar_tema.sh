#!/bin/bash

# Caminhos dos arquivos
HYPR_COLORS="$HOME/.config/hypr/colors.conf"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"
VICINAE_THEMES_DIR="$HOME/.local/share/vicinae/themes"

# NOVO (migração AGS -> Quickshell): em vez do colors.css do AGS, geramos
# um JSON simples que o config/Colors.qml do Quickshell já sabe ler
# (FileView com watchChanges: true) — o shell atualiza as cores sozinho,
# sem precisar de "ags request reload-css" nem reiniciar nada.
QUICKSHELL_COLORS="$HOME/.config/quickshell/theme-colors.json"

# Verifica o argumento passado
if [ "$1" == "retro" ]; then
    echo "Aplicando tema: Retro-Futurista 💜"
    FUNDO="1E1726"
    SUPERFICIE="2B2135"
    BASE="514064"
    DESTAQUE1="9A7BB5"
    DESTAQUE2="7BB59A"
    TEXTO="E2DCE8"

    WALL_HDMI="/home/haru/Images/flower_knight.png"
    WALL_DP="/home/haru/Images/flower_knight.png"

elif [ "$1" == "doomer" ]; then
    echo "Aplicando tema: Doomer 🖤"
    FUNDO="0D0D11"
    SUPERFICIE="16161F"
    BASE="282934"
    DESTAQUE1="5E677A"
    DESTAQUE2="5C3F3F"
    TEXTO="A0A8B7"

    WALL_HDMI="/home/haru/Images/doomer.jpeg"
    WALL_DP="/home/haru/Images/doomer.jpeg"

else
    echo "Uso: $0 [retro | doomer]"
    exit 1
fi

# 1. Gerar o JSON de cores do Quickshell
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

# 2. Gerar o arquivo de cores do Hyprland
cat > "$HYPR_COLORS" <<EOF
\$fundo = rgb($FUNDO)
\$superficie = rgb($SUPERFICIE)
\$base = rgb($BASE)
\$destaque1 = rgb($DESTAQUE1)
\$destaque2 = rgb($DESTAQUE2)
\$texto = rgb($TEXTO)
EOF

# 3. Gerar as configurações do Hyprpaper
cat > "$HYPRPAPER_CONF" <<EOF
wallpaper {
    monitor = HDMI-A-1
    path = $WALL_HDMI
    fit_mode = cover
}

wallpaper {
    monitor = DP-1
    path = $WALL_DP
    fit_mode = cover
}

splash = false
EOF

# 4. Gerar o tema do Vicinae com as mesmas cores, e ativá-lo.
mkdir -p "$VICINAE_THEMES_DIR"
VICINAE_THEME_FILE="$VICINAE_THEMES_DIR/$1.toml"

cat > "$VICINAE_THEME_FILE" <<EOF
[meta]
version = 1
name = "$1"
description = "Tema $1 gerado automaticamente por trocar_tema.sh"
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

# 5. Recarregar os programas
echo "Recarregando interfaces..."

# CORRIGIDO: não existe mais "ags request reload-css" — o Quickshell
# detecta a mudança no theme-colors.json sozinho (FileView.watchChanges)
# e recarrega as cores automaticamente, sem esse passo manual.

# Reinicia o Hyprpaper para forçar a leitura do novo arquivo
if command -v hyprctl &> /dev/null; then
    hyprctl hyprpaper preload "$WALL_HDMI"
    hyprctl hyprpaper preload "$WALL_DP"
    hyprctl hyprpaper wallpaper "HDMI-A-1,$WALL_HDMI"
    hyprctl hyprpaper wallpaper "DP-1,$WALL_DP"
else
    echo "Aviso: hyprctl não encontrado para recarregar o papel de parede."
fi

# Ativa o tema recém-gerado no Vicinae via CLI.
if command -v vicinae &> /dev/null; then
    vicinae theme set "$1"
else
    echo "Aviso: comando 'vicinae' não encontrado para trocar o tema do launcher."
fi

echo "Feito! Sistema totalmente transformado."
