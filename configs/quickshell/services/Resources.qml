pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Cfg

// PORTADO de ResourceMonitor.tsx: mesmos comandos (vmstat p/ CPU, sensors p/
// temp, nvidia-smi p/ GPU, free p/ RAM, df p/ disco). Cada métrica tem seu
// próprio Process + Timer, exatamente como no createPoll original.
QtObject {
    id: root

    property int cpu: 0
    property int cpuTemp: 0
    property int gpu: 0
    property int gpuTemp: 0
    property int ram: 0
    property string ramText: ""
    property int disk: 0

    property color accentColor: {
        const usageMax = Math.max(cpu, ram, gpu, disk)
        if (usageMax > 90) return Cfg.Colors.critical
        if (usageMax > 70) return Cfg.Colors.warning
        return Cfg.Colors.accent
    }

    readonly property string severity: {
        const usageMax = Math.max(cpu, ram, gpu, disk)
        const tempMax = Math.max(cpuTemp, gpuTemp)
        if (usageMax >= 85 || tempMax >= 80) return "critical"
        if (usageMax >= 60 || tempMax >= 65) return "warning"
        return "normal"
    }

    readonly property real overallUsage: Math.max(cpu, ram, gpu, disk) / 100

    property Process cpuProc: Process {
        command: ["bash", "-c", "LC_ALL=C vmstat 1 2 | tail -1 | awk '{print 100 - $15}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text)
                root.cpu = isFinite(n) ? Math.round(n) : 0
            }
        }
    }
    property Process cpuTempProc: Process {
        command: ["bash", "-c", "sensors | grep 'Tctl' | grep -Eo '\\+[0-9.]+' | tr -d '+' | head -n 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text)
                root.cpuTemp = isFinite(n) ? Math.round(n) : 0
            }
        }
    }
    property Process gpuProc: Process {
        command: ["bash", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text)
                root.gpu = isFinite(n) ? Math.round(n) : 0
            }
        }
    }
    property Process gpuTempProc: Process {
        command: ["bash", "-c", "nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text)
                root.gpuTemp = isFinite(n) ? Math.round(n) : 0
            }
        }
    }
    property Process ramProc: Process {
        command: ["bash", "-c", "LC_ALL=C free -m | awk '/^Mem/ { printf \"{\\\"text\\\":\\\"%.1fG/%.1fG\\\",\\\"pct\\\":%.0f}\", $3/1024, $2/1024, $3/$2*100 }'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text)
                    root.ram = data.pct
                    root.ramText = data.text
                } catch (e) {
                    root.ram = 0
                    root.ramText = "Erro"
                }
            }
        }
    }
    property Process diskProc: Process {
        command: ["bash", "-c", "df -h / | awk 'NR==2 {print $5}' | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseFloat(this.text)
                root.disk = isFinite(n) ? Math.round(n) : 0
            }
        }
    }

    property Timer fastTimer: Timer {
        interval: Cfg.Config.resourceIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            cpuTempProc.running = true
            gpuProc.running = true
            gpuTempProc.running = true
            ramProc.running = true
        }
    }
    property Timer diskTimer: Timer {
        interval: Cfg.Config.diskIntervalMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }
}
