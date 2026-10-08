import QtQuick
import Quickshell

/**
 * NotifIndicator — bell icon in the bar; clicking it turns the button into its
 * own panel, anchored under the bell and sized to its content. New
 * notifications raise a toast in the same spot. Both are popups sized to their
 * content — never a fullscreen surface (niri blurs the overlay layer, so a
 * fullscreen window blurs the whole monitor).
 */
Item {
    id: root

    readonly property var cfg: Settings.notifications
    implicitWidth:  cfg.iconSize + 8
    implicitHeight: Settings.bar.height

    property bool _open: false

    // The bar window spans the whole screen, so anchoring to its content item
    // and offsetting from its right edge lines the toast up with the bar's
    // right margin — no screen-size guessing.
    readonly property var _host: root.Window.window ? root.Window.window.contentItem : null

    function toggle()    { _open = !_open; Notifications._panelOpen = _open }
    function close()     { _open = false;    Notifications._panelOpen = false }
    function openPanel() { _open = true;     Notifications._panelOpen = true }

    // ── Bell ──────────────────────────────────────────────────────────────
    Text {
        id: bell
        anchors.centerIn: parent
        text:           cfg.iconBell
        font.family:    cfg.fontFamily
        font.pixelSize: cfg.iconSize
        color:          Notifications.count > 0 ? cfg.iconColorActive : cfg.iconColor
        scale: hit.containsMouse || root._open ? 1.18 : 1.0
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        visible: Notifications.count > 0
        height: 12; width: Math.max(12, blText.implicitWidth + 6); radius: 6
        color:  cfg.badgeColor
        anchors { right: bell.right; rightMargin: -4; top: bell.top; topMargin: -4 }
        Text {
            id: blText
            anchors.centerIn: parent
            text:           Notifications.count > 9 ? "9+" : String(Notifications.count)
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
        onClicked: root.toggle()
    }

    // Clicking any other window closes the panel (niri reports focus changes)
    Connections {
        target: NiriIpc
        function onFocusMoved() { root.close() }
    }

    // ── Panel: grows out of the bell, sized to its content ────────────────
    PopupWindow {
        id: panel
        anchor.item:    root
        anchor.gravity: Edges.Top
        anchor.edges:   Edges.Bottom
        anchor.rect.x:  Math.round((root.width - panel.implicitWidth) / 2)
        anchor.rect.y:  -8
        visible:        root._open
        // Built-in click-away: the compositor dismisses the popup and flips
        // `visible` to false on any click outside it
        grabFocus:      true
        color:          "transparent"
        implicitWidth:  cfg.panelWidth
        implicitHeight: Notifications.count > 0
                        ? 40 + Math.min(Notifications.count, cfg.maxItems) * cfg.rowHeight
                        : 92

        property real t: root._open ? 1 : 0
        Behavior on t { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

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

        // Caret pointing back at the bell
        Rectangle {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
            width: 10; height: 10; rotation: 45
            color: cfg.panelBg
            border.color: cfg.panelBorder
            border.width: 1
            opacity: panel.t
        }

        Text {
            id: titleText
            anchors { left: parent.left; top: parent.top; leftMargin: 14; topMargin: 12 }
            text:           "Notifications (" + Notifications.count + ")"
            font.family:    cfg.fontFamily
            font.pixelSize: 13
            font.bold:      true
            color:          Settings.settingsUI.textPrimary
        }

        Text {
            id: closeText
            anchors { right: parent.right; top: parent.top; rightMargin: 12; topMargin: 12 }
            text:           "✕"
            font.family:    cfg.fontFamily
            font.pixelSize: 13
            color:          closeMouse.containsMouse ? Settings.settingsUI.textPrimary : Settings.settingsUI.textSecondary
            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }

        Text {
            id: clearText
            visible: Notifications.count > 0
            anchors { right: closeText.left; top: parent.top; rightMargin: 14; topMargin: 13 }
            text:           "Clear all"
            font.family:    cfg.fontFamily
            font.pixelSize: 11
            color:          clearMouse.containsMouse ? Settings.settingsUI.accentColor : Settings.settingsUI.textSecondary
            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifications.dismissAll()
            }
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: titleText.bottom; topMargin: 8 }
            anchors.leftMargin: 14
            anchors.rightMargin: 14

            Repeater {
                model: Notifications.count > cfg.maxItems
                       ? Notifications.list.slice(0, cfg.maxItems)
                       : Notifications.list

                delegate: Item {
                    width:  cfg.panelWidth - 28
                    height: cfg.rowHeight

                    property var n: modelData

                    Rectangle {
                        id: dismissHit
                        width: 18; height: 18; radius: 9
                        anchors { right: parent.right; top: parent.top; topMargin: 2 }
                        color: dismissMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text:           "✕"
                            font.family:    cfg.fontFamily
                            font.pixelSize: 11
                            color:          Settings.settingsUI.textSecondary
                        }
                        MouseArea {
                            id: dismissMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (n) n.dismiss()
                        }
                    }

                    Column {
                        anchors { left: parent.left; top: parent.top; topMargin: 3; right: dismissHit.left; rightMargin: 6 }
                        spacing: 2

                        Text {
                            width:  parent.width
                            text:   n ? n.appName : ""
                            font.family:    cfg.fontFamily
                            font.pixelSize: 9
                            color:          Settings.settingsUI.textDisabled
                            elide: Text.ElideRight
                        }
                        Text {
                            width:  parent.width
                            text:   n ? n.summary : ""
                            font.family:    cfg.fontFamily
                            font.pixelSize: 12
                            font.bold:      true
                            color:          Settings.settingsUI.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            width:  parent.width
                            text:   n ? n.body : ""
                            font.family:    cfg.fontFamily
                            font.pixelSize: 11
                            color:          Settings.settingsUI.textSecondary
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: Notifications.count === 0
            text:           "No notifications"
            font.family:    cfg.fontFamily
            font.pixelSize: 12
            color:          Settings.settingsUI.textDisabled
        }
    }

    // ── Toast: same spot, sized to its content, auto-hides ─────────────────
    PopupWindow {
        id: toastWin
        readonly property var n: Notifications.toast

        anchor.item:    root._host
        anchor.gravity: Edges.Top
        anchor.edges:   Edges.Bottom
        anchor.rect.x:  root._host
                        ? Math.round(root._host.width - Settings.bar.paddingSides - card.implicitWidth)
                        : 0
        anchor.rect.y:  -8
        visible:        n !== null
        color:          "transparent"
        implicitWidth:  card.implicitWidth
        implicitHeight: card.implicitHeight

        property real t: n !== null ? 1 : 0
        Behavior on t { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        // One card that slides and fades as a whole — text included
        Item {
            id: card
            width:  cfg.panelWidth
            implicitHeight: toastCol.implicitHeight + 24

            x: (1 - toastWin.t) * 60
            opacity: toastWin.t

            Rectangle {
                anchors { fill: parent; bottomMargin: 6 }
                radius: 12
                color:  cfg.panelBg
                border.color: cfg.panelBorder
                border.width: 1
            }

            Column {
                id: toastCol
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 12 }
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 3

                Text {
                    width:  parent.width
                    text:           toastWin.n ? toastWin.n.appName : ""
                    font.family:    cfg.fontFamily
                    font.pixelSize: 9
                    color:          cfg.badgeColor
                    elide: Text.ElideRight
                }
                Text {
                    width:  parent.width
                    text:           toastWin.n ? toastWin.n.summary : ""
                    font.family:    cfg.fontFamily
                    font.pixelSize: 12
                    font.bold:      true
                    color:          Settings.settingsUI.textPrimary
                    elide: Text.ElideRight
                }
                Text {
                    width:  parent.width
                    text:           toastWin.n ? toastWin.n.body : ""
                    font.family:    cfg.fontFamily
                    font.pixelSize: 11
                    color:          Settings.settingsUI.textSecondary
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            // Click the toast → open the list
            MouseArea {
                anchors.fill: parent
                onClicked: { Notifications.clearToast(); root.openPanel() }
            }
        }

        Timer {
            id: toastTimer
            interval: cfg.toastDuration
            repeat: false
            onTriggered: Notifications.clearToast()
        }
        onNChanged: if (n !== null) toastTimer.restart()
    }
}
