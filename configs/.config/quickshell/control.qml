import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
ShellRoot {
WallPalette { id: pal }
PanelWindow {
id: panel
visible: false
anchors { top: true; bottom: true; left: true; right: true }
color: "transparent"
exclusionMode: ExclusionMode.Ignore
WlrLayershell.layer: WlrLayer.Overlay
WlrLayershell.namespace: "yolo-control"
WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
readonly property string bin: Quickshell.env("HOME") + "/.local/bin/"
readonly property string helper: bin + "yolo-control"
readonly property color primary: pal.accent
readonly property color secondary: pal.highlight
readonly property color glass: Qt.rgba(1,1,1,0.12)
readonly property color ink: Qt.rgba(0,0,0,0.85)
readonly property string icons: "JetBrainsMono Nerd Font"
readonly property var sink: Pipewire.defaultAudioSink
readonly property var mic: Pipewire.defaultAudioSource
readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
readonly property real ui: Math.max(0.8, Math.min(1, screen.height * 0.2 / 240))
property string picker: ""
property bool closing: false
property var afterClose: null
function fmtTime(sec) {
const s = Math.max(0, Math.floor(sec || 0))
const m = Math.floor(s / 60)
const r = s % 60
return m + ":" + (r < 10 ? "0" : "") + r
}
function openPanel() {
closeTimer.stop()
afterClose = null
closing = false
visible = true
seekRow.livePos = player?.position ?? 0
}

function closePanel(afterClose) {
if (!visible || closing) return
closing = true
panel.afterClose = afterClose || null
closeTimer.start()
}

Timer {
id: closeTimer
interval: 210
onTriggered: {
panel.visible = false
panel.closing = false
panel.picker = ""
const callback = panel.afterClose
panel.afterClose = null
if (callback) callback()
}
}

IpcHandler {
target: "control"

function open(): void {
panel.openPanel()
}

function close(): void {
panel.closePanel()
}

function toggle(): void {
if (panel.visible && !panel.closing)
    panel.closePanel()
else
    panel.openPanel()
}
}
PwObjectTracker { objects: [panel.sink, panel.mic].filter(n => n) }
Shortcut { sequence: "Escape"; onActivated: panel.closePanel() }
MouseArea { anchors.fill: parent; onClicked: panel.closePanel() }
component Card: Rectangle {
radius: 15
color: Qt.alpha(pal.fg, 0.065)
border.color: Qt.alpha(pal.fg, 0.12)
}
component Caption: Text {
font.family: "Orbitron"; font.letterSpacing: 1.5; font.pixelSize: 13; font.weight: Font.DemiBold
color: pal.fg; elide: Text.ElideRight
}
component RoundButton: Button {
id: tile
required property string title
required property int glyph
property bool lit: false
property int diameter: 58
implicitWidth: diameter; implicitHeight: diameter; padding: 0
Accessible.name: title
hoverEnabled: true
ToolTip.visible: hovered
ToolTip.text: title
scale: down ? 0.96 : 1
opacity: enabled ? 1 : 0.38
Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
background: Rectangle {
radius: 15; color: tile.lit ? panel.primary : panel.glass
border.color: tile.visualFocus ? panel.secondary : Qt.alpha(pal.fg, 0.13)
Behavior on color { ColorAnimation { duration: 145; easing.type: Easing.OutCubic } }
}
contentItem: Text {
horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
font.family: panel.icons; font.pixelSize: Math.round(tile.diameter * 0.43)
text: String.fromCodePoint(tile.glyph); color: tile.lit ? panel.ink : pal.fg
}
}
component SquareTile: Button {
id: tile
required property string label
required property int glyph
property string iconText: ""
property bool active: false
property color activeColor: panel.primary
property color inactiveColor: pal.fg
property color activeFill: Qt.alpha(pal.fg, 0.12)
property bool tintWhenInactive: false
property bool longPressEnabled: false
property bool longPressTriggered: false
signal longHeld()
implicitWidth: 68*panel.ui
implicitHeight: implicitWidth
Accessible.name: label
hoverEnabled: true
Timer {
    id: holdTimer
    interval: 1000
    onTriggered: {
        if (!tile.longPressEnabled || !tile.pressed) return
        tile.longPressTriggered = true
        tile.longHeld()
    }
}
onPressed: {
    longPressTriggered = false
    if (longPressEnabled) holdTimer.start()
}
onReleased: holdTimer.stop()
onCanceled: holdTimer.stop()
scale: down ? 0.96 : 1
Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
opacity: enabled ? 1 : 0.38
background: Item {
Rectangle {
anchors.fill: parent; anchors.margins: -4
radius: 15; color: Qt.alpha(tile.activeColor, 0.14)
opacity: tile.active ? 1 : 0
Behavior on opacity { NumberAnimation { duration: 140 } }
}
Rectangle {
anchors.fill: parent; radius: 15
color: tile.active ? tile.activeFill : Qt.alpha(pal.fg, 0.06)
border.width: tile.active ? 2 : 1
border.color: tile.active ? tile.activeColor : Qt.alpha(pal.fg, 0.14)
Behavior on color { ColorAnimation { duration: 150 } }
Behavior on border.color { ColorAnimation { duration: 150 } }
}
}
contentItem: Column {
spacing: 3
topPadding: Math.max(0, (height - symbol.height) / 2)
Text { id: symbol; anchors.horizontalCenter: parent.horizontalCenter
font.family: panel.icons; font.pixelSize: 25*panel.ui
color: tile.active || tile.tintWhenInactive ? tile.activeColor : tile.inactiveColor
text: tile.iconText || String.fromCodePoint(tile.glyph) }
}
}
component RadioTile: SquareTile {
id: radio
required property string control
enabled: !write.running
Process { id: read; command: [panel.helper, radio.control, "get"]
stdout: StdioCollector { onStreamFinished: radio.active = text.trim() === "true" } }
Timer { interval: 2500; repeat: true; running: panel.visible; triggeredOnStart: true
onTriggered: if (!write.running) read.running = true }
Process { id: write; onExited: read.running = true }
onClicked: {
    if (radio.longPressTriggered) return
    write.exec(["env", "SWAYNC_TOGGLE_STATE=" + !active, panel.helper, control, "set"])
}
}
component HSlider: Rectangle {
id: pill
required property string label
required property int glyph
required property real level
property bool active: enabled
property real dragged: 0
readonly property real amount: Math.min(1, Math.max(0, touch.pressed ? dragged : level))
signal clicked(real value)
Layout.fillWidth: true; implicitHeight: 56*panel.ui; radius: 15
color: Qt.alpha(pal.fg,0.06); border.color: Qt.alpha(pal.fg,0.14)
opacity: active ? 1 : 0.45
Accessible.name: label; Accessible.role: Accessible.Slider
Item {
id: sourceItem; anchors.fill: parent; visible: false; layer.enabled: true
Rectangle { height: parent.height; width: parent.width * pill.amount; color: panel.primary }
}
Rectangle { id: shape; anchors.fill: parent; radius: 15; color: "white"; visible: false; layer.enabled: true }
MultiEffect { anchors.fill: parent; source: sourceItem; maskEnabled: true; maskSource: shape }
Text { x: 16; anchors.verticalCenter: parent.verticalCenter; font.family: panel.icons; font.pixelSize: 22
text: String.fromCodePoint(pill.glyph); color: x+width/2 < pill.width * pill.amount ? panel.ink : pal.fg }
Caption { anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
text: Math.round(pill.amount * 100)+"%"; color: x+width/2 < pill.width*pill.amount ? panel.ink : pal.fg }
MouseArea {
id: touch; anchors.fill: parent; preventStealing: true
function setAt(x) { pill.dragged = Math.max(0, Math.min(1,x/width)); pill.clicked(pill.dragged) }
onPressed: e => setAt(e.x)
onPositionChanged: e => { if (pressed) setAt(e.x) }
}
}
component DeviceRow: ColumnLayout {
id: row
required property bool output
readonly property string title: output ? "Output" : "Input"
readonly property var node: output ? panel.sink : panel.mic
readonly property bool expanded: panel.picker === title
visible: panel.picker === "" || row.expanded
Layout.fillHeight: row.expanded
Layout.minimumHeight: header.implicitHeight
spacing: 4 * panel.ui
Button {
id: header
Layout.fillWidth: true; implicitHeight: 40 * panel.ui
Accessible.name: row.title + " device"
background: Card { radius: 15}
onClicked: panel.picker = row.expanded ? "" : row.title
contentItem: RowLayout {
Text { text: String.fromCodePoint(row.output ? 0xf04c3 : 0xf036c); color: panel.primary; font.family: panel.icons; font.pixelSize: 18 }
Caption { text: row.title }
Caption { Layout.fillWidth: true; horizontalAlignment: Text.AlignRight; text: row.node?.nickname || row.node?.description || "Unavailable" }
Caption { text: row.expanded ? "\u25b4" : "\u25be" }
}
}
ListView {
id: devices
visible: row.expanded
Layout.fillWidth: true
Layout.fillHeight: true
Layout.minimumHeight: 0
Layout.preferredHeight: 100 * panel.ui
spacing: 2 * panel.ui
clip: true
model: row.expanded ? Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink === row.output) : []
Caption { anchors.centerIn: parent; visible: !devices.count; text: "No devices available" }
delegate: Button {
required property var modelData
width: devices.width; height: 30 * panel.ui
leftPadding: 12 * panel.ui; rightPadding: 12 * panel.ui
background: Card { radius: 10 * panel.ui}
contentItem: Caption {
verticalAlignment: Text.AlignVCenter
text: modelData.nickname || modelData.description || modelData.name
color: modelData === row.node ? panel.primary : pal.fg
}
onClicked: {
if (row.output) Pipewire.preferredDefaultAudioSink = modelData
else Pipewire.preferredDefaultAudioSource = modelData
panel.picker = ""
}
}
}
}
property real brightness: 0
property int pending: -1
Process { id: getLight; command: [panel.helper,"brightness","get"]
stdout: StdioCollector { onStreamFinished: if (!setLight.running && panel.pending < 0 && text.trim()) panel.brightness = Number(text.trim())/100 } }
Timer { interval: 1800; triggeredOnStart: true; repeat: true; running: panel.visible
onTriggered: if (!setLight.running && panel.pending < 0) getLight.running = true }
Timer { id: flush; interval: 60; onTriggered: if (!setLight.running && panel.pending >= 0) {
const value = panel.pending; panel.pending = -1
setLight.exec([panel.helper,"brightness","set",String(value)])
} }
Process { id: setLight; onExited: if (panel.pending >= 0) flush.restart() }
Card {
id: surface
anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
height: Math.max(panel.screen.height*0.2, 256*panel.ui)
radius: 15; color: Qt.tint(Qt.rgba(0,0,0,0.85), Qt.alpha(panel.primary,0.06))
border.color: Qt.alpha(panel.primary,0.35)
property bool ready: false
Component.onCompleted: ready = true
property real appear: (ready && panel.visible && !panel.closing) ? 1 : 0
Behavior on appear {
NumberAnimation {
duration: panel.closing ? 200 : 180
easing.type: panel.closing ? Easing.InCubic : Easing.OutCubic
}
}
opacity: panel.closing ? 1 : appear
transform: Translate { y: -(surface.height + 24) * (1 - surface.appear) }
MouseArea { anchors.fill: parent }
Flickable {
id: viewport
anchors.fill: parent; anchors.margins: 16*panel.ui
contentWidth: strip.width; contentHeight: height; clip: true
RowLayout {
id: strip; height: viewport.height; width: Math.max(viewport.width, 1190*panel.ui)
spacing: 16*panel.ui
ColumnLayout {
Layout.fillWidth: true
Layout.preferredWidth: 360 * panel.ui
spacing: 12 * panel.ui
RowLayout {
Layout.alignment: Qt.AlignHCenter
spacing: 14 * panel.ui
Rectangle {
Layout.preferredWidth: 84 * panel.ui
Layout.preferredHeight: 84 * panel.ui
radius: 15
color: panel.glass
Text { anchors.centerIn: parent; text: String.fromCodePoint(0xf0387); font.family: panel.icons; color: pal.fg }
Image {
anchors.fill: parent
source: panel.player?.trackArtUrl ?? ""
asynchronous: true
fillMode: Image.PreserveAspectCrop
layer.enabled: true
layer.effect: MultiEffect { maskEnabled: true; maskSource: artMask }
}
Rectangle { id: artMask; anchors.fill: parent; radius: 15; visible: false; layer.enabled: true }
}
ColumnLayout {
Layout.maximumWidth: 220 * panel.ui
spacing: 4
Caption {
Layout.fillWidth: true
text: panel.player?.trackTitle || "NOT PLAYING"
font.pixelSize: 14
}
Caption {
Layout.fillWidth: true
text: panel.player?.trackArtist || ""
opacity: 0.68
}
RowLayout {
spacing: 4
RoundButton { title: "Previous"; glyph: 0xf04ae; diameter: 33; enabled: !!panel.player?.canGoPrevious; onClicked: panel.player.previous() }
RoundButton { title: "Play or pause"; glyph: panel.player?.isPlaying ? 0xf03e4 : 0xf040a; diameter: 38; enabled: !!panel.player?.canTogglePlaying; onClicked: panel.player.togglePlaying() }
RoundButton { title: "Next"; glyph: 0xf04ad; diameter: 33; enabled: !!panel.player?.canGoNext; onClicked: panel.player.next() }
}
}
}
RowLayout {
id: seekRow
Layout.fillWidth: true
spacing: 10 * panel.ui
visible: (panel.player?.length ?? 0) > 0
property real livePos: panel.player?.position ?? 0
property real draggedRatio: 0
readonly property real length: panel.player?.length ?? 0
readonly property real displayPos: seekTouch.pressed ? (draggedRatio * length) : livePos
readonly property real progress: length > 0 ? Math.min(1, Math.max(0, displayPos / length)) : 0
Connections {
target: panel.player
function onPositionChanged() { seekRow.livePos = panel.player.position }
function onTrackChanged() { seekRow.livePos = panel.player.position }
}
FrameAnimation {
running: panel.visible && !!panel.player?.isPlaying && !seekTouch.pressed
onTriggered: seekRow.livePos += frameTime * (panel.player?.rate ?? 1)
}
Caption {
text: panel.fmtTime(seekRow.displayPos)
font.pixelSize: 11
opacity: 0.85
}
Rectangle {
Layout.fillWidth: true
implicitHeight: 6 * panel.ui
radius: 15
color: Qt.alpha(pal.fg, 0.16)
Rectangle {
height: parent.height
width: parent.width * seekRow.progress
radius: 15
color: panel.primary
}
MouseArea {
id: seekTouch
anchors.fill: parent
anchors.topMargin: -8
anchors.bottomMargin: -8
enabled: !!panel.player?.canSeek
cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
function ratioAt(x) { return Math.max(0, Math.min(1, x / width)) }
onPressed: e => seekRow.draggedRatio = ratioAt(e.x)
onPositionChanged: e => { if (pressed) seekRow.draggedRatio = ratioAt(e.x) }
onReleased: e => {
const targetSec = ratioAt(e.x) * seekRow.length
if (panel.player?.positionSupported) {
panel.player.position = targetSec
} else if (panel.player?.canSeek) {
panel.player.seek(targetSec - seekRow.livePos)
}
seekRow.livePos = targetSec
}
}
}
Caption {
text: panel.fmtTime(seekRow.length)
font.pixelSize: 11
opacity: 0.85
}
}
}
Grid {
columns: 4; spacing: 15*panel.ui
RadioTile {
control: "wifi"; label: "Wi-Fi"; glyph: 0xf05a9
longPressEnabled: true
onLongHeld: panel.closePanel(() => wifiManager.running = true)
Process { id: wifiManager; command: [panel.bin+"yolo-manager-current", "wifi"]
onExited: (exitCode) => {
    if (exitCode !== 0) console.warn("Control panel: Wi-Fi manager restart failed with exit code", exitCode)
} }
}
RadioTile { control: "airplane"; label: "AIRPLANE"; glyph: 0xf001d }
SquareTile {
id: bluetooth
label: "Bluetooth"; glyph: 0xf00af; enabled: !!Bluetooth.defaultAdapter
active: Bluetooth.defaultAdapter?.enabled ?? false
longPressEnabled: true
onLongHeld: panel.closePanel(() => bluetoothManager.running = true)
Process { id: bluetoothManager; command: [panel.bin+"yolo-manager-current", "bluetooth"]
onExited: (exitCode) => {
    if (exitCode !== 0) console.warn("Control panel: Bluetooth manager restart failed with exit code", exitCode)
} }
onClicked: {
    if (bluetooth.longPressTriggered) return
    Bluetooth.defaultAdapter.enabled = !bluetooth.active
}
}
SquareTile {
id: power
property string modeClass: ""
property string tooltipText: ""
property color modeColor: modeClass === "powersave" ? "#64ffc8"
    : modeClass === "performance" ? "#ff2d55" : "#00d2ff"
label: "POWER"; ToolTip.visible: hovered; ToolTip.text: tooltipText; glyph: 0xf0a0f
activeColor: modeColor; tintWhenInactive: true
enabled: !powerWrite.running
Process { id: powerRead; command: [panel.bin+"yolo-power","get"]
stdout: StdioCollector { onStreamFinished: {
    try {
        const state = JSON.parse(text)
        const classes = Array.isArray(state.class) ? state.class : [state.class]
        power.modeClass = String(classes[0] || "")
        power.iconText = String(state.text || "")
        power.tooltipText = String(state.tooltip || power.modeClass)
    } catch (e) {
        console.warn("Control panel: could not read power-mode state:", e)
    }
} } }
Timer { interval: 2500; triggeredOnStart: true; repeat: true; running: panel.visible
onTriggered: if (!powerWrite.running) powerRead.running = true }
Process { id: powerWrite; command: [panel.bin+"yolo-power","toggle"]
onExited: (exitCode) => {
    if (exitCode !== 0) console.warn("Control panel: power-mode toggle failed with exit code", exitCode)
    powerRead.running = true
} }
onClicked: powerWrite.running = true
}
SquareTile {
id: lidToggle
property string tooltipText: ""
label: "LID SLEEP"; glyph: 0xf0322
activeColor: "#0db2ff"; inactiveColor: "#ebf9ff"
activeFill: Qt.alpha("#0db2ff", 0.10)
ToolTip.visible: hovered; ToolTip.text: tooltipText
enabled: !lidWrite.running
Process { id: lidRead; command: [panel.bin+"lidtoggle","waybar"]
stdout: StdioCollector { onStreamFinished: {
    try {
        const state = JSON.parse(text)
        lidToggle.active = state.class === "enabled"
        lidToggle.iconText = String(state.text || "")
        lidToggle.tooltipText = String(state.tooltip || "")
    } catch (e) {
        console.warn("Control panel: could not read lid-toggle state:", e)
    }
} } }
Timer { interval: 2500; repeat: true; running: panel.visible; triggeredOnStart: true
onTriggered: if (!lidWrite.running) lidRead.running = true }
Process { id: lidWrite; command: [panel.bin+"lidtoggle","toggle"]
onExited: (exitCode) => {
    if (exitCode !== 0) console.warn("Control panel: lid-toggle failed with exit code", exitCode)
    lidRead.running = true
} }
onClicked: lidWrite.running = true
}
SquareTile { label: "MUTE SPK"; enabled: !!panel.sink?.audio; active: panel.sink?.audio?.muted ?? false
glyph: active ? 0xf0581 : 0xf057e; onClicked: panel.sink.audio.muted = !active }
SquareTile { label: "MUTE MIC"; enabled: !!panel.mic?.audio; active: panel.mic?.audio?.muted ?? false
glyph: active ? 0xf036d : 0xf036c; onClicked: panel.mic.audio.muted = !active }
}
ColumnLayout {
Layout.fillWidth: true; Layout.preferredWidth: 270*panel.ui
HSlider { label: "Brightness"; glyph: 0xf00e0; level: panel.brightness
onClicked: v => { panel.brightness=v; panel.pending=Math.max(1,Math.round(v * 100)); flush.start() } }
HSlider { label: "Speaker"; glyph: panel.sink?.audio?.muted ? 0xf0581 : 0xf057e
enabled: !!panel.sink?.audio; level: panel.sink?.audio?.volume ?? 0; onClicked: v => panel.sink.audio.volume=v }
HSlider { label: "Microphone"; glyph: panel.mic?.audio?.muted ? 0xf036d : 0xf036c
enabled: !!panel.mic?.audio; level: panel.mic?.audio?.volume ?? 0; onClicked: v => panel.mic.audio.volume=v }
}
ColumnLayout {
Layout.fillWidth: true
Layout.preferredWidth: 260 * panel.ui
Layout.alignment: Qt.AlignHCenter
Layout.fillHeight: true
spacing: 8 * panel.ui
DeviceRow { Layout.fillWidth: true; output: true }
DeviceRow { Layout.fillWidth: true; output: false }
}
}
}
Caption { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 8
text: ""; font.pixelSize: 10; font.letterSpacing: 2; opacity: 0.45 }
}
}
}
