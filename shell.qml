import Quickshell
import QtQuick
import Quickshell.Widgets
import "modules" as Mod

PanelWindow {
    id: bar

    property bool menuOpen: false

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Mod.Theme.barHeight
    color: Mod.Theme.barBackgound

    //left side
    Row {
        anchors {
            left: parent.left
            leftMargin: Mod.Theme.barMargin
            verticalCenter: parent.verticalCenter
        }
        // spacing: 100 seems like this does not work at all

        MouseArea {
            height: 16
            width: 16

            onClicked: {
                menuOpen = !menuOpen
            }
            IconImage {
                source: Qt.resolvedUrl("./assets/icons/nixos-customized-monochrome-white.svg")
                anchors.fill: parent
            }
        }
    }

    // menu dropdown
    PopupWindow {
        id: menu

        anchor.window: bar
        anchor.rect.x: 10
        anchor.rect.y: 25
        visible: menuOpen
        height: 160
        width: Mod.Theme.menuWidht
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Mod.Theme.radius
            color: Mod.Theme.menuBackgound
            border.color: Mod.Theme.menuBorder

            Column {
                anchors.fill: parent
                anchors.margins: Mod.Theme.menuMargin
                spacing: Mod.Theme.menuSpacing

                Repeater {
                    model: [
                        { type: "item", text: "About this", command: ["foot fastfetch"] },
                        { type: "separator" },
                        { type: "item", text: "Sleep", command: ["suspend"] },
                        { type: "item", text: "Hibernate", command: ["hibernate"] },
                        { type: "item", text: "Restart", command: ["systemctl reboot"] },
                        { type: "item", text: "Shutdown", command: ["shutdown now"] },
                        { type: "separator" },
                        { type: "item", text: "Lock Screen", command: ["pkill niri"] },
                        { type: "item", text: "Log Out mehherrr...", command: ["swaylock"] }
                    ]
                    delegate: Item {
                        required property var modelData

                        width: parent.width
                        height: modelData.type === "separator" ? 1 : Mod.Theme.menuItemHeight

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: 1
                            color: Mod.Theme.separator
                            visible: modelData.type === "separator"
                        }

                        Mod.MenuItem {
                            id: menuItem
                            width: parent.widht
                            visible: modelData.type === "item"

                            text: modelData.type === "item" ? modelData.text : ""
                            command: modelData.type === "item" ? modelData.command : []
                        }
                    }
                }
            }
        }
    }

    //right side
    Row {
        spacing: 10
        anchors {
            right: parent.right
            rightMargin: Mod.Theme.barMargin
            verticalCenter: parent.verticalCenter
        }
        Mod.StyledText {
            text: Qt.formatDate(clock.date, "ddd d MMM")
        }

        Mod.StyledText {
            text: Qt.formatTime(clock.date, "hh:mm")
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
