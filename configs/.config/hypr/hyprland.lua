local HOME = os.getenv("HOME")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland")
require("modules.startup")
require("modules.keybindings")
require("modules.windowrules")
require("modules.plugins")
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
local profile = loadfile(HOME .. "/.config/hypr/zenbook.lua")
if profile then profile() end

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

local function animation(leaf, speed, style)
    hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = "default", style = style })
end
animation("windows", 7, "popin 85%")
animation("windowsOut", 5, "popin 92%")
animation("fade", 6)
animation("specialWorkspace", 6, "slide")
animation("workspaces", 6, "slide")
animation("windowsMove", 6)
animation("border", 4)

local borderColors = {
    active = { "rgba(00D2C8ff)", "rgba(8B2FC9ff)" },
    inactive = { "rgba(0D0520ff)", "rgba(050308ff)" },
}

local borderFile = HOME .. "/.cache/wallpalette/borders.lua"
local chunk = loadfile(borderFile)

if chunk then
    local ok, result = pcall(chunk)
    if ok and type(result) == "table" then
        borderColors = result
    end
end

hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = false,
        },
        sensitivity = 0,
        force_no_accel = 0,
        numlock_by_default = false,
    },
    -- ---------- GLOBAL COLORS / BORDERS ----------
    general = {
        border_size = 3,
        gaps_in = 3,
        gaps_out = 8,
        resize_on_border = true,
        no_focus_fallback = false,
        col = {
            active_border = { colors = borderColors.active, angle = 90 },
            inactive_border = { colors = borderColors.inactive, angle = 90 },
        },
        layout = "dwindle",
    },
    group = {
        col = {
            border_active = { colors = borderColors.active, angle = 90 },
            border_inactive = { colors = borderColors.inactive, angle = 90 },
            border_locked_active = { colors = { "rgba(FF6B00ff)", "rgba(E91E8Cff)" }, angle = 45 },
            border_locked_inactive = { colors = { "rgba(8B2FC9cc)", "rgba(8B2FC9cc)" }, angle = 45 },
        },
    },
    dwindle = {

        preserve_split = true,
    },
    -- ---------- DECORATION: rounded corners, soft shadow, blur ----------
    decoration = {
        rounding = 14,
        active_opacity = 1.0,
        inactive_opacity = 0.94,
        blur = {
            enabled = true,
            size = 8,
            passes = 2,
            new_optimizations = false,
        },
        shadow = {
            enabled = true,
            range = 12,
            render_power = 3,
            color = "rgba(2B0526cc)",
        },
    },
    animations = {
        enabled = 1,
    },
    cursor = {
        no_hardware_cursors = true,
    },
    -- cursor + font + GTK settings (keeps your selections)
    misc = {
        vrr = 0,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
    xwayland = {
        force_zero_scaling = true,
    },
    gestures = {
        workspace_swipe_touch = true,
        workspace_swipe_cancel_ratio = 0.15,
    },
    render = {
        cm_auto_hdr = 0, 
    },
})

hl.on("config.reloaded", function()
    local cursor = "Adwaita"
    local bibata = io.open("/usr/share/icons/Bibata-Modern-Ice/cursors/left_ptr", "rb")
    if bibata then
        bibata:close()
        cursor = "Bibata-Modern-Ice"
    end
    if os.getenv("YOLO_CURSOR") == "Bibata-Modern-Ice" then cursor = "Bibata-Modern-Ice" end
    hl.exec_cmd("hyprctl setcursor " .. cursor .. " 20")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme " .. cursor)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 20")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'Cantarell 10'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 10'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'CaskaydiaCove Nerd Font Mono 9'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-hinting 'full'")
end)

