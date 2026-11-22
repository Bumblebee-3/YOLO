// YOLO greeter. See LICENSE and CREDITS for licensing and original contributors.
import QtQuick
import QtQuick.Controls
import QtMultimedia
import "Components"

Pane {
    id: root

    width: Screen.width
    height: Screen.height
    padding: 0
    focus: true
    font.family: config.Font
    font.pointSize: Number(config.FontSize) || 13
    palette.window: config.BackgroundColor
    palette.highlight: config.HighlightBackgroundColor
    palette.highlightedText: config.HighlightTextColor
    LayoutMirroring.enabled: config.RightToLeftLayout == "true" || Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    readonly property url wallpaper: Qt.resolvedUrl(config.Background)
    readonly property bool videoWallpaper: /\.(avi|mp4|mov|mkv|m4v|webm)$/i.test(config.Background)

    Loader {
        anchors.fill: parent
        sourceComponent: root.videoWallpaper ? video : image
    }

    Component {
        id: image
        AnimatedImage {
            source: root.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            clip: true
        }
    }

    Component {
        id: video
        VideoOutput {
            id: output
            fillMode: VideoOutput.PreserveAspectCrop
            MediaPlayer {
                source: root.wallpaper
                videoOutput: output
                loops: MediaPlayer.Infinite
                Component.onCompleted: play()
            }
        }
    }

    LoginForm {
        anchors.fill: parent
    }

    TahoeStatus {
        id: tahoeStatus
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.rightMargin: 22
    }

    Loader {
        id: virtualKeyboard
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.4
        source: "Components/VirtualKeyboard.qml"

        function switchState() {
            item.activated = !item.active
            if (item.activated)
                Qt.inputMethod.show()
            else
                Qt.inputMethod.hide()
        }
    }
}
