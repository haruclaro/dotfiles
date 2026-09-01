# Migração AGS → Quickshell

## Como instalar
```bash
mv ~/.config/quickshell ~/.config/quickshell.bak   # se já existir algo lá
cp -r . ~/.config/quickshell
# copia os scripts bash antigos (ver scripts/README.md)
cp ~/.config/ags/scripts/*.sh ~/.config/quickshell/scripts/
chmod +x ~/.config/quickshell/scripts/*.sh
~/.config/quickshell/scripts/launch.sh   # ou: exec-once = ~/.config/quickshell/scripts/launch.sh no hyprland.conf
```

**Importante**: o Quickshell precisa ser aberto via `scripts/launch.sh` (e
não `qs`/`quickshell` direto) pra usar o tema de ícones configurado no
`nwg-look` — esse script lê o valor real (`gtk-icon-theme-name` em
`~/.config/gtk-3.0/settings.ini`) e exporta como `QS_ICON_THEME` antes de
abrir o `qs`. Se você trocar de tema no `nwg-look`, é só reiniciar o
Quickshell (`launch.sh` de novo) pra ele pegar o novo tema.

## Estrutura
```
shell.qml               # entrypoint, instancia TopBar+BottomBar por monitor
config/                 # Colors.qml e Config.qml (singletons de tema/tamanhos)
services/                # Weather, Resources, Peripherals (singletons com Process/Timer)
modules/                 # TopBar, BottomBar, WorkspaceDock, SysTrayDock,
                          # ClockWeather, MediaIndicator, ResourceIndicator
popups/                  # Conteúdo dos popups: AudioMixer, SysMenu, Calendar,
                          # Resource, Media
widgets/                 # Pill.qml (dock recolhível) e AnchoredPopup.qml
                          # (substitui o hack de hyprctl movewindowpixel do
                          # Popover.tsx antigo — o Quickshell ancora popups
                          # nativamente via PopupWindow.anchor.item)
scripts/                 # copia os .sh antigos pra cá (ver README local)
```

## O que mudou em relação ao pedido, e por quê (premissas assumidas)

1. **Cores/tema**: não tínhamos o `style.css` antigo, só nomes de classes
   (`doomer-panel`, etc). `config/Colors.qml` é uma paleta nova, escura,
   estilo catppuccin-macchiato/Caelestia. Troca os valores lá se quiseres
   bater com uma paleta específica.

2. **Mixer de áudio**: o pedido não disse onde o botão de volume (que no
   `Bar.tsx` antigo ficava solto no `bar-right`) deveria ir na nova
   estrutura. Coloquei como um ícone dentro do dock SysMenu+Tray
   (`SysTrayDock.qml`) — é fácil mover se preferires outro lugar (ex: um
   terceiro dock próprio, ou dentro da TopBar).

3. **Fechar popup ao clicar fora**: implementei abertura/fechamento via
   clique no botão-gatilho (toggle) e Esc. Fechar clicando fora da janela
   do popup depende de captura de clique fora do próprio Quickshell popup,
   que costuma exigir uma camada extra (overlay full-screen invisível) —
   deixei um comentário no `AnchoredPopup.qml` sinalizando isso; é a parte
   mais provável de precisar de ajuste fino depois de testar na tua
   versão do Quickshell instalada.

4. **APIs do Quickshell**: o projeto é jovem e a API muda entre versões
   (o changelog deles avisa isso explicitamente). Usei a sintaxe mais
   recente que encontrei documentada (Hyprland, Pipewire, Mpris, SystemTray,
   PopupWindow), mas vale rodar `quickshell` com o log aberto na primeira
   vez e ajustar qualquer nome de propriedade que tenha mudado na tua
   versão instalada.

5. **Rede/Bluetooth**: mantive a mesma estratégia pragmática do original
   (ler status via `nmcli`/`bluetoothctl`, abrir `nm-connection-editor`/
   `blueman-manager` ao clicar) em vez de tentar um binding nativo mais
   profundo, pra não inventar comportamento que o pedido não especificou.

## Correções da 10ª rodada — menus nativos do tray (PlatformMenuEntry)

O log já veio com a solução: menus de tray que usam `PlatformMenuEntry`
(o tipo de menu nativo que alguns apps tray usam, em vez do DBusMenu) só
funcionam se o Quickshell for iniciado em modo `QApplication`. Adicionado
`//@ pragma UseQApplication` na primeira linha de `shell.qml`.

**Importante**: esse pragma só tem efeito num processo NOVO do Quickshell
— um simples reload de config não basta. Mata o processo atual e roda
`qs` de novo (ou reinicia o serviço, se estiver rodando via systemd/
exec-once do Hyprland).

## Correções da 26ª rodada — Criador de Temas e Config. Hyprland viraram janelas próprias

Movidos pra FORA da ilha inferior — não são mais popups ancorados a um
botão da barra, e sim janelas flutuantes independentes (mesmo padrão que
o `ClipboardWindow.qml` já usava: `PanelWindow` sem anchors nos 4 lados =
fica centralizada na tela, tamanho do conteúdo, controlada via IPC).

