local mainMod = "SUPER"

hl.bind(mainMod .. "+ J", function()
    -- Read the current layout setting
    local current_layout = hl.get_config("general.layout")
    
    -- Swap between layouts dynamically
    if current_layout == "dwindle" then
        hl.config({ general = { layout = "master" } })
    else
        hl.config({ general = { layout = "dwindle" } })
    end
end)


local phone = os.getenv("YOLO_ANDROID_DEVICE")
if phone and phone:match("^[%w%.:%-]+$") then
    hl.bind("code:201", hl.dsp.exec_cmd("pkill scrcpy || (adb connect " .. phone ..
        " && scrcpy -s " .. phone .. " --max-size=1280 --video-bit-rate=5M --turn-screen-off --max-fps=60)"),
        { ignore_mods = true })
end
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("command -v code >/dev/null && code"))
hl.bind("XF86Launch1", hl.dsp.exec_cmd("~/.local/bin/circle"), {
    ignore_mods = true
})

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + I",hl.dsp.exec_cmd("~/.local/bin/lidtoggle"))
hl.bind("CTRL+SHIFT+Escape",hl.dsp.exec_cmd( "kitty --class floating-taskmanager -e btop"))
hl.bind(mainMod .. "+ SHIFT + F23", hl.dsp.exec_cmd("pkill scrcpy || scrcpy --tcpip --turn-screen-off"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill rofi || ~/.local/bin/wallswitch"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("kdeconnect-app"))
hl.bind(mainMod .. " + U", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("pkill memoria-ui || memoria-ui"))
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("pkill rofi || rofimoji --action type --hidden-descriptions --selector-args=\"-theme @YOLO_HOME@/.config/rofi/rofi-emoji.rasi\""))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("pkill rofi ||rofi -show drun -theme ~/.config/rofi/application-manager.rasi"))
hl.bind(mainMod .. " + k", hl.dsp.exec_cmd("hyprctl kill"))
hl.bind("SUPER + O", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle", window = "active" }))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd("GTK_THEME=Adwaita:dark firefox"))
hl.bind("Print", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"))
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("~/.config/hypr/scripts/kbd_backlight.sh"))
-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))

hl.bind("SUPER+ALT + S", hl.dsp.window.move({ workspace = "special", follow = false }))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special(""))

-- Move focused window to a relative workspace
hl.bind("SUPER+CTRL+ALT + Right", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER+CTRL+ALT + Left", hl.dsp.window.move({ workspace = "r-1" }))



-- Move active window around current workspace with mainMod + SHIFT + CTRL [←→↑↓]
local moveactivewindow = "hyprctl activewindow -j | jq -e .floating >/dev/null && hyprctl dispatch moveactive"
hl.bind(mainMod .. "+ SHIFT+ CTRL + left", hl.dsp.exec_cmd(moveactivewindow .. " -30 0 || hyprctl dispatch movewindow l"), { repeating = true, description = "Move activewindow left" })
hl.bind(mainMod .. "+ SHIFT+ CTRL + right", hl.dsp.exec_cmd(moveactivewindow .. " 30 0 || hyprctl dispatch movewindow r"), { repeating = true, description = "Move activewindow right" })
hl.bind(mainMod .. "+ SHIFT+ CTRL + up", hl.dsp.exec_cmd(moveactivewindow .. "  0 -30 || hyprctl dispatch movewindow u"), { repeating = true, description = "Move activewindow up" })
hl.bind(mainMod .. "+ SHIFT+ CTRL + down", hl.dsp.exec_cmd(moveactivewindow .. " 0 30 || hyprctl dispatch movewindow d"), { repeating = true, description = "Move activewindow down" })

hl.bind("SUPER+SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color Picker" })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("hyprctl keyword general:layout \"$(hyprctl getoption general:layout | grep -q 'dwindle' && echo 'master' || echo 'dwindle')\""))
-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/Resize focused window
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())
hl.bind(mainMod .. " + Z", hl.dsp.window.drag())
hl.bind(mainMod .. " + X", hl.dsp.window.resize())

-- Switch workspaces to a relative workspace
hl.bind("SUPER+CTRL + Right", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER+CTRL + Left", hl.dsp.focus({ workspace = "r-1" }))

-- Move to the first empty workspace
hl.bind("SUPER+CTRL + Down", hl.dsp.focus({ workspace = "empty" }))

-- Resize windows
hl.bind("SUPER+SHIFT + Right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER+SHIFT + Left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER+SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind("SUPER+SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

-- Move/Change window focus
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 10 do
    local key = tostring(workspace % 10)
    hl.bind("SUPER + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end
