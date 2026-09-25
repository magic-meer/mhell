import QtQuick

/**
 * SToggle — iOS-style animated toggle switch.
 * Usage:  SToggle { checked: Settings.foo.bar; onToggled: Settings.foo.bar = val }
 */
Item {
    id: root

    property bool checked: false
    signal toggled(bool val)

    readonly property var cfg: Settings.settingsUI

    implicitWidth:  44
    implicitHeight: 26

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? cfg.accentColor : Qt.rgba(1, 1, 1, 0.12)

        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
            id: thumb
            width:  20
            height: 20
            radius: 10
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: "white"

            // Subtle shadow
            layer.enabled: true
            layer.effect: null   // no ShaderEffect dependency — shadow via border
            border.color: Qt.rgba(0, 0, 0, 0.15)
            border.width: 1

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            // Slight scale bounce on toggle
            scale: mouse.pressed ? 0.88 : 1.0
            Behavior on scale {
                NumberAnimation { duration: 100; easing.type: Easing.OutBack }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
