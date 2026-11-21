import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

ShellRoot {
    WallPalette { id: pal }

    PanelWindow {
        id: panel

        // ---- tune these ----
        property int topOffset: 600          // distance from screen top to the SYSTEM CORE heading
        property bool showBackground: false // true = same translucent rounded card as NOW PLAYING
        property int pad: 18
        // --------------------

        property real cpu: 0
        property real mem: 0
        property real disk: 0
        property string net: "0.0"

        Process {
            running: panel.visible
            command: [Quickshell.env("HOME") + "/.config/quickshell/sysstat.sh"]
            stdout: SplitParser {
                onRead: data => {
                    const p = data.trim().split(" ");
                    if (p.length < 4) return;
                    panel.cpu = parseFloat(p[0]);
                    panel.mem = parseFloat(p[1]);
                    panel.disk = parseFloat(p[2]);
                    panel.net = p[3];
                }
            }
        }

        readonly property bool musicPlaying: Mpris.players.values.some(p => p.isPlaying)
        visible: !musicPlaying
        color: "transparent"
        anchors { top: true }
        margins { top: topOffset }
        implicitWidth: 800
        implicitHeight: 27 + 8 + 4 * 23 + 4
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "systemcore"

        // one "LABEL  value  [bar]" line, columns match the old conky goto 245 / 320 / 415
        component StatRow: Item {
            id: row
            property string label
            property string value
            property real fill: 0
            property bool showBar: true
            property color labelColor: "#E0F7FF"
            property color valueColor: "#00E5FF"
            property color barColor: "#00E5FF"
            width: 800
            height: 23

            Text {
                x: 245
                anchors.verticalCenter: parent.verticalCenter
                text: row.label
                color: row.labelColor
                font.family: "Iceland"; font.pixelSize: 24; font.bold: true
            }
            Text {
                x: 320
                anchors.verticalCenter: parent.verticalCenter
                text: row.value
                color: row.valueColor
                font.family: "Iceland"; font.pixelSize: 24; font.bold: true
            }
            Rectangle {
                visible: row.showBar
                x: 415
                width: 140; height: 6
                anchors.verticalCenter: parent.verticalCenter
                color: "transparent"
                border.width: 1
                border.color: row.barColor
                Rectangle {
                    width: parent.width * Math.min(1, row.fill / 100)
                    height: parent.height
                    color: row.barColor
                }
            }
        }

        Rectangle {
            visible: panel.showBackground
            x: 245 - panel.pad
            y: -panel.pad / 2
            width: 310 + 2 * panel.pad
            height: parent.height + panel.pad
            radius: 8
            color: "#66000000"
        }

        Text {
            id: heading
            anchors.horizontalCenter: parent.horizontalCenter
            text: "SYSTEM CORE"
            color: pal.fg
            font.pixelSize: 32; font.bold: true
	    font.letterSpacing: 3
	    font.family: "Iceland"
            //style : Text.Outline
            //styleColor: pal.warn
        }

        Column {
            y: heading.height + 8
            StatRow { label: "CPU";  value: Math.round(panel.cpu) + "%";  fill: panel.cpu
                      labelColor: pal.fg; valueColor: pal.accent; barColor: pal.accent }
            StatRow { label: "RAM";  value: Math.round(panel.mem) + "%";  fill: panel.mem
                      labelColor: pal.fg; valueColor: pal.accent; barColor: pal.accent }
            StatRow { label: "DISK"; value: Math.round(panel.disk) + "%"; fill: panel.disk
                      labelColor: pal.fg; valueColor: pal.accent; barColor: pal.accent }
            StatRow { label: "NET";  value: ""+panel.net + " KB/s"; showBar: false
                      labelColor: pal.fg; valueColor: pal.warn }
        }
    }
}
