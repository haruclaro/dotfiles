pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string modConfPath: "/.config/hypr/quickshell-mod.conf"
    readonly property string mainConfPath: "/.config/hypr/hyprland.conf"

    property int gapsIn: 5
    property int gapsOut: 10
    property int borderSize: 2
    property int rounding: 8
    property var autostart: []

    property bool loaded: false
    property bool dirty: false

    signal saved()
    signal saveFailed(string reason)

    function _fullPath(rel) {
        return "file://" + Quickshell.env("HOME") + rel
    }

    property FileView modFile: FileView {
        path: root._fullPath(root.modConfPath)
        printErrors: false
        watchChanges: false
    }

    function load() {
        try {
            const text = modFile.text()
            _parse(text)
        } catch (e) {
        }
        root.loaded = true
        root.dirty = false
    }

    function _parse(text) {
        const gi = text.match(/gaps_in\s*=\s*(\d+)/)
        const go = text.match(/gaps_out\s*=\s*(\d+)/)
        const bs = text.match(/border_size\s*=\s*(\d+)/)
        const ro = text.match(/rounding\s*=\s*(\d+)/)
        if (gi) root.gapsIn = parseInt(gi[1])
        if (go) root.gapsOut = parseInt(go[1])
        if (bs) root.borderSize = parseInt(bs[1])
        if (ro) root.rounding = parseInt(ro[1])

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
        out += "general {\n"
        out += "    gaps_in = " + root.gapsIn + "\n"
        out += "    gaps_out = " + root.gapsOut + "\n"
        out += "    border_size = " + root.borderSize + "\n"
        out += "}\n\n"
        out += "decoration {\n"
        out += "    rounding = " + root.rounding + "\n"
        out += "}\n\n"
        for (const cmd of root.autostart) {
            out += "exec-once = " + cmd + "\n"
        }
        return out
    }

    function _buildLuaText() {
        let out = "-- Gerado pelo módulo de configurações do Quickshell.\n"
        out += "hl.config({\n"
        out += "    general = {\n"
        out += "        gaps_in = " + root.gapsIn + ",\n"
        out += "        gaps_out = " + root.gapsOut + ",\n"
        out += "        border_size = " + root.borderSize + "\n"
        out += "    },\n"
        out += "    decoration = {\n"
        out += "        rounding = " + root.rounding + "\n"
        out += "    }\n"
        out += "})\n\n"
        for (const cmd of root.autostart) {
            out += "hl.on('hyprland.start', function() hl.exec_cmd('" + cmd.replace(/'/g, "\\'") + "') end)\n"
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
        const luaText = _buildLuaText()
        const escapedLua = luaText.replace(/'/g, "'\\''")
        const escaped = text.replace(/'/g, "'\\''")
        
        const cmd = "set -e; " +
            "mkdir -p \"$HOME/.config/hypr\"; " +
            "printf '%s' '" + escaped + "' > \"$HOME" + root.modConfPath + "\"; " +
            "printf '%s' '" + escapedLua + "' > \"$HOME/.config/hypr/quickshell-mod.lua\"; "

        saveProc.command = ["bash", "-c", cmd]
        saveProc.running = true
    }

    property Process reloadProc: Process {
        command: ["hyprctl", "reload"]
    }

    Component.onCompleted: load()
}
