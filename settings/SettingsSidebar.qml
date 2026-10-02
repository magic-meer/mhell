import QtQuick
import ".."

/**
 * SettingsSidebar — animated vertical nav with section icons and labels.
 * Emits pageChanged(index) when a nav item is clicked.
 * The active item shows an accent-colored pill indicator.
 */
Item {
    id: root

    property int  currentPage: 0
    signal pageChanged(int index)

    readonly property var cfg: Settings.settingsUI

    readonly property var pages: [
        { icon: "󰓩", label: "Bar"         },
        { icon: "󰀻", label: "Workspaces"  },
        { icon: "󰥔", label: "Clock"       },
        { icon: "󰕾", label: "Volume"      },
        { icon: "󰃠", label: "Brightness"  },
        { icon: "󰤨", label: "Network"     },
    ]

    // Sidebar bg
    Rectangle {
        anchors.fill: parent
        color: cfg.sidebarBg
    }

    // Top label
    Item {
        id: header
        width: parent.width
        height: 56

        Text {
            anchors.centerIn: parent
            text: "Settings"
            font.family:    cfg.fontFamily
            font.pixelSize: 15
            font.weight:    Font.DemiBold
            color:          cfg.textPrimary
        }
    }

    // Thin divider under header
    Rectangle {
        id: divider
        anchors.top: header.bottom
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    // Nav items
    Column {
        id: navCol
        anchors.top: divider.bottom
        anchors.topMargin: 8
        width: parent.width
        spacing: 2

        Repeater {
            model: root.pages

            delegate: Item {
                id: navItem

                required property var modelData
                required property int index

                width:  parent.width
                height: 44

                readonly property bool isActive: root.currentPage === index

                // Active pill background
                Rectangle {
                    id: pill
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 8
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    height: 36
                    radius: 8
                    color: navItem.isActive
                        ? Qt.rgba(cfg.accentColor.r, cfg.accentColor.g, cfg.accentColor.b, 0.18)
                        : hoverArea.containsMouse
                            ? Qt.rgba(1, 1, 1, 0.05)
                            : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    // Left accent bar
                    Rectangle {
                        anchors {
                            left: parent.left
                            leftMargin: 0
                            verticalCenter: parent.verticalCenter
                        }
                        width:  3
                        height: navItem.isActive ? 22 : 0
                        radius: 2
                        color:  cfg.accentColor

                        Behavior on height {
                            NumberAnimation { duration: cfg.animDuration; easing.type: Easing.OutCubic }
                        }
                    }

                    Row {
                        anchors {
                            left: parent.left
                            leftMargin: 18
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           navItem.modelData.icon
                            font.family:    cfg.fontFamily
                            font.pixelSize: 16
                            color: navItem.isActive ? cfg.accentColor : cfg.textSecondary

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text:           navItem.modelData.label
                            font.family:    cfg.fontFamily
                            font.pixelSize: 13
                            font.weight:    navItem.isActive ? Font.Medium : Font.Normal
                            color: navItem.isActive ? cfg.textPrimary : cfg.textSecondary

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }
                }

                // Scale on hover
                scale: hoverArea.containsMouse && !navItem.isActive ? 1.02 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root.currentPage = navItem.index
                        root.pageChanged(navItem.index)
                    }
                }
            }
        }
    }

    // Version / footer
    Text {
        anchors {
            bottom: parent.bottom
            bottomMargin: 12
            horizontalCenter: parent.horizontalCenter
        }
        text: "my_quickshell"
        font.family:    cfg.fontFamily
        font.pixelSize: 10
        color:          cfg.textDisabled
    }
}
