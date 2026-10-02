import QtQuick
import Quickshell.Io

/**
 * Network — morphs from icon to icon+ssid on hover. Click opens iwgtk.
 */
Item {
    id: root

    readonly property var cfg: Settings.network

    property string state:  "unknown"
    property string ssid:   ""

    readonly property string iconStr: {
        if (state === "connected")    return cfg.iconConnected
        if (state === "disconnected") return cfg.iconDisconnected
        return cfg.iconUnknown
    }
    readonly property color iconColor: {
        if (state === "connected")    return cfg.colorConnected
        if (state === "disconnected") return cfg.colorDisconnected
        return cfg.colorUnknown
    }
    readonly property string displayText: {
        if (state === "connected")    return ssid.length > 0 ? ssid : "Connected"
        if (state === "disconnected") return "No network"
        return "Checking…"
    }

    // ── Poll ──────────────────────────────────────────────────────────────
    Process {
        id: pollProc
        command: ["bash", "-c",
            "nmcli -t -f CONNECTIVITY g; nmcli -t -f ACTIVE,SSID,DEVICE dev wifi 2>/dev/null | grep '^yes' | head -1"
        ]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const conn  = (lines[0] || "").toLowerCase()
                root.state = (conn === "full" || conn === "limited") ? "connected"
                           : (conn === "none" || conn === "portal")  ? "disconnected"
                           : "unknown"
                if (lines[1]) {
                    const p = lines[1].split(":")
                    root.ssid  = p[1] || ""
                } else {
                    root.ssid = ""
                }
            }
        }
    }
    Timer { interval: cfg.pollInterval; running: true; repeat: true; onTriggered: pollProc.running = true }
    Process { id: iwgtkProc; command: ["iwgtk"] }

    // ── Expand state ──────────────────────────────────────────────────────
    property bool expanded: mouse.containsMouse

    property real _exp: 0.0
    Behavior on _exp { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    onExpandedChanged: _exp = expanded ? 1.0 : 0.0

    readonly property real _textW:     Math.min(120, ssidMetrics.width + 8)
    readonly property real _collapsedW: cfg.iconSize + 4
    readonly property real _expandedW:  cfg.iconSize + 4 + _textW

    implicitWidth:  _collapsedW + (_expandedW - _collapsedW) * _exp
    implicitHeight: Settings.bar.height

    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    TextMetrics { id: ssidMetrics; font.family: cfg.fontFamily; font.pixelSize: 12; text: root.displayText }

    // ── Pill background ───────────────────────────────────────────────────
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
        id: netIcon
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        text:           root.iconStr
        font.family:    cfg.fontFamily
        font.pixelSize: cfg.iconSize
        color:          root.iconColor
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // ── SSID label (slides in) ─────────────────────────────────────────────
    Text {
        anchors {
            left:   netIcon.right; leftMargin: 6
            verticalCenter: parent.verticalCenter
        }
        text:           root.displayText
        font.family:    cfg.fontFamily
        font.pixelSize: 12
        color:          Qt.rgba(1, 1, 1, 0.80 * root._exp)
        clip:           true
        width:          root._textW * root._exp
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    // ── Hover + click ─────────────────────────────────────────────────────
    scale: cfg.hoverEnabled && mouse.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    iwgtkProc.running = true
    }
}
