import QtQuick
import "../.."

/**
 * SIconPicker — shows the current icon (glyph or image) plus a text field
 * to type a Nerd Font glyph or paste a file path (.svg/.png/.ico).
 * Emits committed(string) when the value changes.
 */
Item {
    id: root

    property string value: ""
    signal committed(string val)

    readonly property var  cfg:       Settings.settingsUI
    readonly property bool isPath:    Settings.isIconPath(value)

    implicitWidth:  220
    implicitHeight: 32

    Row {
        anchors.fill: parent
        spacing: 8

        // Preview
        Rectangle {
            width:  32
            height: 32
            radius: 6
            color:  Qt.rgba(1, 1, 1, 0.06)
            border.color: Qt.rgba(1, 1, 1, 0.10)
            border.width: 1

            Text {
                visible:        !root.isPath
                anchors.centerIn: parent
                text:           root.value
                font.family:    cfg.iconFont
                font.pixelSize: 16
                color:          cfg.textPrimary
            }

            Image {
                visible:        root.isPath
                anchors.centerIn: parent
                source:         root.isPath ? root.value : ""
                width:          20
                height:         20
                fillMode:       Image.PreserveAspectFit
                smooth:         true
                mipmap:         true
            }
        }

        // Text field
        STextInput {
            width:       root.width - 40
            height:      32
            value:       root.value
            placeholder: "glyph or /path/to/icon.svg"
            onCommitted: val => root.committed(val)
        }
    }
}
