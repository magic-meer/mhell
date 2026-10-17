import QtQuick
import Quickshell.Io

/**
 * Network — morphs from icon to icon+ssid on hover. Click opens iwgtk.
 */
Item {
    id: root

    readonly property var cfg: Settings.network

    property string state:  "checking"
    property string ssid:   ""
    /// "wifi" | "ethernet" | "bridge" | "lo" | ""
    property string devType: ""

    /// Full state machine. nmcli CONNECTIVITY only reports four values, but
    /// the real world has more: radio switched off, wired with no SSID, a
    /// captive portal (connected to the AP but no internet), and a poll that
    /// has not run yet. Each gets its own icon instead of collapsing into
    /// "disconnected".
    readonly property bool _airplane:  state === "airplane"
    readonly property bool _limited:   state === "limited"
    readonly property bool _wired:     state === "connected" && ssid.length === 0
    readonly property bool _connected: state === "connected" || state === "limited"

    readonly property string iconStr: {
        if (state === "connected")    return cfg.iconConnected
        if (state === "limited")      return cfg.iconLimited
        if (state === "disconnected") return cfg.iconDisconnected
        if (state === "airplane")     return cfg.iconAirplane
        if (state === "checking")     return cfg.iconChecking
        return cfg.iconUnknown
    }

    readonly property color iconColor: {
        if (state === "connected")    return cfg.colorConnected
        if (state === "limited")      return cfg.colorLimited
        if (state === "disconnected") return cfg.colorDisconnected
        if (state === "airplane")     return cfg.colorAirplane
        if (state === "checking")     return cfg.colorUnknown
        return cfg.colorUnknown
    }

    readonly property string displayText: {
        if (state === "connected")    return ssid.length > 0 ? ssid : (devType === "ethernet" ? "Wired" : "Connected")
        if (state === "limited")      return ssid.length > 0 ? ssid + " (limited)" : "Limited"
        if (state === "disconnected") return "No network"
        if (state === "airplane")     return "Wi-Fi off"
        if (state === "checking")     return "Checking…"
        return "Unknown"
    }

    // ── Poll ──────────────────────────────────────────────────────────────
    // One probe emits a single delimited line: conn|radio|devtype|ssid.
// Doing it in one shell rather than several concurrent Process objects
// avoids a race between the connectivity read and the SSID read.
    Process {
        id: pollProc
        running: false
        stdout: StdioCollector { onStreamFinished: root._ingest(text) }
    }

    function _probe() {
        pollProc.command = ["bash", "-c",
            'conn=$(nmcli -t -f CONNECTIVITY g 2>/dev/null);' +
            'radio=$(nmcli -t -f WIFI radio 2>/dev/null);' +
            'dev=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep -vE "^(lo|br-|docker|veth|tun)" | head -1);' +
            'type=$(echo "$dev" | cut -d: -f2);' +
            'state=$(echo "$dev" | cut -d: -f3 | cut -d" " -f1);' +
            'ssid="";' +
            'if [ "$type" = "wifi" ] && [ "$state" = "connected" ]; then' +
            '  ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep "^yes" | head -1 | cut -d: -f2);' +
            'fi;' +
            'echo "$conn|$radio|$type|$ssid"'
        ]
        pollProc.running = true
    }

    function _ingest(out) {
        const p = String(out || "").trim().split("|").map(s => s.trim())
        const conn  = (p[0] || "").toLowerCase()
        const radio = (p[1] || "").toLowerCase()
        const devTyp = p[2] || ""
        const devSsid = p[3] || ""

        root.devType = devTyp
        root.ssid    = devSsid

        if (radio.startsWith("disabled") || radio === "missing") root.state = "airplane"
        else if (conn === "full")                            root.state = "connected"
        else if (conn === "limited" || conn === "portal")     root.state = "limited"
        else if (conn === "none")                             root.state = "disconnected"
        else                                                  root.state = "unknown"
    }

    Timer {
        interval: cfg.pollInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root._probe()
    }
    // Only launch the GUI for states where there is something to configure;
    // a disconnected or radio-off link has no UI worth showing.
    Process { id: iwgtkProc; command: ["iwgtk"] }

    function _canOpenGui() {
        return root._connected || root.state === "unknown"
    }

    // ── Expand state ──────────────────────────────────────────────────────
    property bool expanded: mouse.containsMouse

    property real _exp: 0.0
    Behavior on _exp { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    onExpandedChanged: _exp = expanded ? 1.0 : 0.0

    readonly property real _textW:     Math.min(120, ssidMetrics.width + 8)
    readonly property real _collapsedW: cfg.iconSize + 4
    readonly property real _expandedW:  cfg.iconSize + 4 + _textW

    implicitWidth:  _collapsedW + (_expandedW - _collapsedW) * _exp
    implicitHeight: Settings.bar.height

    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    TextMetrics { id: ssidMetrics; font.family: cfg.fontFamily; font.pixelSize: 12; text: root.displayText }

    // ── Pill background ───────────────────────────────────────────────────
    Rectangle {
        anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
        radius:  height / 2
        color:   Qt.rgba(1, 1, 1, 0.07 * root._exp)
        border.color: Qt.rgba(1, 1, 1, 0.10 * root._exp)
        border.width: 1
        Behavior on color { ColorAnimation { duration: 180 } }
    }

    // ── Icon ──────────────────────────────────────────────────────────────
    Text {
        id: netIcon
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        text:           root.iconStr
        font.family:    Settings.settingsUI.iconFont
        font.pixelSize: cfg.iconSize
        color:          root.iconColor
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // ── SSID label (slides in) ─────────────────────────────────────────────
    Text {
        anchors {
            left:   netIcon.right; leftMargin: 6
            verticalCenter: parent.verticalCenter
        }
        text:           root.displayText
        font.family:    cfg.fontFamily
        font.pixelSize: 12
        color:          Qt.rgba(1, 1, 1, 0.80 * root._exp)
        clip:           true
        width:          root._textW * root._exp
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    // ── Hover + click ─────────────────────────────────────────────────────
    scale: cfg.hoverEnabled && mouse.containsMouse ? cfg.hoverScale : 1.0
    Behavior on scale { NumberAnimation { duration: cfg.hoverDuration; easing.type: Easing.OutCubic } }

MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled:      root._canOpenGui()
        cursorShape:  root._canOpenGui() ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked:    if (root._canOpenGui()) iwgtkProc.running = true
    }
}
