import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Workspaces"
    subtitle: "Box style, indicators and animations"

    SettingsGroup {
        label: "Box Geometry"

        SettingsRow {
            label: "Box Size"
            SSpinBox {
                value: Settings.workspaces.boxSize; from: 12; to: 60; step: 2; suffix: "px"
                onEdited: val => Settings.workspaces.boxSize = val
            }
        }

        SettingsRow {
            label: "Box Spacing"
            SSpinBox {
                value: Settings.workspaces.boxSpacing; from: 0; to: 24; step: 1; suffix: "px"
                onEdited: val => Settings.workspaces.boxSpacing = val
            }
        }

        SettingsRow {
            label: "Corner Radius"
            last:  true
            SSpinBox {
                value: Settings.workspaces.boxRadius; from: 0; to: 30; step: 1; suffix: "px"
                onEdited: val => Settings.workspaces.boxRadius = val
            }
        }
    }

    SettingsGroup {
        label: "Content"

        SettingsRow {
            label:       "Show Numbers"
            description: "Display workspace index inside each box"
            SToggle {
                checked:   Settings.workspaces.showNumbers
                onToggled: val => Settings.workspaces.showNumbers = val
            }
        }

        SettingsRow {
            label: "Number Size"
            SSpinBox {
                value: Settings.workspaces.numberSize; from: 8; to: 20; suffix: "px"
                onEdited: val => Settings.workspaces.numberSize = val
            }
        }

        SettingsRow {
            label:       "Show Dots"
            description: "Small dot when workspace has a window"
            SToggle {
                checked:   Settings.workspaces.showDots
                onToggled: val => Settings.workspaces.showDots = val
            }
        }

        SettingsRow {
            label: "Dot Size"
            SSpinBox {
                value: Settings.workspaces.dotSize; from: 2; to: 12; suffix: "px"
                onEdited: val => Settings.workspaces.dotSize = val
            }
        }

        SettingsRow {
            label: "Dot Opacity"
            last:  true
            SSlider {
                value: Settings.workspaces.dotOpacity; from: 0; to: 1
                onEdited: val => Settings.workspaces.dotOpacity = val
            }
        }
    }

    SettingsGroup {
        label: "Highlight"

        SettingsRow {
            label: "Highlight Color"
            SColorSwatch {
                value:          Settings.workspaces.highlightColor
                onPicked: c => Settings.workspaces.highlightColor = c
            }
        }

        SettingsRow {
            label: "Border Color"
            SColorSwatch {
                value:          Settings.workspaces.highlightBorderColor
                onPicked: c => Settings.workspaces.highlightBorderColor = c
            }
        }

        SettingsRow {
            label: "Border Width"
            last:  true
            SSpinBox {
                value: Settings.workspaces.highlightBorderWidth; from: 0; to: 4; suffix: "px"
                onEdited: val => Settings.workspaces.highlightBorderWidth = val
            }
        }
    }

    SettingsGroup {
        label: "Idle Box"

        SettingsRow {
            label: "Border Color"
            SColorSwatch {
                value:          Settings.workspaces.idleBorderColor
                onPicked: c => Settings.workspaces.idleBorderColor = c
            }
        }

        SettingsRow {
            label: "Border Width"
            last:  true
            SSpinBox {
                value: Settings.workspaces.idleBorderWidth; from: 0; to: 4; suffix: "px"
                onEdited: val => Settings.workspaces.idleBorderWidth = val
            }
        }
    }

    SettingsGroup {
        label: "Animations"

        SettingsRow {
            label: "Enable Animations"
            SToggle {
                checked:   Settings.workspaces.animationsEnabled
                onToggled: val => Settings.workspaces.animationsEnabled = val
            }
        }

        SettingsRow {
            label:       "Slide Duration"
            description: "Highlight glide speed"
            SSpinBox {
                value: Settings.workspaces.slideDuration; from: 0; to: 800; step: 20; suffix: "ms"
                onEdited: val => Settings.workspaces.slideDuration = val
            }
        }

        SettingsRow {
            label: "Hover Scale"
            SSlider {
                value: Settings.workspaces.hoverScale; from: 1.0; to: 1.5
                onEdited: val => Settings.workspaces.hoverScale = val
            }
        }

        SettingsRow {
            label: "Enable Hover"
            last:  true
            SToggle {
                checked:   Settings.workspaces.hoverEnabled
                onToggled: val => Settings.workspaces.hoverEnabled = val
            }
        }
    }
}
