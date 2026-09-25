pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * NiriIpc — subscribes to `niri msg -j event-stream`.
 *
 * Uses a single persistent Process + SplitParser (one line = one JSON event).
 * No polling — Niri pushes all state changes to us.
 *
 * Exposed:
 *   workspaces  — sorted list of workspace objects (by idx)
 *   windows     — map of window id → window object
 */
Singleton {
    id: root

    // ── Public state ──────────────────────────────────────────────────────
    property var workspaces: []
    property var windows: ({})

    // ── Event-stream process ──────────────────────────────────────────────
    Process {
        id: eventStream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => root._handleEvent(line)
        }

        onExited: (code, status) => reconnectTimer.start()
    }

    Timer {
        id: reconnectTimer
        interval: 2000
        repeat: false
        onTriggered: eventStream.running = true
    }

    // ── Event handler ─────────────────────────────────────────────────────
    function _handleEvent(line) {
        const trimmed = line.trim()
        if (trimmed.length === 0) return

        let evt
        try {
            evt = JSON.parse(trimmed)
        } catch (e) {
            return
        }

        if (evt.WorkspacesChanged) {
            const sorted = evt.WorkspacesChanged.workspaces.slice()
            sorted.sort(function(a, b) { return a.idx - b.idx })
            root.workspaces = sorted

        } else if (evt.WindowsChanged) {
            const map = {}
            for (let i = 0; i < evt.WindowsChanged.windows.length; i++) {
                const w = evt.WindowsChanged.windows[i]
                map[w.id] = w
            }
            root.windows = map

        } else if (evt.WorkspaceActivated) {
            // Partial update: flip is_active/is_focused without a full reload
            const activatedId = evt.WorkspaceActivated.id
            const focused = evt.WorkspaceActivated.focused

            // Find which output the activated workspace belongs to
            let output = null
            for (let i = 0; i < root.workspaces.length; i++) {
                if (root.workspaces[i].id === activatedId) {
                    output = root.workspaces[i].output
                    break
                }
            }

            const updated = []
            for (let i = 0; i < root.workspaces.length; i++) {
                const ws = root.workspaces[i]
                // Use Object.assign to copy without spread operator
                const copy = Object.assign({}, ws)
                if (output !== null && ws.output === output) {
                    copy.is_active = (ws.id === activatedId)
                }
                if (focused) {
                    copy.is_focused = (ws.id === activatedId)
                }
                updated.push(copy)
            }
            root.workspaces = updated
        }
    }
}
