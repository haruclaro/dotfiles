import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../config" as Cfg

Item {
    id: root
    property var statsData: ({"pacman": "0", "aur": "0", "flatpak": "0", "appimage": "0", "updates": "0"})
    property var searchResults: []
    property bool isSearching: false
    property string currentTitle: "Resultados da Pesquisa"

    IpcHandler {
        target: "packages"
        function reload() {
            root.reloadStats();
            if (listProc.ptype) root.loadList(listProc.ptype, root.currentTitle);
        }
    }

    function reloadStats() { statsProc.running = true }

    Process {
        id: statsProc
        command: ["python3", "/home/haru/.config/quickshell/scripts/packages_info.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.statsData = JSON.parse(this.text) } catch (e) {}
            }
        }
    }
    
    Process {
        id: searchProc
        property string query: ""
        command: ["python3", "/home/haru/.config/quickshell/scripts/packages_info.py", "search", query]
        stdout: StdioCollector {
            onStreamFinished: {
                try { 
                    root.searchResults = JSON.parse(this.text).results 
                    root.isSearching = false
                    root.currentTitle = "Resultados da Pesquisa"
                } catch (e) { root.isSearching = false }
            }
        }
    }

    Process {
        id: listProc
        property string ptype: ""
        property string title: ""
        command: ["python3", "/home/haru/.config/quickshell/scripts/packages_info.py", "list", ptype]
        stdout: StdioCollector {
            onStreamFinished: {
                try { 
                    root.searchResults = JSON.parse(this.text).results 
                    root.isSearching = false
                    root.currentTitle = listProc.title
                } catch (e) { root.isSearching = false }
            }
        }
    }

    // Carregamento inicial agora é feito pelo onShownChanged na janela principal

    function search(q) {
        if (!q) { root.searchResults = []; root.currentTitle = "Resultados da Pesquisa"; return }
        root.isSearching = true
        searchProc.query = q
        searchProc.running = true
    }

    function loadList(ptype, title) {
        root.isSearching = true
        listProc.ptype = ptype
        listProc.title = title
        listProc.running = true
    }

    function installPkg(name) {
        Quickshell.execDetached(["python3", "/home/haru/.config/quickshell/scripts/packages_info.py", "install", name])
    }

    function removePkg(name, repo, app_id) {
        if (repo === "Flatpak") name = app_id;
        Quickshell.execDetached(["python3", "/home/haru/.config/quickshell/scripts/packages_info.py", "remove", name, repo])
        // If it's AppImage, reload stats instantly since it's just rm
        if (repo === "AppImage") {
            setTimeout(() => { loadList("appimage", "Pacotes AppImage"); reloadStats(); }, 500)
        }
    }
    
    function updateSystem() {
        Quickshell.execDetached(["python3", "/home/haru/.config/quickshell/scripts/packages_info.py", "update"])
    }

    // Workaround for setTimeout
    Timer { id: timer; property var cb; interval: 500; onTriggered: if(cb) cb() }
    function setTimeout(callback, time) { timer.interval = time; timer.cb = callback; timer.restart() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text { text: "Gerenciador de Pacotes"; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 22 }

        // Dashboard
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            component StatBox: Rectangle {
                property string title: ""
                property string val: ""
                property string icon: ""
                property string ptype: ""
                property color bgColor: Cfg.Colors.bgAlt
                Layout.fillWidth: true
                height: 70
                radius: 8
                color: ma.containsMouse ? Cfg.Colors.hoverOverlay : bgColor
                border.color: Cfg.Colors.border
                RowLayout {
                    anchors.fill: parent; anchors.margins: 12
                    Text { text: icon; font.pixelSize: 24 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { text: val; color: Cfg.Colors.text; font.pixelSize: 20; font.bold: true }
                        Text { text: title; color: Cfg.Colors.dim; font.pixelSize: 11 }
                    }
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (ptype) root.loadList(ptype, title)
                    }
                }
            }

            StatBox { title: "Sistema"; val: root.statsData.pacman; icon: "📦"; ptype: "native" }
            StatBox { title: "AUR"; val: root.statsData.aur; icon: "✨"; ptype: "aur" }
            StatBox { title: "Flatpak"; val: root.statsData.flatpak; icon: "📦"; ptype: "flatpak" }
            StatBox { title: "AppImage"; val: root.statsData.appimage; icon: "📦"; ptype: "appimage" }
            
            Rectangle {
                Layout.fillWidth: true; height: 70; radius: 8
                color: updatesMa.containsMouse ? Qt.lighter(bgColor, 1.1) : bgColor
                property color bgColor: parseInt(root.statsData.updates) > 0 ? Cfg.Colors.accent : Cfg.Colors.bgAlt
                border.color: Cfg.Colors.border
                RowLayout {
                    anchors.fill: parent; anchors.margins: 12
                    Text { text: "🔄"; font.pixelSize: 24 }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 0
                        Text { text: root.statsData.updates; color: parseInt(root.statsData.updates) > 0 ? Cfg.Colors.bg : Cfg.Colors.text; font.pixelSize: 20; font.bold: true }
                        Text { text: "Atualizações"; color: parseInt(root.statsData.updates) > 0 ? Cfg.Colors.bg : Cfg.Colors.dim; font.pixelSize: 11 }
                    }
                }
                MouseArea {
                    id: updatesMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.updateSystem()
                }
            }
        }

        // Search Bar
        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                Layout.fillWidth: true; height: 40; radius: 4; color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border
                TextInput {
                    id: searchInput
                    anchors.fill: parent; anchors.margins: 10
                    color: Cfg.Colors.text; font.pixelSize: 14
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    onAccepted: root.search(text)
                    Text {
                        text: "Pesquisar pacotes (Ex: discord, firefox)..."
                        color: Cfg.Colors.dim
                        visible: !parent.text && !parent.activeFocus
                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                    }
                }
            }
            Rectangle {
                width: 100; height: 40; radius: 4; color: Cfg.Colors.accent
                Text { text: root.isSearching ? "Buscando..." : "Buscar"; color: Cfg.Colors.bg; anchors.centerIn: parent; font.bold: true }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.search(searchInput.text) }
            }
        }

        // Title for results
        Text {
            text: root.currentTitle
            color: Cfg.Colors.text
            font.pixelSize: 14
            font.bold: true
            visible: root.searchResults.length > 0 || root.isSearching
            Layout.topMargin: 4
        }

        // Results List
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: Cfg.Colors.bgAlt; radius: 8; border.color: Cfg.Colors.border
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 8
                model: root.searchResults
                spacing: 8
                delegate: Rectangle {
                    width: ListView.view.width; height: 60
                    color: "transparent"; border.color: Cfg.Colors.divider; radius: 4
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 10; spacing: 12
                        
                        // Ícone de atualização
                        Text {
                            text: "⬆️"
                            visible: modelData.has_update === true
                            font.pixelSize: 16
                            ToolTip.visible: updatesMaIcon.containsMouse
                            ToolTip.text: "Atualização Disponível"
                            MouseArea { id: updatesMaIcon; anchors.fill: parent; hoverEnabled: true }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                Text { text: modelData.name; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 14 }
                                Rectangle {
                                    width: repoTxt.implicitWidth + 12; height: 18; radius: 9; color: Cfg.Colors.divider
                                    Text { id: repoTxt; text: modelData.repo; color: Cfg.Colors.subtext; font.pixelSize: 10; anchors.centerIn: parent }
                                }
                            }
                            Text { text: modelData.desc; color: Cfg.Colors.dim; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                        
                        Rectangle {
                            width: 100; height: 32; radius: 4
                            color: modelData.installed ? "#ff4444" : Cfg.Colors.accent
                            Text { text: modelData.installed ? "Remover" : "Instalar"; color: modelData.installed ? "#ffffff" : Cfg.Colors.bg; anchors.centerIn: parent; font.bold: true }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: modelData.installed ? root.removePkg(modelData.name, modelData.repo, modelData.app_id) : root.installPkg(modelData.name)
                            }
                        }
                    }
                }
                
                Text {
                    text: root.isSearching ? "Carregando..." : "Nenhum pacote encontrado."
                    visible: root.searchResults.length === 0
                    color: Cfg.Colors.dim
                    anchors.centerIn: parent
                }
            }
        }
    }
}
