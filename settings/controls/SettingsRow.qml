import QtQuick
import "../.."

/**
 * SettingsRow — a single row inside a SettingsGroup.
 * Left side: label + optional description.
 * Right side: the control (passed as the default property).
 *
 * Draws a hairline divider below itself unless `last: true`.
 */
Item {
    id: root

    property string label:       ""
    property string description: ""
    property bool   last:        false
    default property alias control: controlSlot.data

    readonly property var cfg: Settings.settingsUI

    implicitWidth:  parent ? parent.width : 400
    implicitHeight: 52

    // Label
    Text {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter; verticalCenterOffset: description.length > 0 ? -8 : 0 }
        text:           root.label
        font.family:    cfg.fontFamily
        font.pixelSize: 13
        color:          cfg.textPrimary
    }

    // Description
    Text {
        visible: root.description.length > 0
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter; verticalCenterOffset: 9 }
        text:           root.description
        font.family:    cfg.fontFamily
        font.pixelSize: 11
        color:          cfg.textSecondary
    }

    // Control slot (right-aligned)
    Item {
        id: controlSlot
        anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        width:  childrenRect.width
        height: childrenRect.height
    }

    // Divider
    Rectangle {
        visible: !root.last
        anchors { bottom: parent.bottom; left: parent.left; right: parent.right; leftMargin: 14 }
        height: 1
        color:  Qt.rgba(1, 1, 1, 0.05)
    }
}
