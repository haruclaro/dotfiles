pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// PEDIDO: "módulo pra editar configurações do Hyprland... que pode ser
// feito apenas via código". Baseado na filosofia do HyprMod
// (github.com/BlueManCZ/hyprmod): NUNCA edita o hyprland.conf principal
// direto — escreve só num arquivo próprio, incluído via "source =". Isso
// significa que o usuário pode editar hyprland.conf à vontade sem medo
// de conflito, e é super fácil de "desfazer tudo": só remove a linha de
// source.
QtObject {
    id: root

    readonly property string modConfPath: "/.config/hypr/quickshell-mod.conf"
    readonly property string mainConfPath: "/.config/hypr/hyprland.conf"

    // Valores atuais (lidos do arquivo próprio na abertura do módulo)
    property int gapsIn: 5
    property int gapsOut: 10
    property int borderSize: 2
    property int rounding: 8
    property string activeBorderColor: "rgba(8aadf4ff)"
    property string inactiveBorderColor: "rgba(2c2f42aa)"
    property var autostart: []   // lista de strings, uma por linha "exec-once"

    property bool loaded: false
    property bool dirty: false    // true quando há mudanças não salvas

    signal saved()
    signal saveFailed(string reason)

    function _fullPath(rel) {
        return "file://" + Quickshell.env("HOME") + rel
    }

    property FileView modFile: FileView {
        path: root._fullPath(root.modConfPath)
        printErrors: false
        watchChanges: false   // evita reler enquanto o próprio módulo está escrevendo
    }

    function load() {
        try {
            const text = modFile.text()
            _parse(text)
        } catch (e) {
            // Arquivo ainda não existe — fica nos valores padrão.
        }
        root.loaded = true
        root.dirty = false
    }

    function _parse(text) {
        const gi = text.match(/gaps_in\s*=\s*(\d+)/)
        const go = text.match(/gaps_out\s*=\s*(\d+)/)
        const bs = text.match(/border_size\s*=\s*(\d+)/)
        const ro = text.match(/rounding\s*=\s*(\d+)/)
        const ab = text.match(/col\.active_border\s*=\s*(\S+)/)
        const ib = text.match(/col\.inactive_border\s*=\s*(\S+)/)
        if (gi) root.gapsIn = parseInt(gi[1])
        if (go) root.gapsOut = parseInt(go[1])
        if (bs) root.borderSize = parseInt(bs[1])
        if (ro) root.rounding = parseInt(ro[1])
        if (ab) root.activeBorderColor = ab[1]
        if (ib) root.inactiveBorderColor = ib[1]

        const execLines = []
        const re = /^exec-once\s*=\s*(.+)$/gm
        let m
        while ((m = re.exec(text)) !== null) execLines.push(m[1].trim())
        root.autostart = execLines
    }

    function addAutostart(cmd) {
        if (!cmd || cmd.trim().length === 0) return
        root.autostart = [...root.autostart, cmd.trim()]
        root.dirty = true
    }

    function removeAutostart(index) {
        const list = [...root.autostart]
        list.splice(index, 1)
        root.autostart = list
        root.dirty = true
    }

    function markDirty() { root.dirty = true }

    function _buildConfText() {
        let out = "# Gerado pelo módulo de configurações do Quickshell.\n"
        out += "# NÃO edite manualmente — suas mudanças serão sobrescritas na\n"
        out += "# próxima vez que salvar pelo shell. Edite hyprland.conf à\n"
        out += "# vontade; este arquivo só existe pra não mexer nele direto.\n\n"
        out += "general {\n"
        out += "    gaps_in = " + root.gapsIn + "\n"
        out += "    gaps_out = " + root.gapsOut + "\n"
        out += "    border_size = " + root.borderSize + "\n"
        out += "    col.active_border = " + root.activeBorderColor + "\n"
        out += "    col.inactive_border = " + root.inactiveBorderColor + "\n"
        out += "}\n\n"
        out += "decoration {\n"
        out += "    rounding = " + root.rounding + "\n"
        out += "}\n\n"
        for (const cmd of root.autostart) {
            out += "exec-once = " + cmd + "\n"
        }
        return out
    }

    property Process saveProc: Process {
        id: saveProcInner
        onExited: (code) => {
            if (code === 0) {
                root.dirty = false
                root.saved()
                reloadProc.running = true
            } else {
                root.saveFailed("Falha ao escrever o arquivo (código " + code + ")")
            }
        }
    }

    function save() {
        const text = _buildConfText()
        // Escreve via bash (heredoc) em vez de FileView.setText, pra
        // garantir permissões corretas e também rodar a checagem/inclusão
        // da linha "source" no hyprland.conf principal na mesma tacada.
        const escaped = text.replace(/'/g, "'\\''")
        const cmd = "set -e; " +
            "mkdir -p \"$HOME/.config/hypr\"; " +
            "printf '%s' '" + escaped + "' > \"$HOME" + root.modConfPath + "\"; " +
            "grep -qF 'source = ~/.config/hypr/quickshell-mod.conf' \"$HOME" + root.mainConfPath + "\" 2>/dev/null || " +
            "echo 'source = ~/.config/hypr/quickshell-mod.conf' >> \"$HOME" + root.mainConfPath + "\""
        saveProc.command = ["bash", "-c", cmd]
        saveProc.running = true
    }

    property Process reloadProc: Process {
        command: ["hyprctl", "reload"]
    }

    Component.onCompleted: load()
}
