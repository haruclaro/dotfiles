import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import "../config" as Cfg
import "../widgets" as Widgets
import "../popups" as Popups

Window {
    id: root
    
    property bool shown: false
    visible: shown
    
    width: 1100
    height: 780
    title: "Central de Configurações"
    color: Cfg.Colors.bg

    function editTheme(data) {
        stack.currentIndex = 1
        themeCreator.themeName = data.nome || ""
        themeCreator.fundo = data.fundo || "1E1726"
        themeCreator.superficie = data.superficie || "2B2135"
        themeCreator.base = data.base || "514064"
        themeCreator.destaque1 = data.destaque1 || "9A7BB5"
        themeCreator.destaque2 = data.destaque2 || "7BB59A"
        themeCreator.texto = data.texto || "E2DCE8"
        themeCreator.wallpaperPath = data.wallpaper || ""
    }

    // Permite fechar a janela pelo gerenciador de janelas (X no hyprland)
    onClosing: function(closeEvent) {
        closeEvent.accepted = false
        root.shown = false
    }

    onShownChanged: {
        if (shown) {
            appearanceTab.reload()
            defaultAppsTab.reload()
            packagesTab.reloadStats()
            hyprlandConfigTab.reload()
        }
    }

    IpcHandler {
        target: "settings"
        function toggle() { root.shown = !root.shown }
        function open() { root.shown = true }
        function close() { root.shown = false }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 210
            color: Cfg.Colors.bgAlt

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                // Header da Sidebar
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        spacing: 8
                        Text { text: "◆"; font.pixelSize: 20; color: Cfg.Colors.accent }
                        Text { text: "Configurações"; font.pixelSize: 21; font.bold: true; color: Cfg.Colors.text }
                    }
                }
                Item { Layout.preferredHeight: 16 }
                
                Text { text: "PERSONALIZAÇÃO"; font.pixelSize: 10; color: Cfg.Colors.dim; font.bold: true; Layout.leftMargin: 20; Layout.topMargin: 10; Layout.bottomMargin: 4 }
                SettingsNavButton { label: "🎨  Meus Temas"; active: stack.currentIndex === 0; onClicked: stack.currentIndex = 0 }
                SettingsNavButton { label: "➕  Criar Tema"; active: stack.currentIndex === 1; onClicked: {
                    stack.currentIndex = 1
                    // Reseta pra não sobrescrever
                    themeCreator.originalFilePath = ""
                    themeCreator.themeName = "Novo Tema"
                    themeCreator.fundo = "141019"
                    themeCreator.superficie = "201931"
                    themeCreator.base = "332844"
                    themeCreator.destaque1 = "9A7BB5"
                    themeCreator.destaque2 = "C77B7B"
                    themeCreator.texto = "EEE8F5"
                    themeCreator.wallpaperPath = ""
                    themeCreator.searchFilter = ""
                } }
                SettingsNavButton { label: "✨  Aparência"; active: stack.currentIndex === 2; onClicked: stack.currentIndex = 2 }
                
                Text { text: "SISTEMA"; font.pixelSize: 10; color: Cfg.Colors.dim; font.bold: true; Layout.leftMargin: 20; Layout.topMargin: 16; Layout.bottomMargin: 4 }
                SettingsNavButton { label: "⭐  Apps Padrão"; active: stack.currentIndex === 3; onClicked: stack.currentIndex = 3 }
                SettingsNavButton { label: "📦  Pacotes"; active: stack.currentIndex === 4; onClicked: stack.currentIndex = 4 }
                SettingsNavButton { label: "⚙️  Gestor de Janelas (Hyprland)"; active: stack.currentIndex === 5; onClicked: stack.currentIndex = 5 }

                Item { Layout.fillHeight: true } // Espaçador

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 16
                    text: "Central de Configurações"
                    font.pixelSize: 11
                    color: Cfg.Colors.dim
                }
            }
        }

        // Conteúdo
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Cfg.Colors.bg

            StackLayout {
                id: stack
                anchors.fill: parent
                anchors.margins: 18

                // 0: Meus Temas
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 20

                        Text {
                            text: "Meus Temas"
                            font.pixelSize: 26
                            font.bold: true
                            color: Cfg.Colors.text
                        }

                        // Grid de Temas
                        GridView {
                            id: themesGrid
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            cellWidth: 260
                            cellHeight: 180
                            clip: true

                            model: FolderListModel {
                                id: folderModel
                                folder: "file:///home/haru/.config/tema_manager/themes"
                                nameFilters: ["*.json"]
                                showDirs: false
                            }

                            delegate: Rectangle {
                                width: 240
                                height: 160
                                radius: Cfg.Config.barRadius
                                color: Cfg.Colors.bgElevated
                                border.color: cardHover.containsMouse ? Cfg.Colors.accent : Cfg.Colors.border
                                border.width: 1
                                clip: true

                                MouseArea {
                                    id: cardHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    propagateComposedEvents: true
                                    preventStealing: false
                                }

                                property var themeData: null

                                FileView {
                                    id: fileReader
                                    path: filePath
                                    watchChanges: true
                                    
                                    onFileChanged: reload()
                                    onLoaded: {
                                        try {
                                            let txt = text()
                                            if (txt) {
                                                themeData = JSON.parse(txt)
                                            }
                                        } catch(e) {}
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    source: themeData && themeData.wallpaper ? "file://" + themeData.wallpaper : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: themeData && themeData.wallpaper !== ""
                                }

                                // Overlay escuro para garantir leitura do texto e das cores
                                Rectangle {
                                    anchors.fill: parent
                                    color: Cfg.Colors.bgSolid
                                    opacity: 0.65
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            Layout.fillWidth: true
                                            text: themeData ? (themeData.nome || fileName) : fileName
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: Cfg.Colors.text
                                            elide: Text.ElideRight
                                        }
                                        
                                        Rectangle {
                                            width: 24; height: 24; radius: 12
                                            color: Cfg.Colors.bgAlt
                                            border.color: Cfg.Colors.border; border.width: 1
                                            opacity: delHover.containsMouse ? 1.0 : 0.7
                                            Text { anchors.centerIn: parent; text: "X"; color: Cfg.Colors.critical; font.pixelSize: 12; font.bold: true }
                                            MouseArea {
                                                id: delHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: {
                                                    Quickshell.execDetached(["rm", filePath])
                                                }
                                            }
                                        }
                                    }

                                    // Bolinhas de Cores
                                    RowLayout {
                                        spacing: 6
                                        Repeater {
                                            model: ["fundo", "superficie", "base", "destaque1", "destaque2", "texto"]
                                            Rectangle {
                                                width: 24; height: 24; radius: 12
                                                color: themeData && themeData[modelData] ? "#" + themeData[modelData] : "#808080"
                                                border.color: Cfg.Colors.border
                                                border.width: 1
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            id: applyBtn
                                            Layout.fillWidth: true
                                            height: 32
                                            radius: Cfg.Config.chipRadius
                                            color: applyMa.containsMouse ? Cfg.Colors.accent : Cfg.Colors.accentDim
                                            
                                            Text { 
                                                anchors.centerIn: parent
                                                text: "Aplicar"
                                                color: applyMa.containsMouse ? Cfg.Colors.bg : Cfg.Colors.text
                                                font.pixelSize: 13
                                                font.bold: true
                                            }

                                            MouseArea {
                                                id: applyMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    console.log("Aplicando tema: " + filePath)
                                                    Quickshell.execDetached(["bash", "-c", "/usr/bin/python3 /home/haru/.config/quickshell/scripts/aplicar_tema.py '" + filePath + "' > /tmp/theme_apply.log 2>&1"])
                                                }
                                            }
                                        }

                                        Rectangle {
                                            id: editBtn
                                            width: 60
                                            height: 32
                                            radius: Cfg.Config.chipRadius
                                            color: editMa.containsMouse ? Cfg.Colors.hoverOverlay : Cfg.Colors.bgAlt
                                            border.color: Cfg.Colors.border
                                            border.width: 1
                                            
                                            Text { 
                                                anchors.centerIn: parent
                                                text: "Editar"
                                                color: Cfg.Colors.text
                                                font.pixelSize: 12
                                            }

                                            MouseArea {
                                                id: editMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    themeCreator.originalFilePath = filePath
                                                    themeCreator.themeName = themeData.nome || ""
                                                    themeCreator.fundo = themeData.fundo || ""
                                                    themeCreator.superficie = themeData.superficie || ""
                                                    themeCreator.base = themeData.base || ""
                                                    themeCreator.destaque1 = themeData.destaque1 || ""
                                                    themeCreator.destaque2 = themeData.destaque2 || ""
                                                    themeCreator.texto = themeData.texto || ""
                                                    themeCreator.wallpaperPath = themeData.wallpaper || ""
                                                    let wpPath = themeData.wallpaper || ""
                                                    themeCreator.searchFilter = wpPath.substring(wpPath.lastIndexOf('/') + 1)
                                                    stack.currentIndex = 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // 1: Criar Tema
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 20

                        Text {
                            text: "Criador de Temas"
                            font.pixelSize: 26
                            font.bold: true
                            color: Cfg.Colors.text
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Popups.ThemeCreatorPopup {
                                id: themeCreator
                                anchors.fill: parent
                                anchors.margins: 16
                            }
                        }
                    }
                }
                // 2: Aparência
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    AppearanceTab {
                        id: appearanceTab
                        anchors.fill: parent
                    }
                }
                
                // 3: Apps Padrão
                DefaultAppsTab { id: defaultAppsTab; Layout.fillWidth: true; Layout.fillHeight: true }
                
                // 4: Pacotes
                PackagesTab { id: packagesTab; Layout.fillWidth: true; Layout.fillHeight: true }
                
                // 5: Hyprland
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    HyprlandConfigTab {
                        id: hyprlandConfigTab
                        anchors.fill: parent
                    }
                }
            }
        }
    }
    
    component SettingsNavButton: Rectangle {
        id: btnRoot
        property string label: ""
        property bool active: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        Layout.leftMargin: 14
        Layout.rightMargin: 14
        radius: Cfg.Config.chipRadius

        color: active ? Cfg.Colors.accentDim : (ma.containsMouse ? Cfg.Colors.hoverOverlay : "transparent")

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 12
            text: btnRoot.label
            color: btnRoot.active ? Cfg.Colors.text : Cfg.Colors.subtext
            font.pixelSize: 13
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btnRoot.clicked()
        }
    }
}
