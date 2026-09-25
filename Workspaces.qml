import QtQuick
import Quickshell.Io

/**
 * Workspaces — reads all configuration from Settings.workspaces.
 */
Item {
    id: root

    readonly property var  cfg:   Settings.workspaces
    readonly property int  count: NiriIpc.workspaces.length

    implicitWidth:  count > 0
                        ? count * cfg.boxSize + (count - 1) * cfg.boxSpacing
                        : cfg.boxSize
    implicitHeight: cfg.boxSize

    // ── Focused index ─────────────────────────────────────────────────────
    property int focusedIndex: {
        for (let i = 0; i < NiriIpc.workspaces.length; i++) {
            if (NiriIpc.workspaces[i].is_focused) return i
        }
        return 0
    }

    // ── Focus command ─────────────────────────────────────────────────────
    Process {
        id: focusProc
        property int targetIdx: 1
        command: ["niri", "msg", "action", "focus-workspace", String(focusProc.targetIdx)]
    }

    function focusWorkspace(idx) {
        focusProc.targetIdx = idx
        focusProc.running   = true
    }

    // ── Sliding highlight ─────────────────────────────────────────────────
    Rectangle {
        id: highlight
        x:      root.focusedIndex * (cfg.boxSize + cfg.boxSpacing)
        y:      0
        width:  cfg.boxSize
        height: cfg.boxSize
        radius: cfg.boxRadius

        color:        cfg.highlightColor
        border.color: cfg.highlightBorderColor
        border.width: cfg.highlightBorderWidth

        Behavior on x {
            enabled: cfg.animationsEnabled
            NumberAnimation {
                duration: cfg.slideDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    // ── Workspace boxes ───────────────────────────────────────────────────
    Repeater {
        model: NiriIpc.workspaces

        delegate: Item {
            id: wsDelegate

            required property var modelData
            required property int index

            readonly property bool hasWindow: modelData.active_window_id !== null
            readonly property bool isFocused: modelData.is_focused

            x:      index * (cfg.boxSize + cfg.boxSpacing)
            y:      0
            width:  cfg.boxSize
            height: cfg.boxSize

            // Idle border
            Rectangle {
                anchors.fill: parent
                radius:       cfg.boxRadius
                color:        "transparent"
                border.color: cfg.idleBorderColor
                border.width: cfg.idleBorderWidth
            }

            // Presence dot
            Rectangle {
                anchors.centerIn: parent
                width:   cfg.dotSize
                height:  cfg.dotSize
                radius:  cfg.dotSize / 2
                visible: hasWindow && cfg.showDots
                color:   Qt.rgba(1, 1, 1, isFocused ? 0.0 : cfg.dotOpacity)

                Behavior on color {
                    enabled: cfg.animationsEnabled
                    ColorAnimation { duration: cfg.colorDuration }
                }
            }

            // Workspace number label
            Text {
                anchors.centerIn: parent
                text:        modelData.idx
                font.family: cfg.fontFamily !== undefined ? cfg.fontFamily : "JetBrainsMono Nerd Font"
                font.pixelSize: cfg.numberSize
                color:       Qt.rgba(1, 1, 1, 0.9)
                visible:     cfg.showNumbers
            }

            // Hover scale
            scale: cfg.hoverEnabled && hoverArea.containsMouse ? cfg.hoverScale : 1.0
            Behavior on scale {
                enabled: cfg.animationsEnabled
                NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: cfg.hoverEnabled
                cursorShape:  Qt.PointingHandCursor
                onClicked:    root.focusWorkspace(modelData.idx)
            }
        }
    }
}
