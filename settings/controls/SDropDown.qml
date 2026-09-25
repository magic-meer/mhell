import QtQuick

/**
 * SDropDown — compact dropdown selector.
 * `model` is a list of strings. `currentIndex` is the selected item.
 */
Item {
    id: root

    property var    model:        []
    property int    currentIndex: 0
    signal selected(int index)

    readonly property var    cfg:         Settings.settingsUI
    readonly property string currentText: model.length > 0 ? model[currentIndex] : ""

    implicitWidth:  140
    implicitHeight: 32

    Rectangle {
        id: button
        anchors.fill: parent
        radius: 8
        color:  popup.visible ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.06)
        border.color: popup.visible ? cfg.accentColor : Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        Behavior on color        { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Row {
            anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 0

            Text {
                width:          parent.width - chevron.width
                text:           root.currentText
                font.family:    cfg.fontFamily
                font.pixelSize: 13
                color:          cfg.textPrimary
                elide:          Text.ElideRight
            }

            Text {
                id: chevron
                text:           popup.visible ? "󰅃" : "󰅀"
                font.family:    cfg.fontFamily
                font.pixelSize: 12
                color:          cfg.textSecondary
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape:  Qt.PointingHandCursor
            onClicked:    popup.visible = !popup.visible
        }
    }

    // Popup list
    Rectangle {
        id: popup
        visible: false
        anchors { top: button.bottom; topMargin: 4; left: button.left; right: button.right }
        height: Math.min(root.model.length * 34, 200)
        radius: 8
        color:  Qt.rgba(0.10, 0.10, 0.14, 0.98)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
        z: 100

        opacity: visible ? 1 : 0
        scale:   visible ? 1 : 0.95
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Flickable {
            anchors.fill: parent
            anchors.margins: 4
            contentHeight: optCol.implicitHeight
            clip: true

            Column {
                id: optCol
                width: parent.width

                Repeater {
                    model: root.model

                    delegate: Item {
                        required property string modelData
                        required property int    index

                        width:  parent.width
                        height: 34

                        Rectangle {
                            anchors { fill: parent; margins: 2 }
                            radius: 6
                            color: root.currentIndex === index
                                ? Qt.rgba(cfg.accentColor.r, cfg.accentColor.g, cfg.accentColor.b, 0.20)
                                : optHover.containsMouse
                                    ? Qt.rgba(1, 1, 1, 0.06)
                                    : "transparent"
                            Behavior on color { ColorAnimation { duration: 80 } }
                        }

                        Text {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text:           modelData
                            font.family:    cfg.fontFamily
                            font.pixelSize: 13
                            color: root.currentIndex === index ? cfg.accentColor : cfg.textPrimary
                        }

                        // Checkmark
                        Text {
                            visible: root.currentIndex === index
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            text:           "󰄵"
                            font.family:    cfg.fontFamily
                            font.pixelSize: 13
                            color:          cfg.accentColor
                        }

                        MouseArea {
                            id: optHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: {
                                root.selected(index)
                                popup.visible = false
                            }
                        }
                    }
                }
            }
        }
    }

    // Close popup when clicking outside
    MouseArea {
        visible:  popup.visible
        anchors { fill: parent; margins: -9999 }
        z: 99
        onClicked: popup.visible = false
    }
}
