import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config" as Cfg
import "../services" as Services
import "../widgets" as Widgets

Item {
    id: root
    implicitWidth: 250
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Widgets.SymbolicIcon {
                name: Services.Weather.icon
                width: 24; height: 24
                color: Cfg.Colors.text
                Layout.alignment: Qt.AlignVCenter
            }
            
            ColumnLayout {
                spacing: 0
                Text { text: Services.Weather.city; color: Cfg.Colors.text; font.bold: true; font.pixelSize: 14 }
                Text { text: Services.Weather.desc; color: Cfg.Colors.dim; font.pixelSize: 12 }
            }
        }
        
        Rectangle { Layout.fillWidth: true; height: 1; color: Cfg.Colors.divider }

        // Metrics Grid
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 10
            columnSpacing: 16
            
            RowLayout {
                spacing: 8
                Text { text: "🌡️"; font.pixelSize: 14; Layout.alignment: Qt.AlignVCenter }
                ColumnLayout {
                    spacing: 0
                    Text { text: "Sensação"; color: Cfg.Colors.dim; font.pixelSize: 10 }
                    Text { text: Services.Weather.feelsLike + "°C"; color: Cfg.Colors.text; font.pixelSize: 13; font.bold: true }
                }
            }

            RowLayout {
                spacing: 8
                Text { text: "💧"; font.pixelSize: 14; Layout.alignment: Qt.AlignVCenter }
                ColumnLayout {
                    spacing: 0
                    Text { text: "Umidade"; color: Cfg.Colors.dim; font.pixelSize: 10 }
                    Text { text: Services.Weather.humidity + "%"; color: Cfg.Colors.text; font.pixelSize: 13; font.bold: true }
                }
            }

            RowLayout {
                spacing: 8
                Text { text: "🌬️"; font.pixelSize: 14; Layout.alignment: Qt.AlignVCenter }
                ColumnLayout {
                    spacing: 0
                    Text { text: "Vento"; color: Cfg.Colors.dim; font.pixelSize: 10 }
                    Text { text: Services.Weather.wind + " km/h"; color: Cfg.Colors.text; font.pixelSize: 13; font.bold: true }
                }
            }
            
            RowLayout {
                spacing: 8
                Text { text: "↕️"; font.pixelSize: 14; Layout.alignment: Qt.AlignVCenter }
                ColumnLayout {
                    spacing: 0
                    Text { text: "Mín/Máx"; color: Cfg.Colors.dim; font.pixelSize: 10 }
                    Text { text: Services.Weather.tempMin + "° / " + Services.Weather.tempMax + "°"; color: Cfg.Colors.text; font.pixelSize: 13; font.bold: true }
                }
            }
        }
    }
}
