import QtQuick
import "../config" as Cfg

Rectangle {
    id: root
    width: 36
    height: 20
    radius: 10
    
    property bool checked: false
    signal clicked()

    color: checked ? Cfg.Colors.accent : Cfg.Colors.bgAlt
    border.color: checked ? Cfg.Colors.accent : Cfg.Colors.border
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade }
    }
    Behavior on border.color {
        ColorAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade }
    }

    Rectangle {
        id: handle
        width: 14; height: 14; radius: 7
        color: checked ? Cfg.Colors.bg : Cfg.Colors.subtext
        anchors.verticalCenter: parent.verticalCenter
        x: checked ? parent.width - width - 3 : 3

        Behavior on x {
            NumberAnimation { 
                duration: Cfg.Config.animMed 
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Cfg.Config.easingEmphasized
            }
        }
        Behavior on color {
            ColorAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
        cursorShape: Qt.PointingHandCursor
    }
}
