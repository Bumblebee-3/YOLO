import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

ShellRoot {
    WallPalette { id: pal }

    PanelWindow {
        id: card

        // ---- tune these ----
        property int topOffset: 665     // distance from screen top to the NOW PLAYING heading
        property int leftInset: 275     // same x as the SYSTEM CORE columns in conky
        property int coverSize: 64
        property int pad: 12
        property int textWidth: 160     // width of the text column (progress bar spans it too)
        // --------------------

        // prefer the player that is currently playing, else the first one
        readonly property var player: {
            const ps = Mpris.players.values;
            return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
        }

        function fmt(s) {
            if (!s || s < 0) return "0:00";
            const m = Math.floor(s / 60);
            const r = Math.floor(s % 60);
            return m + ":" + (r < 10 ? "0" : "") + r;
        }

        readonly property real pos: player ? player.position : 0
        readonly property real len: player ? player.length : 0
        readonly property real ratio: len > 0 ? Math.min(1, pos / len) : 0

        // MPRIS position doesn't tick by itself, so ask for it once a second while playing
        Timer {
            interval: 1000
            repeat: true
            running: card.player !== null && card.player.isPlaying
            onTriggered: card.player.positionChanged()
        }

        visible: player !== null && player.isPlaying
        color: "transparent"
        anchors { top: true }
        margins { top: topOffset }
        implicitWidth: 800
        implicitHeight: pad + coverSize + pad
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "nowplaying"

        //Text {
        //    id: heading
        //    anchors.horizontalCenter: parent.horizontalCenter
        //    text: "NOW PLAYING"
        //    color: pal.fg
        //    font.family: "Orbitron"
        //    font.pixelSize: 12
        //    font.bold: true
        //}

        Rectangle {
            x: content.x - card.pad
            y: content.y - card.pad
            width: content.width + 2 * card.pad
            height: content.height + 2 * card.pad
            radius: 8
            color: "#66000000"
        }

        Rectangle {
            x: content.x - card.pad
            y: content.y - card.pad
            width: content.width + 2 * card.pad
            height: content.height + 2 * card.pad
            radius: 8
            color: "#66000000"
        }

        Row {
            x: card.leftInset
            id: content
            y: card.pad
            spacing: 14

            Item {
                width: card.coverSize; height: card.coverSize

                Image {
                    id: art
                    anchors.fill: parent
                    visible: false
                    source: card.player ? card.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: card.coverSize * 2
                    sourceSize.height: card.coverSize * 2
                    asynchronous: true
                    cache: false
                }

                Item {
                    id: artMask
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: "black"
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: art
                    maskEnabled: true
                    maskSource: artMask
                }
            }

            Column {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: card.textWidth
                    elide: Text.ElideRight
                    text: card.player ? card.player.trackTitle : ""
                    color: pal.fg
                    font.family: "Iceland"; font.pixelSize: 16; font.bold: true
                }
                Text {
                    width: card.textWidth
                    elide: Text.ElideRight
                    text: card.player ? card.player.trackArtist : ""
                    color: pal.accent
                    font.family: "Iceland"; font.pixelSize: 14; font.bold: true
                }

                // progress row: 1:37 ━━━━━━━──── 2:46
                Row {
                    width: card.textWidth
                    height: 14
                    spacing: 8

                    Text {
                        width: 30
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: card.fmt(card.pos)
                        color: pal.fg
                        font.family: "Iceland"; font.pixelSize: 12; font.bold: true
                    }

                    Rectangle {
                        width: card.textWidth - 2 * 30 - 2 * 8
                        height: 4
                        radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.alpha(pal.fg, 0.2)

                        Rectangle {
                            width: parent.width * card.ratio
                            height: parent.height
                            radius: 2
                            color: pal.accent
                        }
                    }

                    Text {
                        width: 30
                        height: parent.height
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        text: card.fmt(card.len)
                        color: pal.fg
                        font.family: "Orbitron"; font.pixelSize: 9; font.bold: true
                    }
                }
            }
        }
    }
}
