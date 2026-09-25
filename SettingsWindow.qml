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
    onVisibleChanged: {
        if (!visible) {
            openAnim.stop()
            closeAnim.stop()
            if (content) {
                content.opacity = 1
                content.scale   = 1
            }
            _toggling = false
            debounceTimer.stop()
        }
    }

    // Intercept compositor close request (Mod+Q) — hide instead of destroy
    onClosed: {
        openAnim.stop()
        closeAnim.stop()
        if (content) {
            content.opacity = 1
            content.scale   = 1
        }
        _toggling    = false
        win.visible  = false
        debounceTimer.stop()
    }

    // ── IPC handler — called by keybind / desktop entry ───────────────────
    IpcHandler {
        target: "toggleSettings"
        function toggleSettings() { win.toggle() }
    }

    // Debounce guard — ignores repeated calls within 600ms (key repeat / double trigger)
    property bool _toggling: false

    function toggle() {
        if (_toggling) return
        _toggling = true
        debounceTimer.restart()

        if (win.visible) {
            closeAnim.start()
        } else {
            win.visible = true
            openAnim.start()
        }
    }

    Timer {
        id: debounceTimer
        interval: 600
        repeat:   false
        onTriggered: win._toggling = false
    }

    // ── Open animation ────────────────────────────────────────────────────
    SequentialAnimation {
        id: openAnim
        PropertyAction  { target: content; property: "opacity"; value: 0 }
        PropertyAction  { target: content; property: "scale";   value: 0.94 }
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 1;    duration: cfg.animDuration; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "scale";   to: 1.0;  duration: cfg.animDuration; easing.type: Easing.OutCubic }
        }
    }

    // ── Close animation ───────────────────────────────────────────────────
    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: content; property: "opacity"; to: 0;    duration: cfg.animDuration; easing.type: Easing.InCubic }
            NumberAnimation { target: content; property: "scale";   to: 0.94; duration: cfg.animDuration; easing.type: Easing.InCubic }
        }
        PropertyAction { target: win; property: "visible"; value: false }
    }

    // ── Root content ──────────────────────────────────────────────────────
    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center

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

            // Pages — declared first so they exist when switchTo is called
            PageBar        { id: p0; anchors.fill: parent; visible: pageStack.currentIndex === 0 }
            PageWorkspaces { id: p1; anchors.fill: parent; visible: pageStack.currentIndex === 1 }
            PageClock      { id: p2; anchors.fill: parent; visible: pageStack.currentIndex === 2 }
            PageVolume     { id: p3; anchors.fill: parent; visible: pageStack.currentIndex === 3 }
            PageBrightness { id: p4; anchors.fill: parent; visible: pageStack.currentIndex === 4 }
            PageNetwork    { id: p5; anchors.fill: parent; visible: pageStack.currentIndex === 5 }

            function pageAt(i) {
                if (i === 0) return p0
                if (i === 1) return p1
                if (i === 2) return p2
                if (i === 3) return p3
                if (i === 4) return p4
                if (i === 5) return p5
                return null
            }

            function switchTo(index) {
                if (index === currentIndex) return
                const dir = index > currentIndex ? 1 : -1
                outAnim.direction = dir
                outAnim.target    = pageAt(currentIndex)
                inAnim.direction  = dir
                inAnim.target     = pageAt(index)
                currentIndex      = index
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
                    PropertyAction { target: _outAnim.target; property: "x";       value: 0 }
                    PropertyAction { target: _outAnim.target; property: "opacity"; value: 1 }
                }

                SequentialAnimation {
                    id: _inAnim
                    property var target:    p0
                    property int direction: 1
                    PropertyAction {
                        target:   _inAnim.target
                        property: "x"
                        value:    _inAnim.direction > 0
                                    ? pageStack.width * 0.25
                                    : -pageStack.width * 0.25
                    }
                    PropertyAction { target: _inAnim.target; property: "opacity"; value: 0 }
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
