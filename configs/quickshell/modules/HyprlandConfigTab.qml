import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../config" as Cfg

Item {
    id: root
    property var hyprData: ({})

    // Valores em tempo real para o Preview
    property real gaps_in_val: 4
    property real gaps_out_val: 8
    property real border_size_val: 2
    property real rounding_val: 14
    property real active_opacity_val: 1.0

    function reload() { fetchProc.running = true }

    Process {
        id: fetchProc
        command: ["python3", "/home/haru/.config/quickshell/scripts/hypr_settings.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { 
                    root.hyprData = JSON.parse(this.text) 
                    root.gaps_in_val = root.hyprData["gaps_in"] !== undefined ? root.hyprData["gaps_in"] : 4
                    root.gaps_out_val = root.hyprData["gaps_out"] !== undefined ? root.hyprData["gaps_out"] : 8
                    root.border_size_val = root.hyprData["border_size"] !== undefined ? root.hyprData["border_size"] : 2
                    root.rounding_val = root.hyprData["rounding"] !== undefined ? root.hyprData["rounding"] : 14
                    root.active_opacity_val = root.hyprData["active_opacity"] !== undefined ? root.hyprData["active_opacity"] : 1.0
                } 
                catch (e) { console.log("Erro parse JSON Hyprland", e) }
            }
        }
    }
    // Component.onCompleted: reload()

    function setKey(key, value) {
        Quickshell.execDetached(["python3", "/home/haru/.config/quickshell/scripts/hypr_settings.py", "set", key, value])
        let d = Object.assign({}, root.hyprData); 
        d[key] = value; 
        root.hyprData = d;
    }

    component SectionHeader: RowLayout {
        property string title: ""
        Layout.fillWidth: true
        Layout.topMargin: 12
        Text { text: title; color: Cfg.Colors.accent; font.bold: true; font.pixelSize: 14 }
        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }
    }

    component RangeRow: RowLayout {
        property string label: ""
        property string key: ""
        property real min: 0
        property real max: 100
        property real step: 1

        Layout.fillWidth: true
        Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 11; Layout.preferredWidth: 100 }
        
        Slider {
            id: control
            Layout.fillWidth: true
            from: min; to: max; stepSize: step
            value: root.hyprData[key] !== undefined ? root.hyprData[key] : min
            
            // Atualiza a UI local em tempo real
            onMoved: {
                let v = step === 1 ? Math.round(value) : Number(value.toFixed(2))
                if (key === "gaps_in") root.gaps_in_val = v
                if (key === "gaps_out") root.gaps_out_val = v
                if (key === "border_size") root.border_size_val = v
                if (key === "rounding") root.rounding_val = v
                if (key === "active_opacity") root.active_opacity_val = v
            }
            
            // Salva no disco ao soltar o clique
            onPressedChanged: {
                if (!pressed) setKey(key, step === 1 ? Math.round(value) : Number(value.toFixed(2)))
            }

            background: Rectangle {
                x: control.leftPadding
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 200; implicitHeight: 4
                width: control.availableWidth; height: implicitHeight; radius: 2
                color: Cfg.Colors.border
                Rectangle {
                    width: control.visualPosition * parent.width
                    height: parent.height; color: Cfg.Colors.accent; radius: 2
                }
            }
            handle: Rectangle {
                x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
                implicitWidth: 12; implicitHeight: 12; radius: 6
                color: control.pressed ? Cfg.Colors.text : Cfg.Colors.accent
            }
        }
        Text { text: step === 1 ? Math.round(control.value) : control.value.toFixed(2); color: Cfg.Colors.text; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 24; horizontalAlignment: Text.AlignRight }
    }

    component SwitchRow: RowLayout {
        property string label: ""
        property string key: ""
        property bool value: root.hyprData[key] === true || root.hyprData[key] === "true"

        Layout.fillWidth: true
        Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 11; Layout.fillWidth: true }
        
        Rectangle {
            width: 30; height: 16; radius: 8
            color: value ? Cfg.Colors.accent : Cfg.Colors.border
            Rectangle {
                width: 12; height: 12; radius: 6; color: Cfg.Colors.bg
                anchors.verticalCenter: parent.verticalCenter
                x: value ? parent.width - width - 2 : 2
                Behavior on x { NumberAnimation { duration: 150 } }
            }
            MouseArea { anchors.fill: parent; onClicked: setKey(key, !value ? "true" : "false") }
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: parent.width
            anchors.margins: 16
            spacing: 8

            Text { text: "Hyprland"; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 22 }
            Text { text: "As alterações são aplicadas instantaneamente."; color: Cfg.Colors.dim; font.pixelSize: 11; Layout.bottomMargin: 8 }

            // Live Preview Box (2 Janelas para gaps_in e gaps_out)
            Rectangle {
                Layout.fillWidth: true
                height: 140
                color: Cfg.Colors.bgAlt
                border.color: Cfg.Colors.divider
                border.width: 1
                radius: 8
                clip: true

                // Desktop Wallpaper Mock
                Image {
                    anchors.fill: parent
                    source: "file:///home/haru/.config/tema_manager/wallpapers/dharmx-walls/aesthetic/1.png"
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.3
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.gaps_out_val
                    spacing: root.gaps_in_val

                    // Fake Window 1
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(Cfg.Colors.bg.r, Cfg.Colors.bg.g, Cfg.Colors.bg.b, root.active_opacity_val)
                        border.color: Cfg.Colors.accent
                        border.width: root.border_size_val
                        radius: root.rounding_val

                        Text { anchors.centerIn: parent; text: "Janela 1"; color: Cfg.Colors.text; font.pixelSize: 10; font.bold: true }
                    }

                    // Fake Window 2
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(Cfg.Colors.bg.r, Cfg.Colors.bg.g, Cfg.Colors.bg.b, root.active_opacity_val)
                        border.color: Cfg.Colors.accent
                        border.width: root.border_size_val
                        radius: root.rounding_val

                        Text { anchors.centerIn: parent; text: "Janela 2"; color: Cfg.Colors.text; font.pixelSize: 10; font.bold: true }
                    }
                }
            }

            SectionHeader { title: "Aparência" }
            RangeRow { label: "Gaps (Entre Janelas)"; key: "gaps_in"; min: 0; max: 40 }
            RangeRow { label: "Gaps (Borda da Tela)"; key: "gaps_out"; min: 0; max: 60 }
            RangeRow { label: "Espessura da Borda"; key: "border_size"; min: 0; max: 15 }
            RangeRow { label: "Arredondamento"; key: "rounding"; min: 0; max: 40 }
            
            SectionHeader { title: "Efeitos" }
            SwitchRow { label: "Blur em janelas"; key: "blur_enabled" }
            SwitchRow { label: "Sombras"; key: "shadow_enabled" }
            RangeRow { label: "Opacidade Ativa"; key: "active_opacity"; min: 0.1; max: 1.0; step: 0.05 }
            RangeRow { label: "Opacidade Inativa"; key: "inactive_opacity"; min: 0.1; max: 1.0; step: 0.05 }

            SectionHeader { title: "Layout & Animação" }
            SwitchRow { label: "Animações do Sistema"; key: "animations_enabled" }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Modo de Layout"; color: Cfg.Colors.subtext; font.pixelSize: 11; Layout.fillWidth: true }
                RowLayout {
                    spacing: 4
                    Rectangle {
                        width: 60; height: 22; radius: 4
                        color: root.hyprData["layout"] === "dwindle" ? Cfg.Colors.accent : "transparent"
                        border.color: Cfg.Colors.border; border.width: 1
                        Text { anchors.centerIn: parent; text: "Dwindle"; color: root.hyprData["layout"] === "dwindle" ? Cfg.Colors.bg : Cfg.Colors.text; font.pixelSize: 10; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: setKey("layout", "dwindle") }
                    }
                    Rectangle {
                        width: 60; height: 22; radius: 4
                        color: root.hyprData["layout"] === "master" ? Cfg.Colors.accent : "transparent"
                        border.color: Cfg.Colors.border; border.width: 1
                        Text { anchors.centerIn: parent; text: "Master"; color: root.hyprData["layout"] === "master" ? Cfg.Colors.bg : Cfg.Colors.text; font.pixelSize: 10; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: setKey("layout", "master") }
                    }
                }
            }

            Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
        }
    }
}
