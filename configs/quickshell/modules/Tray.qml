import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../config" as Cfg
import "../widgets" as Widgets

// PEDIDO: Tray como seção própria, posicionada à direita da ilha inferior
// (ver BottomBar.qml — é o último item do RowLayout, então fica na ponta
// direita).
//
// PEDIDO NOVO 1: o ícone de wifi/rede (nm-applet) não precisa aparecer
// aqui — já mostramos o status de rede dentro do SysMenuPopup. Filtramos
// pelo id/título do item.
//
// PEDIDO NOVO 2: recolhido, mostra só um ícone ">" (pan-end-symbolic);
// ao passar o mouse, os ícones reais da bandeja aparecem (o ">" some) —
// mesmo padrão de "encolhe pro ícone/expande no hover" já usado no
// MediaIndicator.qml.
//
// CORRIGIDO (log: "PlatformMenuEntry.display() must be called with a
// window"): SystemTrayItem.display(parentWindow, x, y) exige um objeto
// de janela do PRÓPRIO Quickshell (QsWindow) — usamos QsMenuAnchor em vez
// disso, ancorado ao próprio ícone via anchor.item (mesma técnica do
// AnchoredPopup.qml).
Item {
    id: root

    // Pode haver vários menus abertos ao mesmo tempo (um por ícone via
    // Repeater) — contamos em vez de um bool simples.
    property int _openMenus: 0
    readonly property bool menuOpen: _openMenus > 0

    readonly property bool expanded: hoverArea.containsMouse || menuOpen

    readonly property var trayItems: {
        const list = []
        for (const item of SystemTray.items.values) {
            const id = (item.id || "").toLowerCase()
            const title = (item.title || "").toLowerCase()
            const isNetwork = id.includes("network") || id.includes("nm-applet")
                || title.includes("network") || title.includes("wi-fi") || title.includes("wifi")
            if (!isNetwork) list.push(item)
        }
        return list
    }

    implicitWidth: expanded ? row.implicitWidth : collapsedIcon.implicitWidth
    implicitHeight: Cfg.Config.dockCollapsedSize
    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: Cfg.Config.animMed
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Cfg.Config.easingEmphasized
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // --- Recolhido: só o ">" ---
    Widgets.SymbolicIcon {
        id: collapsedIcon
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        name: Cfg.Icons.trayCollapsed
        width: 14; height: 14
        color: Cfg.Colors.subtext
        opacity: root.expanded ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }
    }

    // --- Expandido: ícones reais da bandeja ---
    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        spacing: 6
        opacity: root.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Cfg.Config.animFast; easing.type: Cfg.Config.easingFade } }

        Repeater {
            model: root.trayItems
            delegate: Item {
                id: trayIcon
                required property var modelData
                implicitWidth: 20; implicitHeight: 20

                Image {
                    anchors.fill: parent
                    source: trayIcon.modelData.icon
                    smooth: true
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: trayIcon.modelData.menu
                    anchor.item: trayIcon
                    anchor.edges: Edges.Bottom | Edges.Left
                    anchor.gravity: Edges.Bottom | Edges.Left
                    anchor.margins.top: 6
                    onVisibleChanged: root._openMenus += visible ? 1 : -1
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (evt) => {
                        const item = trayIcon.modelData
                        if ((evt.button === Qt.RightButton || item.onlyMenu) && item.hasMenu) {
                            menuAnchor.open()
                        } else if (!item.onlyMenu) {
                            item.activate()
                        }
                    }
                }
            }
        }

        // Placeholder discreto quando não há nenhum ícone na bandeja
        // (depois do filtro de rede), só pra não colapsar a zero.
        Text {
            visible: root.trayItems.length === 0
            text: "—"
            color: Cfg.Colors.dim
            font.pixelSize: 11
        }
    }
}
