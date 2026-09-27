import QtQuick
import Quickshell.Services.Pipewire

/**
 * Volume — bar module with hover popup slider.
 */
Item {
    id: root

    readonly property var cfg: Settings.volume

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    // ── Pipewire state ────────────────────────────────────────────────────
    readonly property var  sink:  Pipewire.defaultAudioSink
    readonly property bool ready: sink ? sink.ready : false
    readonly property var  audio: ready ? sink.audio : null
    readonly property real vol:   audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    readonly property string iconStr: {
        if (!audio || muted || vol === 0) return cfg.iconMuted
        if (vol < 34)                     return cfg.iconLow
        if (vol < 67)                     return cfg.iconMid
        return cfg.iconHigh
    }
    readonly property bool iconIsPath: Settings.isIconPath(iconStr)

    // ── Bar display ───────────────────────────────────────────────────────
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
            color:          root.muted ? cfg.iconMutedColor : cfg.iconColor
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Image {
            visible:        root.iconIsPath
            anchors.verticalCenter: parent.verticalCenter
            source:         root.iconIsPath ? root.iconStr : ""
            width:          cfg.iconSize; height: cfg.iconSize
            fillMode:       Image.PreserveAspectFit; smooth: true; mipmap: true
            opacity:        root.muted ? 0.35 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
        Text {
            visible:        cfg.showLabel
            anchors.verticalCenter: parent.verticalCenter
            text:           root.muted ? "mute" : root.vol + "%"
            font.family:    cfg.fontFamily
            font.pixelSize: cfg.labelSize
            color:          root.muted ? cfg.labelMutedColor : cfg.labelColor
            Behavior on color { ColorAnimation { duration: 120 } }
        }
    }

    scale: cfg.hoverEnabled && mouse.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: if (root.ready && root.audio) root.audio.muted = !root.audio.muted
        onWheel: wheel => {
            if (!root.ready || !root.audio) return
            const delta = wheel.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
            root.audio.volume = Math.max(0.0, Math.min(cfg.maxVolume, root.audio.volume + delta))
        }
    }

    // ── Hover popup ───────────────────────────────────────────────────────
    BarPopup {
        id: popup
        anchorHovered: mouse.containsMouse
        padding: 16

        // ── Volume slider row ──────────────────────────────────────────────
        Row {
            spacing: 10

            // Mute toggle button
            Item {
                width: 28; height: 28
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent; radius: 8
                    color: muteBtnMouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.12)
                        : Qt.rgba(1, 1, 1, 0.06)
                    Behavior on color { ColorAnimation { duration: 80 } }
                }
                Text {
                    anchors.centerIn: parent
                    text:           root.muted ? "󰝟" : "󰕾"
                    font.family:    cfg.fontFamily
                    font.pixelSize: 14
                    color:          root.muted ? Qt.rgba(1,1,1,0.35) : Qt.rgba(1,1,1,0.80)
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                MouseArea {
                    id: muteBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: if (root.ready && root.audio) root.audio.muted = !root.audio.muted
                }
            }

            // Slider track
            Item {
                width: 160; height: 28
                anchors.verticalCenter: parent.verticalCenter

                readonly property real fraction: Math.max(0, Math.min(1,
                    (root.audio ? root.audio.volume : 0) / cfg.maxVolume))

                // Track bg
                Rectangle {
                    id: trackBg
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 4; radius: 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    // Fill
                    Rectangle {
                        width:  Math.max(thumb.width / 2, trackBg.width * parent.parent.fraction)
                        height: parent.height; radius: parent.radius
                        color:  root.muted ? Qt.rgba(1,1,1,0.20) : Qt.rgba(0.4, 0.6, 1.0, 0.90)
                        Behavior on width { NumberAnimation { duration: 80 } }
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                // Thumb
                Rectangle {
                    id: thumb
                    width: 16; height: 16; radius: 8
                    color: "white"
                    border.color: Qt.rgba(0, 0, 0, 0.15); border.width: 1
                    x: (trackBg.width - width) * parent.fraction
                    anchors.verticalCenter: trackBg.verticalCenter
                    scale: sliderMouse.pressed ? 1.20 : sliderMouse.containsMouse ? 1.10 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                    Behavior on x     { NumberAnimation { duration: 80 } }
                }

                MouseArea {
                    id: sliderMouse
                    anchors { fill: parent; margins: -6 }
                    hoverEnabled: true
                    preventStealing: true

                    function setVol(mx) {
                        if (!root.ready || !root.audio) return
                        const frac = Math.max(0, Math.min(1, mx / trackBg.width))
                        root.audio.volume = frac * cfg.maxVolume
                    }
                    onPressed:      mouse => setVol(mouse.x)
                    onMouseXChanged: if (pressed) setVol(mouseX)
                    onWheel: wheel => {
                        if (!root.ready || !root.audio) return
                        const delta = wheel.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
                        root.audio.volume = Math.max(0, Math.min(cfg.maxVolume, root.audio.volume + delta))
                    }
                }
            }

            // Volume percentage label
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text:           root.muted ? "mute" : root.vol + "%"
                font.family:    cfg.fontFamily
                font.pixelSize: 12
                color:          root.muted ? Qt.rgba(1,1,1,0.30) : Qt.rgba(1,1,1,0.60)
                width:          38
                horizontalAlignment: Text.AlignRight
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }
    }
}
