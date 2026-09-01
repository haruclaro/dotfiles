import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../config" as Cfg
import "../widgets" as Widgets

PanelWindow {
    id: root

    // Posição tipo Windows (centro-baixo)
    anchors.bottom: true
    anchors.horizontalCenter: true
    margins.bottom: 60

    implicitWidth: 260
    implicitHeight: 60

    // overlay layer
    WlrLayershell.namespace: "quickshell:volumeosd"
    WlrLayershell.layer: WlrLayer.Overlay

    focusable: false
    color: "transparent"

    opacity: osdTimer.running ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: 200 }
    }

    // Monitorar Pipewire Audio Sink
    property var audioNode: Pipewire.defaultAudioSink
    property real currentVolume: audioNode?.audio?.volume ?? 0
    property bool currentMuted: audioNode?.audio?.muted ?? false

    PwObjectTracker {
        objects: root.audioNode ? [root.audioNode] : []
    }

    // Usar onVolumeChanged e onMutedChanged para reiniciar o timer e mostrar o popup
    onCurrentVolumeChanged: svcTimerHelper.trigger()
    onCurrentMutedChanged: svcTimerHelper.trigger()

    // Atraso curto para não mostrar popup na inicialização
    property bool _initialized: false
    
    Component.onCompleted: {
        initTimer.start()
    }
    
    Timer {
        id: initTimer
        interval: 1000
        onTriggered: root._initialized = true
    }

    QtObject {
        id: svcTimerHelper
        function trigger() {
            if (root._initialized) {
                osdTimer.restart()
            }
        }
    }

    Timer {
        id: osdTimer
        interval: 2000
        running: false
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Cfg.Colors.bgElevated
        border.color: Cfg.Colors.border
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Widgets.SymbolicIcon {
                name: root.currentMuted || root.currentVolume === 0 ? Cfg.Icons.volumeMuted : 
                      (root.currentVolume < 0.3 ? Cfg.Icons.volumeLow : 
                      (root.currentVolume < 0.7 ? Cfg.Icons.volumeMedium : Cfg.Icons.volumeHigh))
                width: 24; height: 24
                color: Cfg.Colors.text
            }

            // Barra de progresso
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Cfg.Colors.border

                    Rectangle {
                        width: parent.width * Math.min(root.currentVolume, 1)
                        height: parent.height
                        radius: 3
                        color: Cfg.Colors.accent
                        
                        Behavior on width {
                            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }

            Text {
                text: Math.floor(root.currentVolume * 100)
                color: Cfg.Colors.text
                font.pixelSize: 14
                font.bold: true
                font.family: Cfg.Config.fontFamily
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
