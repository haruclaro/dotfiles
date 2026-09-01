import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config" as Cfg
import "../widgets" as Widgets
import "../popups" as Popups

// PEDIDO: sem hover próprio — a ilha inteira que esconde/aparece agora
// (ver BottomBar.qml). Aqui dentro, tudo fica sempre visível.
//
// PEDIDO: "criador de temas" e "configurações do Hyprland" saíram daqui
// — viraram janelas próprias, independentes da ilha inferior, abertas
// via IPC (ver modules/ThemeCreatorWindow.qml e
// modules/HyprSettingsWindow.qml). De volta ao layout original: só
// áudio + sistema.
Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    readonly property bool popupOpen: audioPopup.visible || sysMenuPopup.visible

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            id: audioBtn
            width: 24; height: 24
            radius: Cfg.Config.chipRadius
            color: audioHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"
            Widgets.SymbolicIcon { anchors.centerIn: parent; name: Cfg.Icons.volumeHigh; width: 14; height: 14; color: Cfg.Colors.text }
            MouseArea {
                id: audioHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: audioPopup.toggle()
            }
        }

        Rectangle {
            id: sysBtn
            width: 24; height: 24
            radius: Cfg.Config.chipRadius
            color: sysHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"
            Widgets.SymbolicIcon { anchors.centerIn: parent; name: Cfg.Icons.systemMenu; width: 14; height: 14; color: Cfg.Colors.text }
            MouseArea {
                id: sysHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sysMenuPopup.toggle()
            }
        }
    }

    Widgets.AnchoredPopup {
        id: audioPopup
        anchorItem: audioBtn
        edges: Edges.Top
        popupMargin: 24
        contentComponent: Popups.AudioMixerPopup {}
    }

    Widgets.AnchoredPopup {
        id: sysMenuPopup
        anchorItem: sysBtn
        edges: Edges.Top
        popupMargin: 24
        contentComponent: Popups.SysMenuPopup {}
    }
}
