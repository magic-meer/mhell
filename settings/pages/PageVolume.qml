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
            label:       "No Device Icon"
            description: "Shown when there is no audio sink at all"
            SIconPicker {
                value:       Settings.volume.iconNoDevice
                onCommitted: val => Settings.volume.iconNoDevice = val
            }
        }

        SettingsRow {
            label:       "Muted / 0% Icon"
            description: "Glyph or path (.svg/.png/.ico)"
            SIconPicker {
                value:       Settings.volume.iconMuted
                onCommitted: val => Settings.volume.iconMuted = val
            }
        }

        SettingsRow {
            label: "Low Icon  (1–33%)"
            SIconPicker {
                value:       Settings.volume.iconLow
                onCommitted: val => Settings.volume.iconLow = val
            }
        }

        SettingsRow {
            label: "Mid Icon  (34–66%)"
            SIconPicker {
                value:       Settings.volume.iconMid
                onCommitted: val => Settings.volume.iconMid = val
            }
        }

        SettingsRow {
            label: "High Icon  (67–100%)"
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
            label: "Icon Size"
            last:  true
            SSpinBox {
                value: Settings.volume.iconSize; from: 8; to: 32; suffix: "px"
                onEdited: val => Settings.volume.iconSize = val
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
            label:       "No Device Color"
            description: "Used when no audio sink exists"
            last:        true
            SColorSwatch {
                value:          Settings.volume.iconNoDeviceColor
                onPicked: c => Settings.volume.iconNoDeviceColor = c
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
