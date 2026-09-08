pragma Singleton
import QtQuick
import Quickshell.Io

// Configuração das barras superior/inferior (TopBar/BottomBar), global e
// independente do tema — gravada por scripts/bars_settings.py em
// ~/.config/quickshell/bar-config.json.
//
// Mesmo padrão do Colors.qml: um FileView observa o arquivo
// (watchChanges: true) e as propriedades aqui embaixo são bindings
// declarativos em cima do JSON parseado — reavaliam sozinhos toda vez que
// o arquivo muda (depois de rodar bars_settings.py set <key> <value>),
// sem precisar de nenhum sinal manual. É isso que faz as barras reagirem
// ao vivo.
//
// fallback: valores ausentes caem nos mesmos números que o Config.qml já
// usava (barHeight 34, barRadius 18, barMargin 8, contentPadding 10) e
// nas listas de itens atuais. opacity = null significa "acompanhar o tema"
// (a barra aplica Cfg.Colors.baseOpacity em vez de forçar um valor).
QtObject {
    id: root

    property var cfg: ({})

    property FileView file: FileView {
        path: Qt.resolvedUrl("../bar-config.json")
        watchChanges: true
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                let parsed = JSON.parse(text())
                if (parsed && typeof parsed === "object") {
                    root.cfg = parsed
                }
            } catch(e) {}
        }
        onFileChanged: reload()
    }

    // --- Geometria ---
    readonly property int barHeight: cfg.barHeight !== undefined && cfg.barHeight !== null ? cfg.barHeight : 34
    readonly property int barRadius: cfg.barRadius !== undefined && cfg.barRadius !== null ? cfg.barRadius : 18
    readonly property int barMargin: cfg.barMargin !== undefined && cfg.barMargin !== null ? cfg.barMargin : 8
    readonly property int itemSpacing: cfg.itemSpacing !== undefined && cfg.itemSpacing !== null ? cfg.itemSpacing : 14
    readonly property int contentPadding: cfg.contentPadding !== undefined && cfg.contentPadding !== null ? cfg.contentPadding : 10

    // --- Borda ---
    readonly property bool showBorder: cfg.showBorder !== undefined ? cfg.showBorder : true
    readonly property int borderWidth: cfg.borderWidth !== undefined && cfg.borderWidth !== null ? cfg.borderWidth : 1

    // --- Opacidade por barra (null = seguir o tema) ---
    readonly property var topOpacity: cfg.topOpacity !== undefined ? cfg.topOpacity : null
    readonly property var bottomOpacity: cfg.bottomOpacity !== undefined ? cfg.bottomOpacity : null

    // --- Itens de cada barra ---
    // Guardados como [{id, enabled}, ...] (ordem visual + quem aparece).
    // As barras consomem apenas topEnabledIds/bottomEnabledIds (ids na ordem,
    // filtrando os desligados); a aba de configuração usa o array completo.
    readonly property var topItems: cfg.topItems !== undefined && typeof cfg.topItems === "object" ? cfg.topItems : null
    readonly property var bottomItems: cfg.bottomItems !== undefined && typeof cfg.bottomItems === "object" ? cfg.bottomItems : null

    readonly property var topEnabledIds: {
        const src = topItems
        if (!src) return ["resource", "clock", "media"]
        return src.filter(o => o && o.enabled).map(o => o.id)
    }
    readonly property var bottomEnabledIds: {
        const src = bottomItems
        if (!src) return ["workspaces", "sysmenu", "tray"]
        return src.filter(o => o && o.enabled).map(o => o.id)
    }
}