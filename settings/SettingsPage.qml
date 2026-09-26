import QtQuick
import ".."

/**
 * SettingsPage — base wrapper for every settings page.
 * Provides a page title, optional subtitle, and a scrollable content area.
 * Usage: put controls inside the default `content` slot.
 * Uses only QtQuick (no QtQuick.Controls) to avoid platform theme interference.
 */
Item {
    id: root

    property string title:    ""
    property string subtitle: ""
    default property alias content: contentCol.data

    readonly property var cfg: Settings.settingsUI

    // Page title area
    Item {
        id: pageHeader
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: subtitle.length > 0 ? 68 : 52

        Text {
            id: titleText
            anchors { left: parent.left; leftMargin: 28; bottom: subtitle.length > 0 ? subtitleText.top : parent.bottom; bottomMargin: subtitle.length > 0 ? 2 : 14 }
            text:           root.title
            font.family:    cfg.fontFamily
            font.pixelSize: 20
            font.weight:    Font.SemiBold
            color:          cfg.textPrimary
        }

        Text {
            id: subtitleText
            visible: root.subtitle.length > 0
            anchors { left: parent.left; leftMargin: 28; bottom: parent.bottom; bottomMargin: 10 }
            text:           root.subtitle
            font.family:    cfg.fontFamily
            font.pixelSize: 12
            color:          cfg.textSecondary
        }

        // Divider
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 28; rightMargin: 28 }
            height: 1
            color:  Qt.rgba(1, 1, 1, 0.06)
        }
    }

    // Scrollable content
    Flickable {
        id: flick
        anchors { top: pageHeader.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        contentHeight: contentCol.implicitHeight + 32
        clip: true

        Column {
            id: contentCol
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 16; leftMargin: 28; rightMargin: 28 }
            spacing: 6
        }
    }

    // Custom scroll indicator — plain Rectangle, no QtQuick.Controls
    Rectangle {
        anchors { right: parent.right; rightMargin: 2; top: flick.top; bottom: flick.bottom }
        width:   3
        radius:  2
        color:   "transparent"

        Rectangle {
            width:   parent.width
            radius:  parent.radius
            color:   Qt.rgba(1, 1, 1, 0.20)

            // Position and size proportional to the visible area
            readonly property real ratio:    flick.height / Math.max(flick.contentHeight, flick.height)
            readonly property real position: flick.contentY / Math.max(flick.contentHeight - flick.height, 1)

            height: Math.max(24, parent.height * ratio)
            y:      position * (parent.height - height)

            visible: flick.contentHeight > flick.height

            Behavior on opacity { NumberAnimation { duration: 150 } }
            opacity: flick.moving ? 1.0 : 0.4
        }
    }
}
