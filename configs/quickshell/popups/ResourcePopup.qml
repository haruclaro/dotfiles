import QtQuick
import QtQuick.Layouts
import "../config" as Cfg
import "../services" as Services

Item {
    id: root
    implicitWidth: 290
    implicitHeight: col.implicitHeight

    component Meter: RowLayout {
        property string label
        property int value
        property string unit: "%"
        property string extraText: ""
        property color barColor: Cfg.Colors.accent
        Layout.fillWidth: true
        spacing: 8

        Text { text: label; color: Cfg.Colors.subtext; font.pixelSize: 11; Layout.preferredWidth: 90 }
        Rectangle {
            Layout.fillWidth: true; height: 6; radius: 3
            color: Cfg.Colors.border
            Rectangle {
                width: parent.width * Math.min(value / 100, 1)
                height: parent.height; radius: 3
                color: barColor
            }
        }
        Text {
            text: (extraText ? extraText + "  " : "") + value + unit
            color: Cfg.Colors.text
            font.pixelSize: 11
            Layout.preferredWidth: 95
            horizontalAlignment: Text.AlignRight
        }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Processador"; color: Cfg.Colors.subtext; font.bold: true; font.pixelSize: 12 }
            Meter { label: "Uso"; value: Services.Resources.cpu }
            Meter { label: "Temperatura"; value: Services.Resources.cpuTemp; unit: "°C"; barColor: Cfg.Colors.warning }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Placa de Vídeo (NVIDIA)"; color: Cfg.Colors.subtext; font.bold: true; font.pixelSize: 12 }
            Meter { label: "Uso"; value: Services.Resources.gpu }
            Meter { label: "Temperatura"; value: Services.Resources.gpuTemp; unit: "°C"; barColor: Cfg.Colors.warning }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Memória e Disco"; color: Cfg.Colors.subtext; font.bold: true; font.pixelSize: 12 }
            Meter { label: "RAM"; value: Services.Resources.ram; extraText: Services.Resources.ramText }
            Meter { label: "Disco (/)"; value: Services.Resources.disk }
        }
    }
}
