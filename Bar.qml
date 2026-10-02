import QtQuick

/**
 * Bar — reads everything from Settings.bar.
 * Receives panelWindow from shell.qml and threads it down to BarSection.
 */
Item {
    id: root

    property var panelWindow: null   // kept for compatibility, unused by popups now
    implicitHeight: Settings.bar.height

    // ── Background ────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Settings.bar.bgColor
        opacity:      Settings.bar.bgOpacity
        radius:       Settings.bar.radius
        border.color: Settings.bar.borderColor
        border.width: Settings.bar.borderWidth
    }

    // ── Left section ──────────────────────────────────────────────────────
    BarSection {
        id: leftSection
        modules: Settings.bar.layout.left
        panelWindow: root.panelWindow
        anchors {
            left: parent.left
            leftMargin: Settings.bar.paddingSides
            top: parent.top
            bottom: parent.bottom
        }
    }

    // ── Center section ────────────────────────────────────────────────────
    BarSection {
        id: centerSection
        modules: Settings.bar.layout.center
        panelWindow: root.panelWindow
        anchors.centerIn: parent
    }

    // ── Right section ─────────────────────────────────────────────────────
    BarSection {
        id: rightSection
        modules: Settings.bar.layout.right
        panelWindow: root.panelWindow
        layoutDirection: Qt.RightToLeft
        anchors {
            right: parent.right
            rightMargin: Settings.bar.paddingSides
            top: parent.top
            bottom: parent.bottom
        }
    }
}
