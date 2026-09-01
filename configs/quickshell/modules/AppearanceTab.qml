import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../config" as Cfg

Item {
    id: root
    property var settingsData: ({})

    function reload() { fetchProc.running = true }

    Process {
        id: fetchProc
        command: ["python3", "/home/haru/.config/quickshell/scripts/appearance_settings.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.settingsData = JSON.parse(this.text)
                } 
                catch (e) { console.log("Erro parse JSON Appearance", e) }
            }
        }
    }
    // Component.onCompleted: reload()

    function setKey(key, value) {
        Quickshell.execDetached(["python3", "/home/haru/.config/quickshell/scripts/appearance_settings.py", "set", key, value])
        let d = Object.assign({}, root.settingsData)
        d[key] = value
        root.settingsData = d
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
            value: root.settingsData[key] !== undefined ? root.settingsData[key] : min
            
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
            spacing: 12

            Text { text: "Aparência do Sistema"; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 22 }
            Text { text: "Configurações de tema, fontes e cursores (requer reinício de alguns apps para aplicar)."; color: Cfg.Colors.dim; font.pixelSize: 11; Layout.bottomMargin: 8 }

            SectionHeader { title: "Modo do Sistema" }
            RowLayout {
                spacing: 16
                Rectangle {
                    width: 140; height: 100; radius: 8
                    color: root.settingsData.color_scheme === "prefer-light" ? Cfg.Colors.accent : Cfg.Colors.bgAlt
                    border.color: Cfg.Colors.border; border.width: 1
                    
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 8
                        Rectangle { width: 60; height: 40; radius: 4; color: "#FFFFFF"; Layout.alignment: Qt.AlignHCenter; border.color: "#E0E0E0"; border.width: 1 }
                        Text { text: "Modo Claro"; color: root.settingsData.color_scheme === "prefer-light" ? Cfg.Colors.bg : Cfg.Colors.text; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: setKey("color_scheme", "prefer-light") }
                }
                Rectangle {
                    width: 140; height: 100; radius: 8
                    color: root.settingsData.color_scheme === "prefer-dark" ? Cfg.Colors.accent : Cfg.Colors.bgAlt
                    border.color: Cfg.Colors.border; border.width: 1
                    
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 8
                        Rectangle { width: 60; height: 40; radius: 4; color: "#1E1E1E"; Layout.alignment: Qt.AlignHCenter; border.color: "#333333"; border.width: 1 }
                        Text { text: "Modo Escuro"; color: root.settingsData.color_scheme === "prefer-dark" ? Cfg.Colors.bg : Cfg.Colors.text; font.pixelSize: 12; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                    }
                    MouseArea { anchors.fill: parent; onClicked: setKey("color_scheme", "prefer-dark") }
                }
            }

            SectionHeader { title: "Tipografia e Cursor" }
            
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Fonte do Sistema"; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 120 }
                ComboBox {
                    id: fontCombo
                    Layout.fillWidth: true
                    model: root.settingsData.fonts || []
                    currentIndex: model.indexOf(root.settingsData.font_family || "Sans")
                    onActivated: (index) => setKey("font_family", fontCombo.textAt(index))
                    
                    delegate: ItemDelegate {
                        width: fontCombo.width
                        contentItem: Text {
                            text: modelData
                            font.family: modelData
                            font.pixelSize: 14
                            color: Cfg.Colors.text
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle { color: fontCombo.highlightedIndex === index ? Cfg.Colors.hoverOverlay : "transparent" }
                    }
                    
                    background: Rectangle { color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border; radius: 4 }
                    contentItem: Text { text: fontCombo.displayText; font.family: fontCombo.displayText; color: Cfg.Colors.text; leftPadding: 10; verticalAlignment: Text.AlignVCenter }
                }
            }
            RangeRow { label: "Tamanho da Fonte"; key: "font_size"; min: 8; max: 32 }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Tema do Cursor"; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 120 }
                ComboBox {
                    id: cursorCombo
                    Layout.fillWidth: true
                    model: root.settingsData.cursors || []
                    currentIndex: model.indexOf(root.settingsData.cursor_theme || "Adwaita")
                    onActivated: (index) => setKey("cursor_theme", cursorCombo.textAt(index))
                    
                    delegate: ItemDelegate {
                        width: cursorCombo.width
                        contentItem: RowLayout {
                            spacing: 12
                            Image {
                                source: root.settingsData.previews && root.settingsData.previews.cursors && root.settingsData.previews.cursors[modelData] ? "file://" + root.settingsData.previews.cursors[modelData] : ""
                                width: 24; height: 24; fillMode: Image.PreserveAspectFit
                                visible: source != ""
                            }
                            Text { text: modelData; color: Cfg.Colors.text; verticalAlignment: Text.AlignVCenter; Layout.fillWidth: true }
                        }
                        background: Rectangle { color: cursorCombo.highlightedIndex === index ? Cfg.Colors.hoverOverlay : "transparent" }
                    }
                    
                    background: Rectangle { color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border; radius: 4 }
                    contentItem: RowLayout {
                        spacing: 12
                        Item { width: 10 }
                        Image {
                            source: root.settingsData.previews && root.settingsData.previews.cursors && root.settingsData.previews.cursors[cursorCombo.displayText] ? "file://" + root.settingsData.previews.cursors[cursorCombo.displayText] : ""
                            width: 24; height: 24; fillMode: Image.PreserveAspectFit
                            visible: source != ""
                        }
                        Text { text: cursorCombo.displayText; color: Cfg.Colors.text; verticalAlignment: Text.AlignVCenter; Layout.fillWidth: true }
                    }
                }
            }
            RangeRow { label: "Tamanho do Cursor"; key: "cursor_size"; min: 16; max: 64 }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Tema de Ícones"; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 120 }
                ComboBox {
                    id: iconCombo
                    Layout.fillWidth: true
                    model: root.settingsData.icons || []
                    currentIndex: model.indexOf(root.settingsData.icon_theme || "Adwaita")
                    onActivated: (index) => setKey("icon_theme", iconCombo.textAt(index))
                    
                    delegate: ItemDelegate {
                        width: iconCombo.width
                        contentItem: RowLayout {
                            spacing: 12
                            Image {
                                source: root.settingsData.previews && root.settingsData.previews.icons && root.settingsData.previews.icons[modelData] ? "file://" + root.settingsData.previews.icons[modelData] : ""
                                width: 24; height: 24; fillMode: Image.PreserveAspectFit
                                visible: source != ""
                            }
                            Text { text: modelData; color: Cfg.Colors.text; verticalAlignment: Text.AlignVCenter; Layout.fillWidth: true }
                        }
                        background: Rectangle { color: iconCombo.highlightedIndex === index ? Cfg.Colors.hoverOverlay : "transparent" }
                    }
                    
                    background: Rectangle { color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border; radius: 4 }
                    contentItem: RowLayout {
                        spacing: 12
                        Item { width: 10 }
                        Image {
                            source: root.settingsData.previews && root.settingsData.previews.icons && root.settingsData.previews.icons[iconCombo.displayText] ? "file://" + root.settingsData.previews.icons[iconCombo.displayText] : ""
                            width: 24; height: 24; fillMode: Image.PreserveAspectFit
                            visible: source != ""
                        }
                        Text { text: iconCombo.displayText; color: Cfg.Colors.text; verticalAlignment: Text.AlignVCenter; Layout.fillWidth: true }
                    }
                }
            }

            SectionHeader { title: "Boot e Login" }
            Text { text: "Alterar essas configurações abrirá uma janela pedindo sua senha, pois afetam o sistema inteiro."; color: Cfg.Colors.dim; font.pixelSize: 11; Layout.bottomMargin: 8; Layout.maximumWidth: parent.width; wrapMode: Text.WordWrap }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Esquerda: Controles
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 400
                    Layout.alignment: Qt.AlignTop
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Tela de Carregamento (Plymouth)"; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 200 }
                        ComboBox {
                            id: plymouthCombo
                            Layout.fillWidth: true
                            model: root.settingsData.plymouth_list || []
                            currentIndex: model.indexOf(root.settingsData.plymouth_theme || "")
                            onActivated: (index) => setKey("plymouth_theme", plymouthCombo.textAt(index))
                            background: Rectangle { color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border; radius: 4 }
                            contentItem: Text { text: plymouthCombo.displayText; color: Cfg.Colors.text; leftPadding: 10; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Tela de Login (SDDM)"; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 200 }
                        ComboBox {
                            id: sddmCombo
                            Layout.fillWidth: true
                            model: root.settingsData.sddm_list || []
                            currentIndex: model.indexOf(root.settingsData.sddm_theme || "")
                            onActivated: (index) => setKey("sddm_theme", sddmCombo.textAt(index))
                            background: Rectangle { color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border; radius: 4 }
                            contentItem: Text { text: sddmCombo.displayText; color: Cfg.Colors.text; leftPadding: 10; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                        }
                    }
                }

                Item { Layout.fillWidth: true } // Espaçador flexível no meio

                // Direita: Emulação de Tela
                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    width: 350
                    height: 197 // Proporção 16:9
                    color: "#000000"
                    border.color: "#333333"
                    border.width: 5
                    radius: 8
                    clip: true

                    property string currentPreview: {
                        if (sddmCombo.activeFocus || sddmCombo.popup.visible) {
                            return (root.settingsData.previews && root.settingsData.previews.sddm) ? root.settingsData.previews.sddm[sddmCombo.displayText] : ""
                        } else {
                            return (root.settingsData.previews && root.settingsData.previews.plymouth) ? root.settingsData.previews.plymouth[plymouthCombo.displayText] : ""
                        }
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        source: parent.currentPreview ? "file://" + parent.currentPreview : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Base do Monitor (Pézinho)
                    Rectangle {
                        width: 60; height: 12
                        color: "#333333"
                        anchors.top: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        width: 100; height: 6
                        color: "#444444"
                        radius: 3
                        anchors.top: parent.bottom
                        anchors.topMargin: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            Item { Layout.fillHeight: true; Layout.minimumHeight: 30 }
        }
    }
}
