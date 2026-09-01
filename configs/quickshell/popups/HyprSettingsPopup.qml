import QtQuick
import QtQuick.Layouts
import "../config" as Cfg
import "../services" as Services

// PEDIDO: "módulo pra editar configurações do Hyprland... que pode ser
// feito apenas via código". Segue a filosofia do HyprMod
// (github.com/BlueManCZ/hyprmod): nunca mexe no hyprland.conf principal —
// só escreve em ~/.config/hypr/quickshell-mod.conf, incluído via
// "source =" (ver services/HyprConfig.qml). Diferente do HyprMod (app
// GTK4 nativo completo, com editor de curvas bezier, layout de monitores,
// keybinds interativos etc — fora do escopo viável aqui dentro de um
// popup do painel), esse é um ponto de partida cobrindo os ajustes mais
// comuns: gaps, bordas, cantos arredondados, cores de borda e itens de
// autostart.
Item {
    id: root
    implicitWidth: 340
    implicitHeight: col.implicitHeight

    component NumberField: RowLayout {
        property string label: ""
        property alias value: input.text
        Layout.fillWidth: true
        spacing: 8
        Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 110 }
        Rectangle {
            Layout.fillWidth: true; height: 28; radius: Cfg.Config.chipRadius
            color: Cfg.Colors.bgAlt; border.color: input.activeFocus ? Cfg.Colors.accent : Cfg.Colors.border; border.width: 1
            TextInput {
                id: input
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Cfg.Colors.text
                font.pixelSize: 12
                validator: IntValidator { bottom: 0; top: 999 }
                selectByMouse: true
                onTextEdited: Services.HyprConfig.markDirty()
            }
        }
    }

    component ColorField: RowLayout {
        property string label: ""
        property alias value: input.text
        Layout.fillWidth: true
        spacing: 8
        Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 12; Layout.preferredWidth: 110 }
        Rectangle {
            Layout.fillWidth: true; height: 28; radius: Cfg.Config.chipRadius
            color: Cfg.Colors.bgAlt; border.color: input.activeFocus ? Cfg.Colors.accent : Cfg.Colors.border; border.width: 1
            TextInput {
                id: input
                anchors.fill: parent
                anchors.margins: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Cfg.Colors.text
                font.pixelSize: 11
                selectByMouse: true
                onTextEdited: Services.HyprConfig.markDirty()
            }
        }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Text { text: "Hyprland"; color: Cfg.Colors.subtext; font.bold: true; font.pixelSize: 12; Layout.fillWidth: true }
            Text {
                text: Services.HyprConfig.dirty ? "Não salvo" : "Salvo"
                color: Services.HyprConfig.dirty ? Cfg.Colors.warning : Cfg.Colors.good
                font.pixelSize: 10
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "Espaçamento e bordas"; color: Cfg.Colors.dim; font.pixelSize: 10 }
            NumberField { label: "Gap interno"; value: Services.HyprConfig.gapsIn; onValueChanged: Services.HyprConfig.gapsIn = parseInt(value) || 0 }
            NumberField { label: "Gap externo"; value: Services.HyprConfig.gapsOut; onValueChanged: Services.HyprConfig.gapsOut = parseInt(value) || 0 }
            NumberField { label: "Espessura borda"; value: Services.HyprConfig.borderSize; onValueChanged: Services.HyprConfig.borderSize = parseInt(value) || 0 }
            NumberField { label: "Arredondamento"; value: Services.HyprConfig.rounding; onValueChanged: Services.HyprConfig.rounding = parseInt(value) || 0 }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "Cores de borda"; color: Cfg.Colors.dim; font.pixelSize: 10 }
            ColorField { label: "Ativa"; value: Services.HyprConfig.activeBorderColor; onValueChanged: Services.HyprConfig.activeBorderColor = value }
            ColorField { label: "Inativa"; value: Services.HyprConfig.inactiveBorderColor; onValueChanged: Services.HyprConfig.inactiveBorderColor = value }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Autostart (exec-once)"; color: Cfg.Colors.dim; font.pixelSize: 10 }

            Repeater {
                model: Services.HyprConfig.autostart
                delegate: RowLayout {
                    required property string modelData
                    required property int index
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: Cfg.Colors.text
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        width: 20; height: 20; radius: Cfg.Config.chipRadius
                        color: rmHover.containsMouse ? Cfg.Colors.critical : Cfg.Colors.bgAlt
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: rmHover.containsMouse ? Cfg.Colors.bg : Cfg.Colors.subtext }
                        MouseArea { id: rmHover; anchors.fill: parent; hoverEnabled: true; onClicked: Services.HyprConfig.removeAutostart(index) }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Rectangle {
                    Layout.fillWidth: true; height: 26; radius: Cfg.Config.chipRadius
                    color: Cfg.Colors.bgAlt; border.color: Cfg.Colors.border; border.width: 1
                    TextInput {
                        id: newAutostart
                        anchors.fill: parent
                        anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        color: Cfg.Colors.text
                        font.pixelSize: 11
                        selectByMouse: true
                        Keys.onReturnPressed: { Services.HyprConfig.addAutostart(text); text = "" }
                    }
                }
                Rectangle {
                    width: 26; height: 26; radius: Cfg.Config.chipRadius
                    color: Cfg.Colors.accentDim
                    Text { anchors.centerIn: parent; text: "+"; color: Cfg.Colors.text; font.pixelSize: 14 }
                    MouseArea { anchors.fill: parent; onClicked: { Services.HyprConfig.addAutostart(newAutostart.text); newAutostart.text = "" } }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Rectangle {
                Layout.fillWidth: true; height: 32; radius: Cfg.Config.chipRadius
                color: Cfg.Colors.accent
                Text { anchors.centerIn: parent; text: "Salvar e recarregar"; color: Cfg.Colors.bg; font.pixelSize: 12; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: Services.HyprConfig.save() }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Escreve em ~/.config/hypr/quickshell-mod.conf (nunca no hyprland.conf principal) e roda \"hyprctl reload\"."
            color: Cfg.Colors.dim
            font.pixelSize: 10
            wrapMode: Text.Wrap
        }
    }
}
