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

    // ── Serialise all settings to JSON and write ──────────────────────────
    function _writeJson() {
        const data = {
            bar: {
                height:          _bar.height,
                position:        _bar.position,
                paddingSides:    _bar.paddingSides,
                moduleSpacing:   _bar.moduleSpacing,
                bgColor:         _colorToHex(_bar.bgColor),
                bgOpacity:       _bar.bgOpacity,
                borderWidth:     _bar.borderWidth,
                borderColor:     _colorToHex(_bar.borderColor),
                radius:          _bar.radius,
                showSeparators:  _bar.showSeparators,
                separatorColor:  _colorToHex(_bar.separatorColor),
                separatorHeight: _bar.separatorHeight,
                separatorWidth:  _bar.separatorWidth,
                layout: {
                    left:   _bar.layout.left,
                    center: _bar.layout.center,
                    right:  _bar.layout.right
                }
            },
            workspaces: {
                boxSize:               _workspaces.boxSize,
                boxSpacing:            _workspaces.boxSpacing,
                boxRadius:             _workspaces.boxRadius,
                showNumbers:           _workspaces.showNumbers,
                numberSize:            _workspaces.numberSize,
                showDots:              _workspaces.showDots,
                dotSize:               _workspaces.dotSize,
                dotOpacity:            _workspaces.dotOpacity,
                highlightColor:        _colorToHex(_workspaces.highlightColor),
                highlightBorderColor:  _colorToHex(_workspaces.highlightBorderColor),
                highlightBorderWidth:  _workspaces.highlightBorderWidth,
                idleBorderColor:       _colorToHex(_workspaces.idleBorderColor),
                idleBorderWidth:       _workspaces.idleBorderWidth,
                animationsEnabled:     _workspaces.animationsEnabled,
                slideDuration:         _workspaces.slideDuration,
                colorDuration:         _workspaces.colorDuration,
                hoverDuration:         _workspaces.hoverDuration,
                hoverEnabled:          _workspaces.hoverEnabled,
                hoverScale:            _workspaces.hoverScale
            },
            clock: {
                timeFormat:   _clock.timeFormat,
                dateFormat:   _clock.dateFormat,
                showDate:     _clock.showDate,
                showSeconds:  _clock.showSeconds,
                fontFamily:   _clock.fontFamily,
                timeSize:     _clock.timeSize,
                dateSize:     _clock.dateSize,
                fontWeight:   _clock.fontWeight,
                timeColor:    _colorToHex(_clock.timeColor),
                dateColor:    _colorToHex(_clock.dateColor),
                hoverEnabled: _clock.hoverEnabled,
                hoverScale:   _clock.hoverScale,
                hoverDuration:_clock.hoverDuration
            },
            volume: {
                iconMuted:       _volume.iconMuted,
                iconLow:         _volume.iconLow,
                iconMid:         _volume.iconMid,
                iconHigh:        _volume.iconHigh,
                fontFamily:      _volume.fontFamily,
                iconSize:        _volume.iconSize,
                labelSize:       _volume.labelSize,
                spacing:         _volume.spacing,
                showLabel:       _volume.showLabel,
                iconColor:       _colorToHex(_volume.iconColor),
                iconMutedColor:  _colorToHex(_volume.iconMutedColor),
                labelColor:      _colorToHex(_volume.labelColor),
                labelMutedColor: _colorToHex(_volume.labelMutedColor),
                scrollStep:      _volume.scrollStep,
                maxVolume:       _volume.maxVolume,
                hoverEnabled:    _volume.hoverEnabled,
                hoverScale:      _volume.hoverScale,
                hoverDuration:   _volume.hoverDuration
            },
            brightness: {
                iconLow:       _brightness.iconLow,
                iconMid:       _brightness.iconMid,
                iconHigh:      _brightness.iconHigh,
                iconFull:      _brightness.iconFull,
                fontFamily:    _brightness.fontFamily,
                iconSize:      _brightness.iconSize,
                labelSize:     _brightness.labelSize,
                spacing:       _brightness.spacing,
                showLabel:     _brightness.showLabel,
                iconColor:     _colorToHex(_brightness.iconColor),
                labelColor:    _colorToHex(_brightness.labelColor),
                scrollStep:    _brightness.scrollStep,
                minBrightness: _brightness.minBrightness,
                pollInterval:  _brightness.pollInterval,
                hoverEnabled:  _brightness.hoverEnabled,
                hoverScale:    _brightness.hoverScale,
                hoverDuration: _brightness.hoverDuration
            },
            network: {
                iconConnected:    _network.iconConnected,
                iconDisconnected: _network.iconDisconnected,
                iconUnknown:      _network.iconUnknown,
                fontFamily:       _network.fontFamily,
                iconSize:         _network.iconSize,
                colorConnected:   _colorToHex(_network.colorConnected),
                colorDisconnected:_colorToHex(_network.colorDisconnected),
                colorUnknown:     _colorToHex(_network.colorUnknown),
                pollInterval:     _network.pollInterval,
                hoverEnabled:     _network.hoverEnabled,
                hoverScale:       _network.hoverScale,
                hoverDuration:    _network.hoverDuration
            },
            settingsUI: {
                windowWidth:   _settingsUI.windowWidth,
                windowHeight:  _settingsUI.windowHeight,
                sidebarWidth:  _settingsUI.sidebarWidth,
                accentColor:   _colorToHex(_settingsUI.accentColor),
                windowBg:      _colorToHex(_settingsUI.windowBg),
                sidebarBg:     _colorToHex(_settingsUI.sidebarBg),
                contentBg:     _colorToHex(_settingsUI.contentBg),
                useBlur:       _settingsUI.useBlur,
                fontFamily:    _settingsUI.fontFamily,
                textPrimary:   _colorToHex(_settingsUI.textPrimary),
                textSecondary: _colorToHex(_settingsUI.textSecondary),
                textDisabled:  _colorToHex(_settingsUI.textDisabled),
                instantApply:  _settingsUI.instantApply,
                animDuration:  _settingsUI.animDuration
            }
        }
        configFile.setText(JSON.stringify(data, null, 2))
    }

    // ── Apply a JSON string onto live settings ────────────────────────────
    function _applyJson(text) {
        let data
        try { data = JSON.parse(text) } catch(e) {
            root._loaded = true
            return
        }

        function pick(src, key, fallback) {
            return (src && src[key] !== undefined) ? src[key] : fallback
        }
        function pickColor(src, key, fallback) {
            const v = src && src[key]
            return (v && typeof v === "string") ? v : fallback
        }

        const b = data.bar || {}
        _bar.height         = pick(b, "height",         _bar.height)
        _bar.position       = pick(b, "position",       _bar.position)
        _bar.paddingSides   = pick(b, "paddingSides",   _bar.paddingSides)
        _bar.moduleSpacing  = pick(b, "moduleSpacing",  _bar.moduleSpacing)
        _bar.bgColor        = pickColor(b, "bgColor",   _bar.bgColor)
        _bar.bgOpacity      = pick(b, "bgOpacity",      _bar.bgOpacity)
        _bar.borderWidth    = pick(b, "borderWidth",    _bar.borderWidth)
        _bar.borderColor    = pickColor(b, "borderColor", _bar.borderColor)
        _bar.radius         = pick(b, "radius",         _bar.radius)
        _bar.showSeparators = pick(b, "showSeparators", _bar.showSeparators)
        _bar.separatorColor = pickColor(b, "separatorColor", _bar.separatorColor)
        _bar.separatorHeight = pick(b, "separatorHeight", _bar.separatorHeight)
        _bar.separatorWidth  = pick(b, "separatorWidth",  _bar.separatorWidth)
        if (b.layout) {
            if (b.layout.left)   _bar.layout.left   = b.layout.left
            if (b.layout.center) _bar.layout.center = b.layout.center
            if (b.layout.right)  _bar.layout.right  = b.layout.right
        }

        const w = data.workspaces || {}
        _workspaces.boxSize              = pick(w, "boxSize",              _workspaces.boxSize)
        _workspaces.boxSpacing           = pick(w, "boxSpacing",           _workspaces.boxSpacing)
        _workspaces.boxRadius            = pick(w, "boxRadius",            _workspaces.boxRadius)
        _workspaces.showNumbers          = pick(w, "showNumbers",          _workspaces.showNumbers)
        _workspaces.numberSize           = pick(w, "numberSize",           _workspaces.numberSize)
        _workspaces.showDots             = pick(w, "showDots",             _workspaces.showDots)
        _workspaces.dotSize              = pick(w, "dotSize",              _workspaces.dotSize)
        _workspaces.dotOpacity           = pick(w, "dotOpacity",           _workspaces.dotOpacity)
        _workspaces.highlightColor       = pickColor(w, "highlightColor",  _workspaces.highlightColor)
        _workspaces.highlightBorderColor = pickColor(w, "highlightBorderColor", _workspaces.highlightBorderColor)
        _workspaces.highlightBorderWidth = pick(w, "highlightBorderWidth", _workspaces.highlightBorderWidth)
        _workspaces.idleBorderColor      = pickColor(w, "idleBorderColor", _workspaces.idleBorderColor)
        _workspaces.idleBorderWidth      = pick(w, "idleBorderWidth",      _workspaces.idleBorderWidth)
        _workspaces.animationsEnabled    = pick(w, "animationsEnabled",    _workspaces.animationsEnabled)
        _workspaces.slideDuration        = pick(w, "slideDuration",        _workspaces.slideDuration)
        _workspaces.colorDuration        = pick(w, "colorDuration",        _workspaces.colorDuration)
        _workspaces.hoverDuration        = pick(w, "hoverDuration",        _workspaces.hoverDuration)
        _workspaces.hoverEnabled         = pick(w, "hoverEnabled",         _workspaces.hoverEnabled)
        _workspaces.hoverScale           = pick(w, "hoverScale",           _workspaces.hoverScale)

        const c = data.clock || {}
        _clock.timeFormat   = pick(c, "timeFormat",   _clock.timeFormat)
        _clock.dateFormat   = pick(c, "dateFormat",   _clock.dateFormat)
        _clock.showDate     = pick(c, "showDate",     _clock.showDate)
        _clock.showSeconds  = pick(c, "showSeconds",  _clock.showSeconds)
        _clock.fontFamily   = pick(c, "fontFamily",   _clock.fontFamily)
        _clock.timeSize     = pick(c, "timeSize",     _clock.timeSize)
        _clock.dateSize     = pick(c, "dateSize",     _clock.dateSize)
        _clock.fontWeight   = pick(c, "fontWeight",   _clock.fontWeight)
        _clock.timeColor    = pickColor(c, "timeColor", _clock.timeColor)
        _clock.dateColor    = pickColor(c, "dateColor", _clock.dateColor)
        _clock.hoverEnabled = pick(c, "hoverEnabled", _clock.hoverEnabled)
        _clock.hoverScale   = pick(c, "hoverScale",   _clock.hoverScale)
        _clock.hoverDuration = pick(c, "hoverDuration", _clock.hoverDuration)

        const v = data.volume || {}
        _volume.iconMuted       = pick(v, "iconMuted",       _volume.iconMuted)
        _volume.iconLow         = pick(v, "iconLow",         _volume.iconLow)
        _volume.iconMid         = pick(v, "iconMid",         _volume.iconMid)
        _volume.iconHigh        = pick(v, "iconHigh",        _volume.iconHigh)
        _volume.fontFamily      = pick(v, "fontFamily",      _volume.fontFamily)
        _volume.iconSize        = pick(v, "iconSize",        _volume.iconSize)
        _volume.labelSize       = pick(v, "labelSize",       _volume.labelSize)
        _volume.spacing         = pick(v, "spacing",         _volume.spacing)
        _volume.showLabel       = pick(v, "showLabel",       _volume.showLabel)
        _volume.iconColor       = pickColor(v, "iconColor",       _volume.iconColor)
        _volume.iconMutedColor  = pickColor(v, "iconMutedColor",  _volume.iconMutedColor)
        _volume.labelColor      = pickColor(v, "labelColor",      _volume.labelColor)
        _volume.labelMutedColor = pickColor(v, "labelMutedColor", _volume.labelMutedColor)
        _volume.scrollStep      = pick(v, "scrollStep",      _volume.scrollStep)
        _volume.maxVolume       = pick(v, "maxVolume",       _volume.maxVolume)
        _volume.hoverEnabled    = pick(v, "hoverEnabled",    _volume.hoverEnabled)
        _volume.hoverScale      = pick(v, "hoverScale",      _volume.hoverScale)
        _volume.hoverDuration   = pick(v, "hoverDuration",   _volume.hoverDuration)

        const br = data.brightness || {}
        _brightness.iconLow       = pick(br, "iconLow",       _brightness.iconLow)
        _brightness.iconMid       = pick(br, "iconMid",       _brightness.iconMid)
        _brightness.iconHigh      = pick(br, "iconHigh",      _brightness.iconHigh)
        _brightness.iconFull      = pick(br, "iconFull",      _brightness.iconFull)
        _brightness.fontFamily    = pick(br, "fontFamily",    _brightness.fontFamily)
        _brightness.iconSize      = pick(br, "iconSize",      _brightness.iconSize)
        _brightness.labelSize     = pick(br, "labelSize",     _brightness.labelSize)
        _brightness.spacing       = pick(br, "spacing",       _brightness.spacing)
        _brightness.showLabel     = pick(br, "showLabel",     _brightness.showLabel)
        _brightness.iconColor     = pickColor(br, "iconColor",  _brightness.iconColor)
        _brightness.labelColor    = pickColor(br, "labelColor", _brightness.labelColor)
        _brightness.scrollStep    = pick(br, "scrollStep",    _brightness.scrollStep)
        _brightness.minBrightness = pick(br, "minBrightness", _brightness.minBrightness)
        _brightness.pollInterval  = pick(br, "pollInterval",  _brightness.pollInterval)
        _brightness.hoverEnabled  = pick(br, "hoverEnabled",  _brightness.hoverEnabled)
        _brightness.hoverScale    = pick(br, "hoverScale",    _brightness.hoverScale)
        _brightness.hoverDuration = pick(br, "hoverDuration", _brightness.hoverDuration)

        const n = data.network || {}
        _network.iconConnected     = pick(n, "iconConnected",     _network.iconConnected)
        _network.iconDisconnected  = pick(n, "iconDisconnected",  _network.iconDisconnected)
        _network.iconUnknown       = pick(n, "iconUnknown",       _network.iconUnknown)
        _network.fontFamily        = pick(n, "fontFamily",        _network.fontFamily)
        _network.iconSize          = pick(n, "iconSize",          _network.iconSize)
        _network.colorConnected    = pickColor(n, "colorConnected",    _network.colorConnected)
        _network.colorDisconnected = pickColor(n, "colorDisconnected", _network.colorDisconnected)
        _network.colorUnknown      = pickColor(n, "colorUnknown",      _network.colorUnknown)
        _network.pollInterval      = pick(n, "pollInterval",      _network.pollInterval)
        _network.hoverEnabled      = pick(n, "hoverEnabled",      _network.hoverEnabled)
        _network.hoverScale        = pick(n, "hoverScale",        _network.hoverScale)
        _network.hoverDuration     = pick(n, "hoverDuration",     _network.hoverDuration)

        const s = data.settingsUI || {}
        _settingsUI.windowWidth   = pick(s, "windowWidth",   _settingsUI.windowWidth)
        _settingsUI.windowHeight  = pick(s, "windowHeight",  _settingsUI.windowHeight)
        _settingsUI.sidebarWidth  = pick(s, "sidebarWidth",  _settingsUI.sidebarWidth)
        _settingsUI.accentColor   = pickColor(s, "accentColor",   _settingsUI.accentColor)
        _settingsUI.windowBg      = pickColor(s, "windowBg",      _settingsUI.windowBg)
        _settingsUI.sidebarBg     = pickColor(s, "sidebarBg",     _settingsUI.sidebarBg)
        _settingsUI.contentBg     = pickColor(s, "contentBg",     _settingsUI.contentBg)
        _settingsUI.useBlur       = pick(s, "useBlur",       _settingsUI.useBlur)
        _settingsUI.fontFamily    = pick(s, "fontFamily",    _settingsUI.fontFamily)
        _settingsUI.textPrimary   = pickColor(s, "textPrimary",   _settingsUI.textPrimary)
        _settingsUI.textSecondary = pickColor(s, "textSecondary", _settingsUI.textSecondary)
        _settingsUI.textDisabled  = pickColor(s, "textDisabled",  _settingsUI.textDisabled)
        _settingsUI.instantApply  = pick(s, "instantApply",  _settingsUI.instantApply)
        _settingsUI.animDuration  = pick(s, "animDuration",  _settingsUI.animDuration)

        root._loaded = true
    }

    // ── Color helpers ─────────────────────────────────────────────────────
    /// Serialise a QML color to "#RRGGBBAA" hex string
    function _colorToHex(c) {
        function h(x) {
            const s = Math.round(x * 255).toString(16)
            return s.length === 1 ? "0" + s : s
        }
        return "#" + h(c.r) + h(c.g) + h(c.b) + h(c.a)
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
