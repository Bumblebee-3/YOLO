import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "yolo-handoff-test"
            Image {
                anchors.fill: parent
                source: Quickshell.env("YOLO_POSTER")
                fillMode: Image.PreserveAspectCrop
            }
        }
    }
}
