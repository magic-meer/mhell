import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Notifications"
    subtitle: "Bell, count badge and panel"

    SettingsGroup {
        label: "Icon"

        SettingsRow {
            label:       "Bell Icon"
            description: "Glyph or path (.svg/.png/.ico)"
            SIconPicker {
                value:       Settings.notifications.iconBell
                onCommitted: val => Settings.notifications.iconBell = val
            }
        }

        SettingsRow {
            label: "Icon Size"
            last:  true
            SSpinBox {
                value: Settings.notifications.iconSize; from: 10; to: 28; suffix: "px"
                onEdited: val => Settings.notifications.iconSize = val
            }
        }
    }

    SettingsGroup {
        label: "Panel"

        SettingsRow {
            label: "Panel Width"
            SSpinBox {
                value: Settings.notifications.panelWidth; from: 240; to: 600; suffix: "px"
                onEdited: val => Settings.notifications.panelWidth = val
            }
        }

        SettingsRow {
            label:       "Max Visible"
            description: "Rows before the list clips"
            last:        true
            SSpinBox {
                value: Settings.notifications.maxItems; from: 3; to: 30
                onEdited: val => Settings.notifications.maxItems = val
            }
        }
    }

    SettingsGroup {
        label: "Toast"

        SettingsRow {
            label:       "Toast Duration"
            description: "How long a new notification stays on screen"
            last:        true
            SSpinBox {
                value: Settings.notifications.toastDuration; from: 1500; to: 15000; step: 500; suffix: "ms"
                onEdited: val => Settings.notifications.toastDuration = val
            }
        }
    }

    SettingsGroup {
        label: "Colors"

        SettingsRow {
            label: "Active Icon Color"
            SColorSwatch {
                value: Settings.notifications.iconColorActive
                onPicked: c => Settings.notifications.iconColorActive = c
            }
        }

        SettingsRow {
            label: "Badge Color"
            SColorSwatch {
                value: Settings.notifications.badgeColor
                onPicked: c => Settings.notifications.badgeColor = c
            }
        }

        SettingsRow {
            label: "Panel Background"
            last:  true
            SColorSwatch {
                value: Settings.notifications.panelBg
                onPicked: c => Settings.notifications.panelBg = c
            }
        }
    }
}
