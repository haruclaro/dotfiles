import QtQuick
import Quickshell
import "../config" as Cfg

PopupWindow {
    id: root

    property Item anchorItem
    property Component contentComponent
    // Edges.Bottom por padrão (cresce pra baixo, centralizado em relação ao botão)
    property int edges: Edges.Bottom
    property int popupMargin: 16

    implicitWidth: loader.item ? loader.item.implicitWidth + Cfg.Config.contentPadding * 2 : 1
    implicitHeight: loader.item ? loader.item.implicitHeight + Cfg.Config.contentPadding * 2 + popupMargin : 1
    visible: false
    color: "transparent"

    property bool isPinned: false
    property bool isTooltip: false
    grabFocus: !isPinned && !isTooltip

    anchor.item: anchorItem
    anchor.edges: edges
    anchor.gravity: edges

    function toggle() {
        if (root.visible) {
            root.close()
        } else {
            root.anchor.updateAnchor()
            root.visible = true
            frameScaleAnim.restart()
            frameOpacityAnim.restart()
        }
    }

    function close() { 
        if (!isPinned) root.visible = false 
    }

    Item {
        anchors.fill: parent
        anchors.bottomMargin: (edges & Edges.Top) ? popupMargin : 0
        anchors.topMargin: (edges & Edges.Bottom) ? popupMargin : 0

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: Cfg.Config.barRadius
            color: Cfg.Colors.bgElevated
            border.color: Cfg.Colors.border
            border.width: 1

            focus: root.visible
            Keys.onEscapePressed: { isPinned = false; root.visible = false }

            scale: 1
            opacity: 1
            
            NumberAnimation on scale {
                id: frameScaleAnim
                from: 0.8
                to: 1.0
                duration: Cfg.Config.animMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Cfg.Config.curveFastSpatial
                running: false
            }
            NumberAnimation on opacity {
                id: frameOpacityAnim
                from: 0
                to: 1
                duration: Cfg.Config.animFast
                easing.type: Cfg.Config.easingFade
                running: false
            }

            Loader {
                id: loader
                anchors.fill: parent
                anchors.margins: Cfg.Config.contentPadding
                sourceComponent: root.contentComponent
                active: root.visible
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                width: 24; height: 24
                radius: Cfg.Config.chipRadius
                color: root.isPinned ? Cfg.Colors.accent : (pinHover.containsMouse ? Cfg.Colors.hoverOverlay : "transparent")
                z: 10
                
                Text {
                    anchors.centerIn: parent
                    text: "📌"
                    font.pixelSize: 10
                    color: root.isPinned ? Cfg.Colors.bg : Cfg.Colors.dim
                }
                MouseArea {
                    id: pinHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.isPinned = !root.isPinned
                }
            }
        }
    }
}
