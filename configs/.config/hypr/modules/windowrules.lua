-- Keep the greeter still opaque and above the daemon until its first image is ready.
hl.layer_rule({ match = { namespace = "^yolo-control$" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "^wallpaper$" }, no_anim = true, order = 10 })
hl.layer_rule({ match = { namespace = "^awww-daemon.*$" }, no_anim = true })

hl.window_rule({
    name        = "conky",
    match       = { class = "^conky$" },
    float       = true,
    pin         = true,
    no_focus    = true,
    no_shadow   = true,
    border_size = 0,
    move        = { 560, 150 },
})

hl.window_rule({
    name  = "qemu-fullscreen",
    match = { class = "^qemu$" },
    fullscreen = true,
})

hl.window_rule({
    match = { title = "^(.*)$" },
    float = false,
})

hl.window_rule({
    match = { class = "^(zenity)$" },
    float = true,
    center = true,
    size = "600 380",
})

hl.window_rule({
    match = { class = "floating-taskmanager" },
    float = true,
    center = true,
    size = "1200 620",
})

hl.window_rule({
    match = { class = "^(scrcpy)$" },
    float = true,
    center = true,
    size = "335 746",
})

hl.window_rule({
    match = { title = "^(Listening...)$" },
    size = "1 140",
})

hl.window_rule({
    match = { title = "^(Processing...)$" },
    size = "1 140",
})

hl.window_rule({
    match = { class = "^(zenity)$" },
    opacity = "0.50 0.50",
})

hl.window_rule({
    match = { class = "^(cmake-gui)$" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "brave-browser" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "Element" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { class = "spotube" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "com.github.rafostar.Clapper" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "kitty" },
    opacity = "0.9 0.90",
})

hl.window_rule({
    match = { class = "firefox" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "LM-Studio" },
    opacity = "0.9 0.9",
})

hl.window_rule({
    match = { class = "Google-chrome" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "Brave-browser" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "code-oss" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "[Cc]ode" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "code-url-handler" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "code-insiders-url-handler" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "kitty" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { class = "org.kde.dolphin" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "nwg-look" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "libreoffice-startcenter" },
    opacity = "0.9 0.90",
})

hl.window_rule({
    match = { class = "swappy" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { class = "^(qt5ct)$" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { class = "^(qt6ct)$" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { class = "^(kvantummanager)$" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^(blueman-manager)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^(nm-applet)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^(nm-connection-editor)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^(polkit-gnome-authentication-agent-1)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^(org.freedesktop.impl.portal.desktop.gtk)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^(org.freedesktop.impl.portal.desktop.hyprland)$" },
    opacity = "0.80 0.70",
})

hl.window_rule({
    match = { class = "^([Ss]team)$" },
    opacity = "0.70 0.70",
})

hl.window_rule({
    match = { class = "^(steamwebhelper)$" },
    opacity = "0.70 0.70",
})

hl.window_rule({
    match = { class = "^([Ss]potify)$" },
    opacity = "0.70 0.70",
})

hl.window_rule({
    match = { title = "^(Spotify Free)$" },
    opacity = "0.70 0.70",
})

hl.window_rule({
    match = { title = "^(Spotify Premium)$" },
    opacity = "0.70 0.70",
})

hl.window_rule({
    match = { class = "^(com.github.rafostar.Clapper)$" },
    opacity = "0.90 0.90",
})

hl.window_rule({
    match = { class = "^(com.github.tchx84.Flatseal)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(org.kde.easyeffects)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(hu.kramo.Cartridges)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(com.obsproject.Studio)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(gnome-boxes)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(vesktop)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(discord)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(WebCord)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(ArmCord)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(app.drey.Warp)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(net.davidotek.pupgui2)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(yad)$" },
    opacity = "0.80 0.80",
    float = true,
    center = true,
})

hl.window_rule({
    match = { class = "^(Signal)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(io.github.alainm23.planify)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(io.gitlab.theevilskeleton.Upscaler)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(com.github.unrud.VideoDownloader)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(io.gitlab.adhami3310.Impression)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(io.missioncenter.MissionCenter)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(io.github.flattool.Warehouse)$" },
    opacity = "0.80 0.80",
})

hl.window_rule({
    match = { class = "^(xfce4-terminal)$" },
    opacity = "0.00 0.00",
    no_blur = true,
})

hl.window_rule({
    match = { title = "^(Progress Dialog — Dolphin)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Copying — Dolphin)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(About Mozilla Firefox)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Library)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(top)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(btop)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(htop)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(vlc)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(kvantummanager)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(qt5ct)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(qt6ct)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(nwg-look)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(org.kde.ark)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(blueman-manager)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(nm-applet)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(nm-connection-editor)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(Signal)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(com.github.rafostar.Clapper)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(app.drey.Warp)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(net.davidotek.pupgui2)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(yad)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(eog)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(io.github.alainm23.planify)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(io.gitlab.theevilskeleton.Upscaler)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(com.github.unrud.VideoDownloader)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(io.gitlab.adhami3310.Impression)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(io.missioncenter.MissionCenter)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Open)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Choose Files)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Save As)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(Confirm to replace files)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(File Operation Progress)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
})

hl.window_rule({
    match = { title = "^(memoria)$" },
    float = true,
    opacity = "0.80 0.80",
    center = true,
    size = "550 500",
})

hl.window_rule({
    match = { class = "^(rofi)$" },
    opacity = "0.85 0.85",
})
