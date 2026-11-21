import Quickshell
import Quickshell.Io
import QtQuick

// Live wallpaper palette, written by ~/.local/bin/wallpalette.
// Use as:  WallPalette { id: pal }   then   pal.accent
// Plain strings (hex), defaults always defined.
Scope {
    id: root

    property string fg: "#E0F7FF"
    property string accent: "#00E5FF"
    property string accent2: "#00D2C8"
    property string warn: "#ee4b30"
    property string highlight: "#fa6ae1"

    function apply(t) {
        try {
            const o = JSON.parse(t);
            if (o.fg) root.fg = String(o.fg);
            if (o.accent) root.accent = String(o.accent);
            if (o.accent2) root.accent2 = String(o.accent2);
            if (o.warn) root.warn = String(o.warn);
            if (o.highlight) root.highlight = String(o.highlight);
            console.log("WallPalette loaded:", root.fg, root.accent, root.warn, root.highlight);
        } catch (e) {
            console.log("WallPalette: could not parse colors.json:", e);
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.cache/wallpalette/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }

    Component.onCompleted: console.log("WallPalette defaults:", fg, accent)
}
