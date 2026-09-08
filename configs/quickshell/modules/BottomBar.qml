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
//
// PERSONALIZÁVEL (aba "Barras" da Central): geometria, borda e opacidade
// vêm de Cfg.BarConfig; os itens visíveis — e a ordem deles — são
// `Cfg.BarConfig.bottomEnabledIds`, instanciados via Loader (a seção de
// cada grupo) com um divisor automático entre grupos diferentes. O
// auto-revelar continua idêntico: a barra só recolhe quando nenhum popup
// (sysmenu) nem menu (tray) estiver aberto.
PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    readonly property int barContentHeight: Cfg.BarConfig.barHeight
    readonly property int revealStrip: 6           // pixels sempre visíveis, encostados na borda
    readonly property int hiddenOffset: barContentHeight + Cfg.BarConfig.barMargin - revealStrip

    property bool revealed: false

    // Rastreia o item de sysmenu/tray atualmente carregado (se estiver
    // habilitado). Mantemos a referência separada pra continuar reagindo a
    // popupOpen/menuOpen por binding real — ver trackItem() no delegate.
    property var sysMenuItem: null
    property var trayItem: null

    function trackItem(id, item) {
        if (id === "sysmenu") root.sysMenuItem = item
        else if (id === "tray") root.trayItem = item
    }

    // Grupo de cada item, pra decidir o divisor automático (workspaces |
    // sysmenu | tray). Itens do mesmo grupo não ganham divisor entre si.
    function groupOf(id) {
        switch (id) {
            case "workspaces": return 0
            case "sysmenu": return 1
            case "tray": return 2
            default: return -1
        }
    }

    // PEDIDO: continuar revelada enquanto o mouse estiver sobre a ilha OU
    // enquanto um popup aberto por ela (áudio/sistema) ou um menu de tray
    // estiver em uso — mesmo que o mouse tenha saído da área da ilha em si
    // pra ir até esse popup/menu, que é uma janela separada e não conta
    // como "hover" pro MouseArea abaixo.
    readonly property bool shouldStayRevealed: hoverHandler.hovered
        || (sysMenuItem !== null && sysMenuItem.popupOpen)
        || (trayItem !== null && trayItem.menuOpen)

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
    implicitHeight: barContentHeight + Cfg.BarConfig.barMargin
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

    readonly property real barAlpha: {
        const o = Cfg.BarConfig.bottomOpacity
        if (o === null || o === undefined || o < 0) return Cfg.Colors.baseOpacity
        return o
    }

    // Cada tipo de item, empacotado em Component pra seleção por id.
    Component { id: compWorkspaces; WorkspaceDock {} }
    Component { id: compSysmenu; SysMenuGroup {} }
    Component { id: compTray; Tray {} }

    function itemById(id) {
        switch (id) {
            case "workspaces": return compWorkspaces
            case "sysmenu": return compSysmenu
            case "tray": return compTray
            default: return null
        }
    }

    Rectangle {
        width: content.implicitWidth + Cfg.BarConfig.contentPadding * 2
        height: root.barContentHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Cfg.BarConfig.barMargin
        radius: Cfg.BarConfig.barRadius
        color: Qt.rgba(Cfg.Colors.bgSolid.r, Cfg.Colors.bgSolid.g, Cfg.Colors.bgSolid.b, root.barAlpha)
        border.color: Cfg.Colors.border
        border.width: Cfg.BarConfig.showBorder ? Cfg.BarConfig.borderWidth : 0

        RowLayout {
            id: content
            anchors.centerIn: parent
            spacing: Cfg.BarConfig.itemSpacing

            Repeater {
                model: Cfg.BarConfig.bottomEnabledIds

                // Uma "seção" por item: divisor (visível quando o grupo muda
                // frente ao item anterior) + widget carregado.
                delegate: RowLayout {
                    id: row
                    spacing: 0

                    readonly property bool showDivider: index > 0
                        && root.groupOf(model[index - 1]) !== root.groupOf(modelData)

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 6
                        Layout.bottomMargin: 6
                        color: Cfg.Colors.divider
                        visible: row.showDivider
                    }

                    Loader {
                        id: itemLoader
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: root.itemById(modelData)
                        onLoaded: root.trackItem(modelData, itemLoader.item)
                        // (não há onUnloaded que dispare neste Loader; o teardown
                        //  real é o delegate destruído ao desligar o item — abaixo)
                        Component.onDestruction: root.trackItem(modelData, null)
                    }
                }
            }
        }
    }
}