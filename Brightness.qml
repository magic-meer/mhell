import QtQuick
import Quickshell.Io

/**
 * Brightness — reads all configuration from Settings.brightness.
 * Supports glyph icons or image paths.
 */
Item {
    id: root

    readonly property var cfg: Settings.brightness

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    property int percent: 0

    // ── Icon selection ────────────────────────────────────────────────────
    readonly property string iconStr: {
        if (percent < 25) return cfg.iconLow
        if (percent < 50) return cfg.iconMid
        if (percent < 75) return cfg.iconHigh
        return cfg.iconFull
    }
    readonly property bool iconIsPath: Settings.isIconPath(iconStr)

    // ── Poll process ──────────────────────────────────────────────────────
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
        interval: cfg.pollInterval
        running:  true
        repeat:   true
        onTriggered: getProc.running = true
    }

    // ── Set process ───────────────────────────────────────────────────────
    Process {
        id: setProc
    }

    function setBrightness(pct) {
        const clamped = Math.max(cfg.minBrightness, Math.min(100, pct))
        setProc.command = ["brightnessctl", "set", clamped + "%"]
        setProc.running = true
        root.percent = clamped
    }

    // ── Layout ────────────────────────────────────────────────────────────
    Row {
        id: row
        anchors.centerIn: parent
        spacing: cfg.spacing

        Text {
            visible:        !root.iconIsPath
            anchors.verticalCenter: parent.verticalCenter
            text:           root.iconStr
            font.family:    cfg.fontFamily
            font.pixelSize: cfg.iconSize
            color:          cfg.iconColor
        }
        Image {
            visible:        root.iconIsPath
            anchors.verticalCenter: parent.verticalCenter
            source:         root.iconIsPath ? root.iconStr : ""
            width:          cfg.iconSize
            height:         cfg.iconSize
            fillMode:       Image.PreserveAspectFit
            smooth:         true
            mipmap:         true
        }

        Text {
            visible:        cfg.showLabel
            anchors.verticalCenter: parent.verticalCenter
            text:           root.percent + "%"
            font.family:    cfg.fontFamily
            font.pixelSize: cfg.labelSize
            color:          cfg.labelColor
        }
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
        onWheel: wheel => {
            const delta = wheel.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
            root.setBrightness(root.percent + delta)
        }
    }
}
