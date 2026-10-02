import QtQuick
import Quickshell.Services.SystemTray

/**
 * SystemTray — renders status-notifier items from the system tray.
 * Each item shows its icon. Right-click opens the item menu if available.
 */
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        Repeater {
            model: SystemTray.items

            delegate: Item {
                id: trayItem

                required property var modelData

                width: 20
                height: 20

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: trayItem.modelData.icon
                    smooth: true
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate(Math.round(mapToGlobal(0, 0).x), Math.round(mapToGlobal(0, 0).y))
                        } else if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
                            trayItem.modelData.display(Math.round(mapToGlobal(0, 0).x), Math.round(mapToGlobal(0, 0).y))
                        }
                    }
                }
            }
        }
    }
}
