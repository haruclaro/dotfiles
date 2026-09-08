import QtQuick
import QtQuick.Layouts
import "../config" as Cfg

// Lista reordenável por arrastar e soltar, usada na aba "Barras" da Central
// (modules/BarsTab.qml) para montar/ordenar os itens de cada barra.
//
// MODEL (API):
//   property var model: [{ id, label, icon, enabled }, ...]
//   signal changed(var newModel)   // dispara com o array final (nova ordem)
//
// Comportamento:
//   - O handle "≡" de cada linha arrasta verticalmente; o slot vazio é
//     aberto/animado AOS OUTROS itens (Behavior on y) enquanto a linha
//     arrastada segue o mouse. O modelo JS NÃO é mutado durante o arraste
//     (assim o Repeater não recria delegates no meio do gesto — causa clássica
//     de drag quebrado); ele só é reordenado no release.
//   - O switch à direita liga/desliga o item (linha fica apagada quando off).
Item {
    id: root
    property var model: []
    signal changed(var newModel)

    readonly property int rowHeight: 40
    readonly property int rowSpacing: 6
    readonly property int itemHeight: rowHeight + rowSpacing

    // Estado interno do arraste (por índice, não por id — estável durante o gesto)
    property int dragIdx: -1          // qual linha está sendo arrastada
    property int dragSlot: -1         // em que slot a linha arrastada está agora
    readonly property int count: model.length

    implicitHeight: count > 0 ? count * itemHeight - rowSpacing : 0

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    // Slot VISUAL de uma linha não-arrastada: remove a linha arrastada da
    // contagem e abre o espaço no dragSlot. É o que faz as outras deslizarem.
    function visualSlot(idx) {
        if (root.dragIdx < 0) return idx
        if (idx === root.dragIdx) return -1            // a arrastada segue o mouse
        let slot = idx < root.dragIdx ? idx : idx - 1
        if (slot >= root.dragSlot) slot += 1
        return slot
    }

    function indexOfId(id) {
        for (let i = 0; i < root.model.length; i++)
            if (root.model[i].id === id) return i
        return -1
    }

    // Regra: este componente NUNCA atribui root.model — apenas emite changed
    // com o array final. Quem guarda a verdade é o pai (BarsTab), que repassa
    // o modelo atualizado via settingsData. Se atribuíssemos model aqui, o
    // binding do pai morreria e a lista ficaria com estado velho depois de um
    // reload() da Central.
    function toggleEnabled(id) {
        // (QJSEngine não aceita object spread `{...o}`, então clonamos via assign)
        const arr = root.model.map(o => Object.assign({}, o))
        for (let i = 0; i < arr.length; i++) {
            if (arr[i].id === id) { arr[i].enabled = !arr[i].enabled; break }
        }
        root.changed(arr)
    }

    Repeater {
        model: root.model
        delegate: Item {
            id: row
            width: root.width
            height: root.itemHeight
            z: isDragged ? 100 : 1

            readonly property bool isDragged: root.dragIdx === index
            property real streamY: 0          // posição durante o arraste
            property real pressY: 0
            property real grabMouseY: 0

            y: isDragged ? streamY : root.visualSlot(index) * root.itemHeight
            Behavior on y {
                enabled: !isDragged
                NumberAnimation { duration: Cfg.Config.animMed; easing.type: Easing.OutCubic }
            }

            opacity: modelData.enabled ? 1.0 : 0.5

            Rectangle {
                id: face
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: root.rowHeight
                radius: Cfg.Config.chipRadius
                color: isDragged ? Cfg.Colors.accentDim : Cfg.Colors.bgAlt
                border.color: Cfg.Colors.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 10
                    spacing: 10

                    // Alça de arrastar
                    Rectangle {
                        id: handleBox
                        width: 22; height: 22; radius: 6
                        color: Cfg.Colors.hoverOverlay
                        Text { anchors.centerIn: parent; text: "≡"; color: Cfg.Colors.subtext; font.pixelSize: 14 }

                        MouseArea {
                            id: handle
                            anchors.fill: parent
                            cursorShape: Qt.SizeVerCursor
                            onPressed: (e) => {
                                root.dragIdx = index
                                root.dragSlot = index
                                row.pressY = row.y
                                row.grabMouseY = e.y
                                row.streamY = row.y
                            }
                            onPositionChanged: (e) => {
                                if (root.dragIdx !== index) return
                                const lo = 0
                                const hi = (root.count - 1) * root.itemHeight
                                row.streamY = root.clamp(row.pressY + (e.y - row.grabMouseY), lo, hi)
                                const target = root.clamp(Math.round(row.streamY / root.itemHeight), 0, root.count - 1)
                                if (target !== root.dragSlot) root.dragSlot = target
                            }
                            onReleased: {
                                if (root.dragIdx !== index) return
                                const from = root.dragIdx
                                const to = root.dragSlot
                                root.dragIdx = -1
                                root.dragSlot = -1
                                if (from !== to && from >= 0 && to >= 0 && from < root.count && to < root.count) {
                                    const arr = root.model.slice()
                                    const moved = arr.splice(from, 1)[0]
                                    arr.splice(to, 0, moved)
                                    root.changed(arr)
                                }
                            }
                        }
                    }

                    Text {
                        text: modelData.icon || "◆"
                        color: Cfg.Colors.text
                        font.pixelSize: 15
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: modelData.label || modelData.id
                        color: Cfg.Colors.text
                        font.pixelSize: 13
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Switch liga/desliga
                    Rectangle {
                        id: sw
                        width: 40; height: 22; radius: 11
                        color: modelData.enabled ? Cfg.Colors.accent : Cfg.Colors.border
                        Rectangle {
                            id: knob
                            width: 16; height: 16; radius: 8
                            color: Cfg.Colors.bgSolid
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: modelData.enabled ? sw.width - knob.width - 3 : 3
                            Behavior on anchors.leftMargin { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleEnabled(modelData.id)
                        }
                    }
                }
            }
        }
    }
}