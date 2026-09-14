#!/bin/bash
# Haru Shell - Installation Script

echo "🌸 Instalando Haru Shell..."

# Dependências
echo "Verificando dependências..."
for cmd in hyprpaper jq python3; do
    if ! command -v $cmd &> /dev/null; then
        echo "Aviso: Dependência '$cmd' não encontrada. O shell pode não funcionar perfeitamente."
    fi
done

# Permissões
echo "Ajustando permissões dos scripts..."
chmod +x ~/.config/quickshell/scripts/*.sh
chmod +x ~/.config/quickshell/scripts/*.py

# Configuração inicial
if [ ! -f ~/.config/quickshell/theme-colors.json ]; then
    echo "Inicializando cores de tema padrão..."
    echo '{"nome": "Haru Default", "fundo": "0D0D11", "superficie": "16161F", "base": "282934", "destaque1": "5E677A", "destaque2": "5C3F3F", "texto": "A0A8B7", "wallpaper": ""}' > ~/.config/quickshell/theme-colors.json
fi

echo "✅ Haru Shell instalado com sucesso!"
echo "Para iniciar, você pode adicionar a seguinte linha no seu hyprland.conf:"
echo "exec-once = ~/.config/quickshell/scripts/launch.sh"
