import QtQuick
import Quickshell.Io

/**
 * Network — reads all configuration from Settings.network.
 * Supports glyph icons or image paths.
 */
Item {
    id: root

    readonly property var cfg: Settings.network

    implicitWidth:  icon.implicitWidth
    implicitHeight: icon.implicitHeight

    property string state: "unknown"

    // ── Resolved icon and color ───────────────────────────────────────────
    readonly property string iconStr: {
        if (state === "connected")    return cfg.iconConnected
        if (state === "disconnected") return cfg.iconDisconnected
        return cfg.iconUnknown
    }
    readonly property bool  iconIsPath: Settings.isIconPath(iconStr)
    readonly property color iconColor: {
        if (state === "connected")    return cfg.colorConnected
        if (state === "disconnected") return cfg.colorDisconnected
        return cfg.colorUnknown
    }

    // ── Poll nmcli ────────────────────────────────────────────────────────
    Process {
        id: pollProc
        command: ["nmcli", "-t", "-f", "CONNECTIVITY,WIFI", "g"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(":")
                const conn  = parts[0] ? parts[0].toLowerCase() : ""
                if (conn === "full" || conn === "limited")
                    root.state = "connected"
                else if (conn === "none" || conn === "portal")
                    root.state = "disconnected"
                else
                    root.state = "unknown"
            }
        }
    }

    Timer {
        interval: cfg.pollInterval
        running:  true
        repeat:   true
        onTriggered: pollProc.running = true
    }

    // ── iwgtk launcher ────────────────────────────────────────────────────
    Process {
        id: iwgtkProc
        command: ["iwgtk"]
    }

    // ── Icon — glyph or image ─────────────────────────────────────────────
    Text {
        id: icon
        visible:        !root.iconIsPath
        anchors.centerIn: parent
        text:           root.iconStr
        font.family:    cfg.fontFamily
        font.pixelSize: cfg.iconSize
        color:          root.iconColor
        Behavior on color { ColorAnimation { duration: 200 } }
    }
    Image {
        id: iconImg
        visible:        root.iconIsPath
        anchors.centerIn: parent
        source:         root.iconIsPath ? root.iconStr : ""
        width:          cfg.iconSize
        height:         cfg.iconSize
        fillMode:       Image.PreserveAspectFit
        smooth:         true
        mipmap:         true
        opacity:        state === "disconnected" ? 0.35 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // ── Hover scale ───────────────────────────────────────────────────────
    scale: cfg.hoverEnabled && mouse.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale {
        NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: cfg.hoverEnabled
        cursorShape:  Qt.PointingHandCursor
        onClicked:    iwgtkProc.running = true
    }
}
