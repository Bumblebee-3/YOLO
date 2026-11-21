
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import SddmComponents 2.0 as SDDM

Item {
    id: formContainer

    SDDM.TextConstants {
        id: textConstants
    }

    // Keep the clock exactly where it is.
    Clock {
        id: clock
        width: parent.width
        height: root.height * 0.22
        anchors.top: parent.top
        anchors.topMargin: root.height * 0.09
    }

    // ---- Tahoe login positioning ----
    property real loginPosition: 0.75
    property int avatarSize: 50
    property int avatarGap: 12

    Item {
        id: loginArea

        width: Math.min(root.width * 0.8, 650)
        height: avatarSize + avatarGap + input.height

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.height * loginPosition

        // Circular profile picture
        Item {
            id: avatar
            width: avatarSize
            height: avatarSize

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            Image {
                id: avatarImage
                anchors.fill: parent
                source: Qt.resolvedUrl("../Assets/tahoe-avatar.png")
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: avatarSize
                sourceSize.height: avatarSize
                visible: false
            }

	    Rectangle {
    		id: avatarMask
    		anchors.fill: parent
    		radius: width / 2
    	 	color: "white"
    	 	visible: false
   	 	layer.enabled: true
	    }
            MultiEffect {
    		anchors.fill: parent
    		source: avatarImage
    		maskEnabled: true
  		maskSource: avatarMask
    		maskThresholdMin: 0.5
   		maskSpreadAtMin: 1.0
	    }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: "#66FFFFFF"
                border.width: 2
            }
        }

        Input {
            id: input

            width: parent.width
            height: root.height * 0.34

            anchors.top: avatar.bottom
            anchors.topMargin: avatarGap
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Compatibility aliases
    property var sessionSelect: tahoeStatus.exposeSession
    property var systemButtons: null
    property var virtualKeyboardButton: null
}
