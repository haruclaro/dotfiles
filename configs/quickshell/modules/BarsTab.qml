import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../config" as Cfg
import "../widgets" as Widgets

// Aba "Barras" da Central de Configurações: personaliza a TopBar e a BottomBar.
// Formato (geometria), borda, opacidade por barra e os itens de cada barra
// (ordem por arrastar e soltar + ligar/desligar). Mesmo molde das outras abas:
// Process (python bars_settings.py get) → settingsData; setKey() grava via
// Quickshell.execDetached + atualiza o dict local; o singleton Cfg.BarConfig
// observa o bar-config.json e as barras reagem ao vivo.
Item {
    id: root
    property var settingsData: ({})

    // Modelo rico exibido pelos ReorderableList (id é o que vai pro disco na ordem)
    property var topList: []
    property var bottomList: []

    // Catálogo visual de cada item de barra (labels em pt-BR + ícone)
    readonly property var catalog: ({
        resource:   { label: "Recursos do Sistema", icon: "📊" },
        clock:      { label: "Relógio & Clima", icon: "🕒" },
        media:      { label: "Mídia Tocando", icon: "🎵" },
        workspaces: { label: "Workspaces", icon: "▦" },
        sysmenu:    { label: "Menu do Sistema", icon: "⚙" },
        tray:       { label: "Bandeja do Sistema", icon: "⇅" }
    })

    readonly property var topKnown: ["resource", "clock", "media"]
    readonly property var bottomKnown: ["workspaces", "sysmenu", "tray"]

    function reload() { fetchProc.running = true }

    Process {
        id: fetchProc
        command: ["python3", "/home/haru/.config/quickshell/scripts/bars_settings.py", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.settingsData = JSON.parse(this.text)
                }
                catch (e) { console.log("Erro parse JSON Barras", e) }
            }
        }
    }

    function setKey(key, value) {
        Quickshell.execDetached(["python3", "/home/haru/.config/quickshell/scripts/bars_settings.py", "set", key, value])
        let d = Object.assign({}, root.settingsData)
        d[key] = value
        root.settingsData = d
    }

    // settingsData.topItems vem de [{id, enabled}] (ou string JSON, logo após setKey)
    function buildList(items, known) {
        let src = items
        if (typeof src === "string") {
            try { src = JSON.parse(src) } catch (e) { src = null }
        }
        if (!Array.isArray(src) || src.length === 0)
            src = known.map(id => ({ id: id, enabled: true }))
        return src.map(o => {
            const info = root.catalog[o.id] || {}
            return { id: o.id, label: info.label || o.id, icon: info.icon || "◆", enabled: !!o.enabled }
        })
    }

    // Converte o modelo rico de volta para [{id, enabled}] e salva
    function saveList(list, key) {
        const arr = list.map(o => ({ id: o.id, enabled: o.enabled }))
        root.setKey(key, JSON.stringify(arr))
    }

    onSettingsDataChanged: {
        root.topList = root.buildList(root.settingsData.topItems, root.topKnown)
        root.bottomList = root.buildList(root.settingsData.bottomItems, root.bottomKnown)
    }

    component SectionHeader: RowLayout {
        property string title: ""
        Layout.fillWidth: true
        Layout.topMargin: 12
        Text { text: title; color: Cfg.Colors.accent; font.bold: true; font.pixelSize: 14 }
        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }
    }

    // Slider numérico que grava ao soltar o clique (ex.: altura, raio, margem)
    component RangeRow: RowLayout {
        property string label: ""
        property string key: ""
        property real min: 0
        property real max: 100
        property real step: 1

        Layout.fillWidth: true
        Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 11; Layout.preferredWidth: 170 }

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

    component SwitchRow: RowLayout {
        property string label: ""
        property string key: ""
        property bool value: root.settingsData[key] === true || root.settingsData[key] === "true"

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
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: setKey(key, !value ? "true" : "false") }
        }
    }

    // Opacidade por barra: null = seguir o tema (chip "Automático");
    // senão um slider 10–100% que grava o valor ao soltar.
    component OpacityRow: ColumnLayout {
        property string label: ""
        property string key: ""
        Layout.fillWidth: true

        readonly property bool isAuto: {
            const v = root.settingsData[key]
            return v === null || v === undefined || String(v).toLowerCase() === "null"
        }

        RowLayout {
            Layout.fillWidth: true
            Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 11; Layout.fillWidth: true }
            Rectangle {
                width: 92; height: 24; radius: Cfg.Config.chipRadius
                color: isAuto ? Cfg.Colors.accent : Cfg.Colors.bgAlt
                border.color: Cfg.Colors.border; border.width: isAuto ? 0 : 1
                Text {
                    anchors.centerIn: parent
                    text: "Automático"
                    color: isAuto ? Cfg.Colors.bg : Cfg.Colors.subtext
                    font.pixelSize: 10; font.bold: isAuto
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setKey(key, "null") }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Slider {
                id: control
                Layout.fillWidth: true
                Layout.leftMargin: 4
                from: 10; to: 100; stepSize: 1
                value: !isAuto ? root.settingsData[key] * 100 : 100
                enabled: !isAuto
                opacity: isAuto ? 0.45 : 1.0

                onPressedChanged: {
                    if (!pressed && !isAuto) setKey(key, Math.round(control.value) / 100)
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
            Text { text: !isAuto ? Math.round(control.value) + "%" : "—"; color: Cfg.Colors.text; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
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
            spacing: 12

            Text { text: "Barras"; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 22 }
            Text { text: "Personalize as barras superior e inferior do shell — formato, borda, opacidade e os itens de cada barra. As mudanças aplicam na hora."; color: Cfg.Colors.dim; font.pixelSize: 11; Layout.bottomMargin: 4 }

            SectionHeader { title: "Formato das Barras" }
            RangeRow { label: "Altura da barra"; key: "barHeight"; min: 20; max: 64 }
            RangeRow { label: "Raio dos cantos"; key: "barRadius"; min: 0; max: 40 }
            RangeRow { label: "Margem até a borda"; key: "barMargin"; min: 0; max: 24 }
            RangeRow { label: "Espaçamento entre itens"; key: "itemSpacing"; min: 0; max: 32 }
            RangeRow { label: "Padding lateral"; key: "contentPadding"; min: 0; max: 32 }

            SectionHeader { title: "Borda" }
            SwitchRow { label: "Mostrar borda ao redor das barras"; key: "showBorder" }
            RangeRow {
                label: "Largura da borda"
                key: "borderWidth"
                min: 0; max: 6
                visible: root.settingsData["showBorder"] === true || root.settingsData["showBorder"] === "true"
                enabled: visible
            }

            SectionHeader { title: "Opacidade" }
            Text { text: "\"Automático\" usa a transparência que o tema define; escolha um valor para fixar a barra."; color: Cfg.Colors.dim; font.pixelSize: 10 }
            OpacityRow { label: "Barra Superior (TopBar)"; key: "topOpacity" }
            OpacityRow { label: "Barra Inferior (BottomBar)"; key: "bottomOpacity" }

            SectionHeader { title: "Itens das Barras" }
            Text { text: "Arraste pela alça \"≡\" para reordenar; o switch liga/desliga cada item na barra."; color: Cfg.Colors.dim; font.pixelSize: 10 }

            Text { text: "Barra Superior"; color: Cfg.Colors.subtext; font.pixelSize: 12; font.bold: true; Layout.topMargin: 4 }
            Widgets.ReorderableList {
                Layout.fillWidth: true
                Layout.maximumWidth: 560
                model: root.topList
                onChanged: (newModel) => root.saveList(newModel, "topItems")
            }

            Text { text: "Barra Inferior"; color: Cfg.Colors.subtext; font.pixelSize: 12; font.bold: true; Layout.topMargin: 8 }
            Widgets.ReorderableList {
                Layout.fillWidth: true
                Layout.maximumWidth: 560
                model: root.bottomList
                onChanged: (newModel) => root.saveList(newModel, "bottomItems")
            }

            Item { Layout.fillHeight: true; Layout.minimumHeight: 30 }
        }
    }
}