pragma Singleton
import QtQuick

// CORRIGIDO: este arquivo tinha revertido pra códigos de Nerd Font (de
// uma rodada anterior de debug), mas o resto do projeto
// (SysMenuPopup/MediaPopup/SysMenuGroup/AudioMixerPopup) já esperava os
// nomes de ícone do TEMA do sistema (resolvidos via
// widgets/SymbolicIcon.qml + Quickshell.iconPath(), com o tema escolhido
// por scripts/launch.sh — ver shell.qml). Nomes copiados direto dos
// arquivos .tsx originais do AGS.
QtObject {
    // Sistema / recursos (ResourceMonitor.tsx)
    readonly property string resourceMonitor: "utilities-system-monitor-symbolic"
    readonly property string temperature: "temperature-symbolic"
    readonly property string gpu: "video-display-symbolic"
    readonly property string ram: "drive-multidisk-symbolic"
    readonly property string disk: "drive-harddisk-symbolic"

    // Áudio (AudioMixer.tsx / Bar.tsx)
    readonly property string volumeHigh: "audio-volume-high-symbolic"
    readonly property string volumeMedium: "audio-volume-medium-symbolic"
    readonly property string volumeLow: "audio-volume-low-symbolic"
    readonly property string volumeMuted: "audio-volume-muted-symbolic"

    // Sistema / conectividade (Bar.tsx / SysMenu.tsx)
    readonly property string systemMenu: "open-menu-symbolic"
    readonly property string styleAll: "emblem-system-symbolic"        // engrenagem — lança o StyleAll
    readonly property string wifi: "network-wireless-symbolic"
    readonly property string bluetoothActive: "bluetooth-active-symbolic"
    readonly property string bluetoothDisabled: "bluetooth-disabled-symbolic"
    readonly property string battery: "battery-good-symbolic"
    readonly property string appearance: "preferences-desktop-appearance-symbolic"
    readonly property string preferencesSystem: "preferences-system-symbolic"   // novo — botão de config. Hyprland

    // Energia (SysMenu.tsx)
    readonly property string logout: "system-log-out-symbolic"
    readonly property string reboot: "system-reboot-symbolic"
    readonly property string poweroff: "system-shutdown-symbolic"

    // Mídia (MediaScroller.tsx)
    readonly property string mediaGeneric: "audio-x-generic-symbolic"
    readonly property string mediaPrevious: "media-skip-backward-symbolic"
    readonly property string mediaNext: "media-skip-forward-symbolic"
    readonly property string mediaPlay: "media-playback-start-symbolic"
    readonly property string mediaPause: "media-playback-pause-symbolic"

    // Clima — segue a mesma convenção "symbolic" do resto do tema
    readonly property string weatherClear: "weather-clear-symbolic"
    readonly property string weatherClouds: "weather-few-clouds-symbolic"
    readonly property string weatherRain: "weather-showers-symbolic"
    readonly property string weatherError: "dialog-warning-symbolic"

    // Bandeja recolhida
    readonly property string trayCollapsed: "pan-end-symbolic"   // ">"

    // Módulo novo: criador de temas / config Hyprland
    readonly property string colorPicker: "applications-graphics-symbolic"
    readonly property string wallpaper: "preferences-desktop-wallpaper-symbolic"
}
