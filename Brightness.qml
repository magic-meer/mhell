import QtQuick
import Quickshell.Io

/**
 * Brightness — bar module with hover popup slider.
 */
Item {
    id: root

    readonly property var cfg: Settings.brightness

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    property int percent: 50

    readonly property string iconStr: {
        if (percent < 25) return cfg.iconLow
        if (percent < 50) return cfg.iconMid
        if (percent < 75) return cfg.iconHigh
        return cfg.iconFull
    }
    readonly property bool iconIsPath: Settings.isIconPath(iconStr)

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

    Timer {
        interval: cfg.pollInterval; running: true; repeat: true
        onTriggered: getProc.running = true
    }

    Process { id: setProc }

    function setBrightness(pct) {
        const clamped = Math.max(cfg.minBrightness, Math.min(100, pct))
        setProc.command = ["brightnessctl", "set", clamped + "%"]
        setProc.running = true
        root.percent = clamped
    }

    // ── Bar display ───────────────────────────────────────────────────────
    Row {
        id: row
        anchors.centerIn: parent
        spacing: cfg.spacing

        Text {
            visible: !root.iconIsPath
            anchors.verticalCenter: parent.verticalCenter
            text: root.iconStr; font.family: cfg.fontFamily
            font.pixelSize: cfg.iconSize; color: cfg.iconColor
        }
        Image {
            visible: root.iconIsPath
            anchors.verticalCenter: parent.verticalCenter
            source: root.iconIsPath ? root.iconStr : ""
            width: cfg.iconSize; height: cfg.iconSize
            fillMode: Image.PreserveAspectFit; smooth: true; mipmap: true
        }
        Text {
            visible: cfg.showLabel
            anchors.verticalCenter: parent.verticalCenter
            text: root.percent + "%"; font.family: cfg.fontFamily
            font.pixelSize: cfg.labelSize; color: cfg.labelColor
        }
    }

    scale: cfg.hoverEnabled && mouse.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onWheel: wheel => {
            const delta = wheel.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
            root.setBrightness(root.percent + delta)
        }
    }

    // ── Hover popup ───────────────────────────────────────────────────────
    BarPopup {
        anchorHovered: mouse.containsMouse
        padding: 16

        Row {
            spacing: 10

            // Sun icon
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           root.iconStr
                font.family:    cfg.fontFamily
                font.pixelSize: 16
                color:          Qt.rgba(1, 1, 1, 0.70)
            }

            // Slider
            Item {
                width: 160; height: 28
                anchors.verticalCenter: parent.verticalCenter

                readonly property real fraction: root.percent / 100.0

                Rectangle {
                    id: bTrack
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 4; radius: 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        width:  Math.max(bThumb.width / 2, bTrack.width * parent.parent.fraction)
                        height: parent.height; radius: parent.radius
                        color:  Qt.rgba(1.0, 0.85, 0.30, 0.90)
                        Behavior on width { NumberAnimation { duration: 80 } }
                    }
                }

                Rectangle {
                    id: bThumb
                    width: 16; height: 16; radius: 8
                    color: "white"
                    border.color: Qt.rgba(0,0,0,0.15); border.width: 1
                    x: (bTrack.width - width) * parent.fraction
                    anchors.verticalCenter: bTrack.verticalCenter
                    scale: bMouse.pressed ? 1.20 : bMouse.containsMouse ? 1.10 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    Behavior on x     { NumberAnimation { duration: 80 } }
                }

                MouseArea {
                    id: bMouse
                    anchors { fill: parent; margins: -6 }
                    hoverEnabled: true
                    preventStealing: true
                    function setPct(mx) {
                        const frac = Math.max(0, Math.min(1, mx / bTrack.width))
                        root.setBrightness(Math.round(frac * 100))
                    }
                    onPressed:      mouse => setPct(mouse.x)
                    onMouseXChanged: if (pressed) setPct(mouseX)
                    onWheel: wheel => {
                        const delta = wheel.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
                        root.setBrightness(root.percent + delta)
                    }
                }
            }

            // Percentage label
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:  root.percent + "%"
                font.family: cfg.fontFamily; font.pixelSize: 12
                color: Qt.rgba(1, 1, 1, 0.60)
                width: 38; horizontalAlignment: Text.AlignRight
            }
        }
    }
}
