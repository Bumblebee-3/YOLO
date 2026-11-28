local shortcuts = require("modules.shortcuts")
local bind = shortcuts.bind
bind("open-control-center", hl.dsp.exec_cmd("qs -n -p ~/.config/quickshell/control.qml"))

bind("switch-tiling-layout", function()
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
    bind("mirror-configured-phone", hl.dsp.exec_cmd("pkill scrcpy || (adb connect " .. phone ..
        " && scrcpy -s " .. phone .. " --max-size=1280 --video-bit-rate=5M --turn-screen-off --max-fps=60)"),
        { ignore_mods = true })
end
bind("open-code-editor", hl.dsp.exec_cmd("command -v code >/dev/null && code"))
bind("circle-to-search", hl.dsp.exec_cmd("~/.local/bin/circle"), {
    ignore_mods = true
})

bind("open-terminal", hl.dsp.exec_cmd("kitty"))
bind("toggle-lid-sleep",hl.dsp.exec_cmd("~/.local/bin/lidtoggle"))
bind("open-task-manager",hl.dsp.exec_cmd( "kitty --class floating-taskmanager -e btop"))
bind("mirror-android-device", hl.dsp.exec_cmd("pkill scrcpy || scrcpy --tcpip --turn-screen-off"))
bind("close-window", hl.dsp.window.close())
bind("exit-hyprland", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
bind("open-file-manager", hl.dsp.exec_cmd("dolphin"))
bind("change-wallpaper", hl.dsp.exec_cmd("pkill rofi || ~/.local/bin/wallswitch"))
bind("open-kde-connect", hl.dsp.exec_cmd("kdeconnect-app"))
bind("toggle-floating", hl.dsp.window.float({ action = "toggle" }))
bind("open-workspace-overview", function()
    if hl.plugin.overview then hl.plugin.overview.open() end
end)
bind("open-clipboard-history", hl.dsp.exec_cmd("pkill memoria-ui || memoria-ui"))
bind("pick-emoji", hl.dsp.exec_cmd("pkill rofi || rofimoji --action type --hidden-descriptions --selector-args=\"-theme @YOLO_HOME@/.config/rofi/rofi-emoji.rasi\""))
bind("open-application-launcher", hl.dsp.exec_cmd("pkill rofi ||rofi -show drun -theme ~/.config/rofi/application-manager.rasi"))
bind("force-close-window", hl.dsp.exec_cmd("hyprctl kill"))
bind("toggle-opaque-window", hl.dsp.window.set_prop({ prop = "opaque", value = "toggle", window = "active" }))
bind("open-browser", hl.dsp.exec_cmd("GTK_THEME=Adwaita:dark firefox"))
bind("capture-region-to-clipboard", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
bind("raise-screen-brightness", hl.dsp.exec_cmd("swayosd-client --brightness raise --device '*'"))
bind("lower-screen-brightness", hl.dsp.exec_cmd("swayosd-client --brightness lower --device '*'"))
bind("cycle-keyboard-backlight", hl.dsp.exec_cmd("~/.config/hypr/scripts/kbd_backlight.sh"))
-- Volume
bind("raise-volume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"))
bind("lower-volume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"))
bind("mute-output", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"))
bind("mute-microphone", hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))

bind("send-to-special-workspace", hl.dsp.window.move({ workspace = "special", follow = false }))
bind("toggle-special-workspace", hl.dsp.workspace.toggle_special(""))

-- Move focused window to a relative workspace
bind("move-to-next-relative-workspace", hl.dsp.window.move({ workspace = "r+1" }))
bind("move-to-previous-relative-workspace", hl.dsp.window.move({ workspace = "r-1" }))



-- Move active window around current workspace with mainMod + SHIFT + CTRL [←→↑↓]
local moveactivewindow = "hyprctl activewindow -j | jq -e .floating >/dev/null && hyprctl dispatch moveactive"
bind("move-window-left", hl.dsp.exec_cmd(moveactivewindow .. " -30 0 || hyprctl dispatch movewindow l"), { repeating = true, description = "Move activewindow left" })
bind("move-window-right", hl.dsp.exec_cmd(moveactivewindow .. " 30 0 || hyprctl dispatch movewindow r"), { repeating = true, description = "Move activewindow right" })
bind("move-window-up", hl.dsp.exec_cmd(moveactivewindow .. "  0 -30 || hyprctl dispatch movewindow u"), { repeating = true, description = "Move activewindow up" })
bind("move-window-down", hl.dsp.exec_cmd(moveactivewindow .. " 0 30 || hyprctl dispatch movewindow d"), { repeating = true, description = "Move activewindow down" })

bind("pick-screen-color", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color Picker" })
bind("lock-screen", hl.dsp.exec_cmd("hyprlock"))
bind("cycle-layout-via-command", hl.dsp.exec_cmd("hyprctl keyword general:layout \"$(hyprctl getoption general:layout | grep -q 'dwindle' && echo 'master' || echo 'dwindle')\""))
-- Scroll through existing workspaces
bind("scroll-to-next-workspace", hl.dsp.focus({ workspace = "e+1" }))
bind("scroll-to-previous-workspace", hl.dsp.focus({ workspace = "e-1" }))

-- Move/Resize focused window
bind("drag-window-with-mouse", hl.dsp.window.drag())
bind("resize-window-with-mouse", hl.dsp.window.resize())
bind("drag-window-with-keyboard", hl.dsp.window.drag())
bind("resize-window-with-keyboard", hl.dsp.window.resize())

-- Switch workspaces to a relative workspace
bind("next-workspace", hl.dsp.focus({ workspace = "r+1" }))
bind("previous-workspace", hl.dsp.focus({ workspace = "r-1" }))

-- Move to the first empty workspace
bind("first-empty-workspace", hl.dsp.focus({ workspace = "empty" }))

-- Resize windows
bind("enlarge-window-horizontally", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
bind("shrink-window-horizontally", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
bind("shrink-window-vertically", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
bind("enlarge-window-vertically", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

-- Move/Change window focus
bind("focus-left", hl.dsp.focus({ direction = "left" }))
bind("focus-right", hl.dsp.focus({ direction = "right" }))
bind("focus-up", hl.dsp.focus({ direction = "up" }))
bind("focus-down", hl.dsp.focus({ direction = "down" }))
bind("cycle-focus", hl.dsp.focus({ direction = "down" }))

for workspace = 1, 10 do
    bind("workspace-" .. workspace, hl.dsp.focus({ workspace = workspace }))
    bind("send-workspace-" .. workspace, hl.dsp.window.move({ workspace = workspace }))
end
bind("edit-shortcuts", hl.dsp.exec_cmd("~/.local/bin/yolo-keybindings"))
bind("record", hl.dsp.exec_cmd("~/.config/hypr/scripts/record-toggle.sh"))
bind("record-mic", hl.dsp.exec_cmd("~/.config/hypr/scripts/record-toggle.sh mic"))
bind("record-system", hl.dsp.exec_cmd("~/.config/hypr/scripts/record-toggle.sh sys"))
bind("record-pause", hl.dsp.exec_cmd("~/.config/hypr/scripts/record-toggle.sh pause"))
shortcuts.bind_custom()
