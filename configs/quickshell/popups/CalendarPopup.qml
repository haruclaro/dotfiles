import QtQuick
import QtQuick.Layouts
import "../config" as Cfg

// CORRIGIDO: Qt.labs.calendar não vem instalado em toda distro do Qt6
// (log: "module Qt.labs.calendar is not installed"). Em vez de depender
// dele, calculamos o grid do mês manualmente — só QtQuick puro, sem
// módulos extras.
Item {
    id: root
    implicitWidth: 240
    implicitHeight: col.implicitHeight

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   // 0-11

    readonly property var weekDayNames: ["D", "S", "T", "Q", "Q", "S", "S"]
    readonly property var monthNames: [
        "Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
        "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"
    ]

    function buildGrid() {
        const first = new Date(root.viewYear, root.viewMonth, 1)
        const startOffset = first.getDay()   // 0=domingo
        const gridStart = new Date(root.viewYear, root.viewMonth, 1 - startOffset)

        const cells = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(gridStart)
            d.setDate(gridStart.getDate() + i)
            cells.push({
                day: d.getDate(),
                month: d.getMonth(),
                year: d.getFullYear(),
                inMonth: d.getMonth() === root.viewMonth,
                isToday: d.toDateString() === root.today.toDateString(),
            })
        }
        return cells
    }

    property var gridCells: buildGrid()
    onViewMonthChanged: gridCells = buildGrid()
    onViewYearChanged: gridCells = buildGrid()

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                width: 22; height: 22; radius: Cfg.Config.chipRadius; color: "transparent"
                Text { anchors.centerIn: parent; text: "‹"; color: Cfg.Colors.text; font.pixelSize: 16 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        let m = root.viewMonth - 1, y = root.viewYear
                        if (m < 0) { m = 11; y -= 1 }
                        root.viewMonth = m; root.viewYear = y
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
                color: Cfg.Colors.text
                font.bold: true
                font.pixelSize: 13
            }

            Rectangle {
                width: 22; height: 22; radius: Cfg.Config.chipRadius; color: "transparent"
                Text { anchors.centerIn: parent; text: "›"; color: Cfg.Colors.text; font.pixelSize: 16 }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        let m = root.viewMonth + 1, y = root.viewYear
                        if (m > 11) { m = 0; y += 1 }
                        root.viewMonth = m; root.viewYear = y
                    }
                }
            }
        }

        GridLayout {
            columns: 7
            rowSpacing: 4
            columnSpacing: 4
            Layout.fillWidth: true

            Repeater {
                model: root.weekDayNames
                delegate: Text {
                    required property string modelData
                    Layout.preferredWidth: 28
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Cfg.Colors.dim
                    font.pixelSize: 10
                }
            }

            Repeater {
                model: root.gridCells
                delegate: Rectangle {
                    id: cell
                    required property var modelData
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: Cfg.Config.chipRadius
                    color: cell.modelData.isToday ? Cfg.Colors.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        font.pixelSize: 11
                        color: cell.modelData.isToday
                            ? Cfg.Colors.bg
                            : (cell.modelData.inMonth ? Cfg.Colors.text : Cfg.Colors.dim)
                    }
                }
            }
        }
    }
}
