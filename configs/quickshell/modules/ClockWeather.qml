import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../config" as Cfg
import "../services" as Services
import "../widgets" as Widgets
import "../popups" as Popups

// PORTADO da seção 1+2 do Bar.tsx antigo (calendário + relógio + clima),
// agora como peça única central da TopBar. PEDIDO NOVO: passar o mouse
// sobre o relógio expande a data PARA A ESQUERDA (não é mais um botão de
// data sempre visível); clicar na data (já expandida) abre o calendário.
RowLayout {
    id: root
    spacing: 8

    property string time: ""
    property string dateText: ""

    Process {
        id: timeProc
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.time = this.text.trim() }
    }
    Process {
        id: dateProc
        // %a já vem com ponto no locale pt_BR (seg., ter., ...)
        command: ["date", "+%a %d/%m"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.dateText = this.text.trim() }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: timeProc.running = true }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: dateProc.running = true }

    // --- Relógio + data revelada no hover ---
    Item {
        id: clockGroup
        implicitWidth: dateReveal.width + clockText.implicitWidth + 6
        implicitHeight: Cfg.Config.barHeight - 8

        readonly property bool hovered: clockHover.containsMouse || dateHover.containsMouse

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Cfg.Config.animMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Cfg.Config.easingEmphasized
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 6
            layoutDirection: Qt.RightToLeft   // clockText fica fixo à direita, data "nasce" à esquerda

            Text {
                id: clockText
                text: root.time
                color: Cfg.Colors.text
                font.family: Cfg.Config.fontFamily
                font.bold: true
                font.pixelSize: 13

                MouseArea {
                    id: clockHover
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                }
            }

            Item {
                id: dateReveal
                implicitWidth: clockGroup.hovered ? dateLabel.implicitWidth + 8 : 0
                implicitHeight: parent.height
                clip: true

                Behavior on implicitWidth {
                    NumberAnimation {
                        duration: Cfg.Config.animMed
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Cfg.Config.easingEmphasized
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Cfg.Config.chipRadius
                    color: dateHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"

                    Text {
                        id: dateLabel
                        anchors.centerIn: parent
                        text: root.dateText
                        color: Cfg.Colors.subtext
                        font.family: Cfg.Config.fontFamily
                        font.pixelSize: 12
                        opacity: clockGroup.hovered ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }
                    }

                    MouseArea {
                        id: dateHover
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: clockGroup.hovered
                        onClicked: calendarPopup.toggle()
                    }
                }
            }
        }
    }

    Widgets.AnchoredPopup {
        id: calendarPopup
        anchorItem: clockGroup
        contentComponent: Popups.CalendarPopup {}
    }

    Rectangle { width: 1; height: 14; color: Cfg.Colors.divider }

    // --- Clima (lógica igual à original em Bar.tsx) ---
    //
    // CORRIGIDO (clima desalinhado verticalmente): a causa raiz era
    // misturar ícone (emoji, de uma fonte de fallback com métricas de
    // altura/baseline bem diferentes) e temperatura (texto normal) dentro
    // do MESMO elemento Text — nenhum alinhamento resolve isso de verdade
    // enquanto os dois glifos vierem de fontes com box de fonte diferente.
    // A correção definitiva foi separar em dois Text: o ícone usa
    // Cfg.Config.iconFontFamily (Nerd Font, desenhada pra alinhar com
    // texto de UI) e a temperatura usa a fonte normal — ver
    // scripts/weather.sh (agora manda "icon" e "temp" como campos JSON
    // separados) e services/Weather.qml.
    Rectangle {
        id: weatherBtn
        implicitWidth: weatherRow.implicitWidth + 16
        implicitHeight: Cfg.Config.barHeight - 8
        radius: Cfg.Config.chipRadius
        color: weatherHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"

        RowLayout {
            id: weatherRow
            anchors.centerIn: parent
            spacing: 5

            Widgets.SymbolicIcon {
                name: Services.Weather.icon
                width: 13; height: 13
                color: Cfg.Colors.text
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                text: Services.Weather.temp
                font.family: Cfg.Config.fontFamily
                font.pixelSize: 12
                color: Cfg.Colors.text
                Layout.alignment: Qt.AlignVCenter
            }
        }

        MouseArea {
            id: weatherHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (evt) => {
                if (evt.button === Qt.RightButton) {
                    weatherLocationPopup.toggle()
                } else {
                    weatherDetailsPopup.toggle()
                }
            }
        }
    }

    Widgets.AnchoredPopup {
        id: weatherDetailsPopup
        anchorItem: weatherBtn
        contentComponent: Popups.WeatherDetailsPopup {}
    }

    Widgets.AnchoredPopup {
        id: weatherLocationPopup
        anchorItem: weatherBtn
        contentComponent: Popups.WeatherLocationPopup {}
    }
}
