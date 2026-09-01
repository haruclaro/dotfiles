import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../config" as Cfg
import "../services" as Svc

// Toast de notificação — painel flutuante no canto superior direito.
// Exibe as notificações recebidas pelo Svc.Notifications.server como
// cards empilhados com animação de entrada/saída.
//
// Uso: adicionar `NotificationToast {}` no shell.qml (sem Variants,
// pois só precisa de uma instância — aparece sempre no monitor focado).
PanelWindow {
    id: root

    // Posição: topo-direita, flutuando sobre tudo
    anchors.top: true
    anchors.right: true
    margins.top: Cfg.Config.barMargin + Cfg.Config.barHeight + 8
    margins.right: Cfg.Config.barMargin

    // Tamanho dinâmico baseado no conteúdo
    implicitWidth: 380
    implicitHeight: toastColumn.implicitHeight + 8

    // Transparente quando vazio, sem bloquear input
    color: "transparent"
    visible: toastColumn.children.length > 0

    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    // Não roubar foco do que o usuário está fazendo
    focusable: false

    // Coluna de toasts empilhados
    ColumnLayout {
        id: toastColumn
        anchors.fill: parent
        anchors.margins: 4
        spacing: 8

        Repeater {
            model: Svc.Notifications.tracked

            delegate: Rectangle {
                id: toast
                required property Notification modelData

                Layout.fillWidth: true
                Layout.preferredHeight: toastContent.implicitHeight + 24
                radius: 14
                color: Cfg.Colors.bgElevated
                border.color: urgencyColor(modelData.urgency)
                border.width: modelData.urgency === NotificationUrgency.Critical ? 2 : 1
                opacity: 0
                scale: 0.95

                // Cor da borda muda conforme urgência
                function urgencyColor(urgency) {
                    switch (urgency) {
                        case NotificationUrgency.Critical: return Cfg.Colors.critical;
                        case NotificationUrgency.Low: return Cfg.Colors.border;
                        default: return Cfg.Colors.accent;
                    }
                }

                // Animação de entrada
                Component.onCompleted: {
                    opacity = 1;
                    scale = 1;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Cfg.Config.animMed
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Cfg.Config.easingEmphasized
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Cfg.Config.animMed
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Cfg.Config.easingEmphasized
                    }
                }

                // Auto-dismiss timer
                Timer {
                    id: dismissTimer
                    interval: modelData.expireTimeout > 0 ? modelData.expireTimeout : Svc.Notifications.defaultTimeout
                    running: true
                    onTriggered: modelData.expire()
                }

                // Pausar timer ao passar o mouse
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: dismissTimer.running = false
                    onExited: dismissTimer.restart()
                    onClicked: modelData.dismiss()

                    RowLayout {
                        id: toastContent
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // Barra colorida lateral (indicador de urgência)
                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.fillHeight: true
                            Layout.topMargin: 2
                            Layout.bottomMargin: 2
                            radius: 2
                            color: toast.urgencyColor(toast.modelData.urgency)
                        }

                        // Conteúdo textual
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            // App name + summary
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: toast.modelData.appName || "Notificação"
                                    font.family: Cfg.Config.fontFamily
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: Cfg.Colors.dim
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 100
                                }

                                Text {
                                    text: "·"
                                    font.pixelSize: 11
                                    color: Cfg.Colors.dim
                                    visible: toast.modelData.appName !== ""
                                }

                                Text {
                                    text: toast.modelData.summary
                                    font.family: Cfg.Config.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    color: Cfg.Colors.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            // Body
                            Text {
                                text: toast.modelData.body
                                font.family: Cfg.Config.fontFamily
                                font.pixelSize: 12
                                color: Cfg.Colors.subtext
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: toast.modelData.body !== ""
                            }
                        }

                        // Botão fechar
                        Text {
                            text: "󰅖"  // nf-md-close
                            font.family: Cfg.Config.iconFontFamily
                            font.pixelSize: 14
                            color: Cfg.Colors.dim
                            Layout.alignment: Qt.AlignTop

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: toast.modelData.dismiss()
                            }
                        }
                    }
                }

                // Barra de progresso (tempo restante)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: 4
                    height: 2
                    radius: 1
                    color: toast.urgencyColor(toast.modelData.urgency)
                    opacity: 0.5

                    width: progressAnim.running ? 0 : (parent.width - 8)

                    Behavior on width {
                        enabled: false
                    }

                    NumberAnimation on width {
                        id: progressAnim
                        from: toast.width - 8
                        to: 0
                        duration: dismissTimer.interval
                        running: dismissTimer.running
                    }
                }
            }
        }
    }
}
