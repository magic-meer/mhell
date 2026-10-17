import Quickshell
import QtQuick
import Quickshell.Widgets

PanelWindow {
    id: bar

    property bool menuOpen: false

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 25
    color: "#00000000"

    // laoding fonts
    FontLoader {
        id: sfPro
        source: Qt.resolvedUrl("./assets/fonts/SF-Pro/SF-Pro-Text-Regular.otf")
        onStatusChanged: {
            if ( status === FontLoader.Ready )
                console.log("Font Loaded: ", name)
            else if ( status === FontLoader.Error )
                console.log("Error loading font!")
        }
    }

    //left side
    Row {
        anchors {
            left: parent.left
            leftMargin: 14
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
        height: 140
        width: 200
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 4
            color: "#C02a2a2a"
            border.color: "#545454"

            Column {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 2

                Text {
                    text: "About this Larper"
                    color: "white"
                }
                //a spacer is rquried
                Text {
                    text:"Sleep"
                    color: "white"
                }
                Text {
                    text: "Hibernate"
                    color: "white"
                }
                Text {
                    text: "Restart"
                    color: "white"
                }
                Text {
                    text: "Shutdown"
                    color: "white"
                }
                //a spacer
                Text {
                    text: "Lock Screen"
                    color: "white"
                }
                Text {
                    text: "Log Out mehherrr..."
                    color: "white"
                }
            }
        }
    }

    //right side
    Row {
        spacing: 10
        anchors {
            right: parent.right
            rightMargin: 10
            verticalCenter: parent.verticalCenter
        }
        Text {
            text: Qt.formatDate(clock.date, "ddd d MMM")
            color: "white"
        }

        Text {
            text: Qt.formatTime(clock.date, "hh:mm")
            color: "white"

            font.family: sfPro.name
            font.pixelSize: 12
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
