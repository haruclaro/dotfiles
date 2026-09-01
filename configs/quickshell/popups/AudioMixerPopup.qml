import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../config" as Cfg
import "../widgets" as Widgets

// PORTADO de AudioMixer.tsx: Wp.Endpoint (AstalWp) vira PwNode (Pipewire
// nativo do Quickshell). A saída padrão é Pipewire.defaultAudioSink; os
// "streams de aplicação" são os nós de Pipewire.nodes cujo tipo é
// Stream/Output/Audio (PwNodeType.AudioOutStream).
Item {
    id: root
    implicitWidth: 320
    implicitHeight: col.implicitHeight

    // CORRIGIDO (volume mestre não mexia, apps não apareciam): duas causas.
    //
    // 1) `PwObjectTracker { objects: [Pipewire.defaultAudioSink, ...] }` —
    //    quando o popup abre antes do Pipewire.defaultAudioSink estar
    //    pronto (ou momentaneamente null, o que a própria doc do Quickshell
    //    avisa que pode acontecer), esse array ficava com `null` dentro.
    //    Um `null` no meio da lista de objetos do tracker quebra o
    //    tracking do restante também — por isso `.audio.volume` nunca
    //    ficava válido pra escrita, mesmo no dispositivo principal.
    //    Filtramos os nulos antes de passar pro tracker.
    //
    // 2) O filtro `isStream && audio && !isSink` pra achar streams de
    //    aplicação era ambíguo e, na prática, não capturava nada. O
    //    código-fonte do Quickshell mapeia media.class "Stream/Output/
    //    Audio" (streams de reprodução de app) direto pra
    //    PwNodeType.AudioOutStream — usamos esse valor, que é exato.
    readonly property var appStreams: {
        const list = []
        for (const n of Pipewire.nodes.values) {
            if (n.type === PwNodeType.AudioOutStream && n.audio) list.push(n)
        }
        return list
    }

    readonly property var trackedObjects: {
        const list = [...appStreams]
        if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink)
        return list
    }

    // Mantém os nós "vivos"/bindáveis (e suas propriedades de volume
    // graváveis) enquanto o popup existe.
    PwObjectTracker {
        objects: root.trackedObjects
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        Text { text: "Saída Principal"; color: Cfg.Colors.subtext; font.pixelSize: 12; font.bold: true }

        Loader {
            Layout.fillWidth: true
            active: Pipewire.defaultAudioSink !== null
            sourceComponent: VolumeRow { node: Pipewire.defaultAudioSink }
            visible: active
        }
        Text {
            visible: Pipewire.defaultAudioSink === null
            text: "Nenhuma saída de áudio detetada."
            color: Cfg.Colors.dim
            font.italic: true
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        Text { text: "Aplicações"; color: Cfg.Colors.subtext; font.pixelSize: 12; font.bold: true }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.appStreams.length > 0
            Repeater {
                model: root.appStreams
                delegate: VolumeRow { required property var modelData; node: modelData; Layout.fillWidth: true }
            }
        }
        Text {
            visible: root.appStreams.length === 0
            text: "Nenhuma aplicação a tocar áudio."
            color: Cfg.Colors.dim
            font.italic: true
        }
    }

    component VolumeRow: RowLayout {
        id: rowRoot
        required property var node
        spacing: 10

        Widgets.SymbolicIcon {
            name: rowRoot.node?.audio?.muted ? Cfg.Icons.volumeMuted : Cfg.Icons.volumeHigh
            width: 15; height: 15
            color: Cfg.Colors.text

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                onClicked: {
                    if (rowRoot.node?.audio) rowRoot.node.audio.muted = !rowRoot.node.audio.muted
                }
            }
        }

        Text {
            Layout.preferredWidth: 100
            text: rowRoot.node?.description || rowRoot.node?.name || "Dispositivo de Áudio"
            color: Cfg.Colors.text
            elide: Text.ElideRight
            font.pixelSize: 12
        }

        // CORRIGIDO (volume mestre não respondia a arrastar): trocamos o
        // QtQuick.Controls.Slider — que era o ÚNICO lugar em todo o
        // projeto usando um controle do QtQuick.Controls, enquanto todo
        // o resto (barra de progresso de mídia, medidores de recurso
        // etc) sempre foi um Rectangle+MouseArea feito à mão — por uma
        // barra igual, no mesmo padrão. Mais controle sobre o gesto de
        // arrastar e consistente com o resto do shell.
        Item {
            id: track
            Layout.fillWidth: true
            Layout.preferredWidth: 130
            Layout.preferredHeight: 16

            readonly property real volume: rowRoot.node?.audio?.volume ?? 0

            function setFromX(x) {
                if (!rowRoot.node?.audio) return
                const frac = Math.max(0, Math.min(1, x / track.width))
                rowRoot.node.audio.volume = frac
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 4; radius: 2
                color: Cfg.Colors.border

                Rectangle {
                    width: parent.width * Math.min(track.volume, 1)
                    height: parent.height; radius: 2
                    color: Cfg.Colors.accent
                }
            }

            Rectangle {
                readonly property real pos: Math.min(track.volume, 1) * (track.width - width)
                x: pos
                anchors.verticalCenter: parent.verticalCenter
                width: 12; height: 12; radius: 6
                color: Cfg.Colors.accent
            }

            MouseArea {
                anchors.fill: parent
                onPressed: (mouse) => track.setFromX(mouse.x)
                onPositionChanged: (mouse) => { if (pressed) track.setFromX(mouse.x) }
            }
        }

        Text {
            Layout.preferredWidth: 36
            horizontalAlignment: Text.AlignRight
            text: Math.floor((rowRoot.node?.audio?.volume ?? 0) * 100) + "%"
            color: Cfg.Colors.subtext
            font.pixelSize: 11
        }
    }
}
