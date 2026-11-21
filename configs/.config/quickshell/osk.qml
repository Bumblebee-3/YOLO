import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Touch on-screen keyboard.  Toggle:  qs -p ~/.config/quickshell/osk.qml ipc call osk toggle
// Keys are typed through `wtype` (virtual keyboard), so the keyboard never steals focus from the app.
ShellRoot {
    WallPalette { id: pal }

    IpcHandler {
        target: "osk"
        function toggle(): void { win.shown = !win.shown }
        function show(): void { win.shown = true }
        function hide(): void { win.shown = false }
        function isShown(): bool { return win.shown }
    }

    PanelWindow {
        id: win

        // ---- tune these ----
        property real heightFraction: 0.35     // of the screen height
        property int gap: 4
        property int margin: 8
        property bool debug: false       // log every key press to the terminal; set false once it works
        property bool ydotoolForCombos: true   // Ctrl/Alt/Super combos go through ydotool so compositor keybinds fire
        // --------------------

        property bool shown: false
        property real slide: shown ? 1 : 0
        Behavior on slide { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        // sticky modifier state
        property bool shiftOnce: false
        property bool caps: false
        property bool ctrl: false
        property bool alt: false
        property bool sup: false
        property bool fn: false
        property bool showFunctions: false
        // Main keyboard stays the same size when the optional function strip opens.
        property int arrowExtra: 16
        property int functionH: 36
        property int repeatDelay: 400
        property int repeatInterval: 65

        readonly property int baseH: Math.round((screen ? screen.height : 800) * heightFraction)
        readonly property int panelH: baseH + (showFunctions ? functionH + gap : 0)
        readonly property real keyH: (baseH - 2 * margin - 4 * gap - arrowExtra) / 5
        readonly property string userHome: Quickshell.env("HOME")

        visible: slide > 0.001
        color: "transparent"
        anchors { left: true; right: true; bottom: true }
        implicitHeight: panelH
        // reserving the space is what makes tiled windows shrink on open and grow back on close
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: shown ? panelH : 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "osk"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // evdev key codes (US layout) for ydotool, and its modifier codes
        readonly property var evdev: ({
            a: 30, b: 48, c: 46, d: 32, e: 18, f: 33, g: 34, h: 35, i: 23, j: 36, k: 37, l: 38, m: 50,
            n: 49, o: 24, p: 25, q: 16, r: 19, s: 31, t: 20, u: 22, v: 47, w: 17, x: 45, y: 21, z: 44,
            "1": 2, "2": 3, "3": 4, "4": 5, "5": 6, "6": 7, "7": 8, "8": 9, "9": 10, "0": 11,
            grave: 41, minus: 12, equal: 13, bracketleft: 26, bracketright: 27, backslash: 43,
            semicolon: 39, apostrophe: 40, comma: 51, period: 52, slash: 53,
            Escape: 1, Tab: 15, BackSpace: 14, Return: 28, space: 57, Left: 105, Right: 106, Up: 103,
            Down: 108, Home: 102, End: 107, Prior: 104, Next: 109, Delete: 111, F1: 59, F2: 60, F3: 61, F4: 62, F5: 63, F6: 64, F7: 65, F8: 66,
            F9: 67, F10: 68, F11: 87, F12: 88
        })
        readonly property var modCode: ({ ctrl: 29, shift: 42, alt: 56, logo: 125 })

        // ------------------------------------------------------------ keyboard data
        function ch(l, s, sym, w) { return { t: "char", l: l, s: s, sym: sym || l, w: w || 1, rep: true }; }
        function ky(l, sym, w, t, rep) { return { t: t || "key", l: l, sym: sym, w: w, rep: !!rep }; }

        function actionKey(l, command, rep) {
            return { t: "action", l: l, w: 1, cmd: command, rep: !!rep };
        }
        function functionKey(n, caption, command, useFn, rep) {
            return useFn ? ky("F" + n, "F" + n, 1)
                         : actionKey("F" + n + "\n" + caption, command, rep);
        }

        function buildRows(useFn) {
            // Fn exposes ordinary F1–F12; the number row always stays available.
            var functions = [
                ky("Esc", "Escape", 1),
                functionKey(1, "Mute", ["swayosd-client", "--output-volume", "mute-toggle"], useFn),
                functionKey(2, "Vol −", ["swayosd-client", "--output-volume", "lower"], useFn, true),
                functionKey(3, "Vol +", ["swayosd-client", "--output-volume", "raise"], useFn, true),
                functionKey(4, "Kbd ☀", [userHome + "/.config/hypr/scripts/kbd_backlight.sh"], useFn),
                functionKey(5, "☀ −", ["swayosd-client", "--brightness", "lower"], useFn, true),
                functionKey(6, "☀ +", ["swayosd-client", "--brightness", "raise"], useFn, true),
                ky("F7", "F7", 1),
                functionKey(8, "Emoji", ["rofimoji", "--action", "type", "--hidden-descriptions",
                    "--selector-args=-theme " + userHome + "/.config/rofi/rofi-emoji.rasi"], useFn),
                functionKey(9, "Mic ⊘", ["pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle"], useFn),
                ky("F10", "F10", 1),
                ky("F11", "F11", 1),
                functionKey(12, "Circle", [userHome + "/.local/bin/circle"], useFn),
                actionKey("Prt Scr", ["sh", "-c", 'grim -g "$(slurp)" - | wl-copy']),
                actionKey("Power", ["quickshell", "--no-duplicate", "-p", userHome + "/.config/quickshell/powermenu.qml"]),
                ky("Del", "Delete", 1, "key", true)
            ];
            var top = [ch("`", "~", "grave"), ch("1", "!"), ch("2", "@"), ch("3", "#"), ch("4", "$"), ch("5", "%"),
                       ch("6", "^"), ch("7", "&"), ch("8", "*"), ch("9", "("), ch("0", ")"), ch("-", "_", "minus"),
                       ch("=", "+", "equal"), ky("\u232B", "BackSpace", 2, "key", true)];
            var up = function (str) { return str.split("").map(function (c) { return ch(c, c.toUpperCase()); }); };
            var r2 = [ky("\u21E5", "Tab", 1.5)].concat(up("qwertyuiop"),
                     [ch("[", "{", "bracketleft"), ch("]", "}", "bracketright"), ch("\\", "|", "backslash", 1.5)]);
            var r3 = [ky("\u21EA", "", 1.75, "caps")].concat(up("asdfghjkl"),
                     [ch(";", ":", "semicolon"), ch("'", "\"", "apostrophe"), ky("\u21B5", "Return", 2.25)]);
            var r4 = [ky("\u21E7", "", 2.25, "shift")].concat(up("zxcvbnm"),
                     [ch(",", "<", "comma"), ch(".", ">", "period"), ch("/", "?", "slash"), ky("\u21E7", "", 2.75, "shift")]);
            // Same Ctrl / Fn / Super / Alt / Space / Alt order as the Zenbook.
            // Hide replaces the Copilot key. Arrows keep the inverted-T arrangement.
            var r5 = [ky("Ctrl", "", 1.25, "ctrl"), ky("Fn", "", 1, "fn"),
                      ky("❖", "", 1, "sup"), ky("Alt", "", 1, "alt"),
                      ky("space", "space", 5.25, "key", true), ky("Alt", "", 1, "alt"),
                      ky("Hide", "", 1, "hide"), ky("", "", 3.5, "arrows")];
            return [functions, top, r2, r3, r4, r5];
        }
        readonly property var rows: buildRows(fn)

        function isLetter(k) { return k.t === "char" && /^[a-z]$/.test(k.l); }
        function label(k) {
            if (k.t !== "char") return k.l;
            var upper = isLetter(k) ? (shiftOnce !== caps) : shiftOnce;
            return upper ? k.s : k.l;
        }
        function active(k) {
            return (k.t === "shift" && shiftOnce) || (k.t === "caps" && caps) || (k.t === "ctrl" && ctrl)
                || (k.t === "alt" && alt) || (k.t === "sup" && sup) || (k.t === "fn" && showFunctions);
        }

        // ------------------------------------------------------------ typing
        function press(k, prepareOnly) {
            if (debug) console.log("osk press:", k.t, JSON.stringify(k.l));
            switch (k.t) {
            case "shift": shiftOnce = !shiftOnce; return;
            case "caps":  caps = !caps; return;
            case "ctrl":  ctrl = !ctrl; return;
            case "alt":   alt = !alt; return;
            case "sup":   sup = !sup; return;
            case "fn":    showFunctions = !showFunctions; return;
            case "hide":  shown = false; return;
            }
            if (k.t === "action") {
                if (debug) console.log("osk run:", JSON.stringify(k.cmd));
                if (!prepareOnly) Quickshell.execDetached(k.cmd);
                shiftOnce = false; ctrl = false; alt = false; sup = false;
                return k.cmd;
            }
            var mods = [];
            if (ctrl) mods.push("ctrl");
            if (alt) mods.push("alt");
            if (sup) mods.push("logo");
            var args = ["wtype"];
            if (k.t === "char" && mods.length === 0) {
                var upper = isLetter(k) ? (shiftOnce !== caps) : shiftOnce;
                args.push("--", upper ? k.s : k.l);
            } else {
                var combo = ctrl || alt || sup;
                if (isLetter(k) ? (shiftOnce !== caps) : shiftOnce) mods.push("shift");
                var code = evdev[k.sym];
                if (combo && ydotoolForCombos && code !== undefined) {
                    // real (kernel-level) key events: compositor keybinds see an actual keyboard
                    var seq = [];
                    mods.forEach(function (m) { seq.push(modCode[m] + ":1"); });
                    seq.push(code + ":1", code + ":0");
                    mods.slice().reverse().forEach(function (m) { seq.push(modCode[m] + ":0"); });
                    args = ["ydotool", "key"].concat(seq);
                } else {
                    mods.forEach(function (m) { args.push("-M", m); });
                    args.push("-k", k.sym);
                    mods.slice().reverse().forEach(function (m) { args.push("-m", m); });
                }
            }
            if (debug) console.log("osk run:", JSON.stringify(args));
            if (!prepareOnly) Quickshell.execDetached(args);
            shiftOnce = false; ctrl = false; alt = false; sup = false;      // one-shot modifiers
            return args;
        }

        // Reusable cap: full pitch is touchable, including the small visual gutters.
        component KeyCap: Item {
            id: cap
            required property var k
            property bool compact: false
            readonly property bool isOn: win.active(k)
            readonly property bool pressed: touch.active
            property var repeatCommand: null
            property bool repeatingCommand: false
            property bool cancelRepeat: false

            function sendCommand(isRepeat) {
                // No queue: a slow injector must finish before another event starts.
                if (!repeatCommand || keyProcess.running) return;
                repeatingCommand = isRepeat;
                cancelRepeat = false;
                keyProcess.command = repeatCommand;
                keyProcess.running = true;
            }
            function stopRepeat() {
                repeatTimer.stop();
                fnHold.stop();
                cancelRepeat = true;
                // Let the initial tap finish so a quick tap is never cancelled.
                // Never interrupt ydotool midway through a modifier release sequence.
                if (repeatingCommand && keyProcess.command[0] === "wtype")
                    keyProcess.signal(9);
                repeatCommand = null;
            }
            Process {
                id: keyProcess
                // Also catches release while the child process was still starting.
                onStarted: {
                    if (cap.repeatingCommand && cap.cancelRepeat && command[0] === "wtype")
                        signal(9);
                }
            }
            Connections {
                target: win
                function onShownChanged() { if (!win.shown) cap.stopRepeat(); }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: win.gap / 2
                radius: cap.compact ? 6 : 9
                color: cap.pressed ? Qt.alpha(pal.accent, 0.75)
                     : cap.isOn ? Qt.alpha(pal.accent, 0.55)
                     : cap.k.sym === "Return" ? Qt.alpha(pal.accent, 0.24)
                     : Qt.alpha(pal.fg, 0.11)
                border.width: 1
                border.color: cap.isOn || cap.pressed ? pal.accent : Qt.alpha(pal.fg, 0.18)
            }
            Text {
                visible: cap.k.t === "char" && !win.isLetter(cap.k)
                anchors { top: parent.top; left: parent.left; topMargin: 5; leftMargin: 9 }
                text: cap.k.t === "char" ? (win.shiftOnce ? cap.k.l : cap.k.s) : ""
                color: Qt.alpha(pal.fg, 0.65)
                font.pixelSize: Math.max(11, win.keyH * 0.24)
            }
            Text {
                anchors.centerIn: parent
                width: parent.width - 12
                height: parent.height - 8
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                fontSizeMode: Text.Fit
                minimumPixelSize: 9
                text: cap.k.t === "fn" ? (win.fn ? "Fn · F" : "Fn") : win.label(cap.k)
                color: cap.pressed ? "#10141a" : pal.fg
                font.family: "JetBrainsMono Nerd Font"
                font.bold: true
                font.pixelSize: cap.compact ? 12 : (cap.k.l.length > 2 ? 15 : 23)
            }
            // Familiar home-row marks, without a pop-up covering the next row.
            Rectangle {
                visible: cap.k.l === "f" || cap.k.l === "j"
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 7 }
                width: 12; height: 2; radius: 1
                color: Qt.alpha(pal.fg, 0.4)
            }
            PointHandler {
                id: touch
                onActiveChanged: {
                    if (active) {
                        // Capture the actual command before one-shot modifiers reset.
                        // Holding Shift+A therefore repeats A, not A followed by aaaa.
                        cap.repeatCommand = win.press(cap.k, true);
                        if (cap.k.rep) cap.sendCommand(false);
                        else if (cap.repeatCommand) Quickshell.execDetached(cap.repeatCommand);
                        if (cap.k.rep && cap.repeatCommand) {
                            repeatTimer.interval = win.repeatDelay;
                            repeatTimer.restart();
                        }
                        if (cap.k.t === "fn") fnHold.restart();
                    } else {
                        cap.stopRepeat();
                    }
                }
            }
            // Hold Fn to switch media actions / F1-F12 while keeping the strip open.
            Timer {
                id: fnHold
                interval: 600
                onTriggered: { win.fn = !win.fn; win.showFunctions = true; }
            }
            Timer {
                id: repeatTimer
                repeat: true
                onTriggered: {
                    if (!win.shown || !touch.active || !cap.repeatCommand) { stop(); return; }
                    interval = win.repeatInterval;
                    cap.sendCommand(true);
                }
            }
        }

        Item {
            id: panel
            width: parent.width
            height: win.panelH
            y: (1 - win.slide) * win.panelH
            Rectangle {
                width: parent.width; height: parent.height + 20
                radius: 16
                color: Qt.rgba(0.03, 0.035, 0.05, 0.97)
                border.width: 1
                border.color: Qt.alpha(pal.accent, 0.4)
            }
            Column {
                x: win.margin - win.gap / 2
                y: win.margin - win.gap / 2
                width: parent.width - 2 * win.margin + win.gap
                Repeater {
                    model: win.rows
                    delegate: Item {
                        id: rowItem
                        required property var modelData
                        required property int index
                        readonly property var keys: modelData
                        readonly property bool compact: index === 0
                        readonly property bool bottomRow: index === win.rows.length - 1
                        width: parent.width
                        visible: !compact || win.showFunctions
                        height: compact ? (win.showFunctions ? win.functionH + win.gap : 0)
                                        : win.keyH + win.gap + (bottomRow ? win.arrowExtra : 0)
                        Row {
                            Repeater {
                                model: rowItem.keys
                                delegate: Item {
                                    id: cell
                                    required property var modelData
                                    readonly property var k: modelData
                                    width: rowItem.compact ? rowItem.width / rowItem.keys.length
                                                          : rowItem.width * k.w / 15
                                    height: rowItem.height
                                    KeyCap {
                                        anchors.fill: parent
                                        visible: cell.k.t !== "arrows"
                                        k: cell.k
                                        compact: rowItem.compact
                                    }
                                    Item {
                                        anchors.fill: parent
                                        visible: cell.k.t === "arrows"
                                        KeyCap {
                                            x: 0; y: parent.height / 2
                                            width: parent.width / 3; height: parent.height / 2
                                            k: win.ky("←", "Left", 1, "key", true)
                                        }
                                        KeyCap {
                                            x: parent.width / 3; y: 0
                                            width: parent.width / 3; height: parent.height / 2
                                            k: win.ky("↑", "Up", 1, "key", true)
                                        }
                                        KeyCap {
                                            x: parent.width / 3; y: parent.height / 2
                                            width: parent.width / 3; height: parent.height / 2
                                            k: win.ky("↓", "Down", 1, "key", true)
                                        }
                                        KeyCap {
                                            x: parent.width * 2 / 3; y: parent.height / 2
                                            width: parent.width / 3; height: parent.height / 2
                                            k: win.ky("→", "Right", 1, "key", true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
