import QtQuick

/**
 * Bar — reads everything from Settings.bar.
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
        modules: Settings.bar.layout.center
        anchors.centerIn: parent
    }

    // ── Right section ─────────────────────────────────────────────────────
    BarSection {
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
