import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * LauncherWindow — full-screen app launcher overlay.
 *
 * Reads .desktop files from XDG_DATA_DIRS, filters live as you type,
 * shows results in a grid. Launch with Enter or click.
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
    property var  _allApps:  []
    property var  _filtered: []
    property int  _selected: 0
    property bool _ready:    false   // apps loaded at least once
    property bool _debouncing: false

    readonly property int _cols: Math.max(1, Math.floor(contentArea.width / (itemW + itemGap)))
    readonly property int itemW:   160
    readonly property int itemH:   104
    readonly property int itemGap: 12

    // ── Open / close / toggle ─────────────────────────────────────────────
    function open() {
        if (visible) return
        visible = true
        searchField.text = ""
        searchField.forceActiveFocus()
        if (!_ready) _scanApps()
        else _applyFilter()
    }

    function close() {
        if (!visible) return
        visible = false
        searchField.text = ""
    }

    function toggle() {
        if (_debouncing) return
        _debouncing = true
        debounceTimer.restart()
        visible ? close() : open()
    }

    function _launchSelected() {
        if (_filtered.length === 0) return
        const idx = Math.max(0, Math.min(_selected, _filtered.length - 1))
        _launch(_filtered[idx])
    }

    function _moveCursor(delta) {
        const n = _filtered.length
        if (n === 0) return
        _selected = ((_selected + delta) % n + n) % n
        // Ensure selected item is visible
        const row = Math.floor(_selected / _cols)
        const itemTop = row * (itemH + itemGap)
        const itemBot = itemTop + itemH
        if (itemBot > gridFlick.contentY + gridFlick.height)
            gridFlick.contentY = itemBot - gridFlick.height + itemGap
        else if (itemTop < gridFlick.contentY)
            gridFlick.contentY = Math.max(0, itemTop - itemGap)
    }

    function _launch(app) {
        launchProc.command = ["bash", "-c", app.exec]
        launchProc.running = true
        close()
    }

    Timer {
        id: debounceTimer
        interval: 400
        repeat:   false
        onTriggered: win._debouncing = false
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
            // Deduplicate by name
            const seen = {}
            _allApps = _parsedApps.filter(a => {
                if (seen[a.name]) return false
                seen[a.name] = true
                return true
            })
            _ready = true
            _applyFilter()
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

        // Strip exec field codes
        exec = exec.replace(/%[uUfFdDnNickvm]/g, "").trim()
        if (terminal) exec = "foot -e " + exec

        _parsedApps.push({ name, exec, icon, keywords })
    }

    // ── Filtering ─────────────────────────────────────────────────────────
    function _applyFilter() {
        const q = searchField.text.toLowerCase().trim()
        const src = _allApps
        if (q === "") {
            _filtered = src.slice(0, 60)
        } else {
            _filtered = src.filter(a =>
                a.name.toLowerCase().includes(q) ||
                a.keywords.includes(q)
            )
        }
        _selected = 0
        gridFlick.contentY = 0
    }

    // ── Icon path resolver ────────────────────────────────────────────────
    function _iconPath(name) {
        if (!name || name === "") return ""
        if (name.startsWith("/"))  return name
        // Prefer SVG then PNG from hicolor theme, then pixmaps
        const bases = [
            "/run/current-system/sw/share/icons/hicolor/scalable/apps/" + name + ".svg",
            "/run/current-system/sw/share/icons/hicolor/48x48/apps/"    + name + ".png",
            "/etc/profiles/per-user/meher/share/icons/hicolor/scalable/apps/" + name + ".svg",
            "/etc/profiles/per-user/meher/share/icons/hicolor/48x48/apps/"    + name + ".png",
            "/run/current-system/sw/share/pixmaps/" + name + ".svg",
            "/run/current-system/sw/share/pixmaps/" + name + ".png",
        ]
        // Return first that might exist — Image will handle missing gracefully
        return bases[0]
    }

    // ── Keyboard ──────────────────────────────────────────────────────────
    // Key handler item — receives focus when launcher opens
    Item {
        id: keyReceiver
        anchors.fill: parent
        focus: win.visible

        Keys.onEscapePressed: win.close()
        Keys.onReturnPressed: win._launchSelected()
        Keys.onEnterPressed:  win._launchSelected()
        Keys.onUpPressed:     win._moveCursor(-win._cols)
        Keys.onDownPressed:   win._moveCursor(win._cols)
        Keys.onLeftPressed:   win._moveCursor(-1)
        Keys.onRightPressed:  win._moveCursor(1)
        Keys.onPressed: event => {
            if (event.text.length === 1 && !event.isAutoRepeat) {
                searchField.forceActiveFocus()
            }
        }
    }

    // ── UI ────────────────────────────────────────────────────────────────

    // Dimmed backdrop
    Rectangle {
        anchors.fill: parent
        color:        Qt.rgba(0, 0, 0, 0.60)
        opacity:      win.visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            onClicked:    win.close()
        }
    }

    // Center card
    Item {
        id: card
        anchors.centerIn: parent
        width:  Math.min(parent.width  * 0.72, 920)
        height: Math.min(parent.height * 0.80, 660)

        MouseArea { anchors.fill: parent }  // block backdrop clicks

        Rectangle {
            anchors.fill: parent
            radius:       16
            color:        Qt.rgba(0.06, 0.06, 0.09, 0.97)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1
        }

        // Search box
        Item {
            id: searchBar
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
            height: 50

            Rectangle {
                anchors.fill: parent
                radius:       12
                color:        Qt.rgba(1, 1, 1, 0.07)
                border.color: searchField.activeFocus
                    ? Qt.rgba(0.4, 0.6, 1.0, 0.70)
                    : Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                    text:           ""
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color:          Qt.rgba(1, 1, 1, 0.35)
                }

                TextInput {
                    id: searchField
                    anchors { left: parent.left; right: clearBtn.left; leftMargin: 46; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    font.family:    "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color:          Qt.rgba(1, 1, 1, 0.92)
                    selectionColor: Qt.rgba(0.4, 0.6, 1.0, 0.35)
                    clip:           true

                    property bool _ready: false
                    Component.onCompleted: _ready = true
                    onTextChanged: if (_ready) win._applyFilter()

                    Text {
                        visible:           searchField.text.length === 0
                        anchors.fill:      parent
                        text:              "Search applications…"
                        font:              searchField.font
                        color:             Qt.rgba(1, 1, 1, 0.22)
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Item {
                    id: clearBtn
                    visible: searchField.text.length > 0
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    width: 26; height: 26

                    Text {
                        anchors.centerIn: parent
                        text:           "󰅖"
                        font.family:    "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color:          clrMouse.containsMouse ? Qt.rgba(1,1,1,0.8) : Qt.rgba(1,1,1,0.30)
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                    MouseArea {
                        id: clrMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    searchField.text = ""
                    }
                }
            }
        }

        // Result count + loading hint
        Text {
            anchors { top: searchBar.bottom; left: parent.left; leftMargin: 24; topMargin: 8 }
            text: !win._ready
                ? "Loading apps…"
                : win._filtered.length === 0
                    ? "No results"
                    : win._filtered.length + " app" + (win._filtered.length === 1 ? "" : "s")
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            color:          Qt.rgba(1, 1, 1, 0.28)
        }

        // App grid
        Item {
            id: contentArea
            anchors {
                top:    searchBar.bottom
                left:   parent.left
                right:  parent.right
                bottom: parent.bottom
                topMargin:    28
                leftMargin:   12
                rightMargin:  12
                bottomMargin: 12
            }
            clip: true

            Flickable {
                id: gridFlick
                anchors.fill: parent
                contentHeight: appGrid.implicitHeight + 16
                clip:          true

                Grid {
                    id: appGrid
                    anchors { top: parent.top; left: parent.left; topMargin: 4; leftMargin: 4 }
                    columns:       win._cols
                    columnSpacing: win.itemGap
                    rowSpacing:    win.itemGap

                    Repeater {
                        model: win._filtered

                        delegate: Item {
                            id: appItem
                            required property var modelData
                            required property int index

                            width:  win.itemW
                            height: win.itemH

                            readonly property bool isSelected: win._selected === index

                            Rectangle {
                                anchors.fill: parent
                                radius:       12
                                color: appItem.isSelected
                                    ? Qt.rgba(0.4, 0.6, 1.0, 0.18)
                                    : hover.containsMouse
                                        ? Qt.rgba(1, 1, 1, 0.07)
                                        : Qt.rgba(1, 1, 1, 0.03)
                                border.color: appItem.isSelected
                                    ? Qt.rgba(0.4, 0.6, 1.0, 0.55)
                                    : Qt.rgba(1, 1, 1, 0.06)
                                border.width: 1
                                Behavior on color        { ColorAnimation { duration: 100 } }
                                Behavior on border.color { ColorAnimation { duration: 100 } }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing:          8

                                // Icon
                                Item {
                                    width: 44; height: 44
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Image {
                                        id: iconImg
                                        anchors.fill: parent
                                        source:       win._iconPath(appItem.modelData.icon)
                                        fillMode:     Image.PreserveAspectFit
                                        smooth:       true
                                        mipmap:       true
                                        visible:      status === Image.Ready
                                    }

                                    // Fallback letter
                                    Rectangle {
                                        anchors.fill:  parent
                                        visible:       iconImg.status !== Image.Ready
                                        radius:        10
                                        color:         Qt.rgba(0.4, 0.6, 1.0, 0.20)
                                        border.color:  Qt.rgba(0.4, 0.6, 1.0, 0.35)
                                        border.width:  1
                                        Text {
                                            anchors.centerIn: parent
                                            text:           appItem.modelData.name.charAt(0).toUpperCase()
                                            font.family:    "JetBrainsMono Nerd Font"
                                            font.pixelSize: 20
                                            font.weight:    Font.Bold
                                            color:          Qt.rgba(0.6, 0.75, 1.0, 0.9)
                                        }
                                    }
                                }

                                // Name
                                Text {
                                    width:          win.itemW - 16
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text:           appItem.modelData.name
                                    font.family:    "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    color:          appItem.isSelected
                                        ? Qt.rgba(1, 1, 1, 0.95)
                                        : Qt.rgba(1, 1, 1, 0.72)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide:          Text.ElideRight
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }

                            MouseArea {
                                id: hover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onEntered:    win._selected = index
                                onClicked:    win._launch(appItem.modelData)
                            }
                        }
                    }
                }
            }

            // Scroll bar
            Rectangle {
                anchors { right: parent.right; rightMargin: 2; top: parent.top; bottom: parent.bottom }
                width: 3; radius: 2; color: "transparent"
                Rectangle {
                    width: parent.width; radius: parent.radius
                    color: Qt.rgba(1, 1, 1, 0.18)
                    readonly property real ratio: gridFlick.height / Math.max(gridFlick.contentHeight, gridFlick.height)
                    readonly property real pos:   gridFlick.contentY / Math.max(gridFlick.contentHeight - gridFlick.height, 1)
                    height:  Math.max(24, parent.height * ratio)
                    y:       pos * (parent.height - height)
                    visible: gridFlick.contentHeight > gridFlick.height
                    opacity: gridFlick.moving ? 1.0 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}
