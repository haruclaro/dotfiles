# 🌸 Haru Shell

Bem-vindo ao **Haru Shell**! Uma interface de desktop moderna, dinâmica e totalmente modular baseada em Quickshell e Wayland (Hyprland).

O Haru Shell não é apenas um painel, é um ambiente completo com painéis, menus, criador de temas ao vivo e monitoramento profundo do seu hardware.

## ✨ Features

- 🎨 **Criação de Temas ao Vivo**: Um motor próprio (`aplicar_tema.py`) que gera e aplica paletas de cores instantaneamente em todo o sistema (Quickshell, Hyprland, Kitty) sem precisar reiniciar.
- 🖼️ **Wallpaper Dinâmico**: Integração nativa e à prova de falhas com o \`hyprpaper\`.
- 📊 **Monitoramento de Hardware Avançado**: Métricas em tempo real (CPU, RAM, GPU, Discos em decimais) que mudam de cor dinamicamente com base no estresse geral do sistema.
- 📅 **Widgets e Popups Inovadores**: Calendário com sistema de pins, reprodutor de mídia ancorado e clima preciso em tempo real.
- ⚙️ **Configurações Centralizadas**: Uma UI linda e nativa para gerenciar as preferências do Shell.

## 🚀 Instalação

Certifique-se de ter as seguintes dependências instaladas no seu sistema:
\`quickshell\`, \`hyprpaper\`, \`jq\`, \`python3\`

Clone ou copie esta pasta para \`~/.config/quickshell\` e rode o script de instalação:

\`\`\`bash
cd ~/.config/quickshell
./install.sh
\`\`\`

Para carregar o Haru Shell junto com o seu gerenciador de janelas, adicione no seu \`~/.config/hypr/hyprland.conf\`:

\`\`\`ini
exec-once = ~/.config/quickshell/scripts/launch.sh
\`\`\`

## 📂 Estrutura

- **\`core/\` / \`shell.qml\`**: O esqueleto e âncoras principais do Shell.
- **\`popups/\`**: Janelas flutuantes como Configurações, Mixer de Volume e Calendário.
- **\`modules/\`**: Partes fixas da interface (TopBar, BottomBar, Workspaces).
- **\`services/\`**: Sensores que comunicam com o Linux (Clima, Mídia, Recursos).
- **\`scripts/\`**: Automações em Bash/Python que conversam com o resto do sistema operacional.

---
*Criado com orgulho e muito código no Wayland.*
