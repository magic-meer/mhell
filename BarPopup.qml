import QtQuick

/**
 * BarPopup — floating pill that slides up from a bar module on hover.
 *
 * Usage: place inside a bar module, pass the parent module's MouseArea
 * containsMouse. Put content in the default slot.
 *
 * The popup positions itself above the parent item, centered horizontally.
 * It auto-dismisses when the mouse leaves both the anchor and the popup.
 */
Item {
    id: root

    // Whether the anchor (bar module) is hovered
    property bool anchorHovered: false

    // Extra padding inside the popup
    property int  padding: 14

    // Content goes here
    default property alias content: contentCol.data

    // Read-only: use to check if popup or anchor is hovered
    readonly property bool popupHovered: popupMouse.containsMouse
    readonly property bool anyHovered:   anchorHovered || popupHovered

    // ── Visibility / animation ────────────────────────────────────────────
    property real _progress: 0.0   // 0 = hidden, 1 = fully shown

    onAnyHoveredChanged: {
        if (anyHovered) showTimer.restart()
        else            hideTimer.restart()
    }

    // Small delay before showing to avoid flicker on quick mouse-throughs
    Timer {
        id: showTimer
        interval: 80
        onTriggered: if (root.anyHovered) showAnim.start()
    }

    // Small delay before hiding so user can move mouse to popup
    Timer {
        id: hideTimer
        interval: 120
        onTriggered: if (!root.anyHovered) hideAnim.start()
    }

    NumberAnimation {
        id: showAnim
        target: root; property: "_progress"
        to: 1.0; duration: 180; easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: hideAnim
        target: root; property: "_progress"
        to: 0.0; duration: 140; easing.type: Easing.InCubic
    }

    // ── Popup container ───────────────────────────────────────────────────
    // Positioned relative to the bar module (parent of this BarPopup)
    Item {
        id: popup

        // Size wraps content
        width:  contentCol.implicitWidth  + root.padding * 2
        height: contentCol.implicitHeight + root.padding * 2

        // Center horizontally above parent, above the bar
        x: (parent.width  - width)  / 2
        y: -(height + 10)

        opacity:        root._progress
        scale:          0.92 + root._progress * 0.08
        transformOrigin: Item.Bottom

        visible: root._progress > 0.01

        // Background pill
        Rectangle {
            anchors.fill: parent
            radius:       12
            color:        Qt.rgba(0.08, 0.08, 0.11, 0.97)
            border.color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1

            // Subtle bottom connector pointing at bar
            Rectangle {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: -4 }
                width: 8; height: 8; radius: 2
                rotation: 45
                color: Qt.rgba(0.08, 0.08, 0.11, 0.97)
                border.color: Qt.rgba(1, 1, 1, 0.10)
                border.width: 1
                // Clip the top half to make a downward arrow
                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: parent.height / 2
                    color: Qt.rgba(0.08, 0.08, 0.11, 0.97)
                }
            }
        }

        // Content column
        Column {
            id: contentCol
            anchors.centerIn: parent
            spacing: 8
        }

        // Mouse area to keep popup alive while hovering it
        MouseArea {
            id: popupMouse
            anchors.fill: parent
            hoverEnabled: true
            // Allow wheel events to pass through to content
            onWheel: wheel => wheel.accepted = false
        }
    }
}