**Considerei também a sugestão de fazer isso fora do Quickshell** (um app
GTK4/Python separado, tipo o próprio HyprMod que você linkou) — decidi
manter dentro do Quickshell porque: (1) a lógica de geração de tema e
edição do Hyprland já estava pronta e testada aqui; (2) ganha o mesmo
tema visual (lê `Colors.qml`) de graça; (3) evita adicionar uma stack
nova (GTK4+Python ou o que for) só pra isso. Se depois de testar você
ainda preferir um app nativo separado, me avisa que eu construo — mas
achei que valia tentar essa opção mais simples primeiro.

**Novos atalhos pra adicionar no `hyprland.conf`** (junto do já existente
`SUPER,V` do clipboard):
```
bind = SUPER, T, exec, qs ipc call theme toggle
bind = SUPER, comma, exec, qs ipc call hyprmod toggle
```
(as teclas são só sugestão — troca pelas que preferir)

`SysMenuGroup.qml` voltou ao layout original (só áudio + sistema) — os
dois botões que eu tinha adicionado na rodada anterior saíram de lá.

## Correções da 25ª rodada — "Aparência" não funcionava

Duas causas, ambas na integração dos módulos novos (Criador de Tema e
Config. Hyprland) que eu tinha feito na rodada anterior:

1. **Popup dentro de popup**: eu tinha colocado os botões desses dois
   módulos DENTRO do `SysMenuPopup.qml` — que já é ele mesmo o conteúdo
   de um `AnchoredPopup` (`PopupWindow`). Um `PopupWindow` ancorado a um
   item que vive dentro do conteúdo de OUTRO `PopupWindow` já aberto é um
   padrão bem mais frágil no protocolo de popup do Wayland do que popups
   abertos direto da barra. Movidos pra `SysMenuGroup.qml`, como botões
   irmãos de topo (mesmo nível de áudio/sistema, que sempre funcionaram
   de forma confiável).
2. **Chave de fechamento perdida**: ao remover os botões de dentro do
   `SysMenuPopup.qml`, a edição também levou junto o `}` de fechamento do
   `RowLayout` que envolvia os presets Retro/Doomer — isso sozinho já
   quebraria o arquivo inteiro (erro de parse do QML). Corrigido.

## Correções da 24ª rodada — ícone de áudio aparecia como texto literal

Achado no `SysMenuGroup.qml`: o botão de áudio (`audioBtn`) ainda usava
`Text { text: Cfg.Icons.volumeHigh }` em vez de `Widgets.SymbolicIcon` —
sobra da mesma confusão Nerd-Font-vs-tema-do-sistema da rodada anterior,
que escapou daquela auditoria porque o NOME da propriedade
(`Cfg.Icons.volumeHigh`) era válido — só o tipo de widget usado pra
renderizar é que estava errado, e isso a auditoria de "propriedade
existe?" não pegava. Como `Cfg.Icons.volumeHigh` agora vale a STRING
`"audio-volume-high-symbolic"` (nome de ícone do tema, não mais um
glifo), um `Text` mostra ela literalmente — exatamente o que apareceu no
teu screenshot. Corrigido, e varri o projeto inteiro atrás de qualquer
outro `Text` renderizando `Cfg.Icons.*` diretamente (zero sobras dessa
vez, busca sem depender de contexto multi-linha).

Não era problema do tema DarK-icons em si — o `launch.sh` já prioriza ele
corretamente.

## Correções/módulos novos da 23ª rodada

**Bug encontrado e corrigido**: `config/Icons.qml` tinha revertido pra
códigos de Nerd Font numa rodada de debug anterior, mas o resto do
projeto (`SysMenuPopup`, `MediaPopup`, `SysMenuGroup`, `AudioMixerPopup`,
`ResourceIndicator`, `MediaIndicator`) já esperava os nomes de ícone do
TEMA (versão AGS, via `SymbolicIcon`) — 11 referências quebradas ao todo.
Corrigido e auditado (comparei TODO uso de `Cfg.Icons.*` contra o que
está definido, zero sobras).

### 1.1 — Clipboard (`services`/`modules/ClipboardWindow.qml`)
Já existia uma versão pronta e até melhor que meu primeiro rascunho (fila
de miniaturas em vez de disparar todas de uma vez). Porta 1:1 do
`Clipboard.tsx`: lista texto e imagem do `cliphist`, clique copia
(`wl-copy`) e fecha, "✕" deleta. Abre via IPC — **precisa de um bind no
Hyprland**:
```
bind = SUPER, V, exec, qs ipc call clipboard toggle
```

### 1.2 — Criador de temas (`popups/ThemeCreatorPopup.qml`)
Esquema de cores (6 campos hex com prévia, pré-preenchidos com o tema
atual) + wallpaper (lista arquivos de imagem achados em
`~/Pictures`/`~/Imagens`/`~/Wallpapers`, ou cola o caminho manualmente —
sem seletor de arquivo nativo, que já se mostrou pouco confiável nesse
ambiente). Ao salvar, chama `scripts/apply-custom-theme.sh` (novo —
generaliza a lógica do `trocar_tema.sh`, que só tinha "retro"/"doomer"
fixos, pra aceitar nome+cores+wallpaper customizados). Acessível pelo
botão "+ Criar tema" dentro do menu de Aparência (ícone de engrenagem no
dock inferior → Aparência).

