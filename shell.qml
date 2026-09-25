import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    // ── Bar — one per screen ──────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors.left:   true
            anchors.right:  true
            anchors.top:    Settings.bar.position === "top"
            anchors.bottom: Settings.bar.position === "bottom"

            exclusiveZone: Settings.bar.height
            implicitHeight: Settings.bar.height
            color: "transparent"

            Bar { anchors.fill: parent }
        }
    }

    // ── Settings window — single instance, toggled via IPC ────────────────
    SettingsWindow { id: settingsWin }
}
