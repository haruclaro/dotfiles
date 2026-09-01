pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Cfg

// PORTADO de SysMenu.tsx: chama o mesmo ~/.config/*/scripts/peripherals.sh
// (copia esse script para scripts/ na nova config) e expõe a lista já
// parseada em vez do JSON cru.
QtObject {
    id: root

    property var devices: []   // [{ model: string, percent: number }]

    property Process proc: Process {
        command: ["bash", Cfg.Config.peripheralsScript]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text || "[]")
                    root.devices = Array.isArray(parsed) ? parsed : []
                } catch (e) {
                    root.devices = []
                }
            }
        }
        onExited: (code) => {
            if (code !== 0) root.devices = []
        }
    }

    property Timer pollTimer: Timer {
        interval: Cfg.Config.peripheralsIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
