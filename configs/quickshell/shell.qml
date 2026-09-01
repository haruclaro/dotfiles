//@ pragma UseQApplication
import Quickshell
import "./modules" as Modules

// Equivalente ao initWindows() do app.ts antigo: uma TopBar + uma BottomBar
// por monitor conectado, reagindo automaticamente se um monitor for
// plugado/desplugado (Quickshell.screens já é reativo).
//
// PEDIDO: usar o pacote de ícones definido no nwg-look, em vez de forçar
// um tema fixo aqui no código. Como o "//@ pragma IconTheme X" só aceita
// um valor ESTÁTICO (não dá pra ler um arquivo em tempo de execução
// dentro de um pragma), a escolha do tema agora vem da variável de
// ambiente QS_ICON_THEME (que o Quickshell também aceita, com a mesma
// função do pragma) — setada por scripts/launch.sh, que lê o tema real
// configurado pelo nwg-look antes de iniciar o `qs`. Ver esse script e o
// README pra trocar o comando usado pra abrir o Quickshell no
// hyprland.conf.
ShellRoot {
    Variants {
        model: Quickshell.screens
        delegate: Modules.TopBar {}
    }
    Variants {
        model: Quickshell.screens
        delegate: Modules.BottomBar {}
    }

    // Não são por monitor — uma instância só de cada, controlada via IPC:
    //   qs ipc call clipboard toggle
    //   qs ipc call theme toggle
    //   qs ipc call hyprmod toggle
    // (bindar teclas no Hyprland — ver README)
    Modules.ClipboardWindow {}
    Modules.ThemeCreatorWindow {}
    Modules.HyprSettingsWindow {}
    Modules.SettingsWindow {}

    // Toast de notificações (substitui o dunst)
    Modules.NotificationToast {}
}
