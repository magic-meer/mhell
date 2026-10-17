import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * Bar — macOS Tahoe style pill bar. Reads everything from Settings.bar.
 *
 * The bar is a translucent pill that sits at the screen edge. Corners are
 * fully rounded (radius == half height by default) so it reads as a single
 * floating pill rather than a full-width strip.
 */
Item {
    id: root

    implicitHeight: Settings.bar.height

    // ── Background pill ─────────────────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.fill: parent
        color:        Settings.bar.bgColor
        opacity:      Settings.bar.bgOpacity
        radius:       Settings.bar.radius
        border.color: Settings.bar.borderColor
        border.width: Settings.bar.borderWidth
    }

    // ── Left section ────────────────────────────────────────────────────────
    BarSection {
        modules: Settings.bar.layout.left
        anchors {
            left: parent.left
            leftMargin: Settings.bar.paddingSides
            top: parent.top
            bottom: parent.bottom
        }
    }

    // ── Center section ──────────────────────────────────────────────────────
    BarSection {
        modules: Settings.bar.layout.center
        anchors.centerIn: parent
    }

    // ── Right section ───────────────────────────────────────────────────────
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
