import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Network"
    subtitle: "Icons, colors and polling"

    SettingsGroup {
        label: "Icons"

        SettingsRow {
            label:       "Connected Icon"
            description: "Glyph or path (.svg/.png/.ico)"
            SIconPicker {
                value:       Settings.network.iconConnected
                onCommitted: val => Settings.network.iconConnected = val
            }
        }

        SettingsRow {
            label: "Disconnected Icon"
            SIconPicker {
                value:       Settings.network.iconDisconnected
                onCommitted: val => Settings.network.iconDisconnected = val
            }
        }

        SettingsRow {
            label: "Unknown Icon"
            last:  true
            SIconPicker {
                value:       Settings.network.iconUnknown
                onCommitted: val => Settings.network.iconUnknown = val
            }
        }
    }

    SettingsGroup {
        label: "Display"

        SettingsRow {
            label: "Icon Size"
            last:  true
            SSpinBox {
                value: Settings.network.iconSize; from: 8; to: 32; suffix: "px"
                onEdited: val => Settings.network.iconSize = val
            }
        }
    }

    SettingsGroup {
        label: "Colors"

        SettingsRow {
            label: "Connected Color"
            SColorSwatch {
                value:          Settings.network.colorConnected
                onPicked: c => Settings.network.colorConnected = c
            }
        }

        SettingsRow {
            label: "Disconnected Color"
            SColorSwatch {
                value:          Settings.network.colorDisconnected
                onPicked: c => Settings.network.colorDisconnected = c
            }
        }

        SettingsRow {
            label: "Unknown Color"
            last:  true
            SColorSwatch {
                value:          Settings.network.colorUnknown
                onPicked: c => Settings.network.colorUnknown = c
            }
        }
    }

    SettingsGroup {
        label: "Behaviour"

        SettingsRow {
            label:       "Poll Interval"
            description: "How often to check network state"
            last:        true
            SSpinBox {
                value: Settings.network.pollInterval; from: 1000; to: 30000; step: 1000; suffix: "ms"
                onEdited: val => Settings.network.pollInterval = val
            }
        }
    }
}
