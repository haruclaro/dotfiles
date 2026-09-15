import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../config" as Cfg
import "../services" as Services
import "../widgets" as Widgets

Item {
    id: root
    implicitWidth: 320
    implicitHeight: col.implicitHeight

    // Filtra redes com SSID vazio ou repetido (só mostra a mais forte)
    readonly property var filteredNetworks: {
        const unique = {}
        for (let i = 0; i < Services.Network.networks.length; i++) {
            const net = Services.Network.networks[i]
            if (!net.ssid || net.ssid.trim() === "") continue
            
            if (!unique[net.ssid] || unique[net.ssid].strength < net.strength) {
                unique[net.ssid] = net
            }
        }
        return Object.values(unique).sort((a, b) => b.strength - a.strength)
    }

    property string selectedSsid: ""
    property string selectedBssid: ""
    property bool requiresPassword: false
    property string errorMsg: ""
    property bool connecting: false

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Redes Wi-Fi"
                color: Cfg.Colors.subtext
                font.pixelSize: 12
                font.bold: true
                Layout.fillWidth: true
            }
            
            Rectangle {
                width: 32; height: 18; radius: 9
                color: Services.Network.wifiEnabled ? Cfg.Colors.accent : Cfg.Colors.border
                Rectangle {
                    width: 14; height: 14; radius: 7; color: Cfg.Colors.bg
                    anchors.verticalCenter: parent.verticalCenter
                    x: Services.Network.wifiEnabled ? parent.width - width - 2 : 2
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Services.Network.setWifiEnabled(!Services.Network.wifiEnabled)
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Services.Network.wifiEnabled
            
            Repeater {
                model: root.filteredNetworks
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 6
                    color: modelData.active ? Cfg.Colors.border : (mouseArea.containsMouse ? Qt.darker(Cfg.Colors.border, 1.2) : "transparent")
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10
                        
                        Widgets.SymbolicIcon {
                            name: modelData.strength > 75 ? Cfg.Icons.wifiHigh : (modelData.strength > 30 ? Cfg.Icons.wifiMedium : Cfg.Icons.wifiLow)
                            width: 16; height: 16
                            color: modelData.active ? Cfg.Colors.accent : Cfg.Colors.text
                        }
                        
                        Text {
                            text: modelData.ssid
                            color: modelData.active ? Cfg.Colors.accent : Cfg.Colors.text
                            font.pixelSize: 12
                            font.bold: modelData.active
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        
                        Widgets.SymbolicIcon {
                            visible: modelData.isSecure
                            name: Cfg.Icons.lock
                            width: 12; height: 12
                            color: Cfg.Colors.subtext
                        }
                    }
                    
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (!modelData.active) {
                                root.errorMsg = ""
                                root.requiresPassword = false
                                root.selectedSsid = modelData.ssid
                                root.selectedBssid = modelData.bssid
                                root.connecting = true
                                
                                Services.Network.connectToNetworkWithPasswordCheck(modelData.ssid, modelData.isSecure, function(res) {
                                    root.connecting = false
                                    if (res.needsPassword) {
                                        root.requiresPassword = true
                                    } else if (!res.success) {
                                        root.errorMsg = "Falha ao conectar."
                                    }
                                }, modelData.bssid)
                            }
                        }
                    }
                }
            }
        }

        // Senha Input Field
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.requiresPassword
            spacing: 8

            Text { text: "Senha para " + root.selectedSsid; color: Cfg.Colors.text; font.pixelSize: 11 }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                color: Cfg.Colors.bgAlt
                border.color: Cfg.Colors.accent
                border.width: 1
                radius: 4

                TextInput {
                    id: passInput
                    anchors.fill: parent
                    anchors.margins: 8
                    color: Cfg.Colors.text
                    font.pixelSize: 12
                    echoMode: TextInput.Password
                    verticalAlignment: TextInput.AlignVCenter
                    onAccepted: connectBtnArea.clicked(null)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 4
                    color: "transparent"
                    border.color: Cfg.Colors.border
                    Text { anchors.centerIn: parent; text: "Cancelar"; color: Cfg.Colors.text; font.pixelSize: 11 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.requiresPassword = false
                            passInput.text = ""
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 4
                    color: Cfg.Colors.accent
                    Text { anchors.centerIn: parent; text: "Conectar"; color: Cfg.Colors.bg; font.pixelSize: 11; font.bold: true }
                    MouseArea {
                        id: connectBtnArea
                        anchors.fill: parent
                        onClicked: {
                            if (passInput.text.trim() === "") return
                            root.requiresPassword = false
                            root.connecting = true
                            Services.Network.connectToNetwork(root.selectedSsid, passInput.text, root.selectedBssid, function(res) {
                                root.connecting = false
                                if (!res.success) {
                                    root.errorMsg = "Senha incorreta ou falha."
                                } else {
                                    passInput.text = ""
                                }
                            })
                        }
                    }
                }
            }
        }

        Text {
            visible: root.errorMsg !== ""
            text: root.errorMsg
            color: Cfg.Colors.red || "#FF5555"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            visible: root.connecting
            text: "Conectando..."
            color: Cfg.Colors.accent
            font.pixelSize: 11
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            visible: !Services.Network.wifiEnabled
            text: "O Wi-Fi está desligado."
            color: Cfg.Colors.dim
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        Text {
            visible: Services.Network.wifiEnabled && root.filteredNetworks.length === 0
            text: Services.Network.scanning ? "Buscando redes..." : "Nenhuma rede encontrada."
            color: Cfg.Colors.dim
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
