import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

ShellRoot {
    WallPalette { id: pal }

    PanelWindow {
        id: win

        // ---- tune these ----
        property int bars: 48              // must match "bars" in cava-viz.conf
        property int barSpacing: 3
        property int maxHeight: 32
        property int bottomOffset: 34      // sit just above waybar (32px) - raise/lower to taste
        property real barOpacity: 0.4
        property bool onlyWhilePlaying: true
        // --------------------

        property var levels: []
        readonly property bool playing: Mpris.players.values.some(p => p.isPlaying)

        function rgb(h) {
            return [parseInt(h.substr(1, 2), 16) / 255,
                    parseInt(h.substr(3, 2), 16) / 255,
                    parseInt(h.substr(5, 2), 16) / 255];
        }
        function mix(a, b, t) {
            const x = rgb(a), y = rgb(b);
            return Qt.rgba(x[0] + (y[0] - x[0]) * t,
                           x[1] + (y[1] - x[1]) * t,
                           x[2] + (y[2] - x[2]) * t, 1);
        }

        visible: onlyWhilePlaying ? playing : true
        color: "transparent"
        anchors { bottom: true }
        margins { bottom: bottomOffset }
        implicitWidth: Math.round((screen ? screen.width : 1920) / 3)
        implicitHeight: maxHeight
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "visualizer"

        // cava prints one line per frame: "12;45;...;7;"
        Process {
            running: win.visible
            command: ["sh", "-c",
                "src=$(pactl get-default-sink).monitor; " +
                "sed \"s|^source = .*|source = $src|\" $HOME/.config/quickshell/cava-viz.conf > \"$XDG_RUNTIME_DIR/cava-viz-run.conf\"; " +
                "exec cava -p \"$XDG_RUNTIME_DIR/cava-viz-run.conf\""]
            stdout: SplitParser {
                onRead: data => {
                    const v = data.split(";").filter(s => s.length > 0).map(Number);
                    if (v.length > 0) win.levels = v;
                }
            }
        }

        Row {
            anchors.fill: parent
            spacing: win.barSpacing

            Repeater {
                model: win.bars

                Item {
                    width: (win.width - win.barSpacing * (win.bars - 1)) / win.bars
                    height: win.maxHeight

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(3, ((win.levels[index] ?? 0) / 100) * win.maxHeight)
                        radius: 1.5
                        opacity: win.barOpacity
                        color: win.mix(pal.accent, pal.highlight, index / Math.max(1, win.bars - 1))

                        Behavior on height { NumberAnimation { duration: 60 } }
                    }
                }
            }
        }
    }
}
