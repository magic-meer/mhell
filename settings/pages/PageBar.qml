import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    id:       root
    title:    "Bar"
    subtitle: "Geometry, appearance and layout"

    function _toList(val) { return val.split(",").map(s => s.trim()).filter(s => s.length > 0) }

    // ── Geometry ──────────────────────────────────────────────────────────
    SettingsGroup {
        label: "Geometry"

        SettingsRow {
            label:       "Height"
            description: "Bar height in pixels"
            SSpinBox {
                value: Settings.bar.height; from: 20; to: 80; step: 2; suffix: "px"
                onEdited: val => Settings.bar.height = val
            }
        }

        SettingsRow {
            label:       "Side Padding"
            description: "Left and right inner padding"
            SSpinBox {
                value: Settings.bar.paddingSides; from: 0; to: 60; step: 2; suffix: "px"
                onEdited: val => Settings.bar.paddingSides = val
            }
        }

        SettingsRow {
            label:       "Module Spacing"
            description: "Gap between modules in a section"
            SSpinBox {
                value: Settings.bar.moduleSpacing; from: 0; to: 60; step: 2; suffix: "px"
                onEdited: val => Settings.bar.moduleSpacing = val
            }
        }

        SettingsRow {
            label: "Position"
            last:  true
            SDropDown {
                model:        ["top", "bottom"]
                currentIndex: Settings.bar.position === "bottom" ? 1 : 0
                onSelected:   idx => Settings.bar.position = idx === 0 ? "top" : "bottom"
            }
        }
    }

    // ── Background ────────────────────────────────────────────────────────
    SettingsGroup {
        label: "Background"

        SettingsRow {
            label:       "Use Blur"
            description: "Transparent window (Niri provides blur)"
            SToggle {
                checked:   Settings.bar.bgColor.a < 0.05
                onToggled: val => Settings.bar.bgColor = val
                    ? Qt.rgba(0, 0, 0, 0)
                    : Qt.rgba(0.08, 0.08, 0.10, 0.85)
            }
        }

        SettingsRow {
            label:       "Background Color"
            description: "Ignored when blur is enabled"
            SColorSwatch {
                value:          Settings.bar.bgColor
                onPicked: c => Settings.bar.bgColor = c
            }
        }

        SettingsRow {
            label: "Opacity"
            SSlider {
                value:          Settings.bar.bgOpacity
                from: 0; to: 1
                onEdited: val => Settings.bar.bgOpacity = val
            }
        }

        SettingsRow {
            label:  "Corner Radius"
            last:   true
            SSpinBox {
                value: Settings.bar.radius; from: 0; to: 24; suffix: "px"
                onEdited: val => Settings.bar.radius = val
            }
        }
    }

    // ── Border ────────────────────────────────────────────────────────────
    SettingsGroup {
        label: "Border"

        SettingsRow {
            label: "Border Width"
            SSpinBox {
                value: Settings.bar.borderWidth; from: 0; to: 8; suffix: "px"
                onEdited: val => Settings.bar.borderWidth = val
            }
        }

        SettingsRow {
            label: "Border Color"
            last:  true
            SColorSwatch {
                value:          Settings.bar.borderColor
                onPicked: c => Settings.bar.borderColor = c
            }
        }
    }

    // ── Separators ────────────────────────────────────────────────────────
    SettingsGroup {
        label: "Module Separators"

        SettingsRow {
            label: "Show Separators"
            SToggle {
                checked:   Settings.bar.showSeparators
                onToggled: val => Settings.bar.showSeparators = val
            }
        }

        SettingsRow {
            label: "Separator Color"
            SColorSwatch {
                value:          Settings.bar.separatorColor
                onPicked: c => Settings.bar.separatorColor = c
            }
        }

        SettingsRow {
            label: "Separator Height"
            last:  true
            SSpinBox {
                value: Settings.bar.separatorHeight; from: 4; to: 32; suffix: "px"
                onEdited: val => Settings.bar.separatorHeight = val
            }
        }
    }

    // ── Layout ────────────────────────────────────────────────────────────
    SettingsGroup {
        label: "Layout"

        SettingsRow {
            label:       "Left Modules"
            description: "Comma-separated list"
            STextInput {
                value:       Settings.bar.layout.left.join(", ")
                placeholder: "workspaces"
                onCommitted: val => Settings.bar.layout.left = _toList(val)
            }
        }

        SettingsRow {
            label:       "Center Modules"
            description: "Comma-separated list"
            STextInput {
                value:       Settings.bar.layout.center.join(", ")
                placeholder: "clock"
                onCommitted: val => Settings.bar.layout.center = _toList(val)
            }
        }

        SettingsRow {
            label:       "Right Modules"
            description: "Comma-separated list"
            last:        true
            STextInput {
                value:       Settings.bar.layout.right.join(", ")
                placeholder: "network, brightness, volume"
                onCommitted: val => Settings.bar.layout.right = _toList(val)
            }
        }
    }
}
