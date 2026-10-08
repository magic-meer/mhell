import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    // Force-instantiate the Notifications singleton at startup — it owns the
    // D-Bus name and only registers when first referenced (lazy singleton).
    readonly property int _notificationsPin: Notifications.count

    // ── Bar — one per screen ──────────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWin
            required property var modelData
            screen: modelData

            anchors.left:   true
            anchors.right:  true
            anchors.top:    Settings.bar.position === "top"
            anchors.bottom: Settings.bar.position === "bottom"

            exclusiveZone: Settings.bar.height
            implicitHeight: Settings.bar.height
            color: "transparent"

            Bar {
                anchors.fill: parent
            }
        }
    }

    // ── Launcher — one per screen ─────────────────────────────────────────
    Variants {
        model: Quickshell.screens

        LauncherWindow {
            required property var modelData
            screen: modelData
        }
    }

    // ── Settings window — single instance, toggled via IPC ────────────────
    SettingsWindow { id: settingsWin }
}
