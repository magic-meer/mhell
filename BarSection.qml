import QtQuick

/**
 * BarSection — renders a horizontal list of modules.
 *
 * `modules` is a list of name strings from Settings.bar.layout.
 * Each name maps to a concrete component. Separators are inserted between
 * modules when Settings.bar.showSeparators is true.
 *
 * Supported module names:
 *   "workspaces"  "clock"  "volume"  "brightness"  "network"
 */
Item {
    id: root

    property var    modules:         []
    property int    layoutDirection: Qt.LeftToRight

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Settings.bar.moduleSpacing
        layoutDirection: root.layoutDirection

        Repeater {
            model: root.modules

            delegate: Row {
                required property string modelData
                required property int    index

                spacing: Settings.bar.moduleSpacing

                // Separator before each module except the first
                Rectangle {
                    visible: index > 0 && Settings.bar.showSeparators
                    width:   Settings.bar.separatorWidth
                    height:  Settings.bar.separatorHeight
                    color:   Settings.bar.separatorColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                // The module itself
                Loader {
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: {
                        switch (modelData) {
                            case "workspaces":  return workspacesComp
                            case "clock":       return clockComp
                            case "volume":      return volumeComp
                            case "brightness":  return brightnessComp
                            case "network":     return networkComp
                            case "systemtray":  return systemTrayComp
                            case "notifications": return notificationsComp
                            case "services":    return servicesComp
                            default:            return null
                        }
                    }
                }
            }
        }
    }

    // ── Component definitions ─────────────────────────────────────────────
    Component { id: workspacesComp; Workspaces  {} }
    Component { id: clockComp;      Clock       {} }
    Component { id: volumeComp;     Volume      {} }
    Component { id: brightnessComp; Brightness  {} }
    Component { id: networkComp;    Network     {} }
    Component { id: systemTrayComp; SystemTray  {} }
    Component { id: notificationsComp; NotifIndicator {} }
    Component { id: servicesComp;    ServiceMonitor  {} }
}
