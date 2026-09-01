import QtQuick
import QtQuick.Layouts
import "../config" as Cfg
import "../services" as Services
import "../widgets" as Widgets
import "../popups" as Popups

Item {
    id: root
    implicitWidth: 62
    implicitHeight: Cfg.Config.barHeight - 8

    readonly property color severityColor: {
        if (Services.Resources.severity === "critical") return Cfg.Colors.critical
        if (Services.Resources.severity === "warning") return Cfg.Colors.warning
        return Cfg.Colors.accent
    }

    Rectangle {
        id: btn
        anchors.fill: parent
        radius: Cfg.Config.chipRadius
        color: hoverArea.containsMouse ? Cfg.Colors.hoverOverlay : "transparent"

        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            Widgets.SymbolicIcon { name: Cfg.Icons.resourceMonitor; width: 14; height: 14; color: root.severityColor }
            Rectangle {
                Layout.preferredWidth: 34; Layout.preferredHeight: 5; radius: 2.5
                color: Cfg.Colors.border
                Rectangle {
                    width: parent.width * Services.Resources.overallUsage
                    height: parent.height; radius: 2.5
                    color: root.severityColor
                    Behavior on width { NumberAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }
                }
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: resourcePopup.toggle()
    }

    Widgets.AnchoredPopup {
        id: resourcePopup
        anchorItem: btn
        contentComponent: Popups.ResourcePopup {}
    }
}
