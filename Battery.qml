import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Battery — morphs from icon into icon+label on hover.
 * Click opens a popup showing percentage, status, and remaining time.
 */
Item {
    id: root

    readonly property var cfg: Settings.battery

    // ── Battery state ───────────────────────────────────────────────────────
    /// false when there is no battery on this machine (desktop, or the sysfs
    /// node is missing/renamed). Drives the "absent" icon instead of pretending
    /// to be a 0% discharging battery.
    property bool  _present:   true
    property bool  _probed:    false
    property int   percent:    0
    property string status:    "Unknown"
    property string timeRemaining: "--:--"
    property real _energyNow: 0
    property real _energyFull: 1
    property real _powerNow: 0

    // ── Polling ───────────────────────────────────────────────────────────
    // One shell probe instead of five `cat` Processes: sysfs exposes
    // energy_* on some machines and charge_* on others, and power_now is
    // optional, so a single tolerant read handles every variant. Emits one
    // `|`-joined line; "absent" when no battery node exists at all.
    Process {
        id: probeProc
        running: false
        // No onExited: it fires on normal exit too, which would mark a healthy
        // battery absent the instant a good probe finished. Absence is reported
        // by the probe itself, on stdout.
        stdout: StdioCollector { onStreamFinished: root._ingest(text) }
    }

    function _ingest(out) {
        const parts = String(out || "").trim().split("|").map(s => s.trim())
        if (parts[0] === "absent" || parts.length < 2 || parts[1] === "") {
            root._present  = false
            root._probed   = true
            root.percent   = 0
            root.status    = "Absent"
            root._powerNow = 0
            root.timeRemaining = "--:--"
            updateIcon()
            return
        }

        root._present = true
        root._probed  = true

        // Field order matches the probe: cap|status|energy_now|energy_full|power_now
        const cap = parseInt(parts[0])
        if (!isNaN(cap)) root.percent = cap
        if (parts[1]) root.status = parts[1]

        const now  = Number(parts[2] || 0)
        const full = Number(parts[3] || 0)
        const watt = Number(parts[4] || 0)
        root._energyNow = now
        root._energyFull = full > 0 ? full : 1
        root._powerNow  = watt

        // ETA only makes sense while discharging with real numbers available.
        if (root.status === "Discharging" && now > 0 && watt > 0) {
            const remaining = now / watt * 60
            const hours = Math.floor(remaining / 60)
            const mins  = Math.floor(remaining) % 60
            root.timeRemaining = (hours > 0 ? hours + ":" : "") +
                                 String(mins < 10 ? "0" : "") + mins
        } else {
            root.timeRemaining = "--:--"
        }
        updateIcon()
    }

    function _probe() {
        const d = "/sys/class/power_supply"
        probeProc.command = ["bash", "-c",
            'if [ ! -e "' + d + '/BAT0" ]; then echo absent; exit 0; fi;' +
            'b="' + d + '/BAT0";' +
            'cap=$(cat $b/capacity 2>/dev/null);' +
            'st=$(cat $b/status 2>/dev/null);' +
            'now=$(cat $b/energy_now $b/charge_now 2>/dev/null | head -1);' +
            'ful=$(cat $b/energy_full $b/charge_full 2>/dev/null | head -1);' +
            'pw=$(cat $b/power_now 2>/dev/null);' +
            'echo "$cap|$st|$now|$ful|$pw"'
        ]
        probeProc.running = true
    }

    Timer {
        id: pollTimer
        interval: cfg.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._probe()
    }

    // ── Expand state ──────────────────────────────────────────────────────
    property bool expanded: mouse.containsMouse || sliderMouse.containsMouse

    property real _exp: 0.0
    Behavior on _exp { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onExpandedChanged: _exp = expanded ? 1.0 : 0.0

    readonly property real _collapsedW: root._present
                                        ? levelLabel.implicitWidth + 3 + cfg.iconSize + 12
                                        : cfg.iconSize + 8
    readonly property real _expandedW:  root._collapsedW + 100 + 30 + 16

    implicitWidth:  _collapsedW + (_expandedW - _collapsedW) * _exp
    implicitHeight: Settings.bar.height

    Behavior on implicitWidth {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    // ── Background pill ───────────────────────────────────────────────────
    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:  height / 2
        color:   Qt.rgba(0, 0, 0, 0.08 * root._exp)
        border.color: Qt.rgba(0, 0, 0, 0.12 * root._exp)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 180 } }
    }

    // ── Icon / label / colour, derived from state ───────────────────────────
    property string _iconName: "battery_unknown"
    property color  _iconColor: cfg.iconColor

    Component.onCompleted: { updateIcon() }

    /// Full battery-state matrix. `Absent` short-circuits everything; the
    /// charging branch is checked before the level ladder so a charging
    /// battery never reads as a discharging one; `Not charging` (on AC but
    /// paused/full) gets its own icon instead of being lumped in with Full.
    function updateIcon() {
        if (!root._present) {
            root._iconName = cfg.iconAbsent
            root._iconColor = cfg.iconAbsentColor
            return
        }

        if (root.status === "Unknown") {
            root._iconName = cfg.iconUnknown
            root._iconColor = cfg.iconColor
            return
        }

        if (root.status === "Full") {
            root._iconName = cfg.iconFullCharged
            root._iconColor = cfg.iconColor
            return
        }

        if (root.status === "Charging") {
            root._iconName = cfg.iconCharging
            root._iconColor = cfg.iconColor
            return
        }

        if (root.status === "Not charging") {
            root._iconName = cfg.iconNotCharging
            root._iconColor = cfg.iconColor
            return
        }

        // Discharging ladder
        const p = root.percent
        if (p < 10) {
            root._iconName = cfg.iconCritical
            root._iconColor = cfg.iconColorCritical
        } else if (p < 20) {
            root._iconName = cfg.iconLow
            root._iconColor = cfg.iconLowColor
        } else if (p < 40) {
            root._iconName = cfg.iconMidLow
            root._iconColor = cfg.iconMidColor
        } else if (p < 60) {
            root._iconName = cfg.iconMid
            root._iconColor = cfg.iconColor
        } else if (p < 80) {
            root._iconName = cfg.iconMidHigh
            root._iconColor = cfg.iconHighColor
        } else if (p < 100) {
            root._iconName = cfg.iconHigh
            root._iconColor = cfg.iconColor
        } else {
            root._iconName = cfg.iconFull
            root._iconColor = cfg.iconColor
        }
    }

    /// macOS shows plain "23%" beside the icon for every state
    readonly property string _shortLabel: {
        if (!root._present) return ""
        return root.percent + "%"
    }

    readonly property string _detailLine: {
        if (!root._present) return "No battery detected"
        if (root.status === "Charging")     return "Charging on AC power"
        if (root.status === "Not charging") return "On AC, not charging"
        if (root.status === "Full")          return "Fully charged"
        if (root.status === "Unknown")       return "State unknown"
        return "Discharging"
    }

    // ── macOS face: "23% [icon]" — percent text left of the battery glyph ──
    Text {
        id: levelLabel
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        visible:        root._shortLabel !== ""
        text:           root._shortLabel
        font.family:    cfg.fontFamily
        font.pixelSize: 12
        color:          root._iconColor
    }

    Text {
        id: iconText
        anchors { left: levelLabel.right; leftMargin: 3; verticalCenter: parent.verticalCenter }
        text:           root._iconName
        font.family:    Settings.settingsUI.iconFont
        font.pixelSize: cfg.iconSize
        color:          root._iconColor
    }

    // ── Hover + popup ────────────────────────────────────────────────────
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onClicked: root.togglePopup()
    }

    // ── Slider MouseArea (needed for expand state) ───────────────────────
    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // ── Popup ─────────────────────────────────────────────────────────────
    property bool _popupOpen: false
    function togglePopup() { _popupOpen = !_popupOpen }
    function openPopup()   { _popupOpen = true }
    function closePopup()  { _popupOpen = false }

    PopupWindow {
        id: popup
        anchor.item: root
        anchor.gravity: Edges.Top
        anchor.edges: Edges.Bottom
        anchor.rect.x: Math.round((root.width - popup.implicitWidth) / 2)
        anchor.rect.y: -8
        visible: root._popupOpen
        grabFocus: true
        color: "transparent"
        implicitWidth: 200
        implicitHeight: 140

        property real t: root._popupOpen ? 1 : 0
        Behavior on t { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors { fill: parent; bottomMargin: 8 }
            radius: 12
            color:  cfg.panelBg
            border.color: cfg.panelBorder
            border.width: 1
            opacity: popup.t
            scale: 0.92 + popup.t * 0.08
            transformOrigin: Item.Bottom
        }

        Rectangle {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
            width: 10; height: 10; rotation: 45
            color: cfg.panelBg
            border.color: cfg.panelBorder
            border.width: 1
            opacity: popup.t
        }

        Text {
            id: popupTitle
            anchors { left: parent.left; top: parent.top; leftMargin: 12; topMargin: 12 }
            text:           root._present ? root._shortLabel : "No battery"
            font.family:    cfg.fontFamily
            font.pixelSize: 13
            font.bold:      true
            color:          Settings.settingsUI.textPrimary
        }

        Text {
            id: popupStatus
            anchors { left: parent.left; top: popupTitle.bottom; leftMargin: 12; topMargin: 6 }
            // ETA is only meaningful while discharging
            text:           (root._present && root.status === "Discharging")
                            ? root.timeRemaining : root._detailLine
            font.family:    cfg.fontFamily
            font.pixelSize: 11
            color:          Settings.settingsUI.textSecondary
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: popupStatus.bottom; topMargin: 6 }
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 4
            visible: root._present

            Row {
                spacing: 4
                Text { text: "•"; font.pixelSize: 10; color: cfg.panelBorder }
                Text {
                    text:    root._detailLine
                    font.family: cfg.fontFamily
                    font.pixelSize: 9
                    color:   root.status === "Discharging" ? cfg.iconColor : cfg.iconColorWarning
                }
            }

            Row {
                spacing: 4
                // Hidden when power_now is unavailable rather than showing a
                // fake "0.0 W"
                visible: root._present && root._powerNow > 0
                Text { text: "•"; font.pixelSize: 10; color: cfg.panelBorder }
                Text {
                    id: powerText
                    text:           root._present && root._powerNow > 0
                                    ? (root._powerNow / 1e6).toFixed(1) + " W"
                                    : ""
                    font.family:    cfg.fontFamily
                    font.pixelSize: 9
                    color:          Settings.settingsUI.textSecondary
                }
            }

            Row {
                spacing: 4
                visible: root.timeRemaining !== "--:--"
                Text { text: "•"; font.pixelSize: 10; color: cfg.panelBorder }
                Text {
                    id: etaText
                    text:           root.timeRemaining !== "--:--" ? "ETA: " + root.timeRemaining : ""
                    font.family:    cfg.fontFamily
                    font.pixelSize: 9
                    color:          Settings.settingsUI.textSecondary
                }
            }
        }

        Text {
            anchors { right: parent.right; bottom: parent.bottom; rightMargin: 12; bottomMargin: 12 }
            text:           "✕"
            font.family:    cfg.fontFamily
            font.pixelSize: 12
            color:          closeMouse.containsMouse ? Settings.settingsUI.textPrimary : Settings.settingsUI.textSecondary
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closePopup()
            }
        }
    }
}