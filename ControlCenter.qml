import QtQuick
import Quickshell
import Quickshell.Io

/**
 * ControlCenter — macOS-style control center. Clicking the bar icon opens a
 * panel anchored under the bar item with quick toggles (Wi-Fi, Bluetooth,
 * Sound, Battery, Focus, Display).
 *
 * Reads config exclusively from Settings.controlcenter.
 */
Item {
    id: root

    readonly property var cfg: Settings.controlcenter

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

    Connections {
        target: NiriIpc
        function onFocusMoved() { root.close() }
    }

    // ── Panel ───────────────────────────────────────────────────────────────
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
            Text {
                text: "Control Center"
                font.family: cfg.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: Settings.settingsUI.textPrimary
            }

            // Toggle rows — only the enabled ones
            Column {
                spacing: 8

                Repeater {
                    model: root.visibleToggles()

                    delegate: Item {
                        width: parent.width
                        height: 32

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            // Icon — SF Symbols SVG asset or fallback ligature
                            Item {
                                width: 18; height: 18
                                anchors.verticalCenter: parent.verticalCenter

                                Image {
                                    visible: Settings.isIconPath(modelData.icon)
                                    source: visible ? Qt.resolvedUrl(modelData.icon) : ""
                                    sourceSize: Qt.size(38, 38)
                                    width: 17; height: 17
                                    anchors.centerIn: parent
                                    asynchronous: true
                                }

                                Text {
                                    visible: !Settings.isIconPath(modelData.icon)
                                    text: modelData.icon
                                    font.family: Settings.settingsUI.iconFont
                                    font.pixelSize: 15
                                    color: modelData.on ? Settings.settingsUI.accentColor : Settings.settingsUI.textSecondary
                                    anchors.centerIn: parent
                                }
                            }

                            // Label
                            Text {
                                text: modelData.label
                                font.family: cfg.fontFamily
                                font.pixelSize: 12
                                color: Settings.settingsUI.textPrimary
                            }

                            // Spacer
                            Item { width: 1 }

                            // Toggle switch
                            Rectangle {
                                id: track
                                width: 36; height: 20; radius: 10
                                color: modelData.on ? Settings.settingsUI.accentColor : Qt.rgba(1, 1, 1, 0.18)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    id: knob
                                    width: 16; height: 16; radius: 8
                                    x: modelData.on ? 18 : 2
                                    color: "white"
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: modelData.toggle()
                                }
                            }
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 1
                            color: Qt.rgba(1, 1, 1, 0.06)
                        }
                    }
                }
            }

            // Volume slider (when sound enabled) — ponytail: placeholder row,
            // replace with a native QML slider once a theme-safe control exists.
            Row {
                visible: cfg.showSound
                spacing: 8

                Text {
                    text: "Sound"
                    font.family: cfg.fontFamily
                    font.pixelSize: 12
                    color: Settings.settingsUI.textSecondary
                    width: 40
                }

                Rectangle {
                    width: 120; height: 4; radius: 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        width: 48; height: parent.height; radius: 2
                        color: Settings.settingsUI.accentColor
                        anchors.verticalCenter: parent.verticalCenter
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

    // ── Toggle definitions ─────────────────────────────────────────────────
    // Icons are SF Symbols SVG paths from assets/sf/. Filtered by the show*
    // flags so disabled ones never appear.
    function visibleToggles() {
        var t = []
        if (cfg.showWifi)      t.push({ label: "Wi-Fi",      icon: "assets/sf/wifi.svg",                                    on: true,  toggle: function() {} })
        if (cfg.showBluetooth) t.push({ label: "Bluetooth",  icon: "assets/sf/antenna.radiowaves.left.and.right.svg",       on: false, toggle: function() {} })
        if (cfg.showSound)     t.push({ label: "Sound",      icon: "assets/sf/speaker.wave.2.svg",                          on: true,  toggle: function() {} })
        if (cfg.showBattery)   t.push({ label: "Battery",    icon: "assets/sf/battery.100percent.svg",                      on: true,  toggle: function() {} })
        if (cfg.showFocus)     t.push({ label: "Focus",      icon: "assets/sf/moon.fill.svg",                               on: false, toggle: function() {} })
        if (cfg.showDisplay)   t.push({ label: "Display",    icon: "assets/sf/sun.max.fill.svg",                            on: true,  toggle: function() {} })
        return t
    }
}
