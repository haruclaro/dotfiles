import QtQuick
import QtQuick.Effects
import Quickshell

// PEDIDO: usar ícones do tema do sistema (iguais ao AGS original), com a
// cor aplicada por cima igual o GTK faz com ícones "symbolic" (eles
// seguem a cor do texto ao redor, não têm cor própria fixa).
//
// HISTÓRICO: as duas primeiras tentativas de colorir com MultiEffect
// pareciam não funcionar — mas isso foi ANTES de descobrirmos que faltava
// o "//@ pragma IconTheme Adwaita" no shell.qml. Sem esse pragma,
// Quickshell.iconPath() retornava string vazia pra tudo, então a Image
// de origem já estava sem nenhuma textura — o MultiEffect não tinha nada
// pra colorir de qualquer forma, então aquele teste não provava nada
// sobre o MultiEffect em si. Agora que os ícones carregam de verdade,
// vale tentar de novo.
Item {
    id: root

    property string name: ""
    property color color: "white"
    property bool colorize: true

    implicitWidth: 16
    implicitHeight: 16

    Image {
        id: img
        anchors.fill: parent
        source: root.name ? Quickshell.iconPath(root.name, true) : ""
        sourceSize.width: Math.max(root.width, 1) * 2   // 2x pra ficar nítido em telas HiDPI
        sourceSize.height: Math.max(root.height, 1) * 2
        smooth: true
        fillMode: Image.PreserveAspectFit
        // MultiEffect precisa que a Image fonte esteja "visible: true" pra
        // conseguir capturar a textura dela — por isso escondemos com
        // opacity (que ainda renderiza o item normalmente) em vez de
        // visible (que exclui o item da cena inteira).
        visible: true
        opacity: root.colorize ? 0 : 1
    }

    MultiEffect {
        anchors.fill: parent
        source: img
        visible: root.colorize
        colorization: 1.0
        colorizationColor: root.color
        // CORRIGIDO ("cor do resource monitor ficou estranha, bloco
        // sólido"): brightness: 1.0 não é um valor neutro — é o MÁXIMO de
        // brilho (o neutro é 0.0, o padrão da propriedade). Com 1.0, o
        // ícone ficava estourado/lavado até virar um bloco sólido em vez
        // de manter o desenho original só tingido na cor. Removido —
        // deixa no padrão (0.0, sem alteração de brilho).
    }
}
