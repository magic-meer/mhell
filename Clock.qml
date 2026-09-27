import QtQuick

/**
 * Clock — bar module with hover popup showing full date + mini calendar.
 */
Item {
    id: root

    readonly property var cfg: Settings.clock

    property var now: new Date()

    implicitWidth:  col.implicitWidth
    implicitHeight: col.implicitHeight

    Timer {
        interval: cfg.showSeconds ? 1000 : 60000
        running:  true; repeat: true
        onTriggered: root.now = new Date()
    }

    scale: cfg.hoverEnabled && hoverArea.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: cfg.hoverEnabled
    }

    // ── Bar display ───────────────────────────────────────────────────────
    Column {
        id: col
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           Qt.formatTime(root.now, cfg.timeFormat)
            font.family:    cfg.fontFamily
            font.pixelSize: cfg.timeSize
            font.weight:    cfg.fontWeight
            color:          cfg.timeColor
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:           Qt.formatDate(root.now, cfg.dateFormat)
            font.family:    cfg.fontFamily
            font.pixelSize: cfg.dateSize
            color:          cfg.dateColor
            visible:        cfg.showDate
            height:         cfg.showDate ? implicitHeight : 0
        }
    }

    // ── Hover popup — mini calendar ───────────────────────────────────────
    BarPopup {
        anchorHovered: hoverArea.containsMouse
        padding: 16

        Column {
            spacing: 10

            // Month + year header
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           Qt.formatDate(root.now, "MMMM yyyy")
                    font.family:    cfg.fontFamily
                    font.pixelSize: 13
                    font.weight:    Font.SemiBold
                    color:          Qt.rgba(1, 1, 1, 0.90)
                }
            }

            // Day-of-week headers
            Row {
                spacing: 0
                Repeater {
                    model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                    Text {
                        width: 30
                        text:           modelData
                        font.family:    cfg.fontFamily
                        font.pixelSize: 10
                        color:          Qt.rgba(1, 1, 1, 0.30)
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // Calendar grid
            Grid {
                columns: 7
                spacing: 0

                // Compute first weekday of month (Monday = 0)
                property int  _year:       root.now.getFullYear()
                property int  _month:      root.now.getMonth()
                property int  _today:      root.now.getDate()
                property int  _daysInMonth: {
                    const d = new Date(_year, _month + 1, 0)
                    return d ? d.getDate() : 30
                }
                // getDay(): 0=Sun,1=Mon…6=Sat → convert to Mon=0
                property int  _firstDay:   (new Date(_year, _month, 1).getDay() + 6) % 7
                property int  _totalCells: _firstDay + _daysInMonth

                Repeater {
                    model: Math.ceil(parent._totalCells / 7) * 7

                    delegate: Item {
                        width: 30; height: 26

                        readonly property int dayNum: index - parent._firstDay + 1
                        readonly property bool isValid: dayNum >= 1 && dayNum <= parent._daysInMonth
                        readonly property bool isToday: isValid && dayNum === parent._today

                        Rectangle {
                            anchors.centerIn: parent
                            width: 24; height: 24; radius: 12
                            visible: isToday
                            color:   Qt.rgba(0.4, 0.6, 1.0, 0.85)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible:        isValid
                            text:           dayNum
                            font.family:    cfg.fontFamily
                            font.pixelSize: 12
                            font.weight:    isToday ? Font.Bold : Font.Normal
                            color:          isToday
                                ? "white"
                                : Qt.rgba(1, 1, 1, 0.72)
                        }
                    }
                }
            }

            // Full datetime line
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text:           Qt.formatDateTime(root.now, "dddd, d MMMM yyyy  •  " + cfg.timeFormat)
                font.family:    cfg.fontFamily
                font.pixelSize: 11
                color:          Qt.rgba(1, 1, 1, 0.35)
            }
        }
    }
}