### 1.3 — Configurações do Hyprland (`services/HyprConfig.qml` +
`popups/HyprSettingsPopup.qml`)
Também já existia um começo (o serviço). Construí a UI em cima: gaps,
espessura de borda, arredondamento, cores de borda, lista de autostart —
tudo editável e com "Salvar e recarregar". Segue a filosofia do HyprMod
(github.com/BlueManCZ/hyprmod, que você linkou): **nunca edita o
`hyprland.conf` principal** — escreve só em
`~/.config/hypr/quickshell-mod.conf`, incluído via `source =`
automaticamente na primeira vez que salva. Acessível pelo botão "H" (ao
lado do de Aparência).

**Diferença importante em relação ao HyprMod**: aquele é um app GTK4
nativo completo (editor de curvas bezier, layout de monitores com
preview, keybinds interativos, window rules...). O que construí aqui é um
ponto de partida cobrindo os ajustes mais comuns — não uma réplica
completa, que não é viável dentro de um popup do painel. Se quiser mais
opções específicas (animações, layout de monitores, etc), me pede que eu
expando.

## Correções da 22ª rodada — wifi revisitado com base no SysMenu.tsx original

O AGS original usava bindings diretos do `AstalNetwork`
(`network.wifi.ssid`, `network.wifi.iconName` — esse já dinâmico
conforme a força do sinal). O Quickshell não tem um serviço de rede
nativo (conferido contra a lista oficial: só
Pipewire/Mpris/SystemTray/UPower/Notifications/Pam/Polkit), então
continuamos com `nmcli`, mas revisado:

1. **Nome da rede**: trocado o comando em 2 passos (que dependia de
   substituição de variável dentro do `bash -c`, mais um ponto de falha)
   por UM único comando: `nmcli device status` já lista `TYPE`, `STATE` e
   `CONNECTION` por dispositivo de uma vez — filtramos
   `type==wifi && state==connected` e pegamos o nome direto.
2. **Ícone dinâmico por força de sinal** — novo, replicando o
   `iconName` do AstalNetwork original: `wifiSignalProc` lê a força do
   sinal (0-100) da rede ativa (`nmcli dev wifi list --rescan no`, sem
   disparar scan novo) e `wifiIconName` mapeia pra
   `network-wireless-signal-{excellent,good,ok,weak,none}-symbolic` (ou
   `-offline-` se desconectado) — os mesmos nomes padrão freedesktop que
   o GTK usa.
3. **Clique continua abrindo `nm-connection-editor`** — confirmado, sem
   mudança (já era esse o comportamento).

Também atualizei `scripts/wifi-status.sh` (já existia, com fallback pra
`iwd`/`iwgetid`) com a mesma lógica mais robusta, e passei a chamá-lo do
QML em vez de duplicar a lógica inline — única fonte de verdade, e ganha
de brinde suporte a quem não usa NetworkManager.

## Correções da 21ª rodada — tema de ícones do nwg-look + wifi (3ª tentativa)

**Ícones muito escuros**: o `//@ pragma IconTheme Adwaita` forçava um
tema FIXO, que provavelmente nem é o que o `nwg-look` tem configurado de
verdade (ícones "symbolic" de temas diferentes têm perfis de cor/desenho
diferentes — daí a diferença de resultado). Removido o pragma; criado
`scripts/launch.sh`, que lê o tema real configurado pelo `nwg-look`
(`gtk-icon-theme-name` em `~/.config/gtk-3.0/settings.ini`, com fallback
pra `gsettings` e por último "Adwaita") e exporta como `QS_ICON_THEME`
antes de abrir o `qs` — variável que o Quickshell aceita com a mesma
função do pragma, só que dinâmica. **Importante**: agora abre o
Quickshell via esse script (`~/.config/quickshell/scripts/launch.sh`) em
vez de `qs`/`quickshell` direto — ajusta o `exec-once` do
`hyprland.conf`.

**Wi-Fi errado (3ª tentativa)**: as duas tentativas anteriores tentavam
casar o TYPE da CONEXÃO (`"802-11-wireless"` ou `"wifi"`), campo que
varia bastante entre versões/backends do NetworkManager. Trocado pela
abordagem mais direta e estável: perguntamos ao DISPOSITIVO
(`nmcli device status`), cujo TYPE é sempre o valor simples "wifi", e
então perguntamos a esse dispositivo especificamente qual conexão está
ativa nele.

## Correções da 20ª rodada — cor do resource monitor estourada

`widgets/SymbolicIcon.qml` tinha `brightness: 1.0` no `MultiEffect` —
essa propriedade vai de -1.0 a 1.0, com **0.0 sendo o valor neutro** (sem
alteração), não 1.0. Com 1.0 (máximo de brilho), o ícone ficava
estourado/lavado até virar um bloco sólido na cor de severidade em vez de
manter o desenho original do ícone só tingido. Removido — fica no padrão
(0.0).

