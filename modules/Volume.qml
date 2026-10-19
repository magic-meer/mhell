import Quickshell
import Quickshell.Widgets
import QtQuick
import "." as Mod
import Quickshell.Services.Pipewire

Item {
    id: root

    implicitHeight: Mod.Theme.iconSize
    implicitWidth: Mod.Theme.menuActionButtonWidth

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: Pipewire.ready && sink != null && sink.ready
    readonly property real volume: ready && sink.audio ? sink.audio.volume : 0
    readonly property bool isMuted: ready && sink.audio ? sink.audio.muted: false
    property bool popupOpen : false

    readonly property var icons: ({
        error: "speaker.badge.exclamationmark.fill.svg",
        muted: "speaker.slash.fill.svg",
        dnd: "speaker.zzz.fill.svg",
        zero:  "speaker.fill.svg",
        low:   "speaker.wave.1.fill.svg",
        mid:   "speaker.wave.2.fill.svg",
        high:  "speaker.wave.3.fill.svg",
        over:  "speaker.plus.fill.svg"
    })

    // pure state resolver: no paths here, easy to reason about / log / reuse for OSD
    readonly property string iconState: {
        if (!root.ready) return "error"
        if (root.isMuted) return "muted"
        if (root.volume <= 0.005) return "zero"       // float compare with tolerance
        if (root.volume > 1.0) return "over"          // only if you allow >100%
        if (root.volume < 0.34) return "low"
        if (root.volume < 0.67) return "mid"
        return "high"
    }

    // single binding mapping state -> file
    readonly property url iconSource:
        Qt.resolvedUrl("../assets/symbols/" + root.icons[root.iconState])

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    function volumeUpdate(change) {
        if( !ready || !sink.audio ) return
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + change))
    }
    function muteSink() {
        if ( ready && sink.audio ) sink.audio.muted = !sink.audio.muted
    }

    Rectangle {
        id: box

        anchors.fill: parent
        width: Mod.Theme.menuActionButtonWidth
        height: Mod.Theme.barHeight
        color: mouse.containsMouse ? Mod.Theme.hoverBackground : Mod.Theme.menuActionButtonBackground
        radius: Mod.Theme.radius

        IconImage {
            anchors.fill: parent
            implicitSize: Mod.Theme.iconSize
            source: root.iconSource
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.SizeVerCursor

            onClicked: (event) => {
                if( event.button === Qt.RightButton )
                    root.muteSink()
                else if( event.button === Qt.LeftButton )
                    root.popupOpen = !root.popupOpen
            }
            onWheel: (event) => { root.volumeUpdate(event.angleDelta.y > 0 ? -0.01 : 0.01) }
        }
    }
}
