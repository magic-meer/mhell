import QtQuick
import Quickshell

/**
 * Clock — morphs from time-only to time+date on hover.
 * A mini calendar popup appears above on extended hover.
 */
Item {
    id: root

    readonly property var cfg: Settings.clock
    property var now: new Date()

    Timer {
        interval: cfg.showSeconds ? 1000 : 60000
        running: true; repeat: true
        onTriggered: root.now = new Date()
    }

    // ── Expand state ──────────────────────────────────────────────────────
    property bool expanded: hoverArea.containsMouse || calPopup.anyHovered

    // ── Bar display ───────────────────────────────────────────────────────
    implicitWidth:  col.implicitWidth
    implicitHeight: Settings.bar.height

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           Qt.formatTime(root.now, cfg.timeFormat)
            font.family:    cfg.fontFamily
            font.pixelSize: cfg.timeSize
            font.weight:    cfg.fontWeight
            color:          cfg.timeColor
        }

        // Date line morphs in on hover
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           Qt.formatDate(root.now, cfg.dateFormat)
            font.family:    cfg.fontFamily
            font.pixelSize: cfg.dateSize
            color:          Qt.rgba(cfg.dateColor.r, cfg.dateColor.g, cfg.dateColor.b, root.expanded ? 1 : 0)
            height:         root.expanded ? implicitHeight : 0
            clip:           true
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }
    }

    scale: cfg.hoverEnabled && hoverArea.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: cfg.hoverEnabled
    }

    // ── Calendar popup (BarPopup + PopupWindow) ────────────────────────────
    BarPopup {
        id: calPopup
        anchorHovered: hoverArea.containsMouse
        popupHovered:  calWin.visible && calMouse.containsMouse
    }

    PopupWindow {
        id: calWin
        anchor.item:    root
        anchor.gravity: Edges.Top
        anchor.edges:   Edges.Bottom
        anchor.rect.x:  Math.round((root.width - calWin.implicitWidth) / 2)
        anchor.rect.y:  -8

        visible:       calPopup.popupVisible
        color:         "transparent"
        implicitWidth:  230
        implicitHeight: calContent.implicitHeight + 28

        Item {
            anchors.fill: parent

            Rectangle {
                anchors { fill: parent; bottomMargin: 8 }
                radius: 12
                color:  Qt.rgba(0.08, 0.08, 0.11, 0.97)
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
                opacity: calPopup.progress
                scale:   0.94 + calPopup.progress * 0.06
                transformOrigin: Item.Bottom
            }
            Rectangle {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
                width: 8; height: 8; rotation: 45
                color: Qt.rgba(0.08,0.08,0.11,0.97)
                border.color: Qt.rgba(1,1,1,0.10); border.width: 1
                opacity: calPopup.progress
                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: parent.height / 2
                    color:  Qt.rgba(0.08, 0.08, 0.11, 0.97)
                }
            }

            Column {
                id: calContent
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 14; leftMargin: 14; rightMargin: 14 }
                spacing: 8
                opacity: calPopup.progress
                scale:   0.94 + calPopup.progress * 0.06
                transformOrigin: Item.Bottom

                // Month header
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           Qt.formatDate(root.now, "MMMM yyyy")
                    font.family:    cfg.fontFamily; font.pixelSize: 13; font.weight: Font.DemiBold
                    color:          Qt.rgba(1,1,1,0.90)
                }

                // Day headers
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Repeater {
                        model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                        Text {
                            width: 28; text: modelData
                            font.family: cfg.fontFamily; font.pixelSize: 10
                            color: Qt.rgba(1,1,1,0.30); horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // Calendar grid
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 7
                    property int _y:   root.now.getFullYear()
                    property int _m:   root.now.getMonth()
                    property int _d:   root.now.getDate()
                    property int _dim: { const x = new Date(_y, _m+1, 0); return x ? x.getDate() : 30 }
                    property int _fd:  (new Date(_y, _m, 1).getDay() + 6) % 7
                    property int _tot: _fd + _dim

                    Repeater {
                        model: Math.ceil(parent._tot / 7) * 7
                        delegate: Item {
                            width: 28; height: 24
                            readonly property int dn: index - parent._fd + 1
                            readonly property bool ok: dn >= 1 && dn <= parent._dim
                            readonly property bool today: ok && dn === parent._d
                            Rectangle {
                                anchors.centerIn: parent; width: 22; height: 22; radius: 11
                                visible: today; color: Qt.rgba(0.4,0.6,1.0,0.85)
                            }
                            Text {
                                anchors.centerIn: parent; visible: ok; text: dn
                                font.family: cfg.fontFamily; font.pixelSize: 12
                                font.weight: today ? Font.Bold : Font.Normal
                                color: today ? "white" : Qt.rgba(1,1,1,0.72)
                            }
                        }
                    }
                }

                // Full datetime
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           Qt.formatDateTime(root.now, "dddd, d MMMM  •  " + cfg.timeFormat)
                    font.family:    cfg.fontFamily; font.pixelSize: 11
                    color:          Qt.rgba(1,1,1,0.32)
                }
            }

            MouseArea { id: calMouse; anchors.fill: parent; hoverEnabled: true; onWheel: e => e.accepted = false }
        }
    }
}
