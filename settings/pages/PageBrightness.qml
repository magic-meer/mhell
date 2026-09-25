import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Brightness"
    subtitle: "Icons, display and scroll behaviour"

    SettingsGroup {
        label: "Icons"

        SettingsRow {
            label: "Low Icon  (< 25%)"
            SIconPicker {
                value:       Settings.brightness.iconLow
                onCommitted: val => Settings.brightness.iconLow = val
            }
        }

        SettingsRow {
            label: "Mid Icon  (25–50%)"
            SIconPicker {
                value:       Settings.brightness.iconMid
                onCommitted: val => Settings.brightness.iconMid = val
            }
        }

        SettingsRow {
            label: "High Icon  (50–75%)"
            SIconPicker {
                value:       Settings.brightness.iconHigh
                onCommitted: val => Settings.brightness.iconHigh = val
            }
        }

        SettingsRow {
            label: "Full Icon  (> 75%)"
            last:  true
            SIconPicker {
                value:       Settings.brightness.iconFull
                onCommitted: val => Settings.brightness.iconFull = val
            }
        }
    }

    SettingsGroup {
        label: "Display"

        SettingsRow {
            label: "Show Label"
            SToggle {
                checked:   Settings.brightness.showLabel
                onToggled: val => Settings.brightness.showLabel = val
            }
        }

        SettingsRow {
            label: "Icon Size"
            SSpinBox {
                value: Settings.brightness.iconSize; from: 8; to: 32; suffix: "px"
                onEdited: val => Settings.brightness.iconSize = val
            }
        }

        SettingsRow {
            label: "Label Size"
            last:  true
            SSpinBox {
                value: Settings.brightness.labelSize; from: 8; to: 24; suffix: "px"
                onEdited: val => Settings.brightness.labelSize = val
            }
        }
    }

    SettingsGroup {
        label: "Colors"

        SettingsRow {
            label: "Icon Color"
            SColorSwatch {
                value:          Settings.brightness.iconColor
                onPicked: c => Settings.brightness.iconColor = c
            }
        }

        SettingsRow {
            label: "Label Color"
            last:  true
            SColorSwatch {
                value:          Settings.brightness.labelColor
                onPicked: c => Settings.brightness.labelColor = c
            }
        }
    }

    SettingsGroup {
        label: "Behaviour"

        SettingsRow {
            label:       "Scroll Step"
            description: "Brightness change per scroll notch"
            SSpinBox {
                value: Settings.brightness.scrollStep; from: 1; to: 20; suffix: "%"
                onEdited: val => Settings.brightness.scrollStep = val
            }
        }

        SettingsRow {
            label:       "Min Brightness"
            description: "Prevents screen going fully black"
            SSpinBox {
                value: Settings.brightness.minBrightness; from: 1; to: 20; suffix: "%"
                onEdited: val => Settings.brightness.minBrightness = val
            }
        }

        SettingsRow {
            label:       "Poll Interval"
            description: "How often to re-read brightness"
            last:        true
            SSpinBox {
                value: Settings.brightness.pollInterval; from: 500; to: 10000; step: 500; suffix: "ms"
                onEdited: val => Settings.brightness.pollInterval = val
            }
        }
    }
}
