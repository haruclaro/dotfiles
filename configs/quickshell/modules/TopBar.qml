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
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    anchors.top: true
    implicitHeight: Cfg.Config.barHeight
    implicitWidth: content.implicitWidth + Cfg.Config.contentPadding * 2
    margins.top: Cfg.Config.barMargin
    color: "transparent"

    WlrLayershell.namespace: "quickshell:topbar"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        radius: Cfg.Config.barRadius
        color: Cfg.Colors.bg
        border.color: Cfg.Colors.border
        border.width: 1

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 14

            ResourceIndicator { Layout.alignment: Qt.AlignVCenter }
            ClockWeather { Layout.alignment: Qt.AlignVCenter }
            MediaIndicator { Layout.alignment: Qt.AlignVCenter }
        }
    }
}
