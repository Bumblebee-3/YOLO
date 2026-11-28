
-- plugin settings: only applied once the plugin is actually loaded, so there is
-- no "unknown option" error flash while Hyprland starts up before hyprpm has run
local plugin_cfg = {
    hyprgrass = {
        sensitivity = 8.0,
        long_press_delay = 400,
        edge_margin = 10,
        resize_on_border_long_press = true,
        excluded_layer_namespaces = "osk, rofi",
    },
    overview = {
        panelHeight = 180,
        panelBorderWidth = 1,
        workspaceMargin = 10,
        reservedArea = 35,
        workspaceBorderSize = 1,
        centerAligned = true,
        onBottom = true,
        drawActiveWorkspace = true,
        hideRealLayers = false,
        affectStrut = false,
        autoDrag = true,
        autoScroll = true,
        exitOnClick = true,
        exitOnSwitch = true,
        disableGestures = false,
        workspaceActiveBackground = "rgba(86b0eb2e)",
        workspaceInactiveBackground = "rgba(080e17d9)",
        workspaceActiveBorder = "rgba(86b0ebff)",
        dragAlpha = 0.85,
        disableBlur = false,
    },
}

local function apply_plugin_config()
    local cfg = {}
    for name, opts in pairs(plugin_cfg) do
        if hl.plugin[name] then cfg[name] = opts end
    end
    if next(cfg) then hl.config({ plugin = cfg }) end
end
apply_plugin_config()

if not hl.plugin.hyprgrass then return end

local rec = "~/.config/hypr/scripts/record-toggle.sh"

hl.plugin.hyprgrass.bind {
    pattern = { kind = "tap", fingers = 5 },
    action = hl.dsp.exec_cmd(rec),            -- video only / stop
}
hl.plugin.hyprgrass.bind {
    pattern = { kind = "longpress", fingers = 5 },
    action = hl.dsp.exec_cmd(rec .. " mic"),  -- video + mic / stop
}
hl.plugin.hyprgrass.bind {
    pattern = { kind = "longpress", fingers = 4 },
    action = hl.dsp.exec_cmd(rec .. " pause"), -- pause / resume
}

-- four-finger swipe left/right: move the focused window to the next/previous workspace
hl.plugin.hyprgrass.bind {
    pattern = { kind = "swipe", fingers = 4, direction = "left" },
    action = hl.dsp.window.move({ workspace = "+1" }),
}
hl.plugin.hyprgrass.bind {
    pattern = { kind = "swipe", fingers = 4, direction = "right" },
    action = hl.dsp.window.move({ workspace = "-1" }),
}

-- three-finger tap: toggle floating
hl.plugin.hyprgrass.bind {
    pattern = { kind = "tap", fingers = 3 },
    action = hl.dsp.window.float(),
}

-- four-finger tap: screenshot a region to the clipboard
hl.plugin.hyprgrass.bind {
    pattern = { kind = "tap", fingers = 4 },
    action = hl.dsp.exec_cmd([[sh -c 'grim -g "$(slurp)" - | wl-copy']]),
}
hl.plugin.hyprgrass.bind {
    pattern = { kind = "longpress", fingers = 1 },
    action = hl.dsp.window.drag(),
    mouse = true,
}
hl.plugin.hyprgrass.gesture {
    pattern = { kind = "swipe", fingers = 4, direction = "down" },
    action = "close",
}
hl.plugin.hyprgrass.bind {
    pattern = { kind = "pinch", fingers = 3, direction = "pinchout" },
    action = hl.dsp.window.fullscreen(),
}
hl.plugin.hyprgrass.bind {
    pattern = { kind = "pinch", fingers = 3, direction = "pinchin" },
    action = hl.dsp.window.fullscreen(),
}

-- optional: resize with a two-finger long press
hl.plugin.hyprgrass.bind {
    pattern = { kind = "longpress", fingers = 2 },
    action = hl.dsp.window.resize(),
    mouse = true,
}
-- three-finger horizontal: workspace switch that follows your fingers
hl.plugin.hyprgrass.gesture {
    pattern = { kind = "swipe", fingers = 3, direction = "horizontal" },
    action = "workspace",
}

-- Bottom-edge swipe opens or closes the overview. 

hl.plugin.hyprgrass.bind {
    pattern = { kind = "edge", origin = "d", direction = "u" },
    action = function() if hl.plugin.overview then hl.plugin.overview.open() end end,
}
hl.plugin.hyprgrass.bind {
    pattern = { kind = "edge", origin = "d", direction = "d" },
    action = function() if hl.plugin.overview then hl.plugin.overview.close() end end,
}


-- Control Centre: swipe down from the top edge to open


-- Control Centre: swipe up towards the top edge to close


-- Control Centre: open
hl.plugin.hyprgrass.bind {
    pattern = { kind = "edge", origin = "u", direction = "d" },
    action = hl.dsp.exec_cmd(
        "qs ipc -p ~/.config/quickshell/control.qml call control open"
    ),
}

-- Control Centre: close
hl.plugin.hyprgrass.bind {
    pattern = { kind = "edge", origin = "u", direction = "u" },
    action = hl.dsp.exec_cmd(
        "qs ipc -p ~/.config/quickshell/control.qml call control close"
    ),
}
