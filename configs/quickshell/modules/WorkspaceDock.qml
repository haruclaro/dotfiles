import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../config" as Cfg
import "../widgets" as Widgets

// PEDIDO: workspaces com janelas ativas SEMPRE visíveis — não recolhe mais
// no hover. Deixou de usar Widgets.Pill (esse comportamento era só disso);
// agora é um Item de conteúdo simples, plugado dentro do fundo único da
// BottomBar, igual como ResourceIndicator/ClockWeather/MediaIndicator já
// funcionam dentro da TopBar.
//
// PEDIDO NOVO: "não segregar por monitor" — antes cada BottomBar (uma por
// tela) só mostrava os workspaces DAQUELE monitor especificamente. Agora
// mostra TODOS os workspaces com janela ativa, de qualquer monitor,
// igual em todas as telas — sem filtro de monitor nenhum.
Item {
    id: root

    readonly property var focusedWs: Hyprland.focusedWorkspace

    readonly property var icons: ({
        1: "一", 2: "二", 3: "三", 4: "四", 5: "五",
        6: "六", 7: "七", 8: "八", 9: "九", 10: "歌",
    })
    readonly property string defaultIcon: "𖡡"

    readonly property var visibleWorkspaces: {
        const list = []
        for (const ws of Hyprland.workspaces.values) {
            if (ws.toplevels.values.length > 0) list.push(ws)
        }
        list.sort((a, b) => a.id - b.id)
        return list
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Repeater {
            model: root.visibleWorkspaces
            delegate: Rectangle {
                id: wsBtn
                required property var modelData
                readonly property bool active: root.focusedWs && root.focusedWs.id === modelData.id

                width: 26; height: 26
                radius: Cfg.Config.chipRadius
                color: active ? Cfg.Colors.accent : (wsHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent")

                Behavior on color { ColorAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }

                Text {
                    anchors.centerIn: parent
                    text: root.icons[wsBtn.modelData.id] ?? root.defaultIcon
                    color: wsBtn.active ? Cfg.Colors.bg : Cfg.Colors.text
                    font.pixelSize: 14
                }

                MouseArea {
                    id: wsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: wsBtn.modelData.activate()
                }

                // Popup com Live Thumbnail da(s) janela(s) neste workspace
                Widgets.AnchoredPopup {
                    id: previewPopup
                    anchorItem: wsBtn
                    edges: Edges.Top | Edges.Right
                    popupMargin: 24
                    isTooltip: true
                    // Abre no hover do botão
                    visible: wsHover.containsMouse && wsBtn.modelData.toplevels.values.length > 0
                    
                    contentComponent: Component {
                        Item {
                            // Dimensões limitadas para manter o preview compacto
                            implicitWidth: 160
                            implicitHeight: 90
                            
                            // fallback caso perca a janela
                            Text {
                                anchors.centerIn: parent
                                text: "Sem Janelas"
                                color: Cfg.Colors.dim
                                font.pixelSize: 11
                                visible: !previewView.captureSource
                            }

                            ScreencopyView {
                                id: previewView
                                anchors.fill: parent
                                // Pega a primeira janela visível no workspace
                                captureSource: wsBtn.modelData.toplevels.values[0]?.wayland ?? null
                                live: true
                                constraintSize.width: 160
                                constraintSize.height: 90
                            }
                        }
                    }
                }
            }
        }

        // Se não houver NENHUM workspace com janela (ex: acabou de ligar),
        // mostra ao menos o workspace focado, pra não sumir a barra toda.
        Text {
            visible: root.visibleWorkspaces.length === 0
            text: root.icons[root.focusedWs?.id] ?? root.defaultIcon
            color: Cfg.Colors.accent
            font.pixelSize: 14
        }
    }
}
