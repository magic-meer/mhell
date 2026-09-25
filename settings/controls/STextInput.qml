import QtQuick
import "../.."

/**
 * STextInput — single-line text field.
 * Emits committed(string) when Enter is pressed or focus is lost.
 */
Item {
    id: root

    property string value:       ""
    property string placeholder: ""
    signal committed(string val)

    readonly property var cfg: Settings.settingsUI

    implicitWidth:  180
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 8
        color:  field.activeFocus ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.05)
        border.color: field.activeFocus ? cfg.accentColor : Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        Behavior on color        { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        TextInput {
            id: field
            anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text:            root.value
            font.family:     cfg.fontFamily
            font.pixelSize:  13
            color:           cfg.textPrimary
            selectionColor:  Qt.rgba(cfg.accentColor.r, cfg.accentColor.g, cfg.accentColor.b, 0.40)
            selectedTextColor: cfg.textPrimary
            clip:            true

            property bool ready: false
            Component.onCompleted: ready = true

            onEditingFinished: { root.committed(text); Settings.scheduleSave() }
            onTextChanged:     if (ready && Settings.settingsUI.instantApply) { root.committed(text); Settings.scheduleSave() }
        }

        // Placeholder
        Text {
            visible: field.text.length === 0 && !field.activeFocus
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            text:           root.placeholder
            font.family:    cfg.fontFamily
            font.pixelSize: 13
            color:          cfg.textDisabled
        }
    }
}
