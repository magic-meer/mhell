import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * LauncherWindow — Spotlight-style app launcher.
 *
 * Animation:
 *   Open  → pill bar "circles out" from screen center (scale 0→1, opacity 0→1)
 *   Type  → results panel "drops" from the bottom of the bar (height 0→max)
 *           like a water droplet separating from the search pill
 *   Close → results retract into bar, bar collapses back to a point
 *
 * IPC: quickshell -c shell ipc call toggleLauncher toggleLauncher
 * Keybind: Mod+D / Mod+Space
 */
PanelWindow {
    id: win

    anchors.left:   true
    anchors.right:  true
    anchors.top:    true
    anchors.bottom: true
    exclusiveZone:  -1
    focusable:      true
    visible:        false
    color:          "transparent"

    // ── IPC ───────────────────────────────────────────────────────────────
    IpcHandler {
        target: "toggleLauncher"
        function toggleLauncher() { win.toggle() }
    }

    // ── State ─────────────────────────────────────────────────────────────
    property var  _allApps:    []
    property var  _filtered:   []
    property int  _selected:   0
    property bool _ready:      false
    property bool _debouncing: false

    // Animation phases
    property real _barScale:      0.0   // 0→1 bar open
    property real _barOpacity:    0.0
    property real _resultsHeight: 0.0   // 0→maxResultsH results drop
    property real _backdropOpacity: 0.0

    readonly property int barW:        620
    readonly property int barH:        58
    readonly property int maxResultsH: 440
    readonly property int resultItemH: 54
    readonly property int maxVisible:  7

    // ── Open / close / toggle ─────────────────────────────────────────────
    function open() {
        if (visible) return
        visible = true
        searchField.text = ""
        _selected    = 0
        if (!_ready) _scanApps()
        else _applyFilter()
        searchField.forceActiveFocus()
        _openAnim.start()
    }

    function close() {
        if (!visible) return
        _closeAnim.start()
    }

    function toggle() {
        if (_debouncing && !visible) return   // debounce only blocks re-open, not close
        _debouncing = true
        debounceTimer.restart()
        visible ? close() : open()
    }

    Timer {
        id: debounceTimer
        interval: 400
        repeat:   false
        onTriggered: win._debouncing = false
    }

    // ── Open animation: bar circles out from center ───────────────────────
    ParallelAnimation {
        id: _openAnim
        NumberAnimation { target: win; property: "_barScale";       from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
        NumberAnimation { target: win; property: "_barOpacity";     from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; property: "_backdropOpacity"; from: 0.0; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
    }

    // ── Close animation: results retract, bar collapses ───────────────────
    SequentialAnimation {
        id: _closeAnim
        // First retract results if showing
        NumberAnimation { target: win; property: "_resultsHeight"; to: 0; duration: 180; easing.type: Easing.InCubic }
        // Then collapse bar + fade backdrop
        ParallelAnimation {
            NumberAnimation { target: win; property: "_barScale";       to: 0.0; duration: 200; easing.type: Easing.InBack; easing.overshoot: 0.5 }
            NumberAnimation { target: win; property: "_barOpacity";     to: 0.0; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: win; property: "_backdropOpacity"; to: 0.0; duration: 200; easing.type: Easing.InCubic }
        }
        PropertyAction { target: win; property: "visible"; value: false }
        ScriptAction { script: { searchField.text = "" } }
    }

    // ── Results drop animation ────────────────────────────────────────────
    Behavior on _resultsHeight {
        enabled: win._barScale >= 0.9   // only animate after bar is open
        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }

    // ── Dimmed backdrop ───────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Qt.rgba(0, 0, 0, 0.45)
        opacity:      win._backdropOpacity
        MouseArea {
            anchors.fill: parent
            onClicked:    win.close()
        }
    }

    // ── Center stage ─────────────────────────────────────────────────────
    // Everything centered on screen
    Item {
        id: stage
        anchors.centerIn: parent
        width:  win.barW
        // Height grows as results drop in
        height: win.barH + win._resultsHeight
        transformOrigin: Item.Top

        // ── Search bar pill ───────────────────────────────────────────────
        Item {
            id: barPill
            width:  win.barW
            height: win.barH
            anchors.top: parent.top
            transformOrigin: Item.Center
            scale:   win._barScale
            opacity: win._barOpacity

            // Pill background
            Rectangle {
                anchors.fill: parent
                radius:       win.barH / 2
                color:        Qt.rgba(0.10, 0.10, 0.14, 0.96)
                border.color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1

                // Subtle inner glow at top
                Rectangle {
                    anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: 1; rightMargin: 1 }
                    height:      1
                    radius:      1
                    color:       Qt.rgba(1, 1, 1, 0.08)
                }
            }

            // Text input
            TextInput {
                id: searchField
                anchors {
                    left:            parent.left
                    right:           clearBtn.left
                    leftMargin:      32
                    rightMargin:     8
                    verticalCenter:  parent.verticalCenter
                }
                font.family:    "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color:          Qt.rgba(1, 1, 1, 0.92)
                selectionColor: Qt.rgba(0.4, 0.6, 1.0, 0.35)
                clip:           true

                property bool _ready: false
                Component.onCompleted: _ready = true

                Keys.onReturnPressed: win._launchSelected()
                Keys.onEnterPressed:  win._launchSelected()
                Keys.onEscapePressed: win.close()
                Keys.onUpPressed:     win._moveCursor(-1)
                Keys.onDownPressed:   win._moveCursor(1)
                Keys.onTabPressed:    win._moveCursor(1)

                onTextChanged: {
                    if (!_ready) return
                    win._applyFilter()
                    // Trigger results drop when text is entered
                    if (text.length > 0 && win._filtered.length > 0) {
                        win._resultsHeight = Math.min(
                            win._filtered.length * win.resultItemH,
                            win.maxResultsH
                        )
                    } else if (text.length === 0) {
                        win._resultsHeight = 0
                    }
                }

                // Placeholder
                Text {
                    visible:           searchField.text.length === 0
                    anchors.fill:      parent
                    text:              "Search…"
                    font:              searchField.font
                    color:             Qt.rgba(1, 1, 1, 0.20)
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Clear button
            Item {
                id: clearBtn
                visible: searchField.text.length > 0
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                width: 28; height: 28

                Rectangle {
                    anchors.centerIn: parent
                    width: 22; height: 22; radius: 11
                    color: clrMouse.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.07)
                    Behavior on color { ColorAnimation { duration: 80 } }
                }
                Text {
                    anchors.centerIn: parent
                    text:           "󰅖"
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color:          Qt.rgba(1, 1, 1, 0.50)
                }
                MouseArea {
                    id: clrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        searchField.text = ""
                        searchField.forceActiveFocus()
                    }
                }
            }
        }

        // ── Results panel — drops from bar bottom ─────────────────────────
        Item {
            id: resultsPanel
            anchors {
                top:   barPill.bottom
                topMargin: 8
                left:  parent.left
                right: parent.right
            }
            height: win._resultsHeight
            clip:   true
            visible: win._resultsHeight > 0
            opacity: win._barOpacity

            Rectangle {
                anchors.fill:   parent
                radius:         16
                color:          Qt.rgba(0.08, 0.08, 0.12, 0.97)
                border.color:   Qt.rgba(1, 1, 1, 0.09)
                border.width:   1

                // Connection nub between pill and results
                Rectangle {
                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                    width: 40; height: 2; radius: 1
                    color: Qt.rgba(1, 1, 1, 0.06)
                }
            }

            // Results list
            Flickable {
                id: resultsFlick
                anchors { fill: parent; topMargin: 4; bottomMargin: 4 }
                contentHeight: resultsList.implicitHeight
                clip:          true

                Column {
                    id: resultsList
                    anchors { left: parent.left; right: parent.right; leftMargin: 6; rightMargin: 6}
                    spacing: 2

                    Repeater {
                        model: win._filtered

                        delegate: Item {
                            id: resultItem
                            required property var modelData
                            required property int index

                            width:  parent.width
                            height: win.resultItemH

                            readonly property bool isSelected: win._selected === index

                            // Hover / selected background
                            Rectangle {
                                anchors { fill: parent; margins: 2 }
                                radius: 10
                                color: resultItem.isSelected
                                    ? Qt.rgba(0.4, 0.6, 1.0, 0.18)
                                    : rowMouse.containsMouse
                                        ? Qt.rgba(1, 1, 1, 0.06)
                                        : "transparent"
                                border.color: resultItem.isSelected ? Qt.rgba(0.4, 0.6, 1.0, 0.40) : "transparent"
                                border.width: 1
                                Behavior on color        { ColorAnimation { duration: 80 } }
                                Behavior on border.color { ColorAnimation { duration: 80 } }
                            }

                            Row {
                                anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
                                spacing: 14

                                // App icon
                                Item {
                                    width: 34; height: 34
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        id: rIconImg
                                        anchors.fill: parent
                                        source:       win._iconPath(resultItem.modelData.icon)
                                        fillMode:     Image.PreserveAspectFit
                                        smooth:       true
                                        mipmap:       true
                                        visible:      status === Image.Ready
                                    }
                                    Rectangle {
                                        anchors.fill:  parent
                                        visible:       rIconImg.status !== Image.Ready
                                        radius:        8
                                        color:         Qt.rgba(0.4, 0.6, 1.0, 0.18)
                                        border.color:  Qt.rgba(0.4, 0.6, 1.0, 0.30)
                                        border.width:  1
                                        Text {
                                            anchors.centerIn: parent
                                            text:           resultItem.modelData.name.charAt(0).toUpperCase()
                                            font.family:    "JetBrainsMono Nerd Font"
                                            font.pixelSize: 15
                                            font.weight:    Font.Bold
                                            color:          Qt.rgba(0.6, 0.75, 1.0, 0.85)
                                        }
                                    }
                                }

                                // App name
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:           resultItem.modelData.name
                                    font.family:    "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    font.weight:    resultItem.isSelected ? Font.Medium : Font.Normal
                                    color:          resultItem.isSelected
                                        ? Qt.rgba(1, 1, 1, 0.95)
                                        : Qt.rgba(1, 1, 1, 0.78)
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                }
                            }

                            // Arrow indicator when selected
                            Text {
                                visible: resultItem.isSelected
                                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                text:           "↵"
                                font.family:    "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                color:          Qt.rgba(0.4, 0.6, 1.0, 0.65)
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:    win._selected = index
                                onClicked:    win._launch(resultItem.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // ── App scanning ──────────────────────────────────────────────────────
    property var _pendingPaths: []
    property int _parseIdx:     0
    property var _parsedApps:   []

    function _scanApps() {
        findProc.running = true
    }

    Process {
        id: findProc
        command: ["bash", "-c",
            "find " +
            "/run/current-system/sw/share/applications " +
            "/etc/profiles/per-user/meher/share/applications " +
            "$HOME/.local/share/applications " +
            "/home/meher/.nix-profile/share/applications " +
            "-maxdepth 1 -name '*.desktop' 2>/dev/null | sort -u"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const paths = text.trim().split("\n").filter(p => p.length > 0)
                win._pendingPaths = paths
                win._parseIdx     = 0
                win._parsedApps   = []
                win._parseNext()
            }
        }
    }

    Process {
        id: readProc
        stdout: StdioCollector {
            onStreamFinished: {
                win._parseOneDesktop(text)
                win._parseIdx++
                win._parseNext()
            }
        }
    }

    Process { id: launchProc }

    function _parseNext() {
        if (_parseIdx >= _pendingPaths.length) {
            _parsedApps.sort((a, b) => a.name.localeCompare(b.name))
            const seen = {}
            _allApps = _parsedApps.filter(a => {
                if (seen[a.name]) return false
                seen[a.name] = true
                return true
            })
            _ready = true
            return
        }
        readProc.command = ["cat", _pendingPaths[_parseIdx]]
        readProc.running = true
    }

    function _parseOneDesktop(content) {
        if (!content.includes("Type=Application")) return
        if (content.includes("NoDisplay=true"))    return
        if (content.includes("Hidden=true"))       return

        const lines = content.split("\n")
        let name = "", exec = "", icon = "", keywords = "", terminal = false

        for (const line of lines) {
            if      (line.startsWith("Name=")     && name === "") name     = line.slice(5).trim()
            else if (line.startsWith("Exec="))                    exec     = line.slice(5).trim()
            else if (line.startsWith("Icon="))                    icon     = line.slice(5).trim()
            else if (line.startsWith("Keywords="))                keywords = line.slice(9).trim().toLowerCase()
            else if (line.startsWith("Terminal="))                terminal = line.slice(9).trim() === "true"
        }

        if (!name || !exec) return
        exec = exec.replace(/%[uUfFdDnNickvm]/g, "").trim()
        if (terminal) exec = "foot -e " + exec

        _parsedApps.push({ name, exec, icon, keywords })
    }

    function _applyFilter() {
        const q = searchField.text.toLowerCase().trim()
        if (q === "") {
            _filtered = []
        } else {
            // Prioritise prefix matches first, then includes
            const prefix  = _allApps.filter(a => a.name.toLowerCase().startsWith(q))
            const rest    = _allApps.filter(a =>
                !a.name.toLowerCase().startsWith(q) && (
                    a.name.toLowerCase().includes(q) || a.keywords.includes(q)
                )
            )
            _filtered = prefix.concat(rest).slice(0, maxVisible)
        }
        _selected = 0
    }

    function _launchSelected() {
        if (_filtered.length === 0) return
        _launch(_filtered[Math.max(0, Math.min(_selected, _filtered.length - 1))])
    }

    function _moveCursor(delta) {
        const n = _filtered.length
        if (n === 0) return
        _selected = ((_selected + delta) % n + n) % n
    }

    function _launch(app) {
        launchProc.command = ["bash", "-c", app.exec]
        launchProc.running = true
        close()
    }

    function _iconPath(name) {
        if (!name || name === "") return ""
        if (name.startsWith("/"))  return name
        return "/run/current-system/sw/share/icons/hicolor/scalable/apps/" + name + ".svg"
    }
}
