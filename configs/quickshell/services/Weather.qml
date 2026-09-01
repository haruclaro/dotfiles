pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../config" as Cfg

// PORTADO de Bar.tsx: mesma lógica (fetch normal via weather.sh, refresh de
// localização via "weather.sh toggle" + novo fetch, e set manual de cidade
// via weather-set-city.sh + novo fetch). O script deve continuar imprimindo
// {"text":...,"tooltip":...} em JSON.
//
// CORRIGIDO (log: "Weather: falha ao interpretar JSON: SyntaxError"): antes
// chamávamos "bash -c <caminho>", que faz o bash tentar EXECUTAR o arquivo
// diretamente — e isso exige permissão +x, que se perde facilmente ao
// copiar/zipar a config. Trocamos pra "bash <caminho>", onde é o próprio
// bash que lê e interpreta o conteúdo do script, sem precisar de +x.
QtObject {
    id: root

    property string text: "…"
    property string icon: ""
    property string temp: "…"
    property string tooltip: "A carregar"
    property bool loading: true

    property string city: ""
    property string desc: ""
    property string feelsLike: ""
    property string humidity: ""
    property string wind: ""
    property string tempMin: ""
    property string tempMax: ""

    function _applyResult(out) {
        try {
            const parsed = JSON.parse(out)
            root.text = typeof parsed.text === "string" ? parsed.text : "⚠ Erro"
            root.icon = typeof parsed.icon === "string" ? parsed.icon : ""
            root.temp = typeof parsed.temp === "string" ? parsed.temp : root.text
            root.tooltip = typeof parsed.tooltip === "string" ? parsed.tooltip : ""
            
            root.city = parsed.city || ""
            root.desc = parsed.desc || ""
            root.feelsLike = parsed.feelsLike || ""
            root.humidity = parsed.humidity || ""
            root.wind = parsed.wind || ""
            root.tempMin = parsed.tempMin || ""
            root.tempMax = parsed.tempMax || ""
        } catch (e) {
            console.warn("Weather: falha ao interpretar JSON:", e)
            root.text = "⚠ Erro"
            root.icon = ""
            root.temp = "Erro"
            root.tooltip = "Falha ao ler o weather.sh"
        }
        root.loading = false
    }

    function refresh() {
        root.loading = true
        fetchProc.running = true
    }

    // Clique esquerdo (antigo): forçava refresh, agora a UI abre o popup
    function refreshLocationThenFetch() {
        root.loading = true
        toggleProc.running = true
    }

    function setCity(city) {
        root.loading = true
        if (city === "auto") {
            toggleProc.running = true
        } else {
            setCityCommand.command = ["bash", Cfg.Config.weatherScript, "set", city]
            setCityCommand.running = true
        }
    }

    property Process setCityCommand: Process {
        onExited: root.refresh()
    }

    property Process fetchProc: Process {
        command: ["bash", Cfg.Config.weatherScript]
        stdout: StdioCollector {
            onStreamFinished: root._applyResult(this.text)
        }
        onExited: (code) => {
            if (code !== 0) {
                root.text = "⚠ Erro"
                root.tooltip = "Falha ao ler o weather.sh"
                root.loading = false
            }
        }
    }

    property Process toggleProc: Process {
        command: ["bash", Cfg.Config.weatherScript, "toggle"]
        onExited: root.refresh()
    }



    property Timer pollTimer: Timer {
        interval: Cfg.Config.weatherIntervalMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
