import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Battery"
    subtitle: "Monitor and manage battery status"

    SettingsGroup {
        label: "Status Icons"

        SettingsRow {
            label:       "No Battery Icon"
            description: "Shown when this machine has no battery"
            SIconPicker {
                value:       Settings.battery.iconAbsent
                onCommitted: val => Settings.battery.iconAbsent = val
            }
        }

        SettingsRow {
            label: "Unknown Icon"
            SIconPicker {
                value:       Settings.battery.iconUnknown
                onCommitted: val => Settings.battery.iconUnknown = val
            }
        }

        SettingsRow {
            label: "Charging Icon"
            SIconPicker {
                value:       Settings.battery.iconCharging
                onCommitted: val => Settings.battery.iconCharging = val
            }
        }

        SettingsRow {
            label:       "Not Charging Icon"
            description: "Plugged in but paused or full"
            SIconPicker {
                value:       Settings.battery.iconNotCharging
                onCommitted: val => Settings.battery.iconNotCharging = val
            }
        }

        SettingsRow {
            label:       "Full Charged Icon"
            description: "status = Full"
            SIconPicker {
                value:       Settings.battery.iconFullCharged
                onCommitted: val => Settings.battery.iconFullCharged = val
            }
        }

        SettingsRow {
            label:       "Critical Icon"
            description: "Discharging below 10%"
            last:        true
            SIconPicker {
                value:       Settings.battery.iconCritical
                onCommitted: val => Settings.battery.iconCritical = val
            }
        }
    }

    SettingsGroup {
        label: "Level Icons  (discharging)"

        SettingsRow {
            label: "Icon  (default)"
            SIconPicker {
                value:       Settings.battery.icon
                onCommitted: val => Settings.battery.icon = val
            }
        }

        SettingsRow {
            label: "Icon  (10–19%)"
            SIconPicker {
                value:       Settings.battery.iconLow
                onCommitted: val => Settings.battery.iconLow = val
            }
        }

        SettingsRow {
            label: "Icon  (20–39%)"
            SIconPicker {
                value:       Settings.battery.iconMidLow
                onCommitted: val => Settings.battery.iconMidLow = val
            }
        }

        SettingsRow {
            label: "Icon  (40–59%)"
            SIconPicker {
                value:       Settings.battery.iconMid
                onCommitted: val => Settings.battery.iconMid = val
            }
        }

        SettingsRow {
            label: "Icon  (60–79%)"
            SIconPicker {
                value:       Settings.battery.iconMidHigh
                onCommitted: val => Settings.battery.iconMidHigh = val
            }
        }

        SettingsRow {
            label: "Icon  (80–99%)"
            SIconPicker {
                value:       Settings.battery.iconHigh
                onCommitted: val => Settings.battery.iconHigh = val
            }
        }

        SettingsRow {
            label: "Icon  (100%)"
            last:  true
            SIconPicker {
                value:       Settings.battery.iconFull
                onCommitted: val => Settings.battery.iconFull = val
            }
        }
    }

    SettingsGroup {
        label: "Display"

        SettingsRow {
            label: "Icon Size"
            SSpinBox {
                value: Settings.battery.iconSize; from: 10; to: 28; suffix: "px"
                onEdited: val => Settings.battery.iconSize = val
            }
        }

        SettingsRow {
            label: "Poll Interval"
            description: "How often to check battery status"
            last:  true
            SSpinBox {
                value: Settings.battery.pollInterval; from: 1000; to: 60000; step: 1000; suffix: "ms"
                onEdited: val => Settings.battery.pollInterval = val
            }
        }
    }

    SettingsGroup {
        label: "Colors"

        SettingsRow {
            label: "Icon Color"
            SColorSwatch {
                value: Settings.battery.iconColor
                onPicked: c => Settings.battery.iconColor = c
            }
        }

        SettingsRow {
            label: "Low Icon Color"
            last:  true
            SColorSwatch {
                value: Settings.battery.iconLowColor
                onPicked: c => Settings.battery.iconLowColor = c
            }
        }

        SettingsRow {
            label: "Mid/Low Icon Color"
            SColorSwatch {
                value: Settings.battery.iconMidColor
                onPicked: c => Settings.battery.iconMidColor = c
            }
        }

        SettingsRow {
            label: "High Icon Color"
            SColorSwatch {
                value: Settings.battery.iconHighColor
                onPicked: c => Settings.battery.iconHighColor = c
            }
        }

        SettingsRow {
            label:       "Warning Color"
            description: "On-AC text in the popup"
            SColorSwatch {
                value: Settings.battery.iconColorWarning
                onPicked: c => Settings.battery.iconColorWarning = c
            }
        }

        SettingsRow {
            label:       "Critical Color"
            description: "Discharging below 10%"
            SColorSwatch {
                value: Settings.battery.iconColorCritical
                onPicked: c => Settings.battery.iconColorCritical = c
            }
        }

        SettingsRow {
            label:       "No Battery Color"
            description: "Machine has no battery"
            last:        true
            SColorSwatch {
                value: Settings.battery.iconAbsentColor
                onPicked: c => Settings.battery.iconAbsentColor = c
            }
        }
    }
}