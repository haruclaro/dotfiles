pragma Singleton
import QtQuick
import Quickshell.Io

// INTEGRADO: trocar_tema.sh escreve ~/.config/quickshell/theme-colors.json
// (ver scripts/trocar_tema.sh). Este FileView observa o arquivo
// (watchChanges: true) e as cores abaixo são bindings DIRETOS em cima do
// JSON parseado — não passam por nenhuma função "aplicar manualmente"
// disparada por sinal.
//
// CORRIGIDO (tema retro não recarregava a TopBar): a versão anterior lia
// o arquivo dentro de um handler `onLoaded` + `onFileChanged: reload()`
// escritos à mão — não consegui confirmar com certeza que esses sinais
// existem/disparam do jeito que eu esperava nessa versão do Quickshell.
// A doc oficial usa um padrão mais simples e à prova de sinais errados:
// `blockLoading: true` (garante que text() já tem conteúdo pronto pra
// ler) + uma property comum fazendo `JSON.parse(fileView.text())` — como
// é um binding declarativo normal, ele reavalia sozinho toda vez que
// `text()` muda (inclusive quando watchChanges detecta o arquivo mudando
// depois de rodar trocar_tema.sh), sem precisar de nenhum sinal manual.
QtObject {
    id: root

    property FileView themeFile: FileView {
        path: Qt.resolvedUrl("../theme-colors.json")
        watchChanges: true
        blockLoading: true
        printErrors: false
    }

    property var themeJson: {
        try {
            let txt = themeFile.text()
            if (txt) {
                let parsed = JSON.parse(txt)
                if (parsed && typeof parsed === "object") {
                    return parsed
                }
            }
        } catch(e) {}
        return null
    }

    // "fundo/superficie/base/destaque1/destaque2/texto" são os nomes que
    // trocar_tema.sh já usava (ver @define-color no CSS antigo do AGS) —
    // mapeamos pros tokens abaixo em vez de inventar nomes novos no script.
    // Cada cor cai no valor padrão (paleta escura estilo Caelestia) se o
    // JSON ainda não existir ou não tiver aquela chave específica.
    readonly property color bgSolid: themeJson?.fundo ? ("#" + themeJson.fundo) : "#11121a"
    
    // Transparência Dinâmica Baseada em Luminosidade (Inspirado no Caelestia)
    readonly property real bgLuminance: {
        const c = root.bgSolid
        return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b)
    }
    readonly property real baseOpacity: root.bgLuminance > 0.6 ? 0.90 : 0.75
    
    readonly property color bg: Qt.rgba(bgSolid.r, bgSolid.g, bgSolid.b, baseOpacity)
    
    readonly property color bgAltSolid: themeJson?.superficie ? ("#" + themeJson.superficie) : "#1a1c2b"
    readonly property color bgAlt: Qt.rgba(bgAltSolid.r, bgAltSolid.g, bgAltSolid.b, baseOpacity + 0.05)
    
    readonly property color bgElevatedSolid: themeJson?.superficie ? ("#" + themeJson.superficie) : "#20222f"
    readonly property color bgElevated: Qt.rgba(bgElevatedSolid.r, bgElevatedSolid.g, bgElevatedSolid.b, baseOpacity + 0.10)
    
    readonly property color text: themeJson?.texto ? ("#" + themeJson.texto) : "#cad3f5"
    readonly property color subtext: themeJson?.texto ? ("#" + themeJson.texto) : "#a5adcb"
    readonly property color dim: "#6e7383"
    readonly property color accent: themeJson?.destaque1 ? ("#" + themeJson.destaque1) : "#8aadf4"
    readonly property color accentDim: Qt.rgba(accent.r, accent.g, accent.b, 0.4)
    readonly property color good: "#a6da95"
    readonly property color warning: "#eed49f"
    readonly property color critical: themeJson?.destaque2 ? ("#" + themeJson.destaque2) : "#ed8796"
    readonly property color border: themeJson?.base ? ("#" + themeJson.base) : "#2c2f42"
    readonly property color divider: themeJson?.base ? ("#" + themeJson.base) : "#2a2c3d"
    
    // Cor de overlay usando luminance para inverter caso seja claro
    readonly property color hoverOverlay: Qt.rgba(root.bgLuminance > 0.6 ? 0 : 1, root.bgLuminance > 0.6 ? 0 : 1, root.bgLuminance > 0.6 ? 0 : 1, 0.1)
    readonly property color pressOverlay: Qt.rgba(root.bgLuminance > 0.6 ? 0 : 1, root.bgLuminance > 0.6 ? 0 : 1, root.bgLuminance > 0.6 ? 0 : 1, 0.2)
    readonly property color shadow: "#00000080"
}