## Correções da 19ª rodada

**Hover da ilha inferior**: aplicada a melhoria feita por você em
`BottomBar.qml` — troca de `MouseArea` (que consome clique, mesmo só com
`hoverEnabled`) por `HoverHandler` (não interfere em cliques dos filhos).
Mantido exatamente como está.

**Wi-Fi "Desconectado"/errado de novo**: o filtro de tipo (`$2==
"802-11-wireless"`) fazia match exato — algumas versões do `nmcli`
relatam o tipo só como `"wifi"`, não `"802-11-wireless"`, fazendo o match
falhar sempre. Trocado por um match tolerante
(`tolower($2) ~ /wireless|wifi/`).

**Cor por cima dos ícones do AGS**: reintroduzido `MultiEffect` em
`SymbolicIcon.qml`. Importante: as duas tentativas anteriores de colorir
(rodadas 16/17) aconteceram ANTES de descobrirmos o `pragma IconTheme`
— sem ele, `Quickshell.iconPath()` retornava vazio pra tudo, então a
Image de origem já estava sem textura nenhuma independente do
`MultiEffect` funcionar ou não. Agora que os ícones carregam de verdade,
a colorização tem uma chance real de funcionar.

**Se os ícones sumirem de novo com essa mudança**: aí sim seria
confirmação de que o `MultiEffect` genuinamente não renderiza nesse
ambiente (problema separado do tema de ícones) — é só avisar que eu
reverto pra ícones sem cor (mas visíveis), que é o estado imediatamente
anterior a essa rodada.

## Correções da 18ª rodada — causa raiz real dos ícones invisíveis: faltava o pragma IconTheme

Achei o motivo de verdade: `Quickshell.iconPath()` segue a resolução de
tema de ícone do Qt (`QIcon::themeName()`), que em setups Hyprland "crus"
(sem GNOME/GTK completo por trás) costuma ficar **vazia** — diferente do
AGS (GTK puro), que sempre caía de volta pro Adwaita sozinho, sem precisar
de configuração nenhuma. O Quickshell não faz esse fallback automático;
existe um pragma específico pra isso, documentado na própria doc oficial:

```qml
//@ pragma IconTheme Adwaita
```

Adicionei isso no topo do `shell.qml` (junto do `UseQApplication` que já
tinha) e voltei TODOS os ícones pra usar `widgets/SymbolicIcon.qml` +
`config/Icons.qml` (nomes de ícone do AGS original), revertendo a
tentativa de voltar pra Nerd Font da rodada anterior.

**Se os ícones ainda não aparecerem com essa mudança**: "Adwaita" pode não
estar instalado nesse sistema. Roda `ls /usr/share/icons/` no teu terminal
pra ver quais temas existem de fato, e troca o nome no pragma (linha 2 do
`shell.qml`) por um deles.

## Correções da 17ª rodada — ícones ainda invisíveis, MultiEffect removido

O fix de `opacity` não resolveu — sinal de que o `MultiEffect` em si não
estava desenhando NADA nesse ambiente (bem provável falta de suporte a
shader no backend de renderização em uso, sem gerar erro nenhum).
Removido por completo: `widgets/SymbolicIcon.qml` agora é uma `Image`
pura, sem efeito nenhum em cima. Desvantagem: os ícones não seguem mais
dinamicamente a cor do texto ao redor (usam a cor própria do tema de
ícones) — troca aceitável por eles aparecerem de fato.

**Se mesmo assim continuarem invisíveis**: já não seria mais um problema
de efeito/shader, e sim de `Quickshell.iconPath()` não estar encontrando
esses nomes de ícone no teu tema atual (retornando string vazia). Nesse
caso o próximo passo é reverter pra a abordagem de glifos de Nerd Font
(que já tínhamos funcionando, só com 2 códigos errados — já corrigidos na
14ª rodada) em vez de ícones do tema do sistema. É só avisar que eu
reverto.

## Correções da 16ª rodada — ícones invisíveis (sem erro nenhum no log)

`widgets/SymbolicIcon.qml`: `MultiEffect` precisa que a `Image` fonte
esteja `visible: true` pra conseguir capturar a textura dela pra colorir
— um item com `visible: false` é totalmente excluído da renderização da
cena (diferente de `opacity: 0`, que ainda renderiza o item normalmente,
só não mostra na composição final). Eu tinha escondido a imagem original
com `visible: !root.colorize`, e como `colorize` é `true` por padrão em
todo lugar que usamos o componente, a Image nunca era renderizada —
por isso nada aparecia, sem gerar warning nenhum (não é um erro, é só
"nada pra mostrar"). Troquei pra `opacity` em vez de `visible`.

Se, depois desse fix, algum ícone ESPECÍFICO continuar em branco (não
todos), aí sim seria um problema diferente — o nome daquele ícone
provavelmente não existe no teu tema de ícones atual — me avisa qual pra
eu trocar por um nome equivalente disponível.

