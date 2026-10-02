import QtQuick
import Quickshell.Io
import "settings/controls"

/**
 * Brightness — morphs from icon into icon+slider on hover.
 */
Item {
    id: root

    readonly property var cfg: Settings.brightness

    property int percent: 50

    readonly property string iconStr: {
        if (percent < 25) return cfg.iconLow
        if (percent < 50) return cfg.iconMid
        if (percent < 75) return cfg.iconHigh
        return cfg.iconFull
    }

    // ── Poll ──────────────────────────────────────────────────────────────
    Process {
        id: getProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                if (parts.length >= 4) {
                    const val = parseInt(parts[3].replace("%", ""))
                    if (!isNaN(val)) root.percent = val
                }
            }
        }
    }
    Timer { interval: cfg.pollInterval; running: true; repeat: true; onTriggered: getProc.running = true }
    Process { id: setProc }

    function setBrightness(pct) {
        const c = Math.max(cfg.minBrightness, Math.min(100, pct))
        setProc.command = ["brightnessctl", "set", c + "%"]
        setProc.running = true
        root.percent = c
    }

    // ── Expand state ──────────────────────────────────────────────────────
    property bool expanded: mouse.containsMouse || sliderMouse.containsMouse

    property real _exp: 0.0
    Behavior on _exp { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onExpandedChanged: _exp = expanded ? 1.0 : 0.0

    readonly property real _collapsedW: cfg.iconSize + 8
    readonly property real _expandedW:  cfg.iconSize + 8 + 160 + 38 + 16

    implicitWidth:  _collapsedW + (_expandedW - _collapsedW) * _exp
    implicitHeight: Settings.bar.height

    Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    // ── Background pill ───────────────────────────────────────────────────
    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:  height / 2
        color:   Qt.rgba(1, 1, 1, 0.07 * root._exp)
        border.color: Qt.rgba(1, 1, 1, 0.10 * root._exp)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 180 } }
    }

    // ── Icon ──────────────────────────────────────────────────────────────
    Text {
        id: iconText
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        text:           root.iconStr
        font.family:    cfg.fontFamily
        font.pixelSize: cfg.iconSize
        color:          cfg.iconColor
    }

    // ── Slider ────────────────────────────────────────────────────────────
    SSlider {
        anchors {
            left:   iconText.right; leftMargin:  8
            right:  pctLabel.left;  rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        height:  28
        opacity: root._exp
        visible: root._exp > 0.01

        value: root.percent / 100
        from:  0
        to:    1

        // Warm yellow for brightness
        fillColor: Qt.rgba(1.0, 0.85, 0.25, 0.90)

        onEdited: val => root.setBrightness(Math.round(val * 100))

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onWheel: e => {
                const d = e.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
                root.setBrightness(root.percent + d)
            }
        }
    }

    // ── Percentage label ──────────────────────────────────────────────────
    Text {
        id: pctLabel
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        text:           root.percent + "%"
        font.family:    cfg.fontFamily
        font.pixelSize: 11
        color:          Qt.rgba(1, 1, 1, 0.55 * root._exp)
        width:          34
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // ── Hover + scroll ────────────────────────────────────────────────────
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: e => {
            const d = e.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
            root.setBrightness(root.percent + d)
        }
    }
}
