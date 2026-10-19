import Quickshell
import Quickshell.Widgets
import QtQuick
import "." as Mod
import Quickshell.Services.UPower

Item {
    id: root

    implicitHeight: Mod.Theme.iconSize
    implicitWidth: Mod.Theme.menuActionButtonWidth

    readonly property var battery: UPower.displayDevice
    property bool popupOpen : false
    readonly property bool ready: battery !== null && battery.ready
    readonly property real percentage: ready ? battery.percentage * 100 : 0

    readonly property var icons: ({
        error:    "batteryblock.slash.svg",
        charging: "battery.100percent.bolt.svg",
        full:     "battery.100percent.svg",
        high:     "battery.75percent.svg",
        mid:      "battery.50percent.svg",
        low:      "battery.25percent.svg",
        empty:    "battery.0percent.svg"
    })

    readonly property string iconState: {
        if (!root.ready) return "error"
        if (root.battery.state === UPowerDeviceState.Charging
            || root.battery.state === UPowerDeviceState.FullyCharged
            || root.battery.state === UPowerDeviceState.PendingCharge)
            return "charging"
        if (root.percentage >= 90) return "full"
        if (root.percentage >= 65) return "high"
        if (root.percentage >= 40) return "mid"
        if (root.percentage >= 20) return "low"
        return "empty"
    }

    readonly property url iconSource:
        Qt.resolvedUrl("../assets/symbols/" + root.icons[root.iconState])

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

            onClicked: {
                root.popupOpen = !root.popupOpen
            }
        }
    }
}
