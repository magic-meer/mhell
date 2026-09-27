import QtQuick
import Quickshell

/**
 * BarPopup — floating popup that appears above a bar module on hover.
 * Uses PopupWindow with the anchor API so it renders outside PanelWindow clip.
 *
 * Usage inside any bar module:
 *   BarPopup {
 *       parentWindow:  root.panelWindow   // the PanelWindow
 *       anchorItem:    root               // the module Item to center above
 *       anchorHovered: mouse.containsMouse
 *       SomeContent {}
 *   }
 */
Item {
    id: root

    property var  parentWindow:  null   // the PanelWindow
    property var  anchorItem:    parent // module to center popup above
    property bool anchorHovered: false
    property int  padding:       16

    default property alias content: contentCol.data

    // ── Hover logic ───────────────────────────────────────────────────────
    readonly property bool _anyHovered: anchorHovered || (popupWin.visible && popupMouse.containsMouse)

    on_AnyHoveredChanged: {
        if (_anyHovered) {
            hideTimer.stop()
            showTimer.restart()
        } else {
            showTimer.stop()
            hideTimer.restart()
        }
    }

    property real _p: 0.0   // animation progress 0→1

    Timer { id: showTimer; interval: 60; repeat: false
        onTriggered: { if (!root._anyHovered) return; root._place(); popupWin.visible = true; openAnim.start() }
    }
    Timer { id: hideTimer; interval: 120; repeat: false
        onTriggered: { if (root._anyHovered) return; closeAnim.start() }
    }

    NumberAnimation { id: openAnim;  target: root; property: "_p"; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
    NumberAnimation { id: closeAnim; target: root; property: "_p"; to: 0.0; duration: 140; easing.type: Easing.InCubic
        onFinished: popupWin.visible = false
    }

    // ── Position: map anchorItem into panelWindow coords ──────────────────
    function _place() {
        if (!anchorItem || !parentWindow) return
        // Map anchor item's center to the parentWindow's coordinate space
        const pt  = anchorItem.mapToItem(null, anchorItem.width / 2, 0)
        const pw  = Math.max(10, contentCol.implicitWidth  + padding * 2)
        const ph  = Math.max(10, contentCol.implicitHeight + padding * 2 + 10)
        // anchor.rect.x/y are relative to the parentWindow
        popupWin.anchor.rect.x      = Math.round(pt.x - pw / 2)
        popupWin.anchor.rect.y      = Math.round(pt.y - ph - 6)
        popupWin.anchor.rect.width  = pw
        popupWin.anchor.rect.height = ph
    }

    // ── Popup window ──────────────────────────────────────────────────────
    PopupWindow {
        id: popupWin
        anchor.window: root.parentWindow
        visible:       false
        color:         "transparent"

        implicitWidth:  Math.max(10, contentCol.implicitWidth  + root.padding * 2)
        implicitHeight: Math.max(10, contentCol.implicitHeight + root.padding * 2 + 10)

        onVisibleChanged: if (visible) root._place()

        Item {
            anchors.fill: parent

            // Card background
            Rectangle {
                anchors { fill: parent; bottomMargin: 10 }
                radius:          12
                color:           Qt.rgba(0.08, 0.08, 0.11, 0.97)
                border.color:    Qt.rgba(1, 1, 1, 0.10)
                border.width:    1
                opacity:         root._p
                scale:           0.94 + root._p * 0.06
                transformOrigin: Item.Bottom
            }

            // Arrow nub
            Item {
                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                width: 14; height: 10
                opacity: root._p
                Rectangle {
                    anchors.centerIn: parent
                    width: 10; height: 10; rotation: 45
                    color:        Qt.rgba(0.08, 0.08, 0.11, 0.97)
                    border.color: Qt.rgba(1, 1, 1, 0.10); border.width: 1
                    Rectangle {
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: parent.height / 2
                        color:  Qt.rgba(0.08, 0.08, 0.11, 0.97)
                    }
                }
            }

            // Content
            Column {
                id: contentCol
                anchors {
                    top: parent.top; topMargin: root.padding
                    left: parent.left; leftMargin: root.padding
                    right: parent.right; rightMargin: root.padding
                }
                spacing:         8
                opacity:         root._p
                scale:           0.94 + root._p * 0.06
                transformOrigin: Item.Bottom
            }

            // Keep popup alive when hovering it
            MouseArea {
                id: popupMouse
                anchors.fill: parent
                hoverEnabled: true
                onWheel: wheel => wheel.accepted = false
            }
        }
    }
}
