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

    implicitHeight: Cfg.BarConfig.barHeight - 8
    implicitWidth: hasMedia ? 166 : 30 // 130 (letreiro) + 6 (spacing) + 14 (ícone) + 16 (padding) = 166

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
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            Widgets.SymbolicIcon {
                name: Cfg.Icons.mediaGeneric
                width: 14; height: 14
                color: root.hasMedia ? Cfg.Colors.accent : Cfg.Colors.dim
            }

            // Letreiro suave e contínuo (pixel-perfect) usando animação de verdade
            Item {
                visible: root.hasMedia
                Layout.preferredWidth: 130
                Layout.preferredHeight: 16
                clip: true

                Row {
                    id: marqueeRow
                    spacing: 30
                    property string fullText: root.hasMedia ? ((root.activePlayer.trackArtist || "Desconhecido") + " - " + (root.activePlayer.trackTitle || "Desconhecido")) : ""
                    property bool shouldScroll: text1.implicitWidth > 130
                    x: 0

                    Text {
                        id: text1
                        text: parent.fullText
                        color: Cfg.Colors.subtext
                        font.family: Cfg.Config.monoFontFamily
                        font.pixelSize: 11
                    }
                    Text {
                        text: parent.fullText
                        color: Cfg.Colors.subtext
                        font.family: Cfg.Config.monoFontFamily
                        font.pixelSize: 11
                        visible: parent.shouldScroll
                    }
                    
                    // Velocidade baseada na largura (distância). Para ficar mais lento, aumentamos o tempo (multiplicador).
                    NumberAnimation on x {
                        from: 0
                        to: -(text1.implicitWidth + 30) // a largura de um ciclo completo
                        duration: (text1.implicitWidth + 30) * 50 // 50ms por pixel (mais lento e suave)
                        loops: Animation.Infinite
                        running: root.hasMedia && marqueeRow.shouldScroll
                    }
                }
            }
        }
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
