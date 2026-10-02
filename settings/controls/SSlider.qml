import QtQuick
import "../.."

/**
 * SSlider — smooth slider with accent fill and animated thumb.
 * Emits valueChanged(real) as the user drags.
 */
Item {
    id: root

    property real value:   0.5
    property real from:    0.0
    property real to:      1.0
    property int  decimal: 2       // decimal places for display
    property color fillColor: Settings.settingsUI.accentColor

    signal edited(real val)

    readonly property real fraction: (value - from) / (to - from)

    implicitWidth:  180
    implicitHeight: 32

    // Track background
    Rectangle {
        id: trackBg
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 4
        radius: 2
        color:  Qt.rgba(1, 1, 1, 0.10)

        // Fill
        Rectangle {
            width:  Math.max(thumb.width / 2, parent.width * root.fraction)
            height: parent.height
            radius: parent.radius
            color:  root.fillColor
        }
    }

    // Thumb
    Rectangle {
        id: thumb
        width:  18
        height: 18
        radius: 9
        color:  "white"
        border.color: Qt.rgba(0, 0, 0, 0.15)
        border.width: 1

        x: (trackBg.width - width) * root.fraction
        anchors.verticalCenter: trackBg.verticalCenter

        scale: dragArea.pressed ? 1.18 : dragArea.containsMouse ? 1.08 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true

        property bool ready: false
        Component.onCompleted: ready = true

        function posToValue(mx) {
            const clamped = Math.max(0, Math.min(trackBg.width, mx))
            const frac    = clamped / trackBg.width
            return root.from + frac * (root.to - root.from)
        }

        onPressed:  mouse => { if (ready) { root.edited(posToValue(mouse.x)); Settings.scheduleSave() } }
        onMouseXChanged: if (ready && pressed) { root.edited(posToValue(mouseX)); Settings.scheduleSave() }
    }
}
