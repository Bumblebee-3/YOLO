
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: sessionButton

    width: 24
    height: 28

    // Preserve the properties expected by Input.qml
    property int selectedSession: selectSession.currentIndex

    // Functional session model and selection
    ComboBox {
        id: selectSession

        visible: false
        model: sessionModel
        currentIndex: model.lastIndex
        textRole: "name"
    }

    // Compact desktop/session icon
    Text {
        id: sessionIcon

        anchors.centerIn: parent
        text: "▣"
        color: "white"
        font.pixelSize: 18

        MouseArea {
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: sessionMenu.open()
        }
    }

    Popup {
        id: sessionMenu

        parent: sessionButton
        x: sessionButton.width - width
        y: sessionButton.height + 8

        width: 220
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

            Repeater {
                model: sessionModel

                delegate: Rectangle {
                    required property int index
                    required property string name

                    width: 208
                    height: 36
                    radius: 7

                    color: sessionMouse.containsMouse
                        ? "#44FFFFFF"
                        : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        text: name
                        color: "white"
                        font.family: "Inter"
                        font.weight: Font.Black
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 30
                    }

                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            selectSession.currentIndex = index
                            sessionMenu.close()
                        }
                    }
                }
            }
        }
    }
}
