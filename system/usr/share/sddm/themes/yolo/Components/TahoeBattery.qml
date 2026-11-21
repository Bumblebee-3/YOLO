import QtQuick 2.15
import TahoeBattery 1.0

Item {
    id: battery

    width: 119
    height: 29

    BatteryInfo {
        id: info
    }

    readonly property real percentage:
        Math.max(0, Math.min(100, info.capacity))

    readonly property bool plugged:
        info.plugged ||
        info.status === "Charging" ||
        info.status === "Full" ||
        info.status === "Not charging"

    readonly property bool charging: plugged

    Canvas {
        id: batteryCanvas
        anchors.fill: parent

        // Redraw whenever the battery state changes.
        Connections {
            target: battery

            function onPercentageChanged() {
                batteryCanvas.requestPaint()
            }

            function onChargingChanged() {
                batteryCanvas.requestPaint()
            }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // Match the 170x42 coordinate system used in Python.
            ctx.save()
            ctx.translate(0, 5)
ctx.scale(0.52, 0.52)

            function roundedRect(x, y, w, h, r, fill, stroke, lineWidth) {
                ctx.beginPath()
                ctx.moveTo(x + r, y)
                ctx.lineTo(x + w - r, y)
                ctx.quadraticCurveTo(x + w, y, x + w, y + r)
                ctx.lineTo(x + w, y + h - r)
                ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h)
                ctx.lineTo(x + r, y + h)
                ctx.quadraticCurveTo(x, y + h, x, y + h - r)
                ctx.lineTo(x, y + r)
                ctx.quadraticCurveTo(x, y, x + r, y)
                ctx.closePath()

                if (fill) {
                    ctx.fillStyle = fill
                    ctx.fill()
                }

                if (stroke) {
                    ctx.strokeStyle = stroke
                    ctx.lineWidth = lineWidth
                    ctx.stroke()
                }
            }

            var white = "rgba(255,255,255,0.92)"

            // Battery outline
            roundedRect(2, 6, 43, 25, 6, null, white, 2)

            // Battery terminal
            roundedRect(
                47, 13, 4, 11, 2,
                "rgba(255,255,255,0.55)",
                null, 0
            )

            // Battery fill
            var levelWidth = 35 * battery.percentage / 100

            if (levelWidth > 0) {
                var fillColor =
                    battery.percentage <= 20 && !battery.charging
                    ? "rgba(255,95,95,0.96)"
                    : white

                roundedRect(
                    6, 10,
                    levelWidth, 17,
                    Math.min(3, levelWidth / 2),
                    fillColor, null, 0
                )
            }

            // Your custom lightning bolt
            if (battery.charging) {
                var points = [
                    [30, 4],
                    [21, 19],
                    [26, 19],
                    [23, 30],
                    [34, 15],
                    [28, 15]
                ]

                ctx.beginPath()
                ctx.moveTo(points[0][0], points[0][1])

                for (var i = 1; i < points.length; i++)
                    ctx.lineTo(points[i][0], points[i][1])

                ctx.closePath()

                ctx.strokeStyle = "rgba(25,25,25,1)"
                ctx.lineWidth = 2
                ctx.lineJoin = "round"
                ctx.stroke()

                ctx.fillStyle = "white"
                ctx.fill()
            }


            ctx.restore()
        }
    }

	Text {
    anchors.left: parent.left
    anchors.leftMargin: 31
    anchors.verticalCenter: parent.verticalCenter

    text: info.capacity < 0
        ? "--%"
        : Math.round(battery.percentage) + "%"

    font.family: "SF Pro Display"
    font.pixelSize: 13
    font.weight: Font.Medium

    color: "white"
}
}
