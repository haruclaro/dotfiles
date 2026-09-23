import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import "../config" as Cfg
import "../widgets" as Widgets

Item {
    id: root
    implicitWidth: 320
    implicitHeight: 380

    // Filtra dispositivos e os ordena: conectados primeiro, depois os com nome
    readonly property var btDevices: {
        const list = []
        for (let i = 0; i < Bluetooth.devices.values.length; i++) {
            const dev = Bluetooth.devices.values[i]
            if (dev.name && dev.name.trim() !== "") {
                list.push(dev)
            }
        }
        return list.sort((a, b) => {
            if (a.connected && !b.connected) return -1
            if (!a.connected && b.connected) return 1
            return a.name.localeCompare(b.name)
        })
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Widgets.SymbolicIcon {
                name: Cfg.Icons.bluetooth
                width: 16; height: 16
                color: Cfg.Colors.subtext
            }
            Text {
                text: "Bluetooth"
                color: Cfg.Colors.subtext
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
            }
            
            Widgets.Switch {
                checked: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                onClicked: {
                    if (Bluetooth.defaultAdapter) {
                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: 8
                
                Repeater {
                    model: root.btDevices
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: 6
                        color: modelData.connected ? Cfg.Colors.border : (mouseArea.containsMouse ? Qt.darker(Cfg.Colors.border, 1.2) : "transparent")
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10
                            
                            Widgets.SymbolicIcon {
                                name: Cfg.Icons.bluetooth
                                width: 16; height: 16
                                color: modelData.connected ? Cfg.Colors.accent : Cfg.Colors.text
                            }
                            
                            Text {
                                text: modelData.name || modelData.address
                                color: modelData.connected ? Cfg.Colors.accent : Cfg.Colors.text
                                font.pixelSize: 12
                                font.bold: modelData.connected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            
                            Text {
                                visible: modelData.connected
                                text: "Conectado"
                                color: Cfg.Colors.accent
                                font.pixelSize: 10
                            }
                        }
                        
                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.connected) {
                                    modelData.disconnect()
                                } else {
                                    modelData.connect()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        Text {
            visible: Bluetooth.defaultAdapter ? !Bluetooth.defaultAdapter.enabled : true
            text: "O Bluetooth está desligado."
            color: Cfg.Colors.dim
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }
        
        Text {
            visible: (Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false) && root.btDevices.length === 0
            text: "Nenhum dispositivo."
            color: Cfg.Colors.dim
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
        }
    }
}
