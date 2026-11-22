
import QtQuick 2.15
import QtQuick.Controls 2.15
import "."

Item {
    id: statusBar

    width: statusRow.implicitWidth
    height: 34

    Row {
        id: statusRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 13

        Text {
            text: "ABC"
            color: "white"
            font.pixelSize: 12
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        // Functional virtual keyboard toggle
        Item {
            width: 22
            height: 28
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "⌨"
                color: "white"
                font.pixelSize: 17
            }

            MouseArea {
                anchors.fill: parent
                enabled: virtualKeyboard.status === Loader.Ready
                cursorShape: Qt.PointingHandCursor

                onClicked: virtualKeyboard.switchState()
            }
        }

        // Real SDDM session selector
	SessionButton {
    		id: sessionSelect
    		width: 24
    		height: 28
    		anchors.verticalCenter: parent.verticalCenter
	}
        TahoeBattery {
            anchors.verticalCenter: parent.verticalCenter
        }

        // Power icon, same size as keyboard
        Item {
            width: 22
            height: 28
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "⏻"
                color: "white"
                font.pixelSize: 17
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: powerMenu.open()
            }
        }
    }

    // Expose session ComboBox to the login form
    readonly property int selectedSession: sessionSelect.selectedSession

    Popup {
        id: powerMenu
        parent: statusBar
        x: statusBar.width - width
        y: statusBar.height + 8
        width: 190
        padding: 6
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#D9222830"
            radius: 12
            border.color: "#55FFFFFF"
            border.width: 1
        }

        contentItem: Column {
            spacing: 2

            PowerItem {
                text: "Sleep"
                enabled: sddm.canSuspend
                onClicked: {
                    powerMenu.close()
                    sddm.suspend()
                }
            }

            PowerItem {
                text: "Restart"
                enabled: sddm.canReboot
                onClicked: {
                    powerMenu.close()
                    sddm.reboot()
                }
            }

            Rectangle {
                width: 178
                height: 1
                color: "#44FFFFFF"
            }

            PowerItem {
                text: "Shut Down"
                enabled: sddm.canPowerOff
                onClicked: {
                    powerMenu.close()
                    sddm.powerOff()
                }
            }
        }
    }

    component PowerItem: Rectangle {
        id: item

        property alias text: label.text
        signal clicked()

        width: 178
        height: 36
        radius: 7

        opacity: enabled ? 1 : 0.4
        color: mouse.containsMouse ? "#44FFFFFF" : "transparent"

        Text {
            id: label
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
            font.pixelSize: 13
            font.family: "SF Pro Display"
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: item.clicked()
        }
    }
}
