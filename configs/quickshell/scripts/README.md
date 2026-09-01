# Scripts

Todos já estão aqui e integrados com o QML (`config/Config.qml` aponta pra
cada um). Lembra de dar permissão de execução depois de copiar a config:

```bash
chmod +x ~/.config/quickshell/scripts/*.sh
```

- **weather.sh** / **weather-set-city.sh** — sem alteração de lógica; só
  atualizei o caminho hardcoded do `weather-set-city.sh` (apontava pro
  `~/.config/ags/scripts`, agora aponta pro `~/.config/quickshell/scripts`).
- **peripherals.sh** — sem alteração.
- **graceful_exit.sh** — sem alteração.
- **trocar_tema.sh** — MODIFICADO: agora escreve
  `~/.config/quickshell/theme-colors.json` em vez do `colors.css` do AGS, e
  não chama mais `ags request reload-css` (não existe mais). O
  `config/Colors.qml` observa esse JSON e recarrega as cores sozinho assim
  que o script roda — não precisa reiniciar o Quickshell.
- **sys_monitor.sh** — NÃO é usado pelo QML atual. `services/Resources.qml`
  já lê CPU/GPU/RAM/disco/temperatura de forma granular (um comando por
  métrica), então esse script (que resume tudo num emoji + tooltip, estilo
  módulo custom do Waybar) ficou aqui só de referência/backup. Se quiseres
  usá-lo em vez da abordagem granular, é só me pedir.
