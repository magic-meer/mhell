import QtQuick
import Quickshell.Services.Pipewire
import "settings/controls"

/**
 * Volume — morphs from icon into icon+slider on hover.
 * The module expands inline in the bar — no separate popup.
 */
Item {
    id: root

    readonly property var cfg: Settings.volume

    // ── Pipewire ──────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink

    // Bind the sink so its audio properties become reactive
    PwObjectTracker {
        objects: [ root.sink ]
    }

    readonly property real vol: sink?.audio?.volume ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property string iconStr: {
        if (!sink?.audio || muted || vol === 0) return cfg.iconMuted
        if (vol < 34)                     return cfg.iconLow
        if (vol < 67)                     return cfg.iconMid
        return cfg.iconHigh
    }

    // ── Expand state ──────────────────────────────────────────────────────
    property bool expanded: mouse.containsMouse || sliderMouse.containsMouse

    // Animated expansion progress 0→1
    property real _exp: 0.0
    Behavior on _exp {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    onExpandedChanged: _exp = expanded ? 1.0 : 0.0

    // Collapsed: just the icon width. Expanded: icon + slider + label
    readonly property real _collapsedW: cfg.iconSize + 8
    readonly property real _expandedW:  cfg.iconSize + 8 + 160 + 38 + 16  // icon + slider + label + gaps

    implicitWidth:  _collapsedW + (_expandedW - _collapsedW) * _exp
    implicitHeight: Settings.bar.height

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // ── Background pill that grows with the module ─────────────────────────
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
        color:          root.muted ? cfg.iconMutedColor : cfg.iconColor

        // Scale bounce on mute toggle
        scale: root._exp > 0.5 && muteMouse.pressed ? 0.85 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: muteMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted
        }
    }

    // ── Slider (fades in as module expands) ───────────────────────────────
    SSlider {
        anchors {
            left:   iconText.right; leftMargin:  8
            right:  levelLabel.left; rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        height:  28
        opacity: root._exp
        visible: root._exp > 0.01

        value: sink?.audio ? Math.max(0, Math.min(1, sink.audio.volume / cfg.maxVolume)) : 0
        from:  0
        to:    1

        onEdited: val => { if (sink?.audio) sink.audio.volume = val * cfg.maxVolume }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onWheel: e => {
                if (!sink?.audio) return
                const d = e.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
                sink.audio.volume = Math.max(0, Math.min(cfg.maxVolume, sink.audio.volume + d))
            }
        }
    }

    // ── Level label (fades in) ─────────────────────────────────────────────
    Text {
        id: levelLabel
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        text:           root.muted ? "mute" : root.vol + "%"
        font.family:    cfg.fontFamily
        font.pixelSize: 11
        color:          Qt.rgba(1, 1, 1, 0.55 * root._exp)
        width:          36
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    // ── Hover + scroll on the whole module ────────────────────────────────
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton   // clicks handled by muteMouse/sliderMouse
        onWheel: e => {
            if (!sink?.audio) return
            const d = e.angleDelta.y > 0 ? cfg.scrollStep : -cfg.scrollStep
            sink.audio.volume = Math.max(0, Math.min(cfg.maxVolume, sink.audio.volume + d))
        }
    }
}