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
        command: ["python3", "/home/haru/.config/quickshell/scripts/default_apps.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.settingsData = JSON.parse(this.text)
                } 
                catch (e) { console.log("Erro parse JSON DefaultApps", e) }
            }
        }
    }
    // Component.onCompleted: reload()

    function setKey(key, value) {
        Quickshell.execDetached(["python3", "/home/haru/.config/quickshell/scripts/default_apps.py", "set", key, value])
        let d = Object.assign({}, root.settingsData)
        d[key] = value
        root.settingsData = d
    }

    component AppCombo: RowLayout {
        property string label: ""
        property string key: ""
        property string icon: ""

        Layout.fillWidth: true
        Layout.preferredHeight: 50
        
        Rectangle {
            width: 40; height: 40; radius: 8; color: Cfg.Colors.bgAlt
            Text { text: icon; anchors.centerIn: parent; font.pixelSize: 20 }
        }

        Text { text: label; color: Cfg.Colors.text; font.pixelSize: 14; font.bold: true; Layout.preferredWidth: 200 }

        ComboBox {
            id: combo
            Layout.fillWidth: true
            model: root.settingsData.apps_list || []
            textRole: "name"
            valueRole: "id"
            
            // Fix currentIndex based on id
            Component.onCompleted: updateIndex()
            Connections {
                target: root
                function onSettingsDataChanged() { combo.updateIndex() }
            }
            function updateIndex() {
                if (!root.settingsData.apps_list) return
                let currentId = root.settingsData[key]
                for (let i = 0; i < root.settingsData.apps_list.length; i++) {
                    if (root.settingsData.apps_list[i].id === currentId) {
                        combo.currentIndex = i
                        return
                    }
                }
            }

            onActivated: (index) => {
                setKey(key, root.settingsData.apps_list[index].id)
            }
            
            delegate: ItemDelegate {
                width: combo.width
                contentItem: Text { text: modelData.name; color: Cfg.Colors.text; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { color: combo.highlightedIndex === index ? Cfg.Colors.hoverOverlay : "transparent" }
            }
            background: Rectangle { color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border; radius: 4 }
            contentItem: Text { text: combo.currentText; color: Cfg.Colors.text; leftPadding: 10; verticalAlignment: Text.AlignVCenter }
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
            spacing: 20

            Text { text: "Aplicativos Padrão"; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 22 }
            Text { text: "Escolha quais programas o sistema usará para abrir diferentes tipos de arquivos."; color: Cfg.Colors.dim; font.pixelSize: 11; Layout.bottomMargin: 8 }

            AppCombo { label: "Navegador Web"; key: "browser"; icon: "🌐" }
            AppCombo { label: "Gerenciador de Arquivos"; key: "file_manager"; icon: "📁" }
            AppCombo { label: "Editor de Texto"; key: "text_editor"; icon: "📝" }
            
            // Terminal uses exact command string in hyprland, not .desktop usually, but listing desktop is easier UI.
            // Wait, hyprland uses `ghostty`, not `ghostty.desktop`. We should handle this logic in python script.
            AppCombo { label: "Terminal"; key: "terminal"; icon: "💻" }

            Item { Layout.fillHeight: true; Layout.minimumHeight: 20 }
        }
    }
}
