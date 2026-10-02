import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Clock"
    subtitle: "Format, typography and colors"

    SettingsGroup {
        label: "Format"

        SettingsRow {
            label:       "Time Format"
            description: "Qt format string, e.g. HH:mm or hh:mm AP"
            STextInput {
                value:       Settings.clock.timeFormat
                placeholder: "HH:mm"
                onCommitted: val => Settings.clock.timeFormat = val
            }
        }

        SettingsRow {
            label:       "Date Format"
            description: "e.g. ddd, MMM d"
            STextInput {
                value:       Settings.clock.dateFormat
                placeholder: "ddd, MMM d"
                onCommitted: val => Settings.clock.dateFormat = val
            }
        }

        SettingsRow {
            label:       "Show Seconds"
            description: "Add :ss to your time format above"
            last:        true
            SToggle {
                checked:   Settings.clock.showSeconds
                onToggled: val => Settings.clock.showSeconds = val
            }
        }
    }

    SettingsGroup {
        label: "Typography"

        SettingsRow {
            label: "Font Family"
            STextInput {
                value:       Settings.clock.fontFamily
                placeholder: "JetBrainsMono Nerd Font"
                onCommitted: val => Settings.clock.fontFamily = val
            }
        }

        SettingsRow {
            label: "Time Size"
            SSpinBox {
                value: Settings.clock.timeSize; from: 8; to: 32; suffix: "px"
                onEdited: val => Settings.clock.timeSize = val
            }
        }

        SettingsRow {
            label: "Date Size"
            last:  true
            SSpinBox {
                value: Settings.clock.dateSize; from: 6; to: 24; suffix: "px"
                onEdited: val => Settings.clock.dateSize = val
            }
        }
    }

    SettingsGroup {
        label: "Colors"

        SettingsRow {
            label: "Time Color"
            SColorSwatch {
                value:          Settings.clock.timeColor
                onPicked: c => Settings.clock.timeColor = c
            }
        }

        SettingsRow {
            label: "Date Color"
            last:  true
            SColorSwatch {
                value:          Settings.clock.dateColor
                onPicked: c => Settings.clock.dateColor = c
            }
        }
    }

    SettingsGroup {
        label: "Hover"

        SettingsRow {
            label: "Enable Hover Scale"
            SToggle {
                checked:   Settings.clock.hoverEnabled
                onToggled: val => Settings.clock.hoverEnabled = val
            }
        }

        SettingsRow {
            label: "Hover Scale"
            last:  true
            SSlider {
                value: Settings.clock.hoverScale; from: 1.0; to: 1.3
                onEdited: val => Settings.clock.hoverScale = val
            }
        }
    }
}
