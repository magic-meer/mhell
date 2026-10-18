import Quickshell
import QtQuick
import "." as Mod

Rectangle {
    id: root

    required property string text
    required property var command

    signal activated()

    width: Mod.Theme.menuWidht
    height: Mod.Theme.menuItemHeight
    radius: Mod.Theme.radius

    color: mouse.containsMouse ? Mod.Theme.hoverBackground : "transparent"

    Mod.StyledText {
        anchors.fill: parent
        // anchors.leftMargin:
        text: root.text
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            console.log("clicked!!")
            Quickshell.execDetached({command: root.command})
        }
    }
}
