import QtQuick

/**
 * Clock — reads all configuration from Settings.clock.
 */
Item {
    id: root

    readonly property var cfg: Settings.clock

    property var now: new Date()

    implicitWidth:  col.implicitWidth
    implicitHeight: col.implicitHeight

    Timer {
        interval: cfg.showSeconds ? 1000 : 60000
        running:  true
        repeat:   true
        onTriggered: root.now = new Date()
    }

    // ── Hover scale ───────────────────────────────────────────────────────
    scale: cfg.hoverEnabled && hoverArea.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale {
        NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: cfg.hoverEnabled
    }

    // ── Layout ────────────────────────────────────────────────────────────
    Column {
        id: col
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text:            Qt.formatTime(root.now, cfg.timeFormat)
            font.family:     cfg.fontFamily
            font.pixelSize:  cfg.timeSize
            font.weight:     cfg.fontWeight
            color:           cfg.timeColor
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
}
