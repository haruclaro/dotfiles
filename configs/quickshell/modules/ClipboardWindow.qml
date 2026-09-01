import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../config" as Cfg

// PORTADO de Clipboard.tsx: mesmo fluxo (cliphist list/decode/delete-query
// + wl-copy), mesma distinção texto/imagem via "binary data" na saída do
// cliphist. PEDIDO: "módulo pra mostrar a lista de ctrl+c salva pelo
// cliphist, salva imagens e texto" — igual ao original, sem botão na
// barra; abre via IPC (SUPER+V no Hyprland, ver README) exatamente como
// o "ags toggle clipboard" fazia.
PanelWindow {
    id: root

    property bool shown: false
    visible: shown

    // Sem anchors nos 4 lados = fica do tamanho do conteúdo, flutuando
    // centralizado na tela (igual a um diálogo comum).
    implicitWidth: 460
    implicitHeight: 480
    color: "transparent"
    WlrLayershell.namespace: "quickshell:clipboard"
    WlrLayershell.layer: WlrLayer.Overlay

    IpcHandler {
        target: "clipboard"
        function toggle(): void { root.shown = !root.shown }
        function open(): void { root.shown = true }
        function close(): void { root.shown = false }
    }

    onShownChanged: if (shown) refresh()

    property var items: []

    function refresh() {
        listProc.running = true
    }

    function selectItem(id) {
        selectProc.command = ["bash", "-c", "cliphist decode " + id + " | wl-copy"]
        selectProc.running = true
        root.shown = false
    }

    function deleteItem(id) {
        deleteProc.command = ["bash", "-c", "cliphist delete-query " + id]
        deleteProc.running = true
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter((l) => l.length > 0)
                const parsed = []
                for (const line of lines) {
                    const tabIdx = line.indexOf("\t")
                    if (tabIdx < 0) continue
                    const id = line.substring(0, tabIdx)
                    const preview = line.substring(tabIdx + 1)
                    const isImage = preview.includes("binary data")
                    const thumb = isImage ? "/tmp/cliphist-thumb-" + id : ""
                    parsed.push({ id, preview, isImage, thumb })
                }
                root.items = parsed
                // Decodifica as miniaturas das imagens em lote, depois da
                // lista já estar montada (evita travar a UI item a item).
                for (const it of parsed) {
                    if (it.isImage) thumbProc.startFor(it.id, it.thumb)
                }
            }
        }
    }

    Process { id: selectProc }
    Process {
        id: deleteProc
        onExited: root.refresh()
    }

    // Fila simples de decodificação de miniaturas — um Process por vez,
    // encadeado, pra não disparar dezenas de processos simultâneos numa
    // lista longa.
    QtObject {
        id: thumbQueue
        property var pending: []
    }
    Process {
        id: thumbProc
        function startFor(id, path) {
            thumbQueue.pending.push([id, path])
            if (!running) _next()
        }
        function _next() {
            if (thumbQueue.pending.length === 0) return
            const [id, path] = thumbQueue.pending.shift()
            command = ["bash", "-c", "cliphist decode " + id + " > " + path]
            running = true
        }
        onExited: _next()
        Component.onCompleted: _next()
    }

    Rectangle {
        anchors.fill: parent
        radius: Cfg.Config.barRadius
        color: Cfg.Colors.bg
        border.color: Cfg.Colors.border
        border.width: 1

        focus: root.shown
        Keys.onEscapePressed: root.shown = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Text {
                text: "Histórico de área de transferência"
                color: Cfg.Colors.text
                font.bold: true
                font.pixelSize: 14
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: listCol.implicitHeight
                clip: true

                ColumnLayout {
                    id: listCol
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.items
                        delegate: Rectangle {
                            id: rowDelegate
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: 44
                            radius: Cfg.Config.chipRadius
                            color: rowHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Rectangle {
                                    visible: rowDelegate.modelData.isImage
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32
                                    radius: 4
                                    color: Cfg.Colors.bgAlt
                                    clip: true
                                    Image {
                                        anchors.fill: parent
                                        source: rowDelegate.modelData.isImage ? "file://" + rowDelegate.modelData.thumb : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: rowDelegate.modelData.isImage ? "[Imagem]" : rowDelegate.modelData.preview
                                    color: Cfg.Colors.text
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Rectangle {
                                    Layout.preferredWidth: 22; Layout.preferredHeight: 22
                                    radius: Cfg.Config.chipRadius
                                    color: delHover.containsMouse ? Cfg.Colors.critical : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 11
                                        color: delHover.containsMouse ? Cfg.Colors.bg : Cfg.Colors.dim
                                    }
                                    MouseArea {
                                        id: delHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.deleteItem(rowDelegate.modelData.id)
                                    }
                                }
                            }

                            MouseArea {
                                id: rowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                                onClicked: root.selectItem(rowDelegate.modelData.id)
                            }
                        }
                    }

                    Text {
                        visible: root.items.length === 0
                        text: "Histórico vazio."
                        color: Cfg.Colors.dim
                        font.italic: true
                        Layout.topMargin: 20
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
