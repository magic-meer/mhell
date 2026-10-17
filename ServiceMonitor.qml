import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property var cfg: Settings.services
    implicitWidth:  cfg.iconSize + 8
    implicitHeight: Settings.bar.height

    property bool _open: false
    // Parenthesised: a bare {} initialiser parses as an empty JS block in
    // QML and evaluates to undefined, not an empty object.
    property var _statuses: ({})
    property var _scope: ({})

    /// Systemd ActiveState is not just active/inactive: a unit can also be
    /// activating, deactivating, reloading, failed, maintenance or "not-found"
    /// (the unit does not exist). `not-found` is tracked apart from `failed`
    /// because a typo'd unit name is a config bug, not a crash.
    readonly property int _failedCount: {
        let count = 0
        for (let i = 0; i < cfg.serviceList.length; i++) {
            const st = root._statuses[cfg.serviceList[i].name]
            // undefined = not polled yet, don't count it as down
            if (st === undefined) continue
            if (st !== "active" && st !== "activating" && st !== "reloading") count++
        }
        return count
    }

    readonly property int _missingCount: {
        let count = 0
        for (let i = 0; i < cfg.serviceList.length; i++) {
            if (root._statuses[cfg.serviceList[i].name] === "not-found") count++
        }
        return count
    }

    readonly property color _iconColor: {
        if (root._missingCount > 0) return cfg.iconColorWarning
        if (root._failedCount > 0)  return cfg.iconColorError
        return cfg.iconColor
    }

    /// Human-readable status for the list row. "not-found" is the only value
    /// worth translating; everything else is already a systemd word.
    function _statusLabel(name) {
        const st = root._statuses[name]
        if (st === undefined) return "checking..."
        if (st === "not-found")   return "no such unit"
        if (st === "deactivating") return "stopping"
        if (st === "maintenance")  return "in maintenance"
        return st
    }

    function _dotColor(name) {
        const st = root._statuses[name]
        if (st === undefined)          return Qt.rgba(1, 1, 1, 0.25)
        if (st === "active")           return Qt.rgba(0.3, 0.9, 0.4, 1.0)
        if (st === "failed")           return Qt.rgba(1.0, 0.35, 0.3, 1.0)
        if (st === "activating" || st === "reloading" || st === "deactivating")
                                         return Qt.rgba(1.0, 0.72, 0.2, 1.0)
        if (st === "not-found")        return Qt.rgba(1.0, 0.72, 0.2, 1.0)
        if (st === "maintenance")      return Qt.rgba(0.4, 0.6, 1.0, 1.0)
        // inactive: deliberately stopped, not an error
        return Qt.rgba(1, 1, 1, 0.25)
    }

    Timer {
        id: pollTimer
        interval: cfg.pollInterval
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root._checkServices()
    }

    Process {
        id: checkProc
        running: false
        stdout: StdioCollector { onStreamFinished: root._ingest(text, 1) }
    }

    // ponytail: user units first, system units fill the "inactive" gaps.
    Process {
        id: sysProc
        running: false
        stdout: StdioCollector { onStreamFinished: root._ingest(text, 2) }
    }

    property string _outUser: ""
    property string _outSys: ""
    property int    _got: 0

    function _units() {
        const u = []
        for (let i = 0; i < cfg.serviceList.length; i++) u.push(cfg.serviceList[i].name)
        return u
    }

    // "is-active" reports "inactive" for both stopped AND nonexistent units,
    // so ask for LoadState too and surface "not-found" honestly.
    function _showArgs() {
        return ["show"].concat(_units(), ["--no-legend", "-p", "Id", "-p", "LoadState", "-p", "ActiveState"])
    }

    function _unitKey(name) { return name.replace(/\.service$/, "") }

    // Keyed by unit name, not output order.
    function _parse(out) {
        const info = {}
        const blocks = String(out || "").split(/\n[ \t]*\n/)
        for (let i = 0; i < blocks.length; i++) {
            const kv = {}
            blocks[i].split("\n").forEach(line => {
                const eq = line.indexOf("=")
                if (eq > 0) kv[line.substring(0, eq)] = line.substring(eq + 1).trim()
            })
            if (!kv.Id) continue
            info[root._unitKey(kv.Id)] = {
                load:   kv.LoadState   || "unknown",
                active: kv.ActiveState || "unknown"
            }
        }
        return info
    }

    // Both scopes are queried concurrently, so merge only once both have
    // landed — merging as results arrive drops whichever finishes first.
    function _ingest(text, bit) {
        if (bit === 1) root._outUser = String(text || "")
        else root._outSys = String(text || "")
        root._got |= bit
        if ((root._got & 3) !== 3) return
        root._got = 0
        const u = root._parse(root._outUser)
        const s = root._parse(root._outSys)
        const statuses = {}
        const scope = {}
        for (let i = 0; i < cfg.serviceList.length; i++) {
            const name = cfg.serviceList[i].name
            const key = root._unitKey(name)
            const ui = u[key]
            const si = s[key]
            const pick = ui && ui.load !== "not-found" ? ui
                       : si && si.load !== "not-found" ? si
                       : null
            if (pick) {
                statuses[name] = pick.active
                scope[name] = ui === pick
            } else {
                statuses[name] = "not-found"
                scope[name] = true
            }
        }
        root._statuses = statuses
        root._scope = scope
    }

    function _checkServices() {
        if (checkProc.running || sysProc.running) return
        const units = _units()
        if (units.length === 0) { root._statuses = {}; return }
        root._outUser = ""
        root._outSys = ""
        root._got = 0
        const args = _showArgs()
        checkProc.exec(["systemctl", "--user"].concat(args))
        sysProc.exec(["systemctl"].concat(args))
    }

    function _runAction(name, action) {
        const proc = Qt.createQmlObject('import Quickshell.Io; Process {}', root)
        proc.exec(["systemctl"].concat(_scope[name] ? ["--user"] : [], [action, name]))
        pollTimer.restart()
    }

    Text {
        id: iconText
        anchors.centerIn: parent
        text:           cfg.icon
        font.family:    Settings.settingsUI.iconFont
        font.pixelSize: cfg.iconSize
        color:          root._iconColor
        scale: hit.containsMouse || root._open ? 1.18 : 1.0
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        visible: root._failedCount > 0
        height: 12; width: Math.max(12, blText.implicitWidth + 6); radius: 6
        color:  cfg.badgeColor
        anchors { right: iconText.right; rightMargin: -4; top: iconText.top; topMargin: -4 }
        Text {
            id: blText
            anchors.centerIn: parent
            text:           root._failedCount > 9 ? "9+" : String(root._failedCount)
            font.family:    cfg.fontFamily
            font.pixelSize: 8
            font.bold:      true
            color:          Qt.rgba(0, 0, 0, 0.85)
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root._open = !root._open
    }

    PopupWindow {
        id: backdrop
        anchor.item: root
        anchor.gravity: Edges.Top
        anchor.edges: Edges.Bottom
        anchor.rect.x: Math.round((root.width - 4000) / 2)
        anchor.rect.y: Math.round((root.height - 3000) / 2 - Settings.bar.height)
        color: "transparent"
        implicitWidth:  4000
        implicitHeight: 3000
        visible: root._open
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            MouseArea {
                anchors.fill: parent
                onClicked: root._open = false
            }
        }
    }

    PopupWindow {
        id: panel
        anchor.item:    root
        anchor.gravity: Edges.Top
        anchor.edges:   Edges.Bottom
        anchor.rect.y:  -6
        visible:       root._open
        color:         "transparent"
        implicitWidth:  cfg.panelWidth
        implicitHeight: head.height + 12 + listView.implicitHeight + 8

        property real _openT: root._open ? 1 : 0
        Behavior on _openT { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            id: caret
            width: 10; height: 10; rotation: 45
            anchors { top: panelBody.top; horizontalCenter: parent.horizontalCenter }
            color: cfg.panelBg
            border.color: cfg.panelBorder; border.width: 1
            opacity: panel._openT
            scale:  0.8 + panel._openT * 0.2
        }

        Rectangle {
            id: panelBody
            anchors { fill: parent; topMargin: 6 }
            radius: 10
            color:  cfg.panelBg
            border.color: cfg.panelBorder
            border.width: 1
            opacity: panel._openT
            transform: Scale {
                origin.x: panelBody.width / 2
                origin.y: 0
                xScale: 0.85 + panel._openT * 0.15
                yScale: 0.85 + panel._openT * 0.15
            }
        }

        Item {
            anchors.fill: parent
            opacity: panel._openT

            Row {
                id: head
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 12; topMargin: 10 }
                spacing: 8

                Text {
                    text: {
                        // Surface missing units separately from failed ones —
                        // they need different fixes.
                        const total = cfg.serviceList.length
                        const miss  = root._missingCount
                        let s = "Services (" + root._failedCount + "/" + total + " down)"
                        if (miss > 0) s += " · " + miss + " missing"
                        return s
                    }
                    font.family:    cfg.fontFamily
                    font.pixelSize: 13
                    font.bold:      true
                    color:          Settings.settingsUI.textPrimary
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { width: Math.max(0, parent.width - headText.implicitWidth - closeText.implicitWidth - parent.spacing * 2 - 50); height: 1 }
                Text {
                    id: headText
                    text:           "Refresh"
                    font.family:    cfg.fontFamily
                    font.pixelSize: 11
                    color:          refreshMouse.containsMouse ? Settings.settingsUI.accentColor : Settings.settingsUI.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._checkServices()
                    }
                }
                Text {
                    id: closeText
                    text:           "✕"
                    font.family:    cfg.fontFamily
                    font.pixelSize: 12
                    color:          closeHover.containsMouse ? Settings.settingsUI.textPrimary : Settings.settingsUI.textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._open = false
                    }
                }
            }

            ListView {
                id: listView
                anchors { left: parent.left; right: parent.right; top: head.bottom; topMargin: 6 }
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                clip: true
                model: cfg.serviceList
                implicitHeight: cfg.serviceList.length > 0 ? cfg.serviceList.length * 48 : 44

                delegate: Item {
                    width: listView.width
                    height: 48

                    property var svc: modelData

                    Row {
                        anchors.fill: parent
                        spacing: 8

                        Rectangle {
                            width: 8; height: 8; radius: 4
                            anchors.verticalCenter: parent.verticalCenter
                            color: root._dotColor(svc.name)
                        }

                        Column {
                            width: parent.width - 120
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text:           svc.displayName || svc.name
                                font.family:    cfg.fontFamily
                                font.pixelSize: 12
                                font.bold:      true
                                color:          Settings.settingsUI.textPrimary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: root._statusLabel(svc.name)
                                font.family:    cfg.fontFamily
                                font.pixelSize: 10
                                color:          Settings.settingsUI.textSecondary
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        Item { width: Math.max(0, parent.width - 200); height: 1 }

                        Text {
                            text:           "▶"
                            font.family:    cfg.fontFamily
                            font.pixelSize: 11
                            color:          startMouse.containsMouse ? Qt.rgba(0.3, 0.9, 0.4, 1.0) : Settings.settingsUI.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                            MouseArea {
                                id: startMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root._runAction(svc.name, "start")
                            }
                        }
                        Text {
                            text:           "■"
                            font.family:    cfg.fontFamily
                            font.pixelSize: 11
                            color:          stopMouse.containsMouse ? Qt.rgba(1.0, 0.35, 0.3, 1.0) : Settings.settingsUI.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                            MouseArea {
                                id: stopMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root._runAction(svc.name, "stop")
                            }
                        }
                        Text {
                            text:           "↻"
                            font.family:    cfg.fontFamily
                            font.pixelSize: 11
                            color:          restartMouse.containsMouse ? Settings.settingsUI.accentColor : Settings.settingsUI.textSecondary
                            anchors.verticalCenter: parent.verticalCenter
                            MouseArea {
                                id: restartMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root._runAction(svc.name, "restart")
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: cfg.serviceList.length === 0
                    text:           "No services configured"
                    font.family:    cfg.fontFamily
                    font.pixelSize: 12
                    color:          Settings.settingsUI.textDisabled
                }
            }
        }
    }
}
