import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config" as Cfg

// PEDIDO: faixa única contínua, flutuante e centralizada.
//
// CORRIGIDO: a versão anterior tentava simular um "centerbox" (like o
// Bar.tsx antigo) calculando `implicitWidth` manualmente e usando
// `anchors.centerIn` pro grupo do meio + `anchors.left/right` pros outros
// dois — isso dava conta errada sempre que o ResourceIndicator e o
// MediaIndicator tinham larguras diferentes (o Media varia de tamanho
// conforme toca música ou não), afastando o relógio do resource de um
// lado e sobrepondo o clima com o ícone de música do outro.
//
// Como a janela já se auto-dimensiona ao conteúdo (não tem largura fixa
// pra "sobrar espaço" e empurrar algo pra ponta), um RowLayout comum com
// espaçamento fixo entre os grupos resolve isso de forma muito mais
// simples e sem contas manuais.
//
// PERSONALIZÁVEL (aba "Barras" da Central): geometria, borda e opacidade
// vêm de Cfg.BarConfig; os itens visíveis — e a ordem deles — são
// `Cfg.BarConfig.topEnabledIds`. Cada id vira um widget real via
// Repeater + Loader + seleção por componente em root.itemById().
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Cfg.BarConfig.barHeight
    margins.top: Cfg.BarConfig.barMargin
    color: "transparent"

    WlrLayershell.namespace: "quickshell:topbar"
    WlrLayershell.layer: WlrLayer.Top

    // Alfa do fundo: null = segue a transparência que o tema define;
    // caso contrário força o valor escolhido na aba Barras.
    readonly property real barAlpha: {
        const o = Cfg.BarConfig.topOpacity
        if (o === null || o === undefined || o < 0) return Cfg.Colors.baseOpacity
        return o
    }

    // Cada tipo de item, empacotado em Component pra poder ser selecionado
    // por id no itemById(). Components declarados aqui não são criados até
    // que um Loader os carregue.
    Component { id: compResource; ResourceIndicator {} }
    Component { id: compClock; ClockWeather {} }
    Component { id: compMedia; MediaIndicator {} }

    function itemById(id) {
        switch (id) {
            case "resource": return compResource
            case "clock": return compClock
            case "media": return compMedia
            default: return null
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: content.implicitWidth + Cfg.BarConfig.contentPadding * 2
        height: Cfg.BarConfig.barHeight

        radius: Cfg.BarConfig.barRadius
        topLeftRadius: 0
        topRightRadius: 0
        color: Qt.rgba(Cfg.Colors.bgSolid.r, Cfg.Colors.bgSolid.g, Cfg.Colors.bgSolid.b, root.barAlpha)
        border.color: Cfg.Colors.border
        border.width: Cfg.BarConfig.showBorder ? Cfg.BarConfig.borderWidth : 0

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Cfg.BarConfig.itemSpacing

            Repeater {
                model: Cfg.BarConfig.topEnabledIds
                delegate: Loader {
                    Layout.alignment: Qt.AlignVCenter
                    sourceComponent: root.itemById(modelData)
                }
            }
        }
    }
}