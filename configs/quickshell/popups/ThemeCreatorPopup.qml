import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell.Io
import "../config" as Cfg
import "../services" as Services

Item {
    id: root
    implicitWidth: 340
    implicitHeight: col.implicitHeight

    ColorDialog {
        id: colorDialog
        title: "Escolha uma cor"
        property string activeTarget: ""
        onAccepted: {
            let selectedHex = colorDialog.selectedColor.toString().toUpperCase()
            // Formato ARGB (#AARRGGBB) -> pegamos apenas RRGGBB
            if (selectedHex.length === 9) {
                selectedHex = "#" + selectedHex.substring(3)
            }
            let code = selectedHex.substring(1)
            
            if (colorDialog.activeTarget === "fundo") root.fundo = code
            else if (colorDialog.activeTarget === "superficie") root.superficie = code
            else if (colorDialog.activeTarget === "base") root.base = code
            else if (colorDialog.activeTarget === "destaque1") root.destaque1 = code
            else if (colorDialog.activeTarget === "destaque2") root.destaque2 = code
            else if (colorDialog.activeTarget === "texto") root.texto = code
        }
    }

    // Pré-preenche com as cores ATUAIS (as que o Colors.qml já está
    // usando), pra editar em cima de algo em vez de começar do zero.
    property string themeName: "Meu Tema"
    property string fundo: Cfg.Colors.bg.toString().replace("#", "")
    property string superficie: Cfg.Colors.bgAlt.toString().replace("#", "")
    property string base: Cfg.Colors.border.toString().replace("#", "")
    property string destaque1: Cfg.Colors.accent.toString().replace("#", "")
    property string destaque2: Cfg.Colors.critical.toString().replace("#", "")
    property string texto: Cfg.Colors.text.toString().replace("#", "")
    property string wallpaperPath: ""
    property string searchFilter: ""
    property string originalFilePath: ""

    readonly property bool canSave: themeName.trim().length > 0 && wallpaperPath.trim().length > 0

    Process {
        id: wallpaperListProc
        command: ["bash", "-c", "find ~/Pictures ~/Images ~/Imagens ~/Wallpapers ~/wallpapers ~/.wallpapers ~/.config/tema_manager/wallpapers -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.wallpaperCandidates = this.text.split("\n").filter((l) => l.length > 0)
        }
    }
    property var wallpaperCandidates: []
    
    property var filteredWallpapers: {
        let filter = root.searchFilter.toLowerCase()
        if (filter.length === 0) return root.wallpaperCandidates;
        return root.wallpaperCandidates.filter(path => path.substring(path.lastIndexOf('/') + 1).toLowerCase().includes(filter))
    }

    signal themeSaved()

    Process {
        id: applyProc
        onExited: (code) => { 
            root.applyResult = code === 0 ? "Tema aplicado e salvo!" : "Falha ao aplicar (código " + code + ")"
            if (code === 0) root.themeSaved()
        }
    }
    property string applyResult: ""

    function save() {
        let cmd = "/usr/bin/python3 /home/haru/.config/quickshell/scripts/salvar_tema.py '" +
            root.themeName + "' '" + root.fundo + "' '" + root.superficie + "' '" + root.base + "' '" +
            root.destaque1 + "' '" + root.destaque2 + "' '" + root.texto + "' '" + root.wallpaperPath + "' '" + root.originalFilePath + "'"
        applyProc.command = ["bash", "-c", cmd]
        applyProc.running = true
    }

    component ColorSwatchField: RowLayout {
        id: swatchField
        property string label: ""
        property string targetName: ""
        property alias value: input.text
        Layout.fillWidth: true
        spacing: 8
        Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 90 }
        
        Rectangle {
            width: 22; height: 22; radius: 5
            color: "#" + (input.text.length === 6 ? input.text : "808080")
            border.color: swatchMouse.containsMouse ? Cfg.Colors.accent : Cfg.Colors.border; border.width: 1
            
            MouseArea {
                id: swatchMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    let hex = input.text.length === 6 ? "#" + input.text : "#808080"
                    colorDialog.activeTarget = swatchField.targetName
                    colorDialog.selectedColor = hex
                    colorDialog.open()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; height: 28; radius: Cfg.Config.chipRadius
            color: Cfg.Colors.bgAlt; border.color: input.activeFocus ? Cfg.Colors.accent : Cfg.Colors.border; border.width: 1
            TextInput {
                id: input
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Cfg.Colors.text
                font.pixelSize: 11
                font.family: Cfg.Config.monoFontFamily
                maximumLength: 6
                selectByMouse: true
                validator: RegularExpressionValidator { regularExpression: /[0-9a-fA-F]{0,6}/ }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Cfg.Colors.bg

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

                Text {
                    text: "Criar ou Editar Tema"
                    color: Cfg.Colors.text
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                    Layout.topMargin: 16
                    Layout.leftMargin: 16
                }

                Rectangle {
                    Layout.fillWidth: true; height: 32; radius: Cfg.Config.chipRadius
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    color: Cfg.Colors.bgAlt; border.color: nameInput.activeFocus ? Cfg.Colors.accent : Cfg.Colors.border; border.width: 1
                    TextInput {
                        id: nameInput
                        anchors.fill: parent
                        anchors.margins: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: Cfg.Colors.text
                        font.pixelSize: 12
                        text: root.themeName
                        onTextEdited: root.themeName = text
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider; Layout.leftMargin: 16; Layout.rightMargin: 16 }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    spacing: 8
                    Text { text: "Esquema de cores"; color: Cfg.Colors.dim; font.pixelSize: 10 }
                    ColorSwatchField { label: "Fundo"; value: root.fundo; onValueChanged: root.fundo = value; targetName: "fundo" }
                    ColorSwatchField { label: "Superfície"; value: root.superficie; onValueChanged: root.superficie = value; targetName: "superficie" }
                    ColorSwatchField { label: "Base"; value: root.base; onValueChanged: root.base = value; targetName: "base" }
                    ColorSwatchField { label: "Destaque 1"; value: root.destaque1; onValueChanged: root.destaque1 = value; targetName: "destaque1" }
                    ColorSwatchField { label: "Destaque 2"; value: root.destaque2; onValueChanged: root.destaque2 = value; targetName: "destaque2" }
                    ColorSwatchField { label: "Texto"; value: root.texto; onValueChanged: root.texto = value; targetName: "texto" }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider; Layout.leftMargin: 16; Layout.rightMargin: 16 }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    spacing: 6
                    Text { text: "Wallpaper"; color: Cfg.Colors.dim; font.pixelSize: 10 }
                    
                    Rectangle {
                        Layout.fillWidth: true; height: 28; radius: Cfg.Config.chipRadius
                        color: Cfg.Colors.bgAlt; border.color: wpInput.activeFocus ? Cfg.Colors.accent : Cfg.Colors.border; border.width: 1
                        TextInput {
                            id: wpInput
                            anchors.fill: parent
                            anchors.margins: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: Cfg.Colors.text
                            font.pixelSize: 11
                            text: root.searchFilter
                            selectByMouse: true
                            onTextEdited: root.searchFilter = text
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 380
                        color: "transparent"
                        clip: true

                        GridView {
                            id: wpGrid
                            anchors.fill: parent
                            cellWidth: 160
                            cellHeight: 120
                            model: root.filteredWallpapers
                        
                            delegate: Rectangle {
                                required property string modelData
                                width: 152
                                height: 112
                                radius: Cfg.Config.chipRadius
                                color: root.wallpaperPath.includes(modelData.substring(modelData.lastIndexOf('/') + 1)) ? Cfg.Colors.accent : Cfg.Colors.bgAlt
                                border.color: wpHover.containsMouse ? Cfg.Colors.accent : Cfg.Colors.border
                                border.width: 1
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: "file://" + modelData
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }

                                MouseArea { 
                                    id: wpHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.wallpaperPath = modelData
                                        root.searchFilter = modelData.substring(modelData.lastIndexOf('/') + 1)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider; Layout.leftMargin: 16; Layout.rightMargin: 16 }

                Rectangle {
                    Layout.fillWidth: true; height: 34; radius: Cfg.Config.chipRadius
                    Layout.leftMargin: 16; Layout.rightMargin: 16
                    Layout.bottomMargin: 16
                    color: root.canSave && root.wallpaperPath !== "Baixando do github..." ? Cfg.Colors.accent : Cfg.Colors.bgAlt
                    Text {
                        anchors.centerIn: parent
                        text: "Salvar Tema"
                        color: root.canSave && root.wallpaperPath !== "Baixando do github..." ? Cfg.Colors.bg : Cfg.Colors.dim
                        font.pixelSize: 12; font.bold: true
                    }
                    MouseArea { anchors.fill: parent; enabled: root.canSave && root.wallpaperPath !== "Baixando do github..."; onClicked: root.save() }
                }

                Text {
                    visible: root.applyResult.length > 0
                    text: root.applyResult
                    color: root.applyResult.startsWith("Tema aplicado") ? Cfg.Colors.good : Cfg.Colors.critical
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 16
                }
            }
        }
    }
}
