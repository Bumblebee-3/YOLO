import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

// Touch-friendly power menu. Launch on demand:  quickshell -p ~/.config/quickshell/powermenu.qml
// Tap = instant (lock, suspend).  Press and hold = confirm (logout, hibernate, reboot, shutdown).
ShellRoot {
    WallPalette { id: pal }

    PanelWindow {
        id: win

        // ---- tune these ----
        property int cardW: 150
        property int cardH: 180
        property int gap: 22
        property int holdMs: 700
        property color danger: "#ff2d55"
        // --------------------

        readonly property string user: Quickshell.env("USER")
        property int sel: 0

        // name, glyph (Nerd Font MD), command, needs hold, dangerous colour
        readonly property var actions: [
            { name: "Lock",      glyph: 0xF033E, cmd: ["hyprlock"],                         hold: false, red: false },
            { name: "Suspend",   glyph: 0xF04B2, cmd: ["systemctl", "suspend"],             hold: false, red: false },
            { name: "Logout",    glyph: 0xF0343, cmd: ["hyprctl", "dispatch", "hl.dsp.exit()"], hold: true,  red: true  },
            { name: "Hibernate", glyph: 0xF0717, cmd: ["systemctl", "hibernate"],           hold: true,  red: false },
            { name: "Reboot",    glyph: 0xF0709, cmd: ["systemctl", "reboot"],              hold: true,  red: true  },
            { name: "Shutdown",  glyph: 0xF0425, cmd: ["systemctl", "poweroff"],            hold: true,  red: true  }
        ]

        function run(i) {
            Quickshell.execDetached(actions[i].cmd);
            Qt.quit();
        }

        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "powermenu"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // dim background, fades in; tapping it closes the menu
        Rectangle {
            id: scrim
            anchors.fill: parent
            color: "#D9000000"
            opacity: 0
            Component.onCompleted: opacity = 1
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent; onClicked: Qt.quit() }
        }

        // keyboard: arrows move, Enter runs, Esc closes
        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) Qt.quit();
                else if (event.key === Qt.Key_Right) win.sel = (win.sel + 1) % win.actions.length;
                else if (event.key === Qt.Key_Left) win.sel = (win.sel + win.actions.length - 1) % win.actions.length;
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.run(win.sel);
            }
        }

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: win.width >= (6 * win.cardW + 5 * win.gap + 120) ? 6 : 3
            spacing: win.gap

            Repeater {
                model: win.actions.length

                Item {
                    id: card
                    property var act: win.actions[index]
                    property real fill: 0
                    property real appear: 0
                    readonly property bool active: win.sel === index
                    readonly property color tint: act.red ? win.danger : pal.accent

                    width: win.cardW
                    height: win.cardH
                    opacity: appear
                    transform: Translate { y: (1 - card.appear) * 36 }
                    scale: press.pressed ? 0.94 : (card.active ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                    // staggered entrance
                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: 90 + index * 55 }
                        NumberAnimation { target: card; property: "appear"; to: 1; duration: 320; easing.type: Easing.OutCubic }
                    }

                    NumberAnimation { id: fillUp; target: card; property: "fill"; to: 1
                        duration: win.holdMs; onStopped: if (card.fill >= 0.999) win.run(index) }
                    NumberAnimation { id: fillDown; target: card; property: "fill"; to: 0; duration: 180 }

                    Rectangle {
                        id: body
                        anchors.fill: parent
                        radius: 22
                        clip: true
                        color: Qt.alpha(pal.fg, card.active ? 0.12 : 0.06)
                        border.width: card.active ? 2 : 1
                        border.color: card.active ? card.tint : Qt.alpha(pal.fg, 0.14)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // hold-to-confirm fill rising from the bottom,
                        // masked to the card's rounded shape so it never pokes out of the corners
                        Item {
                            id: fillSrc
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.height * card.fill
                                color: Qt.alpha(card.tint, 0.38)
                            }
                        }
                        Item {
                            id: fillMask
                            anchors.fill: parent
                            visible: false
                            layer.enabled: true
                            Rectangle {
                                anchors.fill: parent
                                radius: body.radius
                                color: "black"
                            }
                        }
                        MultiEffect {
                            anchors.fill: parent
                            visible: card.fill > 0
                            source: fillSrc
                            maskEnabled: true
                            maskSource: fillMask
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * 0.24
                            text: String.fromCodePoint(card.act.glyph)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 54
                            color: card.active || card.fill > 0 ? card.tint : pal.fg
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * 0.66
                            text: card.act.name.toUpperCase()
                            font.family: "Orbitron"; font.pixelSize: 13; font.bold: true
                            font.letterSpacing: 1.5
                            color: pal.fg
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * 0.82
                            visible: card.act.hold
                            text: card.fill > 0 ? "KEEP HOLDING" : "HOLD"
                            font.family: "Orbitron"; font.pixelSize: 9; font.bold: true
                            color: Qt.alpha(pal.fg, 0.5)
                        }
                    }

                    MouseArea {
                        id: press
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.sel = index
                        onPressed: {
                            win.sel = index;
                            if (!card.act.hold) { win.run(index); return; }
                            fillDown.stop();
                            fillUp.from = card.fill;
                            fillUp.duration = win.holdMs * (1 - card.fill);
                            fillUp.start();
                        }
                        onReleased: cancelHold()
                        onCanceled: cancelHold()
                        function cancelHold() {
                            if (!card.act.hold) return;
                            fillUp.stop();
                            if (card.fill < 0.999) { fillDown.from = card.fill; fillDown.start(); }
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            text: "TAP TO LOCK OR SUSPEND  ·  HOLD TO CONFIRM  ·  ESC TO CLOSE"
            font.family: "Orbitron"; font.pixelSize: 10; font.bold: true
            font.letterSpacing: 1.2
            color: Qt.alpha(pal.fg, 0.45)
        }
    }
}
