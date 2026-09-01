pragma Singleton
import QtQuick

QtObject {
    // --- Tipografia ---
    // PEDIDO: revisar fontes/ícones. O sys_monitor.sh original do usuário
    // já usava glifos de Nerd Font no tooltip do Waybar (ex: "󰢮" pra GPU) —
    // ou seja, já existe uma Nerd Font instalada no sistema. Trocamos os
    // emojis "soltos" (que vêm de fontes de fallback com métricas de
    // altura/baseline inconsistentes — causa raiz do clima desalinhado) por
    // glifos de ícone dessa mesma família, que são desenhados pra encaixar
    // certinho ao lado de texto normal em barras de status.
    readonly property string fontFamily: "Inter"                    // texto normal da UI
    readonly property string monoFontFamily: "JetBrainsMono Nerd Font"  // letreiro de mídia, monoespaçado
    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"  // glifos de ícone (Font Awesome/MDI via Nerd Font)
    // Se algumas dessas famílias não estiverem instaladas, o Qt substitui
    // automaticamente pela fonte padrão do sistema — não trava nem gera
    // erro, só fica com aparência menos consistente. Ajusta os nomes acima
    // pra bater com o que tens instalado (`fc-list | grep -i nerd`).

    // --- Geometria ---
    readonly property int barRadius: 18
    readonly property int chipRadius: 999          // pill totalmente arredondado
    readonly property int barHeight: 34
    readonly property int barMargin: 8              // distância da barra até a borda da tela
    readonly property int dockCollapsedSize: 34      // diâmetro do dock recolhido (workspaces / sysmenu)
    readonly property int contentPadding: 10

    // --- Animação ---
    // Caelestia usa curvas "emphasized" (Material 3) em vez de easing linear/padrão do Qt.
    // Aproximação via bezier: expressivo ao entrar, suave ao sair.
    readonly property int animFast: 200
    readonly property int animMed: 350
    readonly property int animSlow: 500
    readonly property var easingEmphasized: [0.05, 0.7, 0.1, 1.0, 1, 1]   // cubic-bezier emphasized-decelerate
    readonly property int easingFade: Easing.OutCubic                      // curva suave p/ opacity e color
    
    // Curvas com Overshoot (Efeito Mola)
    readonly property var curveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]

    // --- Caminhos ---
    // PEDIDO: os scripts que já existiam em ~/.config/ags/scripts devem ser
    // copiados para ~/.config/quickshell/scripts (mesmos arquivos, sem
    // alteração de conteúdo — só o local muda). Ajusta aqui se preferires
    // manter outro caminho.
    readonly property string scriptsDir: Qt.resolvedUrl("../scripts").toString().replace("file://", "")
    readonly property string weatherScript: scriptsDir + "/weather.sh"
    readonly property string weatherSetCityScript: scriptsDir + "/weather-set-city.sh"
    readonly property string peripheralsScript: scriptsDir + "/peripherals.sh"
    readonly property string wifiStatusScript: scriptsDir + "/wifi-status.sh"
    readonly property string themeScript: scriptsDir + "/trocar_tema.sh"
    readonly property string themeApplyScript: scriptsDir + "/apply-custom-theme.sh"
    readonly property string exitScript: scriptsDir + "/graceful_exit.sh"

    // --- Polling ---
    readonly property int weatherIntervalMs: 600000   // 10 min, igual ao Waybar original
    readonly property int resourceIntervalMs: 2000
    readonly property int diskIntervalMs: 60000
    readonly property int peripheralsIntervalMs: 10000
}
