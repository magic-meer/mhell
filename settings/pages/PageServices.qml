import QtQuick
import "../controls"
import ".."
import "../.."

SettingsPage {
    title:    "Services"
    subtitle: "Monitor and manage systemd services"

    SettingsGroup {
        label: "Services"

        Repeater {
            model: Settings.services.serviceList

            delegate: SettingsRow {
                required property var modelData
                required property int index

                label:       modelData.displayName || modelData.name
                description: modelData.name

                Item {
                    width:  32
                    height: 32

                    Text {
                        anchors.centerIn: parent
                        text:           "✕"
                        font.family:    Settings.settingsUI.fontFamily
                        font.pixelSize: 14
                        color:          removeMouse.containsMouse ? Qt.rgba(1.0, 0.35, 0.3, 1.0) : Settings.settingsUI.textSecondary
                    }

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const list = Settings.services.serviceList
                            list.splice(index, 1)
                            Settings.services.serviceList = list
                            Settings.scheduleSave()
                        }
                    }
                }

                last: index === Settings.services.serviceList.length - 1
            }
        }

        SettingsRow {
            label:       "Service Name"
            description: "systemd unit name (e.g. kanate)"
            STextInput {
                id: svcNameInput
                width:       200
                placeholder: "service-name"
            }
        }

        SettingsRow {
            label:       "Display Name"
            description: "Shown in the monitor popup"
            STextInput {
                id: svcDisplayInput
                width:       200
                placeholder: "Display Name"
            }
        }

        SettingsRow {
            label: "Add Service"
            last:  true

            Item {
                width:  80
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color:  addMouse.containsMouse ? Settings.settingsUI.accentColor : Qt.rgba(1, 1, 1, 0.08)
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                Text {
                    anchors.centerIn: parent
                    text:           "+ Add"
                    font.family:    Settings.settingsUI.fontFamily
                    font.pixelSize: 12
                    font.bold:      true
                    color:          Settings.settingsUI.textPrimary
                }

                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const name = svcNameInput.value.trim()
                        if (!name) return
                        const display = svcDisplayInput.value.trim() || name
                        const list = Settings.services.serviceList
                        const exists = list.some(s => s.name === name)
                        if (!exists) {
                            list.push({ name: name, displayName: display, icon: "" })
                            Settings.services.serviceList = list
                            Settings.scheduleSave()
                        }
                        svcNameInput.value = ""
                        svcDisplayInput.value = ""
                    }
                }
            }
        }
    }

    SettingsGroup {
        label: "Display"

        SettingsRow {
            label:       "Icon"
            description: "Glyph or path (.svg/.png/.ico)"
            SIconPicker {
                value:       Settings.services.icon
                onCommitted: val => Settings.services.icon = val
            }
        }

        SettingsRow {
            label: "Icon Size"
            last:  true
            SSpinBox {
                value: Settings.services.iconSize; from: 10; to: 28; suffix: "px"
                onEdited: val => Settings.services.iconSize = val
            }
        }
    }

    SettingsGroup {
        label: "Colors"

        SettingsRow {
            label: "Icon Color"
            SColorSwatch {
                value: Settings.services.iconColor
                onPicked: c => Settings.services.iconColor = c
            }
        }

        SettingsRow {
            label: "Error Icon Color"
            SColorSwatch {
                value: Settings.services.iconColorError
                onPicked: c => Settings.services.iconColorError = c
            }
        }

        SettingsRow {
            label: "Badge Color"
            last:  true
            SColorSwatch {
                value: Settings.services.badgeColor
                onPicked: c => Settings.services.badgeColor = c
            }
        }
    }

    SettingsGroup {
        label: "Panel"

        SettingsRow {
            label: "Panel Width"
            SSpinBox {
                value: Settings.services.panelWidth; from: 240; to: 600; suffix: "px"
                onEdited: val => Settings.services.panelWidth = val
            }
        }

        SettingsRow {
            label: "Poll Interval"
            description: "How often to check service status"
            SSpinBox {
                value: Settings.services.pollInterval; from: 2000; to: 60000; step: 1000; suffix: "ms"
                onEdited: val => Settings.services.pollInterval = val
            }
        }

        SettingsRow {
            label: "Panel Background"
            last:  true
            SColorSwatch {
                value: Settings.services.panelBg
                onPicked: c => Settings.services.panelBg = c
            }
        }
    }
}
