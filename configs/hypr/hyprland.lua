-- ==============================================================================
-- hyprland.lua  (config em Lua — Hyprland 0.56+)
-- Migrado do hyprland.conf legado. O arquivo hyprland.conf foi mantido como
-- backup/garantia e o Hyprland prioriza este .lua automaticamente.
-- ==============================================================================

-- ==============================================================================
-- 1. MONITORES (DISPLAYS)
-- ==============================================================================
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "0x0",  scale = 1 })
hl.monitor({ output = "DP-1",     mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = "",         mode = "preferred", position = "auto", scale = 1 }) -- fallback

-- ==============================================================================
-- 2. VARIÁVEIS E FONTES
-- ==============================================================================
local mainMod    = "SUPER"
local terminal    = "/usr/bin/ghostty"
local fileManager = "thunar"
local menu        = "vicinae toggle"

-- Cores (Lidas dinamicamente do motor de temas)
local c = dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")
local fundo      = c.fundo
local superficie = c.superficie
local base       = c.base
local destaque1  = c.destaque1
local destaque2  = c.destaque2
local texto      = c.texto

-- ==============================================================================
-- 3. AUTOSTART (exec-once)
-- ==============================================================================
hl.on("hyprland.start", function()
    hl.exec_cmd("solaar")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/portal.sh")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/quickshell/scripts/launch.sh")
    hl.exec_cmd("fcitx5 -d")

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd("systemctl --user start graphical-session.target")

    -- Papel de Parede
    hl.exec_cmd("hyprpaper")

    -- Aplicativos
    hl.exec_cmd("discord")
    hl.exec_cmd("spotify")
    hl.exec_cmd("steam")
    hl.exec_cmd("vicinae server")
end)

-- ==============================================================================
-- 5. TECLADO E MOUSE (INPUT)
-- ==============================================================================
hl.config({
    input = {
        kb_layout  = "br",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
    },
})

-- ==============================================================================
-- 6. APARÊNCIA (LOOK & FEEL)
-- ==============================================================================
hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 5,
        border_size = 2,

        -- Bordas com degradê fosco entre o azul gélido discreto e o cinza asfalto
        col = {
            active_border   = { colors = {destaque1, destaque2}, angle = 45 },
            inactive_border = base,
        },

        layout = "dwindle",
    },

    misc = {
        focus_on_activate = true,
    },

    decoration = {
        rounding        = 10,
        active_opacity  = 1,
        inactive_opacity = 0.95,

        -- Blur sutil nas janelas sem gerar "neon" nos fundos
        blur = {
            enabled           = false,
            size              = 5,
            passes            = 2,
            new_optimizations = true,
        },

        -- Desativando sombras brilhantes para focar em superfícies puras e foscas
        shadow = {
            enabled = false,
        },
    },
})

-- ==============================================================================
-- 7. WORKSPACES
-- ==============================================================================
-- Workspaces do Monitor Principal (HDMI-A-1)
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", persistent = true })

-- Workspaces do Monitor Secundário (DP-1)
hl.workspace_rule({ workspace = "6",  monitor = "DP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "7",  monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "8",  monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "9",  monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "DP-1", persistent = true })

-- ==============================================================================
-- 8. REGRAS DE JANELAS (WINDOW RULES)
-- ==============================================================================
-- Associações de Workspaces
hl.window_rule({ match = { class = ".*discord.*" }, workspace = "9" })
hl.window_rule({ match = { class = ".*Spotify.*" }, workspace = "10" })
hl.window_rule({ match = { class = ".*steam.*" },   workspace = "5" })

-- Popups Flutuantes
hl.window_rule({
    name  = "popup_volume",
    match = { class = ".*pavucontrol.*" },
    float = true,
    size  = {400, 300},
    move  = {"100%-410", "50"},
    pin   = true,
})

hl.window_rule({
    name  = "popup_wifi",
    match = { class = ".*nm-connection-editor.*" },
    float = true,
    size  = {400, 300},
    move  = {"100%-410", "50"},
    pin   = true,
})

hl.window_rule({
    name  = "popup_bluetooth",
    match = { class = ".*blueman-manager.*" },
    float = true,
    size  = {400, 300},
    move  = {"100%-410", "50"},
    pin   = true,
})

-- Regras de Layer
hl.layer_rule({
    name  = "janela-rss",
    match = { class = ".*janela-rss*" },
    blur  = true, -- no Lua, blur de layer rule é booleano (legacy 0.1 → true)
})

hl.layer_rule({
    name = "vicinae-blur",
    match = { namespace = "vicinae" },
    blur  = true,
    ignore_alpha = 0,
})

hl.layer_rule({
    name     = "vicinae-no-animation",
    match    = { namespace = "vicinae" },
    no_anim  = true,
})

-- ==============================================================================
-- 9. ATALHOS (KEYBINDINGS)
-- ==============================================================================
-- Aplicativos e Sistema
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/smart_close.sh"))
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd(menu), { release = true })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("vicinae deeplink vicinae://launch/clipboard/history"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("zen"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("quickshell ipc call settings toggle"))

-- Captura de Tela (Satty - anotações estilo Lightshot)
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty --filename - --fullscreen'))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | satty --filename - --fullscreen'))

-- Gerenciamento de Janelas e Layout
hl.bind(mainMod .. " + Z", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + left",  hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/workspace_cycle.sh prev"))
hl.bind(mainMod .. " + right", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/workspace_cycle.sh next"))

hl.bind(mainMod .. " + down", hl.dsp.window.move({ workspace = "e-1" }))
hl.bind(mainMod .. " + up",   hl.dsp.window.move({ workspace = "e+1" }))

-- Workspaces e Movimentação
for i = 1, 10 do
    local key = (i == 10) and "0" or tostring(i)
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Controle pelo Mouse (Arrastar e Redimensionar)
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ==============================================================================
-- 10. CONTROLE DE MÍDIA E VOLUME
-- ==============================================================================
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioPlay",        hl.dsp.exec_cmd("playerctl --player=spotify,%any play-pause"),        { locked = true })
hl.bind("XF86AudioPause",       hl.dsp.exec_cmd("playerctl --player=spotify,%any play-pause"),        { locked = true })
hl.bind("XF86AudioNext",        hl.dsp.exec_cmd("playerctl --player=spotify,%any next"),              { locked = true })
hl.bind("XF86AudioPrev",        hl.dsp.exec_cmd("playerctl --player=spotify,%any previous"),          { locked = true })pcall(dofile, os.getenv("HOME") .. "/.config/hypr/quickshell-mod.lua")
os.execute("echo RELOADED >> /tmp/hypr_lua.log")