## Correções da 15ª rodada

**1) Ícones diferentes do AGS.** O AGS original usava `<icon icon="...">`
— ícones do TEMA do sistema (GTK/Adwaita symbolic), não glifos de fonte.
Criei `widgets/SymbolicIcon.qml` (usa `Quickshell.iconPath()` + recolore
via `MultiEffect`, igual ao GTK faz com ícones "symbolic") e reescrevi
`config/Icons.qml` com os MESMOS nomes de ícone que apareciam nos `.tsx`
originais (`audio-volume-high-symbolic`, `emblem-system-symbolic`,
`system-shutdown-symbolic`, `preferences-desktop-appearance-symbolic`,
etc — copiados direto do código antigo, não inventados). Aplicado em
`ResourceIndicator`, `MediaIndicator`, `SysMenuGroup`, `SysMenuPopup`,
`MediaPopup`, `AudioMixerPopup`. O clima também: `weather.sh` agora manda
um NOME de ícone (`weather-clear-symbolic` etc, padrão freedesktop) em vez
de um glifo — `config/Icons.qml` não tem mais glifos de Nerd Font.
`CalendarPopup.qml` mantém setas de texto simples (‹ ›), já que o
`Gtk.Calendar` original não tinha ícone de tema equivalente pra portar.

**2) Workspaces segregados por monitor.** `WorkspaceDock.qml` não filtra
mais por `monitorScreen` — mostra todos os workspaces com janela ativa,
de qualquer monitor, igual em todas as telas.

**3) Ícone de wifi no tray.** `Tray.qml` agora filtra itens cujo
`id`/`title` contenha "network"/"wifi"/"nm-applet" antes de renderizar —
esse ícone já não aparece mais na bandeja (o status de rede continua
disponível no SysMenuPopup).

**4) Tray recolhido em ">".** `Tray.qml` ganhou o mesmo padrão de
"encolhe pro ícone / expande no hover" que o `MediaIndicator.qml` já
tinha: recolhido mostra só `pan-end-symbolic` (">"); ao passar o mouse,
os ícones reais da bandeja aparecem e o ">" some.

## Correções da 14ª rodada

**1) Ícones que não carregavam.** Consegui a lista oficial e completa de
codepoints do Nerd Fonts e conferi TODOS os que eu tinha usado — achei
dois errados: `ram` (usava `\uf538`, o certo é `\uefc5` — faixa "ef"
é onde ficam os ícones FontAwesome 5/6 adicionados depois, diferente da
faixa clássica "f0xx-f2xx") e **`palette`** (usava `\uf53f`, o certo é
`\uefcc` — esse era o ícone de "tema" que você notou quebrado). Corrigidos
em `config/Icons.qml`.
Sobre os warnings `battery-050`, `battery-missing`,
`preferences-desktop-peripherals`, `help-about`, `application-exit`: já
conferi, nenhum desses nomes aparece em lugar nenhum do nosso código —
são ícones de TEMA (busca por nome via XDG icon theme spec) pedidos pelos
PRÓPRIOS menus de apps externos (nm-applet/blueman/etc, via
`PlatformMenuEntry`), não pela nossa fonte de ícones. Não é algo que o
`shell.qml` controla; se quiser eliminar esses warnings específicos, o
caminho é instalar um tema de ícones mais completo (`papirus-icon-theme`
cobre bem esses nomes) e configurá-lo como padrão do sistema.

**2) Wi-Fi mostrando "Desconectado" mesmo conectado.** O comando usava
`nmcli dev wifi` (dispara um SCAN de redes por perto, mais lento e reflete
a lista de scan, não a conexão real). Troquei por
`nmcli connection show --active` filtrado por tipo wireless — lê direto
as conexões já ativas.

**3) Tema retro não recarregava a TopBar.** Reescrevi `config/Colors.qml`
inteiro pro padrão oficial da doc do Quickshell: em vez de reagir a sinais
escritos à mão (`onLoaded`/`onFileChanged: reload()`, que eu não
conseguia confirmar 100% que existiam/disparavam nessa versão), agora é
tudo binding declarativo direto sobre `FileView.text()` (com
`blockLoading: true`) — reavalia sozinho sempre que o arquivo muda, sem
depender de nenhum sinal manual.

**4) MediaIndicator não recolhia com tudo pausado.** A lógica antiga caía
num fallback "qualquer player com trackTitle" quando nada estava tocando
— só que players MPRIS mantêm o `trackTitle` mesmo pausados (só some
quando o player fecha de vez), então na prática nunca recolhia depois da
primeira música. Agora exige `isPlaying` de verdade.

## Correções da 13ª rodada — clima desalinhado, volume ainda travado, ícones/fontes revisados

**1) Clima desalinhado.** Causa raiz: misturar ícone (emoji, fonte de
fallback com métricas de altura/baseline bem diferentes) e temperatura
(texto normal) dentro do MESMO `Text` — nenhum alinhamento resolve isso de
verdade enquanto os glifos vierem de fontes com caixa diferente. Separei
em dois `Text`: ícone com `Cfg.Config.iconFontFamily`, temperatura com a
fonte normal. `scripts/weather.sh` agora manda `icon` e `temp` como campos
JSON separados (mantendo `text` combinado por compatibilidade).

