import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../config" as Cfg
import "../widgets" as Widgets
import "../popups" as Popups

// PORTADO de MediaScroller.tsx. PEDIDO NOVO: "na falta de mídia tocada deve
// ficar recolhido apresentando apenas o ícone musical" — antes (AGS) sempre
// mostrava um widthRequest fixo de 200px com "Nenhuma mídia"; agora o botão
// encolhe pra caber só o ícone quando não há player ativo/tocando.
Item {
    id: root

    // CORRIGIDO (pílula não recolhia com tudo pausado): a versão anterior
    // caía num fallback "qualquer player com trackTitle" quando ninguém
    // estava tocando — só que players MPRIS mantêm o trackTitle mesmo
    // pausados (só some quando o player fecha de vez), então na prática
    // NUNCA recolhia depois da primeira música. Agora "tem mídia" exige
    // isPlaying de verdade; pausado/parado conta como "sem mídia" pra
    // fins de recolher a pílula (o popup, ao clicar, ainda mostra o
    // player pausado — essa parte usa a lógica própria do MediaPopup.qml).
    readonly property var activePlayer: {
        for (const p of Mpris.players.values) {
            if (p.isPlaying) return p
        }
        return null
    }
    readonly property bool hasMedia: activePlayer !== null

    implicitHeight: Cfg.Config.barHeight - 8
    implicitWidth: hasMedia ? 190 : 30

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Cfg.Config.animMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Cfg.Config.easingEmphasized
        }
    }

    Rectangle {
        id: btn
        anchors.fill: parent
        radius: Cfg.Config.chipRadius
        color: hoverArea.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"
        clip: true

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Widgets.SymbolicIcon {
                name: Cfg.Icons.mediaGeneric
                width: 14; height: 14
                color: root.hasMedia ? Cfg.Colors.accent : Cfg.Colors.dim
            }

            // Letreiro simples — mesma ideia do ScrollingLabel original
            // (recorta o texto e faz ele "andar" a cada tick).
            Item {
                visible: root.hasMedia
                Layout.preferredWidth: 130
                Layout.preferredHeight: 16
                clip: true

                Text {
                    id: marquee
                    property string full: root.hasMedia
                        ? ((root.activePlayer.trackArtist || "Desconhecido") + " - " + (root.activePlayer.trackTitle || "Desconhecido"))
                        : ""
                    property int offset: 0
                    text: full.length <= 22 ? full : (full + "     " + full).substring(offset, offset + 22)
                    color: Cfg.Colors.subtext
                    font.family: Cfg.Config.monoFontFamily
                    font.pixelSize: 11
                }
            }
        }
    }

    Timer {
        interval: 200
        running: root.hasMedia && marquee.full.length > 22
        repeat: true
        onTriggered: marquee.offset = (marquee.offset + 1) % (marquee.full.length + 5)
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: mediaPopup.toggle()
    }

    Widgets.AnchoredPopup {
        id: mediaPopup
        anchorItem: btn
        contentComponent: Popups.MediaPopup {}
    }
}
