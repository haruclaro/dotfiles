import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../config" as Cfg
import "../services" as Services
import "../widgets" as Widgets

// PORTADO de SysMenu.tsx — SEM o SysTray (que agora é seção própria no
// SysTrayDock.qml, ver pedido do usuário) e sem o wrapper de <box class=
// "sys-menu-panel">, que agora é o AnchoredPopup que já dá a moldura.
//
// Rede/Bluetooth: o Quickshell não tem um binding tão pronto quanto o
// AstalNetwork/AstalBluetooth do AGS para status detalhado, então aqui
// mantemos a mesma estratégia pragmática do original: ler status via
// nmcli/bluetoothctl (polling leve) e abrir o gerenciador gráfico ao
// clicar — mesmo comportamento de antes, só trocando o transporte.
Item {
    id: root
    implicitWidth: 320
    implicitHeight: col.implicitHeight

    // PORTADO de SysMenu.tsx: lá o ícone vinha pronto de
    // createBinding(network.wifi, "iconName"), já dinâmico conforme a
    // força do sinal. Replicamos a mesma faixa de nomes padrão
    // freedesktop (network-wireless-signal-*-symbolic) manualmente aqui.
    readonly property string wifiIconName: {
        if (!root.wifiConnected) return "network-wireless-offline-symbolic"
        if (root.wifiSignal >= 80) return "network-wireless-signal-excellent-symbolic"
        if (root.wifiSignal >= 60) return "network-wireless-signal-good-symbolic"
        if (root.wifiSignal >= 40) return "network-wireless-signal-ok-symbolic"
        if (root.wifiSignal >= 20) return "network-wireless-signal-weak-symbolic"
        return "network-wireless-signal-none-symbolic"
    }

    property string wifiStatus: "…"
    property bool wifiConnected: false
    property int wifiSignal: 0     // 0-100, espelha o iconName dinâmico do AstalNetwork original
    property bool btPowered: false

    // PORTADO de SysMenu.tsx: lá, o ícone e o label vinham de bindings
    // diretos do AstalNetwork (network.wifi.ssid, network.wifi.iconName —
    // esse último já dinâmico conforme a força do sinal). O Quickshell não
    // tem um serviço de rede nativo (só Pipewire/Mpris/SystemTray/UPower),
    // então replicamos a MESMA ideia com nmcli: um comando pro nome da
    // rede conectada, outro pra força do sinal (pra escolher o ícone).
    Process {
        id: wifiProc
        // CORRIGIDO (mostrava status errado, 4 tentativas): trocamos pro
        // script scripts/wifi-status.sh — única fonte de verdade, já com
        // fallback pra iwd/iwgetid pra quem não usa NetworkManager. "bash
        // <caminho>" (não "-c") não depende de permissão +x no arquivo.
        command: ["bash", Cfg.Config.wifiStatusScript]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiConnected = this.text.trim().length > 0
                root.wifiStatus = this.text.trim().length > 0 ? this.text.trim() : "Desconectado"
            }
        }
    }
    Process {
        id: wifiSignalProc
        // Força do sinal (0-100) da rede ATIVA — usa a lista já em cache
        // do nmcli (--rescan no evita disparar um scan novo, que é lento).
        command: ["bash", "-c", "nmcli -t -f active,signal dev wifi list --rescan no 2>/dev/null | awk -F: '$1==\"yes\" {print $2; exit}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(this.text.trim())
                root.wifiSignal = isFinite(n) ? n : 0
            }
        }
    }
    Process {
        id: btProc
        command: ["bash", "-c", "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.btPowered = this.text.trim() === "yes"
        }
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { wifiProc.running = true; wifiSignalProc.running = true; btProc.running = true } }

    function changeTheme(themeCmd) {
        Quickshell.execDetached(["bash", Cfg.Config.themeScript, themeCmd])
    }
    function exit(action) {
        Quickshell.execDetached(["bash", Cfg.Config.exitScript, action])
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 12

        // 1. Central de Configurações — abre o gerenciador completo (StyleAll)
        Rectangle {
            Layout.fillWidth: true
            height: 34; radius: Cfg.Config.chipRadius
            color: styleAllHover.containsMouse ? Cfg.Colors.accentDim : Cfg.Colors.bgAlt
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10; anchors.rightMargin: 10
                spacing: 8
                Text { text: "Central de Configurações"; color: Cfg.Colors.text; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true }
                Widgets.SymbolicIcon { name: Cfg.Icons.styleAll; width: 16; height: 16; color: Cfg.Colors.text }
            }
            MouseArea {
                id: styleAllHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["qs", "ipc", "call", "settings", "toggle"])
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        // 2. Conectividade
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.fillWidth: true; height: 34; radius: Cfg.Config.chipRadius
                color: root.wifiConnected ? Cfg.Colors.accentDim : Cfg.Colors.bgAlt
                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    Widgets.SymbolicIcon { name: root.wifiIconName; width: 14; height: 14; color: root.wifiConnected ? Cfg.Colors.text : Cfg.Colors.dim }
                    Text { text: root.wifiStatus; color: Cfg.Colors.text; font.pixelSize: 11; elide: Text.ElideRight }
                }
                MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
            }
            Rectangle {
                Layout.fillWidth: true; height: 34; radius: Cfg.Config.chipRadius
                color: root.btPowered ? Cfg.Colors.accentDim : Cfg.Colors.bgAlt
                RowLayout {
                    anchors.centerIn: parent; spacing: 6
                    Widgets.SymbolicIcon { name: root.btPowered ? Cfg.Icons.bluetoothActive : Cfg.Icons.bluetoothDisabled; width: 14; height: 14; color: root.btPowered ? Cfg.Colors.text : Cfg.Colors.dim }
                    Text { text: root.btPowered ? "Bluetooth ON" : "Bluetooth OFF"; color: Cfg.Colors.text; font.pixelSize: 11 }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["bash", "-c", "blueman-manager || blueberry"])
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        // 3. Baterias de periféricos
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Services.Peripherals.devices.length > 0
            Repeater {
                model: Services.Peripherals.devices
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10
                    Widgets.SymbolicIcon { name: Cfg.Icons.battery; width: 14; height: 14; color: Cfg.Colors.good }
                    Rectangle {
                        Layout.preferredWidth: 100; height: 6; radius: 3
                        color: Cfg.Colors.border
                        Rectangle {
                            width: parent.width * (parent.parent.modelData.percent / 100)
                            height: parent.height; radius: 3
                            color: Cfg.Colors.good
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: parent.modelData.percent + "% - " + parent.modelData.model
                        color: Cfg.Colors.subtext
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        // 4. Energia
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 14
            Repeater {
                model: [
                    { icon: Cfg.Icons.logout, action: "logout", tip: "Sair da Sessão", critical: false },
                    { icon: Cfg.Icons.reboot, action: "reboot", tip: "Reiniciar", critical: false },
                    { icon: Cfg.Icons.poweroff, action: "poweroff", tip: "Desligar", critical: true },
                ]
                delegate: Rectangle {
                    id: powerBtn
                    required property var modelData
                    width: 38; height: 38; radius: Cfg.Config.chipRadius
                    color: ma.containsMouse ? 
                           (powerBtn.modelData.critical ? Qt.lighter("#ff5555", 1.2) : Cfg.Colors.hoverOverlay) : 
                           (powerBtn.modelData.critical ? "#ff5555" : Cfg.Colors.bgAlt)
                    Widgets.SymbolicIcon {
                        anchors.centerIn: parent
                        name: powerBtn.modelData.icon
                        width: 18; height: 18
                        color: powerBtn.modelData.critical ? Cfg.Colors.bg : Cfg.Colors.text
                    }
                    MouseArea { 
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.exit(powerBtn.modelData.action) 
                    }
                }
            }
        }
    }
}
