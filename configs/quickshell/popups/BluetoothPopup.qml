import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Bluetooth
import "../config" as Cfg
import "../widgets" as Widgets

Item {
    id: root
    implicitWidth: 320
    implicitHeight: col.implicitHeight

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
        width: parent.width
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Bluetooth"
                color: Cfg.Colors.subtext
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
            }
            
            Rectangle {
                width: 32; height: 18; radius: 9
                readonly property bool isOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                color: isOn ? Cfg.Colors.accent : Cfg.Colors.border
                Rectangle {
                    width: 14; height: 14; radius: 7; color: Cfg.Colors.bg
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.parent.isOn ? parent.width - width - 2 : 2
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (Bluetooth.defaultAdapter) {
                            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
            
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
                            name: modelData.connected ? Cfg.Icons.bluetoothActive : Cfg.Icons.bluetoothDisabled
                            width: 16; height: 16
                            color: modelData.connected ? Cfg.Colors.accent : Cfg.Colors.text
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.name
                                color: modelData.connected ? Cfg.Colors.accent : Cfg.Colors.text
                                font.pixelSize: 12
                                font.bold: modelData.connected
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: modelData.connected && modelData.batteryAvailable
                                text: "Bateria: " + Math.round(modelData.battery * 100) + "%"
                                color: Cfg.Colors.subtext
                                font.pixelSize: 10
                            }
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
        
        Text {
            visible: Bluetooth.defaultAdapter ? !Bluetooth.defaultAdapter.enabled : true
            text: "O Bluetooth está desligado."
            color: Cfg.Colors.dim
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            visible: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) && root.btDevices.length === 0
            text: "Nenhum dispositivo encontrado."
            color: Cfg.Colors.dim
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
