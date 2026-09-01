import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../config" as Cfg
import "../services" as Services
import "../widgets" as Widgets

Item {
    id: root
    implicitWidth: 250
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Widgets.SymbolicIcon {
                name: "find-location-symbolic"
                width: 18; height: 18
                color: Cfg.Colors.text
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: "Localização"
                color: Cfg.Colors.text
                font.bold: true
                font.pixelSize: 14
                Layout.fillWidth: true
            }
        }

        Text {
            text: "Ex: São Leopoldo,BR ou auto"
            color: Cfg.Colors.dim
            font.pixelSize: 11
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 36
            color: Cfg.Colors.bg
            radius: Cfg.Config.chipRadius
            border.color: Cfg.Colors.border
            border.width: 1

            TextInput {
                id: inputField
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Cfg.Colors.text
                font.pixelSize: 13
                focus: true
                clip: true
                onAccepted: {
                    if (text !== "") {
                        Services.Weather.setCity(text)
                        inputField.text = ""
                    }
                }
            }
        }
    }
}