**2) Volume ainda não respondia.** Reparei que `AudioMixerPopup.qml` era o
ÚNICO lugar em todo o projeto usando `QtQuick.Controls.Slider` — todo o
resto (barra de progresso de mídia, medidores de recurso) sempre foi um
`Rectangle`+`MouseArea` feito à mão. Troquei o Slider por uma barra igual,
no mesmo padrão do resto do shell — mais previsível e sob controle total
do gesto de arrastar.

**3/4) Ícones e fontes.** Criei `config/Icons.qml` (tabela central de
glifos Nerd Font, conjunto clássico `nf-fa-*`, praticamente garantido em
qualquer Nerd Font patched) e `Config.fontFamily`/`iconFontFamily`/
`monoFontFamily`. Troquei TODOS os emoji soltos (🔊⚙🎵📶🔵🔋🎨⏮⏸▶⏭ etc)
por esses glifos em `ResourceIndicator`, `MediaIndicator`, `SysMenuGroup`,
`SysMenuPopup`, `MediaPopup`, `CalendarPopup`. Os ícones dos workspaces
(kanji 一二三...) foram mantidos — eram uma escolha de design deliberada,
não um emoji "solto".

Sobre o warning `Could not load icon "battery-060"`: isso não vem do
nosso código (não referenciamos esse nome de ícone em lugar nenhum, já
conferi) — é um item de tray EXTERNO (provavelmente um applet de bateria/
power) pedindo um ícone temático que o teu tema de ícones do sistema não
tem nesse frame específico. Inofensivo, mas não é algo que o shell.qml
controla.

## Correções da 12ª rodada — mixer de áudio (apps não apareciam, volume mestre travado)

Duas causas, ambas em `popups/AudioMixerPopup.qml`:

1. `PwObjectTracker { objects: [Pipewire.defaultAudioSink, ...] }` — se o
   popup abrisse antes do `Pipewire.defaultAudioSink` estar pronto (a
   própria doc do Quickshell avisa que ele pode ficar `null`
   momentaneamente), esse `null` no meio da lista quebrava o tracking de
   TUDO — inclusive do dispositivo principal, por isso o volume mestre não
   respondia a nada. Agora filtramos `null` antes de montar a lista.
2. O filtro pra achar "streams de aplicação tocando áudio" usava
   `isStream && audio && !isSink`, uma combinação ambígua que na prática
   não capturava nada. Achei o código-fonte real do Quickshell: media.class
   "Stream/Output/Audio" (streams de reprodução de app) mapeia direto pra
   `PwNodeType.AudioOutStream` — trocamos pra esse valor exato.

## Correções da 11ª rodada — ilha não esconde mais com menu de tray aberto

Mesmo princípio da 8ª rodada, agora aplicado ao `Tray.qml`: ele expõe
`menuOpen` (contador de menus abertos, já que há um `QsMenuAnchor` por
ícone via `Repeater`). `BottomBar.qml` inclui isso em
`shouldStayRevealed`.

### Sobre o estilo do menu de tray destoar do tema
Os menus de nm-applet/blueman (e de qualquer app SNI/DBusMenu) são
`PlatformMenuEntry` — renderizados pelo **Qt Widgets** (`QMenu` nativo),
não pelo nosso QML. É por isso que precisamos do `//@ pragma
UseQApplication` pra eles funcionarem: literalmente é outro motor de
renderização, que não lê `config/Colors.qml` de jeito nenhum — segue o
tema Qt Widgets do sistema (via `qt6ct`/`qt5ct` ou a variável de ambiente
`QT_QPA_PLATFORMTHEME`). Pra aproximar visualmente, o caminho é configurar
esse tema do sistema (`qt6ct` ou similar) pra bater com a paleta do
`Colors.qml`, não algo que dá pra fazer de dentro do shell.qml.

## Correções da 10ª rodada — menus da bandeja (nm-applet/blueman) finalmente abrindo

Log: `PlatformMenuEntry.display() must be called with a window`.
`SystemTrayItem.display(parentWindow, x, y)` exige um objeto de janela do
próprio Quickshell (`QsWindow`); o que passávamos (`Item.Window.window`,
window "crua" do QtQuick) não serve. Troquei por `QsMenuAnchor` — o jeito
que a doc do Quickshell recomenda pra exibir `SystemTrayItem.menu`,
ancorado direto no ícone via `anchor.item` (mesma técnica que o
`AnchoredPopup.qml` já usa pros nossos próprios popups). `Tray.qml` não
depende mais de resolver referência de janela manualmente.

## Correções da 9ª rodada — popup finalmente fecha ao clicar fora

