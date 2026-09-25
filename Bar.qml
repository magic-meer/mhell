import QtQuick

/**
 * Bar — reads everything from Settings.bar.
 *
 * Layout sections (left/center/right) are driven by Settings.bar.layout.*
 * which are lists of module name strings. BarSection.qml instantiates the
 * right component for each name.
 */
Item {
    id: root

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
        anchors.centerIn: parent
    }

    // ── Right section ─────────────────────────────────────────────────────
    BarSection {
        id: rightSection
        modules: Settings.bar.layout.right
        layoutDirection: Qt.RightToLeft
        anchors {
            right: parent.right
            rightMargin: Settings.bar.paddingSides
            top: parent.top
            bottom: parent.bottom
        }
    }
}
