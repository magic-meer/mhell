import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: root

    // Force-instantiate the Notifications singleton at startup — it owns the
    // D-Bus name and only registers when first referenced (lazy singleton).
    readonly property int _notificationsPin: Notifications.count

    // ── Icons ───────────────────────────────────────────────────────────
    // Lucide lives in assets/ so the shell carries its own icon set and needs
    // no system font install. Publishes the loaded family to Settings, which
    // every module reads as `Settings.settingsUI.iconFont`.
    FontLoader {
        id: lucide
        source: Qt.resolvedUrl("assets/Lucide.ttf")
        // QML reads `A.B.C: value` at object scope as an attached-object
        // declaration, so this cannot be a grouped binding — assign instead.
        onStatusChanged: root._publishIconFont()
    }

    // SF Pro — Apple's system font (pulled from a GitHub mirror). Every text
    // label in the bar/panels uses Settings.settingsUI.fontFamily, published
    // here the same way Lucide publishes iconFont.
    FontLoader {
        id: sfPro
        source: Qt.resolvedUrl("assets/fonts/SF-Pro-Text-Regular.otf")
        onStatusChanged: if (status === FontLoader.Ready) Settings.settingsUI.fontFamily = name
    }
    // Semibold ships as a separate static family; publish so font-weight
    // semantics map onto a real family instead of synthetic bold.
    FontLoader {
        id: sfProSemi
        source: Qt.resolvedUrl("assets/fonts/SF-Pro-Text-Semibold.otf")
        onStatusChanged: if (status === FontLoader.Ready) Settings.settingsUI.fontFamilySemibold = name
    }

    function _publishIconFont() {
        Settings.settingsUI.iconFont =
            lucide.status === FontLoader.Ready ? lucide.font.family : ""
    }
    Component.onCompleted: _publishIconFont()

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