A tentativa anterior (`HyprlandFocusGrab`) não fechava o popup na prática.
Achei a causa: essa API, segundo a doc oficial do `PopupWindow`, serve pra
um caso mais avançado ("detectar clique fora SEM fechar o popup
automaticamente"). O que a gente quer é bem mais simples e já existe como
propriedade nativa do próprio `PopupWindow`: **`grabFocus: true`** — "se
verdadeiro, o popup será dispensado e `visible` vira `false` se o usuário
clicar fora dele". Troquei o `HyprlandFocusGrab` por essa propriedade em
`AnchoredPopup.qml`. Bônus: como `SysMenuGroup.popupOpen` já observa
`audioPopup.visible`/`sysMenuPopup.visible`, fechar por clique-fora agora
também libera a ilha inferior pra esconder de novo automaticamente (ver
8ª rodada).

## Correções da 8ª rodada — ilha não esconde mais com popup aberto

`SysMenuGroup.qml` agora expõe `popupOpen` (true se o popup de áudio ou o
de sistema estiver visível). `BottomBar.qml` usa isso combinado com o
hover: `shouldStayRevealed = hoverArea.containsMouse || sysMenuGroup.popupOpen`.
Antes, se o mouse saísse da área da ilha em direção a um popup aberto por
ela (que é uma janela separada, não conta como "hover" da ilha), o timer
de esconder disparava por baixo do popup. Agora ela só esconde quando
nenhuma das duas condições for verdadeira.

## Correções da 7ª rodada — cliques quebrados + fechar popup ao clicar fora

1. **Bluetooth/rede/tray não clicáveis** — causa raiz confirmada pelo log:
   `popups/SysMenuPopup.qml` usava `Quickshell.execDetached(...)` (troca de
   tema, botões de energia, abrir `nm-connection-editor`/`blueman-manager`)
   sem ter `import Quickshell` no topo do arquivo — `ReferenceError:
   Quickshell is not defined`. Adicionado o import. Também varri o resto do
   projeto atrás do mesmo padrão de erro; não achei outro caso.
2. **Ícones reais da bandeja (nm-applet, blueman, etc)** — blindei
   `Tray.qml`: antes chamava `display()` (abrir menu) sempre que era
   `onlyMenu` ou botão direito, mesmo que o item não tivesse `hasMenu` —
   agora só chama `display()` quando `hasMenu` é verdadeiro, e só chama
   `activate()` quando o item não é `onlyMenu`.
3. **Fechar popup ao clicar fora** — implementado com `HyprlandFocusGrab`
   (protocolo `hyprland_focus_grab_v1`), o mecanismo nativo do
   Quickshell+Hyprland pra isso: `AnchoredPopup.qml` agora ativa um grab
   enquanto o popup está visível, e o sinal `cleared` (disparado ao
   clicar/tocar fora da janela) fecha o popup automaticamente. `Esc`
   continua funcionando também.

## Correções da 6ª rodada — auto-hide de volta + Tray fixo à direita

A ilha inferior tinha ficado sempre visível (pedido da 4ª rodada); agora
volta a ficar escondida por padrão, aparecendo só com o mouse na borda de
baixo da tela (igual à barra de tarefas do Windows — mesma técnica da 3ª
rodada, mas revisada). Dentro dela, nada recolhe mais individualmente:
`WorkspaceDock.qml` sempre mostra todos os workspaces com janela, e o dock
de tray/config perdeu o hover próprio que tinha ganhado na 5ª rodada.

`SysTrayDock.qml` foi dividido em dois módulos novos:
- `Tray.qml` — só os ícones da bandeja do sistema, fixo, sempre visível.
- `SysMenuGroup.qml` — áudio + botão de configurações, também fixo.

No `RowLayout` da `BottomBar.qml`, a ordem agora é
Workspaces → Áudio/Config → **Tray** (por último = fica na ponta direita
da ilha).

## Correções da 5ª rodada — hover de volta só no dock de tray/config
(SUBSTITUÍDA pela 6ª rodada acima — mantida aqui só de histórico.)

`WorkspaceDock.qml` continua sempre visível (sem mudanças). `SysTrayDock.qml`
voltou a ter comportamento de hover — mas SÓ ele, a `BottomBar.qml` em si
segue sempre visível como pedido na rodada anterior. Também troquei a
ordem: antes era tray→áudio→configurações (configurações por último);
agora configurações fica FIXA e visível (é o "ícone recolhido" do dock), e
áudio+bandeja aparecem ao lado dela ao passar o mouse.

## Correções da 4ª rodada — "barra inferior igual à superior"

Removido todo o mecanismo de auto-hide (estilo barra do Windows) e o
recolher/expandir por hover dos docks. `BottomBar.qml` agora segue
exatamente o mesmo padrão de `TopBar.qml`: faixa única flutuante, sempre
visível, sem `MouseArea`/`Timer`/`margins` animadas. `WorkspaceDock.qml`
mostra sempre todos os workspaces com janela ativa (se nenhum tiver janela,
mostra pelo menos o workspace focado, pra nunca sumir); `SysTrayDock.qml`
mostra sempre bandeja + áudio + botão de sistema. `widgets/Pill.qml`
continua no projeto (não é usado por nada agora, mas fica disponível se
precisares de algum recolhimento por hover em outro widget no futuro).

## Correções da 3ª rodada (log + screenshot mais recentes)

1. **Clima não aparecia (`JSON.parse` falhando)** — causa raiz: chamávamos
   `bash -c "<caminho-do-script>"`, que faz o bash tentar EXECUTAR o
   arquivo diretamente (exige `+x`, que se perde facilmente ao
   zipar/copiar). Troquei todas as chamadas de script próprio para
   `bash <caminho> [args]` — agora é o bash que LÊ o conteúdo, então
   **não precisa mais de `chmod +x`** (`Weather.qml`, `Peripherals.qml`,
   `SysMenuPopup.qml`, `weather-set-city.sh`).
2. **Hover da barra inferior não respondia direito** — a janela só existia
   embaixo dos próprios ícones (largura = largura dos docks). Agora a
   janela ocupa a tela inteira na horizontal, então qualquer ponto da
   borda de baixo dispara a revelação.
3. **Resource Monitor longe do relógio + clima/música sobrepostos** — a
   `TopBar.qml` calculava centralização manualmente (`anchors.centerIn` +
   soma de larguras), o que dava conta errada sempre que o
   MediaIndicator mudava de tamanho (toca/não toca música). Troquei por um
   `RowLayout` simples com espaçamento fixo — sem contas manuais, sem
   sobreposição.

## Correções da 2ª rodada (log + screenshots anteriores)

1. **Calendário não abria / TopBar sem relógio nem clima** — `Qt.labs.calendar`
   não vem instalado por padrão em toda distro Qt6. `CalendarPopup.qml` foi
   reescrito sem esse módulo (grid do mês calculado manualmente em JS, só
   QtQuick puro).
2. **TopBar usava `Loader` pra cada seção** — quando um deles falhava (o
   calendário, no caso), isso mascarava o erro e deixava a UI sem pista
   clara. Troquei por instanciação direta dos componentes.
3. **Workspaces não apareciam** — `WorkspaceDock.qml` tem uma
   `required property monitorScreen`; estava sendo setada tarde demais via
   `Loader.onLoaded`, o que o Quickshell não aceita pra required properties.
   `BottomBar.qml` agora instancia `WorkspaceDock { monitorScreen: ... }`
   diretamente.
4. **Também troquei `Hyprland.monitorFor()`** (não consegui confirmar esse
   método com certeza pra tua versão) **por comparação de nome de monitor**
   (`m.name === monitorScreen.name`), mais portável.
5. **Botões de volume e do menu de sistema não apareciam** —
   `SysTrayDock.qml` declarava os `AnchoredPopup` FORA do bloco `content`,
   mas eles precisavam enxergar `audioBtn`/`sysBtn`, que só existem DENTRO
   dele (ids declarados dentro de um `Component` — o que `content` vira por
   baixo dos panos — não são visíveis por fora). Os popups agora moram no
   mesmo escopo.
6. **`Keys.onEscapePressed` gerava warning** — estava anexado direto no
   `PopupWindow` (que não é um `Item`). Movido pro `Rectangle` interno.
7. **Barra inferior agora esconde/aparece como a barra de tarefas do
   Windows** — fica com só uma tira de ~6px encostada na borda; ao tocar
   nela com o mouse, a barra inteira sobe (animada). Os docks
   individuais (Workspaces / SysMenu+Tray) continuam recolhendo/expandindo
   por conta própria dentro dela, como antes.
8. **Scripts integrados** — os 5 `.sh` que mandaste agora estão em
   `scripts/`, já com os caminhos ajustados pro Quickshell.
   `trocar_tema.sh` foi migrado: em vez de escrever `colors.css` pro AGS e
   chamar `ags request reload-css` (que não existe mais), ele escreve
   `theme-colors.json`, que `config/Colors.qml` observa e recarrega
   automaticamente (sem precisar reiniciar nada).

## Coisas que eu não consegui verificar 100% (sem acesso a rodar o Quickshell)
- O nome exato de algumas propriedades/métodos pode variar pela tua versão
  instalada (`qs --version` pra conferir). Se algo ainda quebrar, me manda o
  log de novo — geralmente é só o nome de uma propriedade que mudou.
- O auto-hide da barra inferior usa `margins.bottom` negativo pra empurrar a
  janela pra fora da tela — é uma técnica comum de layer-shell, mas testa
  na prática pra ver se o Hyprland aceita suavemente ou se prefere que eu
  troque por outra abordagem (ex: opacidade + `exclusiveZone` dinâmico).

- Barra inferior: **Workspaces** sozinho + **SysMenu+Tray** juntos, os dois
  recolhidos por padrão, expandindo no hover (`widgets/Pill.qml`).
- Tray como seção própria dentro do dock SysMenu (não mais dentro do painel
  de sistema).
- Barras como faixa única contínua flutuante (não mais 3 ilhas separadas).
- Barra superior: Resource | Clock+Weather (centro) | Media.
- MediaIndicator recolhe pro ícone 🎵 quando não há mídia tocando.
- Relógio: hover expande a data **pra esquerda**; clique na data (já
  expandida) abre o popup de calendário.
