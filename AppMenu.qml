import QtQuick
import Quickshell
import Quickshell.Io

/**
 * AppMenu — macOS-style Apple menu. Clicking the icon opens a panel anchored
 * under the bar item with system actions (settings, restart, shutdown, …).
 *
 * Reads config exclusively from Settings.applemenu.
 */
Item {
    id: root

    readonly property var cfg: Settings.applemenu

    implicitWidth:  cfg.iconSize + 8
    implicitHeight: Settings.bar.height

    property bool _open: false

    function toggle() { _open = !_open }
    function close()  { _open = false }

    // ── Icon ────────────────────────────────────────────────────────────────
    Loader {
        id: iconWrap
        anchors.centerIn: parent
        sourceComponent: Settings.isIconPath(cfg.icon) ? imgIconComp : txtIconComp
        scale: hit.containsMouse || root._open ? 1.12 : 1.0
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
    }

    Component {
        id: imgIconComp
        Image {
            source: Qt.resolvedUrl(cfg.icon)
            sourceSize: Qt.size(38, 38)
            width: cfg.iconSize; height: cfg.iconSize
            asynchronous: true
        }
    }

    Component {
        id: txtIconComp
        Text {
            text: cfg.icon
            font.family:    Settings.settingsUI.iconFont
            font.pixelSize: cfg.iconSize
            color:          cfg.iconColor
        }
    }

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
    }

    // Close the panel when focus moves away (niri reports focus changes)
    Connections {
        target: NiriIpc
        function onFocusMoved() { root.close() }
    }

    // ── Panel: grows out of the icon, sized to its content ──────────────────
    PopupWindow {
        id: panel
        anchor.item:    root
        anchor.gravity: Edges.Top
        anchor.edges:   Edges.Bottom
        anchor.rect.x:  Math.round((root.width - panel.implicitWidth) / 2)
        anchor.rect.y:  -8
        visible:        root._open
        grabFocus:      true
        color:          "transparent"
        implicitWidth:  cfg.panelWidth
        implicitHeight: panelContent.implicitHeight + 28

        property real t: root._open ? 1 : 0
        Behavior on t { NumberAnimation { duration: cfg.animDuration; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors { fill: parent; bottomMargin: 8 }
            radius: 12
            color:  cfg.panelBg
            border.color: cfg.panelBorder
            border.width: 1
            opacity: panel.t
            scale: 0.92 + panel.t * 0.08
            transformOrigin: Item.Bottom
        }

        Column {
            id: panelContent
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom }
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 14
            anchors.bottomMargin: 14
            spacing: 10

            // Header
            Row {
                id: headerRow
                height: 36
                spacing: 10

                Text {
                    text: "Quickshell"
                    font.family: cfg.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: Settings.settingsUI.textPrimary
                }

                Text {
                    text: "Tahoe Shell"
                    font.family: cfg.fontFamily
                    font.pixelSize: 10
                    color: Settings.settingsUI.textSecondary
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Qt.rgba(1, 1, 1, 0.10)
            }

            // Menu items
            Column {
                width: parent.width
                spacing: 2
                Repeater {
                    model: root.items

                    delegate: Item {
                        width: parent.width
                        height: 34

                        Rectangle {
                            id: hoverBg
                            anchors.fill: parent
                            color: hover.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                            radius: 6
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            text: modelData.label
                            font.family: cfg.fontFamily
                            font.pixelSize: 12
                            color: hover.containsMouse ? Settings.settingsUI.accentColor : Settings.settingsUI.textPrimary
                        }

                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                modelData.action()
                                root.close()
                            }
                        }
                    }
                }
            }
        }

        // Caret pointing back at the icon
        Rectangle {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
            width: 10; height: 10; rotation: 45
            color: cfg.panelBg
            border.color: cfg.panelBorder
            border.width: 1
            opacity: panel.t
        }
    }

    // ── Menu item definitions ───────────────────────────────────────────────
    // Each item: { label, action() }. Kept minimal so the user can extend via
    // Settings.applemenu in future. Actions shell out via Process for now.
    readonly property var items: [
        { label: "System Settings…", action: function() { shellProc.command = ["quickshell", "-c", "shell", "ipc", "call", "toggleSettings", "toggleSettings"]; shellProc.running = true } },
        { label: "Restart Shell",    action: function() { shellProc.command = ["pkill", "-x", "quickshell"]; shellProc.running = true } },
        { label: "Lock Screen",      action: function() { lockProc.command = ["swaylock"]; lockProc.running = true } },
        { label: "Sleep",            action: function() { sysProc.command = ["systemctl", "suspend"]; sysProc.running = true } },
        { label: "Restart",          action: function() { sysProc.command = ["systemctl", "reboot"]; sysProc.running = true } },
        { label: "Shut Down",        action: function() { sysProc.command = ["systemctl", "poweroff"]; sysProc.running = true } },
    ]

    Process { id: shellProc }
    Process { id: lockProc }
    Process { id: sysProc }
}
