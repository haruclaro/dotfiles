import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config" as Cfg
import "../popups" as Popups

// PEDIDO: tirar o criador de temas de dentro da ilha inferior — vira uma
// janela própria, "como se fosse um programa separado", igual ao
// ClipboardWindow.qml já era. Abre via IPC:
//   qs ipc call theme toggle
// (bindar SUPER+T ou o que preferir no hyprland.conf — ver README)
PanelWindow {
    id: root

    property bool shown: false
    visible: shown

    implicitWidth: 400
    implicitHeight: content.implicitHeight + 70
    color: "transparent"
    WlrLayershell.namespace: "quickshell:theme-creator"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    IpcHandler {
        target: "theme"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }

    Rectangle {
        anchors.fill: parent
        radius: Cfg.Config.barRadius
        color: Cfg.Colors.bg
        border.color: Cfg.Colors.border
        border.width: 1

        focus: root.shown
        Keys.onEscapePressed: root.shown = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Criador de Temas"; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 14; Layout.fillWidth: true }
                Rectangle {
                    width: 22; height: 22; radius: Cfg.Config.chipRadius
                    color: closeHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"
                    Text { anchors.centerIn: parent; text: "✕"; color: Cfg.Colors.subtext; font.pixelSize: 12 }
                    MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.shown = false }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

            Popups.ThemeCreatorPopup { id: content; Layout.fillWidth: true }
        }
    }
}
