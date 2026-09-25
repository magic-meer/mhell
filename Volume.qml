import QtQuick
import Quickshell.Services.Pipewire

/**
 * Volume — reads all configuration from Settings.volume.
 * Supports glyph icons (Nerd Font) or image paths (.svg/.png/.ico).
 */
Item {
    id: root

    readonly property var cfg: Settings.volume

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    // ── Pipewire state ────────────────────────────────────────────────────
    readonly property var  sink:  Pipewire.defaultAudioSink
    readonly property var  audio: sink  ? sink.audio : null
    readonly property real vol:   audio ? Math.round(audio.volume * 100) : 0
    readonly property bool muted: audio ? audio.muted : false

    // ── Icon selection ────────────────────────────────────────────────────
    readonly property string iconStr: {
        if (!audio || muted || vol === 0) return cfg.iconMuted
        if (vol < 34)                     return cfg.iconLow
        if (vol < 67)                     return cfg.iconMid
        return cfg.iconHigh
    }
    readonly property bool iconIsPath: Settings.isIconPath(iconStr)

    // ── Layout ────────────────────────────────────────────────────────────
    Row {
        id: row
        anchors.centerIn: parent
        spacing: cfg.spacing

        // Icon — glyph or image
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
            width:          cfg.iconSize
            height:         cfg.iconSize
            fillMode:       Image.PreserveAspectFit
            smooth:         true
            mipmap:         true
            opacity:        root.muted ? 0.35 : 1.0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        // Label
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

    // ── Hover scale ───────────────────────────────────────────────────────
    scale: cfg.hoverEnabled && mouse.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale {
        NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: cfg.hoverEnabled
        acceptedButtons: Qt.LeftButton
        onClicked: if (root.audio) root.audio.muted = !root.audio.muted
        onWheel: wheel => {
            if (!root.audio) return
            const delta = wheel.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
            root.audio.volume = Math.max(0.0, Math.min(cfg.maxVolume, root.audio.volume + delta))
        }
    }
}
