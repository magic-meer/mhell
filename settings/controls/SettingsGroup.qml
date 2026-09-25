import QtQuick

/**
 * SettingsGroup — a card-style container that groups related controls.
 * Provides a section label above the card and a subtle rounded background.
 */
Item {
    id: root

    property string label: ""
    default property alias content: innerCol.data

    readonly property var cfg: Settings.settingsUI

    implicitWidth:  parent ? parent.width : 400
    implicitHeight: groupLabel.height + groupLabel.anchors.topMargin
                    + card.height

    Text {
        id: groupLabel
        visible: root.label.length > 0
        anchors { top: parent.top; left: parent.left; leftMargin: 2 }
        text:               root.label.toUpperCase()
        font.family:        cfg.fontFamily
        font.pixelSize:     10
        font.weight:        Font.Medium
        font.letterSpacing: 1.2
        color:              cfg.textDisabled
    }

    Rectangle {
        id: card
        anchors {
            top: root.label.length > 0 ? groupLabel.bottom : parent.top
            topMargin: root.label.length > 0 ? 6 : 0
            left: parent.left
            right: parent.right
        }
        height: innerCol.implicitHeight + 2   // 1px top + 1px bottom padding handled by column
        radius: 10
        color:  Qt.rgba(1, 1, 1, 0.04)
        border.color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1

        Column {
            id: innerCol
            anchors { left: parent.left; right: parent.right }
            spacing: 0
        }
    }
}
