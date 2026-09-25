import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Volume"
    subtitle: "Icons, display and scroll behaviour"

    SettingsGroup {
        label: "Icons"

        SettingsRow {
            label:       "Muted Icon"
            description: "Glyph or path (.svg/.png/.ico)"
            SIconPicker {
                value:       Settings.volume.iconMuted
                onCommitted: val => Settings.volume.iconMuted = val
            }
        }

        SettingsRow {
            label: "Low Icon  (< 34%)"
            SIconPicker {
                value:       Settings.volume.iconLow
                onCommitted: val => Settings.volume.iconLow = val
            }
        }

        SettingsRow {
            label: "Mid Icon  (34–67%)"
            SIconPicker {
                value:       Settings.volume.iconMid
                onCommitted: val => Settings.volume.iconMid = val
            }
        }

        SettingsRow {
            label: "High Icon  (> 67%)"
            last:  true
            SIconPicker {
                value:       Settings.volume.iconHigh
                onCommitted: val => Settings.volume.iconHigh = val
            }
        }
    }

    SettingsGroup {
        label: "Display"

        SettingsRow {
            label: "Show Label"
            SToggle {
                checked:   Settings.volume.showLabel
                onToggled: val => Settings.volume.showLabel = val
            }
        }

        SettingsRow {
            label: "Icon Size"
            SSpinBox {
                value: Settings.volume.iconSize; from: 8; to: 32; suffix: "px"
                onEdited: val => Settings.volume.iconSize = val
            }
        }

        SettingsRow {
            label: "Label Size"
            last:  true
            SSpinBox {
                value: Settings.volume.labelSize; from: 8; to: 24; suffix: "px"
                onEdited: val => Settings.volume.labelSize = val
            }
        }
    }

    SettingsGroup {
        label: "Colors"

        SettingsRow {
            label: "Icon Color"
            SColorSwatch {
                value:          Settings.volume.iconColor
                onPicked: c => Settings.volume.iconColor = c
            }
        }

        SettingsRow {
            label: "Icon Muted Color"
            SColorSwatch {
                value:          Settings.volume.iconMutedColor
                onPicked: c => Settings.volume.iconMutedColor = c
            }
        }

        SettingsRow {
            label: "Label Color"
            SColorSwatch {
                value:          Settings.volume.labelColor
                onPicked: c => Settings.volume.labelColor = c
            }
        }

        SettingsRow {
            label: "Label Muted Color"
            last:  true
            SColorSwatch {
                value:          Settings.volume.labelMutedColor
                onPicked: c => Settings.volume.labelMutedColor = c
            }
        }
    }

    SettingsGroup {
        label: "Behaviour"

        SettingsRow {
            label:       "Scroll Step"
            description: "Volume change per scroll notch"
            SSlider {
                value: Settings.volume.scrollStep; from: 0.01; to: 0.20
                onEdited: val => Settings.volume.scrollStep = val
            }
        }

        SettingsRow {
            label:       "Max Volume"
            description: "1.0 = 100%, 1.5 = 150%"
            last:        true
            SSlider {
                value: Settings.volume.maxVolume; from: 1.0; to: 2.0
                onEdited: val => Settings.volume.maxVolume = val
            }
        }
    }
}
