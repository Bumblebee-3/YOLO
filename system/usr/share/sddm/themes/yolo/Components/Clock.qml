import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: clock

    width: parent.width
    height: parent.height

    Text {
        id: dateLabel

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        font.family: "Inter Black"
        font.pixelSize: root.height * 0.028
        font.weight: Font.Black

        color: "#D9F2FF"
        style: Text.Outline
        styleColor: "#55FFFFFF"

        function updateTime() {
            text = Qt.formatDate(new Date(), "ddd MMM d")
        }
    }

    Text {
        id: timeLabel

        anchors.top: dateLabel.bottom
        anchors.topMargin: -root.height * 0.008
        anchors.horizontalCenter: parent.horizontalCenter

        font.family: "Inter Black"
        font.pixelSize: root.height * 0.145
        font.weight: Font.Black

        color: "#BCE8FF"
        style: Text.Outline
        styleColor: "#AAFFFFFF"

        function updateTime() {
            text = Qt.formatTime(new Date(), "HH:mm")
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            dateLabel.updateTime()
            timeLabel.updateTime()
        }
    }

    Component.onCompleted: {
        dateLabel.updateTime()
        timeLabel.updateTime()
    }
}
