import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: root
    // env: GEOM="x,y wxh" (slurp), ELAPSED=seconds so far, PAUSED=0|1
    property var m: /(-?\d+),(-?\d+) (\d+)x(\d+)/.exec(Quickshell.env("GEOM"))
    property real rx: parseInt(m[1])
    property real ry: parseInt(m[2])
    property real rw: parseInt(m[3])
    property real rh: parseInt(m[4])

    property int base: parseInt(Quickshell.env("ELAPSED") || "0")
    property bool paused: Quickshell.env("PAUSED") === "1"
    property double t0: Date.now()
    property double tick: t0
    property int elapsed: paused ? base : base + Math.floor((tick - t0) / 1000)
    property bool blinkOn: true

    // tweak these
    property color dimColor: Qt.rgba(0.08, 0.08, 0.08, 0.65)
    property color lineColor: "#ff2626"
    property real lineW: 1.5
    property real radius: 8
    property real gap: 3
    property real pillH: 26

    // pill goes above the border, else below it, else inside (which ends up in the video)
    property bool roomAbove: ry >= pillH + gap + 8
    property bool roomBelow: ry + rh + gap + 8 + pillH <= height

    function fmt(s) {
        var h = Math.floor(s / 3600), mi = Math.floor((s % 3600) / 60), se = s % 60;
        var p = function(n) { return (n < 10 ? "0" : "") + n; };
        return (h > 0 ? h + ":" : "") + p(mi) + ":" + p(se);
    }

    Timer { interval: 250; repeat: true; running: !root.paused; onTriggered: root.tick = Date.now() }
    Timer { interval: 600; repeat: true; running: true; onTriggered: root.blinkOn = !root.blinkOn }

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    // dim everything except the region
    Rectangle { color: root.dimColor; x: 0; y: 0; width: root.width; height: Math.max(0, root.ry) }
    Rectangle { color: root.dimColor; x: 0; y: root.ry + root.rh; width: root.width; height: Math.max(0, root.height - (root.ry + root.rh)) }
    Rectangle { color: root.dimColor; x: 0; y: root.ry; width: Math.max(0, root.rx); height: root.rh }
    Rectangle { color: root.dimColor; x: root.rx + root.rw; y: root.ry; width: Math.max(0, root.width - (root.rx + root.rw)); height: root.rh }

    // dashed rounded border
    Canvas {
        property real pad: 8
        x: root.rx - pad
        y: root.ry - pad
        width: root.rw + 2 * pad
        height: root.rh + 2 * pad

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.lineColor;
            ctx.lineWidth = root.lineW;
            ctx.setLineDash([7, 5]);

            var g = root.gap, r = root.radius;
            var x0 = pad - g, y0 = pad - g;
            var x1 = pad + root.rw + g, y1 = pad + root.rh + g;

            ctx.beginPath();
            ctx.moveTo(x0 + r, y0);
            ctx.lineTo(x1 - r, y0); ctx.arcTo(x1, y0, x1, y0 + r, r);
            ctx.lineTo(x1, y1 - r); ctx.arcTo(x1, y1, x1 - r, y1, r);
            ctx.lineTo(x0 + r, y1); ctx.arcTo(x0, y1, x0, y1 - r, r);
            ctx.lineTo(x0, y0 + r); ctx.arcTo(x0, y0, x0 + r, y0, r);
            ctx.closePath();
            ctx.stroke();
        }
    }

    // REC 00:42 pill
    Rectangle {
        x: (root.roomAbove || root.roomBelow) ? root.rx : root.rx + 10
        y: root.roomAbove ? root.ry - root.gap - root.pillH - 6
           : root.roomBelow ? root.ry + root.rh + root.gap + 6
           : root.ry + 10
        height: root.pillH
        width: pillRow.implicitWidth + 24
        radius: height / 2
        color: "#d9141414"

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 8; height: 8; radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: root.paused ? "#ffcc00" : "#ff2626"
                opacity: root.paused ? 1 : (root.blinkOn ? 1 : 0.25)
            }
            Text {
                text: (root.paused ? "PAUSED " : "REC ") + root.fmt(root.elapsed)
                color: "white"
                font.family: "monospace"
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
