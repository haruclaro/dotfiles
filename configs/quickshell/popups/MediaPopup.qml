import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../config" as Cfg
import "../widgets" as Widgets

// PORTADO de MediaPlayerPanel (dentro de MediaScroller.tsx). Mesmo critério
// de "player ativo": tocando > com título > primeiro da lista.
Item {
    id: root
    implicitWidth: 320
    implicitHeight: 140

    readonly property var activePlayer: {
        let playing = null, withTitle = null
        for (const p of Mpris.players.values) {
            if (p.isPlaying && !playing) playing = p
            if (p.trackTitle && !withTitle) withTitle = p
        }
        return playing || withTitle || (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null)
    }

    function fmt(s) {
        if (!isFinite(s) || s < 0) s = 0
        const m = Math.floor(s / 60), sec = Math.floor(s % 60)
        return m + ":" + (sec < 10 ? "0" + sec : sec)
    }

    Text {
        anchors.centerIn: parent
        visible: !root.activePlayer
        text: "Nenhuma mídia em reprodução"
        color: Cfg.Colors.dim
    }

    RowLayout {
        anchors.fill: parent
        visible: root.activePlayer !== null
        spacing: 15

        Rectangle {
            width: 110; height: 110; radius: 12
            color: Cfg.Colors.bgAlt
            clip: true
            Image {
                anchors.fill: parent
                source: root.activePlayer?.trackArtUrl || ""
                fillMode: Image.PreserveAspectCrop
                visible: source !== ""
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            ColumnLayout {
                spacing: 2
                Text {
                    text: root.activePlayer?.trackTitle || "Desconhecido"
                    color: Cfg.Colors.text
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }
                Text {
                    text: root.activePlayer?.trackArtist || "Desconhecido"
                    color: Cfg.Colors.subtext
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.maximumWidth: 160
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 18
                Widgets.SymbolicIcon {
                    name: Cfg.Icons.mediaPrevious; width: 14; height: 14; color: Cfg.Colors.text
                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.activePlayer?.previous() }
                }
                Widgets.SymbolicIcon {
                    name: root.activePlayer?.isPlaying ? Cfg.Icons.mediaPause : Cfg.Icons.mediaPlay
                    width: 18; height: 18; color: Cfg.Colors.accent
                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.activePlayer?.togglePlaying() }
                }
                Widgets.SymbolicIcon {
                    name: Cfg.Icons.mediaNext; width: 14; height: 14; color: Cfg.Colors.text
                    MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.activePlayer?.next() }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: root.fmt(root.activePlayer?.position ?? 0); color: Cfg.Colors.dim; font.pixelSize: 10 }
                Rectangle {
                    Layout.fillWidth: true; height: 4; radius: 2
                    color: Cfg.Colors.border
                    Rectangle {
                        readonly property real frac: (root.activePlayer && root.activePlayer.length > 0)
                            ? root.activePlayer.position / root.activePlayer.length : 0
                        width: parent.width * frac
                        height: parent.height; radius: 2
                        color: Cfg.Colors.accent
                    }
                }
                Text { text: root.fmt(root.activePlayer?.length ?? 0); color: Cfg.Colors.dim; font.pixelSize: 10 }
            }
        }
    }
}
