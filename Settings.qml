pragma Singleton
import QtQuick
import Quickshell

/**
 * Settings — the single source of truth for the entire shell.
 *
 * Every visual and behavioural value lives here.
 * Components read from Settings.<section>.<property> directly via QML bindings,
 * so changing any value here instantly propagates everywhere without a restart.
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
 * Supported names: "workspaces", "clock", "volume", "brightness", "network"
 * Order in the list determines render order.
 */
Singleton {
    id: root

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
            property var right:  ["network", "brightness", "volume"]
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
        property bool showDate:    true
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
        property int    labelSize:  12
        property int    spacing:    5     // gap between icon and label

        // ── Visibility ────────────────────────────────────────────────────
        property bool showLabel: true

        // ── Colors ────────────────────────────────────────────────────────
        property color iconColor:       Qt.rgba(1, 1, 1, 0.85)
        property color iconMutedColor:  Qt.rgba(1, 1, 1, 0.35)
        property color labelColor:      Qt.rgba(1, 1, 1, 0.75)
        property color labelMutedColor: Qt.rgba(1, 1, 1, 0.35)

        // ── Behaviour ─────────────────────────────────────────────────────
        /// Volume step per scroll notch (0.0–1.0, maps to 0–100%)
        property real scrollStep: 0.05
        /// Maximum allowed volume (1.0 = 100%, 1.5 = 150% for boost)
        property real maxVolume:  1.5

        // ── Hover ─────────────────────────────────────────────────────────
        property bool hoverEnabled: true
        property real hoverScale:   1.06
        property int  hoverDuration: 120
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
        property int    labelSize:  12
        property int    spacing:    5

        // ── Visibility ────────────────────────────────────────────────────
        property bool showLabel: true

        // ── Colors ────────────────────────────────────────────────────────
        property color iconColor:  Qt.rgba(1, 1, 1, 0.85)
        property color labelColor: Qt.rgba(1, 1, 1, 0.75)

        // ── Behaviour ─────────────────────────────────────────────────────
        /// Step in percentage points per scroll notch
        property int scrollStep:    5
        /// Minimum brightness (% — prevents screen going fully black)
        property int minBrightness: 5
        /// Poll interval in milliseconds
        property int pollInterval:  2000

        // ── Hover ─────────────────────────────────────────────────────────
        property bool hoverEnabled: true
        property real hoverScale:   1.06
        property int  hoverDuration: 120
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

        /// Content area background
        property color contentBg:    Qt.rgba(0.10, 0.10, 0.13, 1.0)

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
