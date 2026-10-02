import QtQuick
import "../.."

/**
 * SColorSwatch — a colored swatch button.
 * Shows the current color. Clicking opens a compact RGBA slider panel.
 * Emits colorChanged(color) as sliders move.
 *
 * Note: Full native color picker dialogs require Qt Widgets which aren't
 * available in QML-only Quickshell, so we provide RGBA sliders instead.
 */
Item {
    id: root

    property color value: Qt.rgba(1, 1, 1, 1)
    signal picked(color c)

    readonly property var cfg: Settings.settingsUI

    implicitWidth:  40
    implicitHeight: 28

    // Swatch
    Rectangle {
        id: swatch
        anchors.fill: parent
        radius: 6
        color: root.value
        border.color: Qt.rgba(1, 1, 1, 0.20)
        border.width: 1

        // Checkerboard pattern underneath (shows transparency)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            clip: true
            z: -1
            visible: root.value.a < 1

            Grid {
                anchors.fill: parent
                columns: Math.ceil(parent.width / 6)
                rows:    Math.ceil(parent.height / 6)
                Repeater {
                    model: parent.columns * parent.rows
                    delegate: Rectangle {
                        required property int index
                        width: 6; height: 6
                        color: (Math.floor(index / Math.ceil(swatch.width / 6))
                               + (index % Math.ceil(swatch.width / 6))) % 2 === 0
                               ? "#aaa" : "#777"
                    }
                }
            }
        }

        scale: swatchMouse.containsMouse ? 1.06 : 1.0
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        MouseArea {
            id: swatchMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked:    panel.visible = !panel.visible
        }
    }

    // RGBA panel
    Rectangle {
        id: panel
        visible: false
        anchors { right: parent.right; top: parent.bottom; topMargin: 6 }
        width:  220
        height: channelCol.implicitHeight + 20
        radius: 10
        color:  Qt.rgba(0.10, 0.10, 0.14, 0.98)
        border.color: Qt.rgba(1, 1, 1, 0.10)
        border.width: 1
        z: 200

        opacity: visible ? 1 : 0
        scale:   visible ? 1 : 0.95
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale   { NumberAnimation { duration: 120 } }

        Column {
            id: channelCol
            anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 10; leftMargin: 12; rightMargin: 12 }
            spacing: 8

            Repeater {
                model: ["R", "G", "B", "A"]

                delegate: Row {
                    required property string modelData
                    required property int    index

                    width:   parent.width
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:           modelData
                        width:          14
                        font.family:    cfg.fontFamily
                        font.pixelSize: 11
                        color:          cfg.textSecondary
                    }

                    SSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width:  parent.width - 50
                        from:   0; to: 1; decimal: 2
                        value: root.value[ ["r", "g", "b", "a"][index] ]
                        onEdited: val => {
                            const c = [root.value.r, root.value.g, root.value.b, root.value.a]
                            c[index] = val
                            root.picked(Qt.rgba(c[0], c[1], c[2], c[3]))
                            Settings.scheduleSave()
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: index === 3 ? root.value.a.toFixed(2)
                                          : Math.round(root.value[["r", "g", "b"][index]] * 255)
                        width:          24
                        font.family:    cfg.fontFamily
                        font.pixelSize: 11
                        color:          cfg.textSecondary
                    }
                }
            }
        }
    }

    // Dismiss panel on outside click
    MouseArea {
        visible:  panel.visible
        anchors { fill: parent; margins: -9999 }
        z: 199
        onClicked: panel.visible = false
    }
}
