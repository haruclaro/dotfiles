import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../config" as Cfg
import "../widgets" as Widgets
import "../popups" as Popups

// PEDIDO: só este dock (não a BottomBar inteira, que continua sempre
// visível) volta a ter comportamento de hover — recolhido, mostra só a
// engrenagem; passar o mouse revela bandeja + áudio.
//
// PEDIDO "trocar o tray e as configurações": antes a engrenagem ficava no
// fim da fila (tray primeiro, configurações por último). Agora é o
// contrário — a engrenagem fica FIXA e visível (é ela quem representa o
// dock recolhido), e o tray/áudio é que aparece ao lado dela quando expande.
Item {
    id: root

    property bool audioPopupOpen: false
    property bool sysPopupOpen: false
    readonly property bool expanded: hoverArea.containsMouse || audioPopupOpen || sysPopupOpen

    implicitHeight: Cfg.Config.dockCollapsedSize
    implicitWidth: row.implicitWidth

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Cfg.Config.animMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Cfg.Config.easingEmphasized
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        layoutDirection: Qt.RightToLeft
        spacing: 8

        // --- Configurações: fixo, sempre visível (é o "ícone recolhido") ---
        Rectangle {
            id: sysBtn
            width: 24; height: 24
            radius: Cfg.Config.chipRadius
            color: sysHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"
            Text { anchors.centerIn: parent; text: "⚙"; font.pixelSize: 13; color: Cfg.Colors.text }
            MouseArea {
                id: sysHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sysMenuPopup.toggle()
            }
        }

        // --- Revelado só no hover: áudio + divisor + bandeja ---
        Item {
            id: revealArea
            clip: true
            implicitWidth: root.expanded ? revealRow.implicitWidth : 0
            implicitHeight: Cfg.Config.dockCollapsedSize

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Cfg.Config.animMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Cfg.Config.easingEmphasized
                }
            }

            RowLayout {
                id: revealRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                layoutDirection: Qt.RightToLeft
                spacing: 8
                opacity: root.expanded ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }

                Rectangle {
                    id: audioBtn
                    width: 24; height: 24
                    radius: Cfg.Config.chipRadius
                    color: audioHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"
                    Text { anchors.centerIn: parent; text: "🔊"; font.pixelSize: 13 }
                    MouseArea {
                        id: audioHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: audioPopup.toggle()
                    }
                }

                Rectangle { width: 1; height: 16; color: Cfg.Colors.divider; visible: SystemTray.items.values.length > 0 }

                RowLayout {
                    layoutDirection: Qt.RightToLeft
                    spacing: 6
                    Repeater {
                        model: SystemTray.items
                        delegate: Item {
                            id: trayIcon
                            required property var modelData
                            implicitWidth: 20; implicitHeight: 20

                            Image {
                                anchors.fill: parent
                                source: trayIcon.modelData.icon
                                smooth: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (evt) => {
                                    if (evt.button === Qt.RightButton || trayIcon.modelData.onlyMenu) {
                                        trayIcon.modelData.display(trayIcon.Window.window, trayIcon.width / 2, trayIcon.height)
                                    } else {
                                        trayIcon.modelData.activate()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Widgets.AnchoredPopup {
        id: audioPopup
        anchorItem: audioBtn
        edges: Edges.Top
        popupMargin: 24
        contentComponent: Popups.AudioMixerPopup {}
        onVisibleChanged: root.audioPopupOpen = visible
    }

    Widgets.AnchoredPopup {
        id: sysMenuPopup
        anchorItem: sysBtn
        edges: Edges.Top
        popupMargin: 24
        contentComponent: Popups.SysMenuPopup {}
        onVisibleChanged: root.sysPopupOpen = visible
    }
}
