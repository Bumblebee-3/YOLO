local panel_scale = 1.5
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = panel_scale, bitdepth = 10 })
-- The handoff compositor exposes the panel under its Wayland output name.
hl.monitor({ output = "WAYLAND-1", mode = "preferred", position = "auto", scale = panel_scale })
local is_flipped = false

local function toggle_flip()
    is_flipped = not is_flipped
    local t = is_flipped and 2 or 0
    
    -- Rotate display
    hl.monitor({
        output = "eDP-1",
        mode = "preferred",
        position = "auto",
        scale = panel_scale,
        transform = t,
    })

    -- Rotate physical touchscreen
    hl.device({
        name = "wdht1f01:00-2575:092e",
        transform = t,
        output = "eDP-1",
    })

    -- Rotate stylus
    hl.device({
        name = "wdht1f01:00-2575:092e-stylus",
        transform = t,
        output = "eDP-1",
    })
end

require("modules.shortcuts").bind("rotate-display", toggle_flip)


hl.env("LIBVA_DRIVER_NAME", "iHD")
hl.env("MOZ_DRM_DEVICE", "/dev/dri/renderD128")
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/powermode.sh apply")
    hl.exec_cmd("sleep 5 && python /usr/share/asus-numberpad-driver/numberpad.py up5401ea /usr/share/asus-numberpad-driver")
end)
