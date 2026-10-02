import QtQuick
import Quickshell

/**
 * BarPopup — manages hover timing and animation state for a bar module popup.
 *
 * This component does NOT contain the PopupWindow — each module owns its own.
 * Instead it exposes `visible` and `progress` for the module to bind to.
 *
 * Usage:
 *   BarPopup {
 *       id: popup
 *       anchorHovered: mouse.containsMouse
 *   }
 *   PopupWindow {
 *       anchor.item:    root
 *       anchor.gravity: Edges.Top
 *       anchor.edges:   Edges.Bottom
 *       visible:        popup.visible
 *       // ... content that can reference root.audio etc directly
 *   }
 */
Item {
    id: root

    property bool anchorHovered:  false
    property bool popupHovered:   false

    // ── Public ────────────────────────────────────────────────────────────
    readonly property bool anyHovered: anchorHovered || popupHovered
    property bool visible:   false
    property real progress:  0.0   // 0→1 animation progress

    onAnyHoveredChanged: {
        if (anyHovered) {
            hideTimer.stop()
            showTimer.restart()
        } else {
            showTimer.stop()
            hideTimer.restart()
        }
    }

    Timer { id: showTimer; interval: 60; repeat: false
        onTriggered: { if (!root.anyHovered) return; root.visible = true; openAnim.start() }
    }
    Timer { id: hideTimer; interval: 120; repeat: false
        onTriggered: { if (root.anyHovered) return; closeAnim.start() }
    }

    NumberAnimation { id: openAnim;  target: root; property: "progress"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
    NumberAnimation { id: closeAnim; target: root; property: "progress"; to: 0.0; duration: 140; easing.type: Easing.InCubic
        onFinished: root.visible = false
    }
}
