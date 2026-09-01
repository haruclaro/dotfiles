import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../config" as Cfg

// PEDIDO: a ilha inferior inteira volta a ficar escondida por padrão,
// aparecendo só com o mouse na borda de baixo da tela (igual à barra de
// tarefas do Windows) — igual ao que já tínhamos feito antes, só que
// dessa vez sem also colapsar os workspaces (esses continuam sempre
// visíveis assim que a ilha aparece) nem o dock de tray/config (que
// também não recolhe mais sozinho — ver SysMenuGroup.qml/Tray.qml).
//
// PEDIDO: Tray movido pra seção própria, fixa, na PONTA DIREITA da ilha.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property int barContentHeight: Cfg.Config.barHeight
    readonly property int revealStrip: 6           // pixels sempre visíveis, encostados na borda
    readonly property int hiddenOffset: barContentHeight + Cfg.Config.barMargin - revealStrip

    property bool revealed: false

    // PEDIDO: continuar revelada enquanto o mouse estiver sobre a ilha OU
    // enquanto um popup aberto por ela (áudio/sistema) ou um menu de tray
    // estiver em uso — mesmo que o mouse tenha saído da área da ilha em si
    // pra ir até esse popup/menu, que é uma janela separada e não conta
    // como "hover" pro MouseArea abaixo.
    // Mudamos de hoverArea.containsMouse para hoverHandler.hovered
    readonly property bool shouldStayRevealed: hoverHandler.hovered || sysMenuGroup.popupOpen || trayDock.menuOpen

    onShouldStayRevealedChanged: {
        if (shouldStayRevealed) {
            hideTimer.stop()
            revealed = true
        } else {
            hideTimer.restart()
        }
    }

    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: 0                                 // não reserva espaço — some de verdade quando escondida
    implicitHeight: barContentHeight + Cfg.Config.barMargin
    margins.bottom: revealed ? 0 : -hiddenOffset
    color: "transparent"

    WlrLayershell.namespace: "quickshell:bottombar"
    WlrLayershell.layer: WlrLayer.Top

    Behavior on margins.bottom {
        NumberAnimation {
            duration: Cfg.Config.animMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Cfg.Config.easingEmphasized
        }
    }

    // Evita "piscar" quando o mouse só passa de raspão pela tira de
    // revelação sem intenção de abrir a barra de verdade. Só dispara de
    // fato se, ao final do intervalo, shouldStayRevealed continuar falso
    // (ou seja, nem hover nem popup aberto).
    Timer {
        id: hideTimer
        interval: 350
        onTriggered: {
            if (!root.shouldStayRevealed) root.revealed = false
        }
    }

    // Cobre a janela inteira (largura total da tela) — qualquer hover na
    // borda de baixo, em qualquer ponto horizontal, revela a barra.
    HoverHandler {
        id: hoverHandler
        // O HoverHandler não precisa de anchors.fill: parent, 
        // ele atua automaticamente sobre o elemento pai (PanelWindow).
    }

    Rectangle {
        width: content.implicitWidth + Cfg.Config.contentPadding * 2
        height: root.barContentHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Cfg.Config.barMargin
        radius: Cfg.Config.barRadius
        color: Cfg.Colors.bg
        border.color: Cfg.Colors.border
        border.width: 1

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: 14

            WorkspaceDock { Layout.alignment: Qt.AlignVCenter }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 6; Layout.bottomMargin: 6; color: Cfg.Colors.divider }

            SysMenuGroup { id: sysMenuGroup; Layout.alignment: Qt.AlignVCenter }

            Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; Layout.topMargin: 6; Layout.bottomMargin: 6; color: Cfg.Colors.divider }

            // Tray por último no RowLayout = fica na ponta direita da ilha.
            Tray { id: trayDock; Layout.alignment: Qt.AlignVCenter }
        }
    }
}
