import QtQuick

/**
 * SSpinBox — integer value editor with − / + buttons.
 */
Item {
    id: root

    property int value: 0
    property int from:  0
    property int to:    9999
    property int step:  1
    property string suffix: ""

    signal edited(int val)

    readonly property var cfg: Settings.settingsUI

    implicitWidth:  120
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 8
        color:  Qt.rgba(1, 1, 1, 0.06)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1

        Row {
            anchors.fill: parent

            // Minus button
            Item {
                width:  32
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text:           "−"
                    font.pixelSize: 16
                    color: root.value <= root.from ? cfg.textDisabled : cfg.textPrimary
                    Behavior on color { ColorAnimation { duration: 80 } }
                }

                Rectangle {
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: if (root.value - root.step >= root.from)
                                   root.edited(root.value - root.step)
                }
            }

            // Value label
            Item {
                width:  parent.width - 64
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text:           root.value + root.suffix
                    font.family:    cfg.fontFamily
                    font.pixelSize: 13
                    color:          cfg.textPrimary
                }
            }

            // Plus button
            Item {
                width:  32
                height: parent.height

                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    width: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                Text {
                    anchors.centerIn: parent
                    text:           "+"
                    font.pixelSize: 16
                    color: root.value >= root.to ? cfg.textDisabled : cfg.textPrimary
                    Behavior on color { ColorAnimation { duration: 80 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: if (root.value + root.step <= root.to)
                                   root.edited(root.value + root.step)
                }
            }
        }
    }
}
