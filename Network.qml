import QtQuick
import Quickshell.Io

/**
 * Network — bar module with hover popup showing connection details.
 */
Item {
    id: root

    readonly property var cfg: Settings.network

    implicitWidth:  icon.implicitWidth
    implicitHeight: icon.implicitHeight

    property string state:   "unknown"
    property string ssid:    ""
    property string iface:   ""

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
        // Get connectivity + active wifi SSID + interface
        command: ["bash", "-c", "nmcli -t -f CONNECTIVITY g; nmcli -t -f ACTIVE,SSID,DEVICE dev wifi 2>/dev/null | grep '^yes' | head -1"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const conn  = (lines[0] || "").toLowerCase()
                if (conn === "full" || conn === "limited")
                    root.state = "connected"
                else if (conn === "none" || conn === "portal")
                    root.state = "disconnected"
                else
                    root.state = "unknown"

                // Parse wifi line: yes:SSID:device
                if (lines[1]) {
                    const parts = lines[1].split(":")
                    root.ssid  = parts[1] || ""
                    root.iface = parts[2] || ""
                } else {
                    root.ssid  = ""
                    root.iface = ""
                }
            }
        }
    }

    Timer {
        interval: cfg.pollInterval; running: true; repeat: true
        onTriggered: pollProc.running = true
    }

    Process { id: iwgtkProc; command: ["iwgtk"] }

    // ── Bar display ───────────────────────────────────────────────────────
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
        width:          cfg.iconSize; height: cfg.iconSize
        fillMode:       Image.PreserveAspectFit; smooth: true; mipmap: true
        opacity:        state === "disconnected" ? 0.35 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    scale: cfg.hoverEnabled && mouse.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    iwgtkProc.running = true
    }

    // ── Hover popup ───────────────────────────────────────────────────────
    BarPopup {
        anchorHovered: mouse.containsMouse
        padding: 14

        Column {
            spacing: 6

            // Status row
            Row {
                spacing: 8
                Text {
                    text:           root.iconStr
                    font.family:    cfg.fontFamily
                    font.pixelSize: 18
                    color:          root.iconColor
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: root.state === "connected"
                            ? (root.ssid.length > 0 ? root.ssid : "Connected")
                            : root.state === "disconnected"
                                ? "No connection"
                                : "Checking…"
                        font.family:    cfg.fontFamily
                        font.pixelSize: 13
                        font.weight:    Font.Medium
                        color:          Qt.rgba(1, 1, 1, 0.90)
                    }
                    Text {
                        visible: root.iface.length > 0
                        text:    root.iface
                        font.family:    cfg.fontFamily
                        font.pixelSize: 11
                        color:          Qt.rgba(1, 1, 1, 0.40)
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width; height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            // Open manager hint
            Text {
                text:           "Click to open network manager"
                font.family:    cfg.fontFamily
                font.pixelSize: 11
                color:          Qt.rgba(1, 1, 1, 0.28)
                horizontalAlignment: Text.AlignHCenter
                width:          parent.width
            }
        }
    }
}
