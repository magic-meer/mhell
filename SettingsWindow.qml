import QtQuick
import Quickshell
import Quickshell.Io
import "settings/pages"
import "settings"

/**
 * SettingsWindow — the settings GUI.
 *
 * Open/close is controlled by:
 *   • `quickshell ipc call -p <path> toggleSettings`  (keybind / desktop entry)
 *   • Calling root.toggle() from QML
 *
 * Animation: the window scales+fades in from 0.92→1.0 on open,
 * reverses on close.  Pages slide horizontally between sections.
 */
FloatingWindow {
    id: win

    readonly property var cfg: Settings.settingsUI

    title:   "Settings"
    visible: false

    implicitWidth:  cfg.windowWidth
    implicitHeight: cfg.windowHeight

    minimumSize.width:  600
    minimumSize.height: 400

    // Transparent so Niri blurs when cfg.useBlur is true
    color: cfg.useBlur ? "transparent" : cfg.windowBg

    // ── External close (e.g. Mod+Q kills the window via compositor) ───────
    // When visible flips to false without going through toggle(), stop any
    // running animations and reset state so the next open works cleanly.
    onVisibleChanged: if (!visible) _resetAnim()

    // Intercept compositor close request (Mod+Q) — hide instead of destroy
    onClosed: {
        _resetAnim()
        win.visible = false
    }

    // ── IPC handler — called by keybind / desktop entry ───────────────────
    IpcHandler {
        target: "toggleSettings"
        function toggleSettings() { win.toggle() }
    }

    function toggle() {
        if (_toggling) return
        _toggling = true
        debounceTimer.restart()

        if (win.visible) {
            content.opacity = 0
            content.scale   = 0.94
        } else {
            win.visible = true
            content.opacity = 1
            content.scale   = 1
        }
        // Restarted on open too, so a close already in flight can't hide the
        // window we just reopened — the onTriggered opacity check drops it.
        hideTimer.restart()
    }

    // Debounce guard — ignores repeated calls within 600ms (key repeat / double trigger)
    property bool _toggling: false

    // Snap everything back to the resting open state and cancel pending hides
    function _resetAnim() {
        hideTimer.stop()
        if (content) {
            content.opacity = 1
            content.scale   = 1
        }
        _toggling = false
        debounceTimer.stop()
    }

    Timer {
        id: debounceTimer
        interval: 600
        repeat:   false
        onTriggered: win._toggling = false
    }

    Timer {
        id: hideTimer
        interval: cfg.animDuration
        repeat:   false
        onTriggered: if (win.visible && content.opacity < 1) win.visible = false
    }

    // ── Root content ──────────────────────────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center

        Behavior on opacity { NumberAnimation { duration: cfg.animDuration; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: cfg.animDuration; easing.type: Easing.OutCubic } }

        // Window background (when not using Niri blur)
        Rectangle {
            anchors.fill: parent
            color:        cfg.useBlur ? Qt.rgba(0, 0, 0, 0.35) : cfg.windowBg
            radius:       12
            border.color: Qt.rgba(1, 1, 1, 0.07)
            border.width: 1
        }

        // ── Sidebar ───────────────────────────────────────────────────────
        SettingsSidebar {
            id: sidebar
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: cfg.sidebarWidth
            onPageChanged: index => pageStack.switchTo(index)
        }

        // Sidebar/content divider
        Rectangle {
            anchors { left: sidebar.right; top: parent.top; bottom: parent.bottom }
            width: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        // ── Page stack ────────────────────────────────────────────────────
        Item {
            id: pageStack
            anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: parent.top; bottom: parent.bottom }
            clip: true

            property int currentIndex: 0

            // Pages — all loaded, visibility managed manually by switchTo
            PageBar        { id: p0; anchors.fill: parent }
            PageWorkspaces { id: p1; anchors.fill: parent; visible: false }
            PageClock      { id: p2; anchors.fill: parent; visible: false }
            PageVolume     { id: p3; anchors.fill: parent; visible: false }
            PageBrightness { id: p4; anchors.fill: parent; visible: false }
            PageNetwork    { id: p5; anchors.fill: parent; visible: false }
            PageNotifications { id: p6; anchors.fill: parent; visible: false }

            function pageAt(i) {
                return [p0, p1, p2, p3, p4, p5, p6][i] || null
            }

            function switchTo(index) {
                if (index === currentIndex) return
                const outPage = pageAt(currentIndex)
                const inPage  = pageAt(index)
                const dir     = index > currentIndex ? 1 : -1

                // Reset incoming page position before animating it in
                inPage.x       = dir > 0 ? pageStack.width * 0.25 : -pageStack.width * 0.25
                inPage.opacity = 0
                inPage.visible = true

                _outAnim.direction = dir
                _outAnim.target    = outPage
                _inAnim.direction  = dir
                _inAnim.target     = inPage

                currentIndex        = index
                sidebar.currentPage = index
                transitionGroup.start()
            }

            ParallelAnimation {
                id: transitionGroup

                SequentialAnimation {
                    id: _outAnim
                    property var target:    p0
                    property int direction: 1
                    ParallelAnimation {
                        NumberAnimation {
                            target:   _outAnim.target
                            property: "x"
                            to:       _outAnim.direction < 0
                                        ? pageStack.width * 0.25
                                        : -pageStack.width * 0.25
                            duration: cfg.animDuration
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target:   _outAnim.target
                            property: "opacity"
                            to:       0
                            duration: cfg.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                    // Hide and reset the outgoing page after it animates out
                    PropertyAction { target: _outAnim.target; property: "visible"; value: false }
                    PropertyAction { target: _outAnim.target; property: "x";       value: 0 }
                    PropertyAction { target: _outAnim.target; property: "opacity"; value: 1 }
                }

                SequentialAnimation {
                    id: _inAnim
                    property var target:    p0
                    property int direction: 1
                    // switchTo already positioned and made the incoming page visible
                    ParallelAnimation {
                        NumberAnimation {
                            target:   _inAnim.target
                            property: "x"
                            to:       0
                            duration: cfg.animDuration
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target:   _inAnim.target
                            property: "opacity"
                            to:       1
                            duration: cfg.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        // ── Close button ──────────────────────────────────────────────────
        Item {
            anchors { top: parent.top; right: parent.right; topMargin: 10; rightMargin: 12 }
            width: 28; height: 28

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: closeBtn.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            Text {
                anchors.centerIn: parent
                text:           "󰅖"
                font.family:    cfg.fontFamily
                font.pixelSize: 14
                color:          closeBtn.containsMouse ? cfg.textPrimary : cfg.textSecondary
                Behavior on color { ColorAnimation { duration: 100 } }
            }

            MouseArea {
                id: closeBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked:    win.toggle()
            }
        }
    }
}
