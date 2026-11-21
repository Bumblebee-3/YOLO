
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
    property int avatarSize: 50
    property int avatarGap: 12

    Item {
        id: loginArea

        width: Math.min(root.width * 0.8, 650)
        height: avatarSize + avatarGap + input.height

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(0, Math.round(parent.height * 0.16) - 70)

        // Circular profile picture
        Item {
            id: avatar
            width: avatarSize
            height: avatarSize

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "#e5e7eb"
            }

            Image {
                id: avatarImage
                anchors.fill: parent
                source: Qt.resolvedUrl("../" + (config.UserIcon || "Assets/default-avatar.png"))
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
            height: implicitHeight

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
