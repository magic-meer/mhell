pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Settings — the single source of truth for the entire shell.
 *
 * Every visual and behavioural value lives here.
 * Components read from Settings.<section>.<property> directly via QML bindings,
 * so changing any value here instantly propagates everywhere without a restart.
 *
 * PERSISTENCE
 * ───────────
 * Settings are saved to ~/.config/my_quickshell/settings.json automatically
 * whenever a value changes (debounced 500 ms). On startup the saved file is
 * loaded and overlaid onto the defaults defined below.
 *
 * ICONS
 * ─────
 * Icon fields accept either:
 *   • A Nerd Font glyph character  →  rendered as Text  (default)
 *   • A file path ending in .svg / .png / .ico  →  rendered as Image
 * Components check Settings.isIconPath(str) to decide which to use.
 *
 * LAYOUT
 * ──────
 * bar.layout.left / center / right are lists of module name strings.
 * Supported names: "workspaces", "clock", "volume", "brightness", "network", "systemtray"
 * Order in the list determines render order.
 */
Singleton {
    id: root

    // ── Persistence ───────────────────────────────────────────────────────
    /// Path to the persisted settings file (inside Quickshell's state dir)
    readonly property string configPath: Quickshell.stateDir + "/settings.json"

    /// Set to true once the initial load is complete — prevents saving during load
    property bool _loaded: false

    FileView {
        id: configFile
        path:         root.configPath
        watchChanges: false
        onLoaded:     root._applyJson(configFile.text())
        onLoadFailed: root._loaded = true   // file doesn't exist yet — use defaults
    }

    /// Debounce timer — saves 500 ms after the last change
    Timer {
        id: saveTimer
        interval: 500
        repeat:   false
        onTriggered: root._writeJson()
    }

    /// Call this from any settings page after a value changes
    function scheduleSave() {
        if (root._loaded) saveTimer.restart()
    }

    readonly property var _persistSchema: [
        {
            name: "bar",
            obj:  _bar,
            keys: [
                "height", "position", "paddingSides", "moduleSpacing",
                "bgColor", "bgOpacity", "borderWidth", "borderColor", "radius",
                "showSeparators", "separatorColor", "separatorHeight",
                "separatorWidth", "layout"
            ]
        },
        {
            name: "workspaces",
            obj:  _workspaces,
            keys: [
                "boxSize", "boxSpacing", "boxRadius", "showNumbers", "numberSize",
                "showDots", "dotSize", "dotOpacity", "highlightColor",
                "highlightBorderColor", "highlightBorderWidth", "idleBorderColor",
                "idleBorderWidth", "animationsEnabled", "slideDuration",
                "colorDuration", "hoverDuration", "hoverEnabled", "hoverScale"
            ]
        },
        {
            name: "clock",
            obj:  _clock,
            keys: [
                "timeFormat", "dateFormat", "showSeconds", "fontFamily",
                "timeSize", "dateSize", "fontWeight", "timeColor", "dateColor",
                "hoverEnabled", "hoverScale", "hoverDuration"
            ]
        },
        {
            name: "volume",
            obj:  _volume,
            keys: [
                "iconMuted", "iconLow", "iconMid", "iconHigh", "fontFamily",
                "iconSize", "iconColor", "iconMutedColor", "scrollStep",
                "maxVolume"
            ]
        },
        {
            name: "brightness",
            obj:  _brightness,
            keys: [
                "iconLow", "iconMid", "iconHigh", "iconFull", "fontFamily",
                "iconSize", "iconColor", "scrollStep", "minBrightness",
                "pollInterval"
            ]
        },
        {
            name: "network",
            obj:  _network,
            keys: [
                "iconConnected", "iconDisconnected", "iconUnknown", "fontFamily",
                "iconSize", "colorConnected", "colorDisconnected", "colorUnknown",
                "pollInterval", "hoverEnabled", "hoverScale", "hoverDuration"
            ]
        },
        {
            name: "notifications",
            obj:  _notifications,
            keys: [
                "iconBell", "fontFamily", "iconSize", "iconColor",
                "iconColorActive", "badgeColor", "panelBg", "panelBorder",
                "panelWidth", "maxItems", "rowHeight", "toastDuration"
            ]
        },
        {
            name: "settingsUI",
            obj:  _settingsUI,
            keys: [
                "windowWidth", "windowHeight", "sidebarWidth", "accentColor",
                "windowBg", "sidebarBg", "useBlur", "fontFamily", "textPrimary",
                "textSecondary", "textDisabled", "instantApply", "animDuration"
            ]
        }
    ]

    // ── Serialise all settings to JSON and write ──────────────────────────
    function _writeJson() {
        const data = {}
        root._persistSchema.forEach(sec => {
            const src = sec.obj
            const out = {}
            sec.keys.forEach(key => {
                if (key === "layout") {
                    out[key] = {
                        left:   src.layout.left,
                        center: src.layout.center,
                        right:  src.layout.right
                    }
                    return
                }
                const v = src[key]
                if (Array.isArray(v)) {
                    out[key] = v
                    return
                }
                if (!(v && typeof v === "object")) {
                    out[key] = v
                    return
                }
                const s = String(v)
                out[key] = (s.length === 7) ? "#ff" + s.slice(1) : s
            })
            data[sec.name] = out
        })
        configFile.setText(JSON.stringify(data, null, 2))
    }

    // ── Apply a JSON string onto live settings ────────────────────────────
    function _applyJson(text) {
        let data
        try { data = JSON.parse(text) } catch(e) { data = null }

        if (data) {
        root._persistSchema.forEach(sec => {
            const from = data[sec.name]
            if (!from || typeof from !== "object") return
            const to = sec.obj
            sec.keys.forEach(key => {
                if (key === "layout") {
                    const l = from.layout
                    if (!l || typeof l !== "object") return
                    if (l.left)   to.layout.left   = l.left
                    if (l.center) to.layout.center = l.center
                    if (l.right)  to.layout.right  = l.right
                    return
                }
                const v = from[key]
                if (v === undefined || v === null) return
                if (key === "serviceList") {
                    // ponytail: legacy builds persisted this as a comma-joined
                    // string; ignore anything that is not an array.
                    if (!Array.isArray(v)) return
                    const cleaned = v.filter(s => s && typeof s === "object" && s.name)
                        .map(s => ({ name: String(s.name), displayName: String(s.displayName || s.name), icon: String(s.icon || "") }))
                    if (cleaned.length > 0) to.serviceList = cleaned
                    // ponytail: empty list is unpersistable (defaults return).
                    // Add a "defaultList" sentinel if you ever need "none".
                    return
                }
                if (typeof v === "object") return
                to[key] = v
            })
        })
        }

        root._loaded = true
    }

    Component.onCompleted: {
        // Kick off the async file load; _applyJson is called via onLoadedChanged
        configFile.reload()
    }

    // ── Utility ───────────────────────────────────────────────────────────
    /// Returns true when `s` looks like a file path rather than a glyph
    function isIconPath(s) {
        return s.endsWith(".svg") || s.endsWith(".png")
               || s.endsWith(".ico") || s.startsWith("/")
               || s.startsWith("./") || s.startsWith("~/")
    }

    // ═════════════════════════════════════════════════════════════════════
    // BAR
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _bar

        // ── Geometry ──────────────────────────────────────────────────────
        /// Height of the bar in pixels
        property int height: 36

        /// "top" or "bottom"
        property string position: "top"

        /// Horizontal padding inside the bar (left and right edges)
        property int paddingSides: 12

        /// Gap between modules inside a section (left/center/right)
        property int moduleSpacing: 14

        // ── Background ────────────────────────────────────────────────────
        /// Background color of the bar (alpha is independent via bgOpacity)
        property color bgColor: Qt.rgba(0, 0, 0, 0)

        /// Extra opacity multiplier on top of bgColor's alpha (0.0–1.0)
        property real bgOpacity: 1.0

        // ── Border / rounding ─────────────────────────────────────────────
        property int   borderWidth:  0
        property color borderColor:  Qt.rgba(1, 1, 1, 0.08)
        property int   radius:       0

        // ── Module separators ─────────────────────────────────────────────
        property bool  showSeparators:   true
        property color separatorColor:   Qt.rgba(1, 1, 1, 0.12)
        property int   separatorHeight:  14
        property int   separatorWidth:   1

        // ── Layout ────────────────────────────────────────────────────────
        /// Lists of module name strings for each section.
        /// Valid names: "workspaces" "clock" "volume" "brightness" "network"
        property var layout: QtObject {
            property var left:   ["workspaces"]
            property var center: ["clock"]
            property var right:  ["notifications", "network", "brightness", "volume"]
        }
    }
    readonly property alias bar: _bar

    // ═════════════════════════════════════════════════════════════════════
    // WORKSPACES
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _workspaces

        // ── Box geometry ──────────────────────────────────────────────────
        property int  boxSize:    28
        property int  boxSpacing: 6
        property int  boxRadius:  6

        // ── Content ───────────────────────────────────────────────────────
        property bool showNumbers: false
        property int  numberSize:  11

        property bool showDots:  true
        property int  dotSize:   5
        property real dotOpacity: 0.55

        // ── Highlight (active/focused indicator) ──────────────────────────
        property color highlightColor:        Qt.rgba(1, 1, 1, 0.18)
        property color highlightBorderColor:  Qt.rgba(1, 1, 1, 0.70)
        property int   highlightBorderWidth:  1

        // ── Idle box ──────────────────────────────────────────────────────
        property color idleBorderColor: Qt.rgba(1, 1, 1, 0.15)
        property int   idleBorderWidth: 1

        // ── Animations ────────────────────────────────────────────────────
        property bool animationsEnabled:  true
        property int  slideDuration:      220   // ms — highlight glide
        property int  colorDuration:      150   // ms — dot color fade
        property int  hoverDuration:      120   // ms — scale bounce

        // ── Hover ─────────────────────────────────────────────────────────
        property bool hoverEnabled: true
        property real hoverScale:   1.15
    }
    readonly property alias workspaces: _workspaces

    // ═════════════════════════════════════════════════════════════════════
    // CLOCK
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _clock

        // ── Format ────────────────────────────────────────────────────────
        /// Qt date/time format strings — see Qt.formatTime / Qt.formatDate docs
        property string timeFormat: "HH:mm"
        property string dateFormat: "ddd, MMM d"

        // ── Visibility ────────────────────────────────────────────────────
        property bool showSeconds: false   // set timeFormat to "HH:mm:ss" to use

        // ── Typography ────────────────────────────────────────────────────
        property string fontFamily:  "JetBrainsMono Nerd Font"
        property int    timeSize:    14
        property int    dateSize:    10
        property int    fontWeight:  Font.Medium

        // ── Colors ────────────────────────────────────────────────────────
        property color timeColor: Qt.rgba(1, 1, 1, 0.95)
        property color dateColor: Qt.rgba(1, 1, 1, 0.55)

        // ── Hover ─────────────────────────────────────────────────────────
        property bool hoverEnabled: true
        property real hoverScale:   1.04
        property int  hoverDuration: 120
    }
    readonly property alias clock: _clock

    // ═════════════════════════════════════════════════════════════════════
    // VOLUME
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _volume

        // ── Icons ─────────────────────────────────────────────────────────
        /// Each accepts a Nerd Font glyph or a file path (.svg/.png/.ico)
        property string iconMuted: "󰝟"
        property string iconLow:   "󰕿"
        property string iconMid:   "󰖀"
        property string iconHigh:  "󰕾"

        // ── Typography / sizing ───────────────────────────────────────────
        property string fontFamily: "JetBrainsMono Nerd Font"
        property int    iconSize:   16

        // ── Colors ────────────────────────────────────────────────────────
        property color iconColor:       Qt.rgba(1, 1, 1, 0.85)
        property color iconMutedColor:  Qt.rgba(1, 1, 1, 0.35)

        // ── Behaviour ─────────────────────────────────────────────────────
        /// Volume step per scroll notch (0.0–1.0, maps to 0–100%)
        property real scrollStep: 0.05
        /// Maximum allowed volume (1.0 = 100%, 1.5 = 150% for boost)
        property real maxVolume:  1.5
    }
    readonly property alias volume: _volume

    // ═════════════════════════════════════════════════════════════════════
    // BRIGHTNESS
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _brightness

        // ── Icons ─────────────────────────────────────────────────────────
        property string iconLow:  "󰃞"
        property string iconMid:  "󰃟"
        property string iconHigh: "󰃠"
        property string iconFull: "󰃠"

        // ── Typography / sizing ───────────────────────────────────────────
        property string fontFamily: "JetBrainsMono Nerd Font"
        property int    iconSize:   16

        // ── Colors ────────────────────────────────────────────────────────
        property color iconColor:  Qt.rgba(1, 1, 1, 0.85)

        // ── Behaviour ─────────────────────────────────────────────────────
        /// Step in percentage points per scroll notch
        property int scrollStep:    5
        /// Minimum brightness (% — prevents screen going fully black)
        property int minBrightness: 5
        /// Poll interval in milliseconds
        property int pollInterval:  2000
    }
    readonly property alias brightness: _brightness

    // ═════════════════════════════════════════════════════════════════════
    // NETWORK
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _network

        // ── Icons ─────────────────────────────────────────────────────────
        property string iconConnected:    "󰤨"
        property string iconDisconnected: "󰤭"
        property string iconUnknown:      "󰤫"

        // ── Typography / sizing ───────────────────────────────────────────
        property string fontFamily: "JetBrainsMono Nerd Font"
        property int    iconSize:   18

        // ── Colors ────────────────────────────────────────────────────────
        property color colorConnected:    Qt.rgba(1, 1, 1, 0.85)
        property color colorDisconnected: Qt.rgba(1, 1, 1, 0.35)
        property color colorUnknown:      Qt.rgba(1, 1, 1, 0.50)

        // ── Behaviour ─────────────────────────────────────────────────────
        /// How often to re-check nmcli (milliseconds)
        property int pollInterval: 5000

        // ── Hover ─────────────────────────────────────────────────────────
        property bool hoverEnabled: true
        property real hoverScale:   1.15
        property int  hoverDuration: 120
    }
    readonly property alias network: _network

    // ═════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _notifications

        // ── Icons / typography ───────────────────────────────────────────
        property string iconBell:  ""
        property string fontFamily: "JetBrainsMono Nerd Font"
        property int    iconSize:   18

        // ── Colors ───────────────────────────────────────────────────────
        property color iconColor:       Qt.rgba(1, 1, 1, 0.85)
        property color iconColorActive: Qt.rgba(0.4, 0.6, 1.0, 1.0)
        property color badgeColor:      Qt.rgba(0.4, 0.6, 1.0, 1.0)
        property color panelBg:         Qt.rgba(0.08, 0.08, 0.11, 0.97)
        property color panelBorder:     Qt.rgba(1, 1, 1, 0.10)

        // ── Panel geometry ───────────────────────────────────────────────
        property int panelWidth: 380
        property int maxItems:   10
        property int rowHeight:  74

        // ── Toast ────────────────────────────────────────────────────────
        /// How long a toast stays on screen (milliseconds)
        property int toastDuration: 5000
    }
    readonly property alias notifications: _notifications

    // ═════════════════════════════════════════════════════════════════════
    // SERVICE MONITOR
    // ═════════════════════════════════════════════════════════════════════

    // ═════════════════════════════════════════════════════════════════════
    // SETTINGS WINDOW UI
    // ═════════════════════════════════════════════════════════════════════
    QtObject {
        id: _settingsUI

        // ── Window geometry ───────────────────────────────────────────────
        property int   windowWidth:  860
        property int   windowHeight: 580
        property int   sidebarWidth: 200

        // ── Appearance ────────────────────────────────────────────────────
        /// Accent color used for selected sidebar item, toggle on-state, sliders
        property color accentColor:  Qt.rgba(0.4, 0.6, 1.0, 1.0)

        /// Background color of the window (set alpha=0 to let Niri blur show through)
        property color windowBg:     Qt.rgba(0.08, 0.08, 0.10, 0.92)

        /// Sidebar background (slightly different from content area)
        property color sidebarBg:    Qt.rgba(0.05, 0.05, 0.07, 1.0)

        /// Whether the window background is fully transparent (lets Niri blur through)
        property bool  useBlur:      false

        // ── Typography ────────────────────────────────────────────────────
        property string fontFamily:  "JetBrainsMono Nerd Font"
        property color  textPrimary:   Qt.rgba(1, 1, 1, 0.92)
        property color  textSecondary: Qt.rgba(1, 1, 1, 0.50)
        property color  textDisabled:  Qt.rgba(1, 1, 1, 0.25)

        // ── Apply mode ────────────────────────────────────────────────────
        /// true  = changes apply the moment you touch a control (default)
        /// false = changes only apply when you press Save
        property bool instantApply: true

        // ── Animation ─────────────────────────────────────────────────────
        property int animDuration: 180   // ms — open/close, page transitions
    }
    readonly property alias settingsUI: _settingsUI
}
