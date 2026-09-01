import QtQuick
import "../config" as Cfg

// Bloco base dos docks da barra inferior: recolhido é um círculo/pílula
// pequena; ao passar o mouse, expande lateralmente revelando o conteúdo.
// Reaproveitado por WorkspaceDock.qml e SysTrayDock.qml.
Item {
    id: root

    property bool expanded: hoverArea.containsMouse || forceExpanded
    property bool forceExpanded: false   // usado p/ manter aberto com popup filho ativo
    property int collapsedWidth: Cfg.Config.dockCollapsedSize
    property int collapsedHeight: Cfg.Config.dockCollapsedSize
    property alias content: contentLoader.sourceComponent
    property alias collapsedContent: collapsedLoader.sourceComponent
    property alias hovered: hoverArea.containsMouse

    implicitHeight: Cfg.Config.dockCollapsedSize
    implicitWidth: expanded ? expandedWidth : collapsedWidth

    property int expandedWidth: contentLoader.item ? contentLoader.item.implicitWidth + Cfg.Config.contentPadding * 2 : collapsedWidth

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
        color: root.hovered ? Cfg.Colors.bgElevated : Cfg.Colors.bgAlt
        border.color: Cfg.Colors.border
        border.width: 1
        clip: true

        Behavior on color {
            ColorAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade }
        }

        // Conteúdo recolhido (ícone único, por ex.)
        Loader {
            id: collapsedLoader
            anchors.centerIn: parent
            active: !root.expanded
            opacity: root.expanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }
        }

        // Conteúdo expandido (fica montado por baixo, só aparece quando abre)
        Loader {
            id: contentLoader
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Cfg.Config.contentPadding
            active: true
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        // Não consome cliques — cada item do conteúdo tem seu próprio MouseArea.
        acceptedButtons: Qt.NoButton
    }
}
