import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    WallPalette { id: pal }

    PanelWindow {
        id: win

        // ---- tune these ----
        property int topOffset: 150                 // same as the old conky gap_y
        property string weekdayFont: "Anurati"      // check: fc-list : family | grep -i anurati
        // --------------------

        SystemClock { id: clock; precision: SystemClock.Minutes }

        color: "transparent"
        anchors { top: true }
        margins { top: topOffset }
        implicitWidth: 800
        implicitHeight: col.implicitHeight
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "clock"

        Column {
            id: col
            width: parent.width
            spacing: 4

            // WEDNESDAY, letter-spaced like the old conky line
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd").toUpperCase().split("").join(" ")
                color: pal.fg
                font.family: win.weekdayFont
		font.pixelSize: 87
		//font.bold: true
		font.kerning: false
		font.letterSpacing: 0
		style: Text.Outline
		styleColor: pal.warn
            }

            // 04 Nov 2026
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dd MMM yyyy")
                color: pal.warn
                font.family: "Iceland"
		font.pixelSize: 46
                font.bold: true
		style : Text.Outline
		styleColor: "#BFFFFFFF"
	    }
            // -  05:44 PM  -
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "-  " + Qt.formatDateTime(clock.date, "hh:mm AP") + "  -"
                color: pal.fg
                font.family: "Iceland"
		font.pixelSize: 40
                font.bold: true
		style : Text.Outline
		styleColor: pal.warn
            }
        }
    }
}
