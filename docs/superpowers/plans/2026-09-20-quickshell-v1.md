# Quickshell Desktop v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the working v1 of the user's liquid-glass Quickshell desktop environment on niri: Theme singleton, shared components, bar with tray/clock/settings pills, clock+calendar popup, quick settings popup (wifi, bluetooth, brightness, volume, battery, power), and the nix/niri integration.

**Architecture:** Modular per-area QML. `shell.qml` (QuickshellRoot) instantiates `bar/Bar.qml` (a layer-shell `PanelWindow`). The bar hosts two `PopupWindow`s (clock/calendar, quick settings) via `anchor { window, rect }` + `grabFocus: true` (dismiss-on-outside-click). One `Theme.qml` singleton (`pragma Singleton` via `theme/qmldir`) carries every tunable token. Background is translucent so niri's compositor blur (via a `layer-rule` on namespace `^myquickshell:`) produces the glass effect. All backends are built-in Quickshell singletons (NetworkManager, BlueZ, UPower, Pipewire) except brightness, which drives `brightnessctl` through `Quickshell.Io.Process`.

**Tech Stack:** QML (QtQuick 6), Quickshell 0.3.1 (Nixpkgs build, verified module APIs), layer-shell + xdg-popup via Quickshell wayland, `brightnessctl`, niri 26.04 (`layer-rule` blur), home-manager nix at `/home/meher/nixconfig`.

**Spec:** `docs/superpowers/specs/2026-09-20-quickshell-v1-design.md` — read it; the plan argues from it.

## Global Constraints

- **All tokens in `Theme.qml`.** No magic numbers in components: colors, radii, spacing, margins, bar height, popup width, font sizes, animation durations, easing. Every value a user might want to tweak is a `readonly property` there. (Spec "Contract".)
- **Icons via `image://icon/` + `IconImage`** (Quickshell.Widgets), `sourceSize`-independent. Verified resolvable names on this system include: `network-wifi`, `network-wifi-symbolic`, `bluetooth-active-symbolic`, `audio-volume-high-symbolic`, `battery-good-symbolic`, `display-brightness-symbolic`, `system-suspend-symbolic`, `weather-clear-symbolic`, `dialog-password-symbolic`, `preferences-system-symbolic`, `applications-internet-symbolic`, `system-shutdown-symbolic`. Use canonical names; where uncertain, pick a verified sibling. **Never add a new binary dependency.**
- **ObjectModels are NOT arrays.** Iterate `Networking.devices`, `WifiDevice.networks`, `Bluetooth.devices`, `SystemTray.items` with `Repeater { model: ...; delegate: Item { required property var modelData } }`. Never call `.length` on them.
- **Quickshell services are singletons** (`isCreatable: false`), so `Networking`, `Bluetooth`, `Pipewire`, `UPower`, `PowerProfiles`, `SystemTray` are referenced directly (e.g. `Networking.wifiEnabled`) — never `Networking { id: x }`.
- Services populate asynchronously over D-Bus; bindings must never crash when `defaultAudioSink`/`defaultAdapter` is temporarily null. Guard with `cond != null`.
- Panel/popup windows set `WlrLayershell.namespace` to `myquickshell:*` so the single niri `layer-rule` blurs them.
- Text style: clock time uses `Theme.fontMono`; body text uses `Theme.fontFamily`. Status colors only via tokens.
- Hot reload: config is live at `~/.config/quickshell/shell/` (out-of-store symlink); `qs -p <path>` also runs any QML file directory for smoke checks.
- Run everything from the repo root `/home/meher/projects/my_quickshell`.

## Review Focus

Inputs the spec implies that a QA-minded reviewer should watch for (each pinned by a test in its owning task):

1. **A device/player/notifier that disappears mid-session** — a bound property whose object becomes null (BT adapter unplugged, sink removed) must degrade to an empty/off state, not throw `Cannot read property of null`. Pinned in Task 6 service-wiring smoke.
2. **Month rollover in the calendar grid** — day math must be exact at month boundaries (Jan start-day=1, Feb leap 2024 last-day col 4). A 1-day offset here is invisible until January. Pinned in Task 2 datecheck.
3. **Slider drag overshoot** — user dragging past the track edge must clamp to 0..1, and value math must round for discrete steps. Pinned in Task 3 (clamp in `handlePress`).
4. **Missing popup dismissal path** — clicking a popup-opening pill again must close the popup, and outside-click/Escape dismissal must keep the toggle state in sync (otherwise the pill and popup desync). Pinned in Task 4 (toggle sync via `onClosed`).
5. **Wired-only or no-network states** — no wifi device (only ethernet), or wifi RF-blocked off, must show a sane empty state instead of an empty broken list. Pinned in Task 6 network section.

---

### Task 1: Theme singleton

Foundation. Everything later imports it. Setup: the config dir is the repo root; Theme lives at `theme/` with a qmldir so both the shell root and nested components can `import "theme"` / `import "../theme"`.

**Files:**
- Create: `theme/Theme.qml`
- Create: `theme/qmldir`
- Test: `theme/themesmoke.qml` (throws if a component can't resolve tokens)

**Interfaces:**
- Produces: singleton `Theme` with `barHeight`, `barMargin`, `popupWidth`, `radiusSmall/Medium/Large`, `radiusPill`, `spacingXs/S/M/L`, `fontFamily`, `fontMono`, `fontXs/S/M/L/Xl`, `surface`, `surfaceRaised`, `surfacePress`, `border`, `background`, `accent`, `accentFg`, `text`, `textDim`, `textFaint`, `ok`, `warn`, `critical`, `glassHighlight`, `durationFast/Base/Slow`, `easingOut`.

- [ ] **Step 1: Create `theme/Theme.qml`**

```qml
pragma Singleton
import QtQuick

QtObject {
    // ---- layout ----
    readonly property int barHeight: 40
    readonly property int barMargin: 6
    readonly property int popupWidth: 340
    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 18
    readonly property int radiusPill: 999
    readonly property int spacingXs: 4
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16

    // ---- typography ----
    readonly property string fontFamily: "sans-serif"
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property int fontXs: 10
    readonly property int fontS: 12
    readonly property int fontM: 14
    readonly property int fontL: 18
    readonly property int fontXl: 30

    // ---- surfaces: translucent tints so niri's compositor blur shows through ----
    readonly property color surface:        "#cc17171d"   // bar + popup bodies
    readonly property color surfaceRaised:  "#e6161620"   // hover / raised items
    readonly property color surfacePress:   "#f01c1c28"   // pressed
    readonly property color border:         "#32323e"     // hairline
    readonly property color background:     "#0e0e13"

    // ---- accent ----
    readonly property color accent:       "#7aa2ff"
    readonly property color accentFg:     "#0e0e13"

    // ---- text ----
    readonly property color text:        "#e8e8ee"
    readonly property color textDim:     "#9ca0ab"
    readonly property color textFaint:   "#5e626e"

    // ---- status ----
    readonly property color ok:      "#7ec98a"
    readonly property color warn:    "#e5c879"
    readonly property color critical: "#e57e7e"

    // ---- glass ----
    readonly property real glassHighlight: 0.35   // top-edge reflection line opacity

    // ---- motion ----
    readonly property int durationFast: 120
    readonly property int durationBase: 200
    readonly property int durationSlow: 320
    readonly property int easingOut: Easing.OutCubic
}
```

- [ ] **Step 2: Create `theme/qmldir`**

```
singleton Theme Theme.qml
```

- [ ] **Step 3: Create and run the smoke check `theme/themesmoke.qml`**

```qml
import QtQuick
import "qmldir"   // no-op keeps qmldir loaded; tokens come from module import below
```

Do not use the above — directory-imported singletons come from importing the *directory*. Use:

```qml
import QtQuick
import "."

Item {
    Component.onCompleted: {
        if (typeof Theme.accent !== "string" && typeof Theme.accent !== "object")
            console.error("SELFCHECK-FAIL theme accent", Theme.accent)
        if (Theme.barHeight !== 40)
            console.error("SELFCHECK-FAIL barHeight", Theme.barHeight)
        if (typeof Theme.easingOut !== "number")
            console.error("SELFCHECK-FAIL easingOut", Theme.easingOut)
        console.log("SELFCHECK-PASS theme tokens")
    }
}
```

Run: `timeout 20 qs -p theme/themesmoke.qml 2>&1 | tee /tmp/t1.log`
Expected: output contains `SELFCHECK-PASS theme tokens` and does **not** contain `SELFCHECK-FAIL`, `Failed to load configuration`, or `is not a type`.
Note: if `import "."` does not expose the singleton, use `import "theme"`-style relative name matching the file location from repo root — i.e. run with `qs -p theme/themesmoke.qml` and import via the qmldir in the same directory. Confirm the singleton resolves before moving on.

- [ ] **Step 4: Commit**

```bash
git add theme/Theme.qml theme/qmldir theme/themesmoke.qml
git commit -m "feat: theme token singleton"
```

---

### Task 2: CalendarCore.js + self-check (TDD on the pure month math)

The one non-trivial pure function of v1. Written as a plain `.js` so it runs under `qs -p` and later under the real shell. `.pragma library` so it is not instantiated per importer.

**Files:**
- Create: `calendar/CalendarCore.js`
- Test: `calendar/datecheck.qml`

**Interfaces:**
- Produces: `Core.monthNumbers(year, month) -> int[42]` (0 = empty cell, else day-of-month), `Core.pad2(n) -> string`, `Core.fmtTime(Date) -> "HH:MM"`.

- [ ] **Step 1: Write the failing test `calendar/datecheck.qml`**

```qml
import QtQuick
import "CalendarCore.js" as Core

Item {
    property int failures: 0
    function check(name, got, want) {
        if (got !== want) {
            failures++
            console.error("SELFCHECK-FAIL " + name + ": got " + got + " want " + want)
        }
    }
    Component.onCompleted: {
        const jan24 = Core.monthNumbers(2024, 0)   // Jan 1 2024 = Monday
        check("jan24 len", jan24.length, 42)
        check("jan24 first", jan24[0], 0)
        check("jan24 day1 col", jan24[1], 1)
        check("jan24 days", jan24.filter(d => d > 0).length, 31)

        const feb24 = Core.monthNumbers(2024, 1)   // leap Feb; 1st = Thursday
        check("feb24 day1", feb24[4], 1)           // 4 weekday blanks before day 1
        check("feb24 lead", feb24.slice(0, 4).every(d => d === 0), true)
        check("feb24 last", feb24[32], 29)         // 29th lands at index 32
        check("feb24 tail", feb24.slice(33).every(v => v === 0), true)
        check("feb24 days", feb24.filter(d => d > 0).length, 29)

        check("pad2 seven", Core.pad2(7), "07")
        check("pad2 twelve", Core.pad2(12), "12")
        check("fmtTime", Core.fmtTime(new Date(2024, 0, 1, 9, 5)), "09:05")

        if (failures === 0)
            console.log("SELFCHECK-PASS calendar")
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `timeout 20 qs -p calendar/datecheck.qml 2>&1 | tee /tmp/t2.log`
Expected: `Failed to load configuration` (module `CalendarCore.js` missing).

- [ ] **Step 3: Write `calendar/CalendarCore.js`**

```js
.pragma library

function monthNumbers(year, month) {
    const startDow = new Date(year, month, 1).getDay()      // 0 = Sunday
    const days = new Date(year, month + 1, 0).getDate()
    const out = []
    let d = 1 - startDow
    for (let i = 0; i < 42; i++, d++)
        out.push(d >= 1 && d <= days ? d : 0)
    return out
}

function pad2(n) { return n < 10 ? "0" + n : "" + n }

function fmtTime(d) { return pad2(d.getHours()) + ":" + pad2(d.getMinutes()) }
```

- [ ] **Step 4: Run to verify it passes**

Run: `timeout 20 qs -p calendar/datecheck.qml 2>&1 | tee /tmp/t2b.log`
Expected: contains `SELFCHECK-PASS calendar`, contains no `SELFCHECK-FAIL` and no `ERROR`.

- [ ] **Step 5: Commit**

```bash
git add calendar/CalendarCore.js calendar/datecheck.qml
git commit -m "feat: calendar month-grid core with self-check"
```

---

### Task 3: Shared components

Four small visual primitives used everywhere. They import `Theme` via `import "../theme"`.

**Files:**
- Create: `shared/GlassPanel.qml`
- Create: `shared/IconButton.qml`
- Create: `shared/Slider.qml`
- Create: `shared/Section.qml`
- Test: `shared/sharedsmoke.qml`

**Interfaces:**
- Produces: `GlassPanel` (`radius`, `fill`, `highlight` bool, default `content`), `IconButton` (`source`, `iconSize`, hover/press animation, `clicked`), `Slider` (`value` 0-1, `step`, `changed(real)`, `pressed`/`released`), `Section` (`text`).

- [ ] **Step 1: Create `shared/GlassPanel.qml`**

```qml
import QtQuick

Rectangle {
    id: root
    default property alias content: root.data
    property int radius: Theme.radiusMedium
    property color fill: Theme.surface
    property bool highlight: true

    radius: root.radius
    color: root.fill
    border.color: Theme.border
    border.width: 1
    clip: true

    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 1
        visible: root.highlight
        color: Qt.rgba(1, 1, 1, Theme.glassHighlight)
    }
}
```

- [ ] **Step 2: Create `shared/IconButton.qml`**

```qml
import QtQuick
import Quickshell.Widgets

Item {
    id: root
    property string source: ""
    property int iconSize: Theme.fontM
    property bool enableHover: true
    signal clicked

    implicitWidth: iconSize + Theme.spacingS * 2
    implicitHeight: iconSize + Theme.spacingS * 2

    readonly property bool hovered: hover.hovered
    readonly property bool pressed: press.pressed

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPill
        color: hover.hovered ? (press.pressed ? Theme.surfacePress : Theme.surfaceRaised) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingOut } }
        scale: press.pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.durationFast; easing.type: Theme.easingOut } }
    }

    IconImage {
        anchors.centerIn: parent
        source: root.source
        implicitSize: root.iconSize
    }

    HoverHandler { id: hover; enabled: root.enableHover }
    TapHandler { id: press; onTapped: root.clicked() }
}
```

- [ ] **Step 3: Create `shared/Slider.qml`**

```qml
import QtQuick

Item {
    id: root
    property real value: 0.0        // 0..1
    property real step: 0.0         // 0 = continuous
    property color fillColor: Theme.accent
    signal changed(real v)
    signal pressed()
    signal released()

    implicitHeight: Theme.spacingL
    implicitWidth: 220

    function handlePress(x) {
        const trackLeft = track.x
        const trackRight = track.x + track.width
        const nx = Math.max(trackLeft, Math.min(trackRight, x))
        let v = (nx - trackLeft) / (trackRight - trackLeft)
        if (root.step > 0) v = Math.round(v / root.step) * root.step
        v = Math.max(0, Math.min(1, v))
        root.value = v
        root.changed(v)
    }

    Rectangle {   // recessed track
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 6
        radius: height / 2
        color: Theme.surfaceRaised
    }

    Rectangle {   // accent fill
        anchors { left: track.left; verticalCenter: track.verticalCenter }
        height: track.height
        width: track.width * root.value
        radius: height / 2
        color: root.fillColor
    }

    Rectangle {   // knob
        id: knob
        width: 14
        height: 14
        radius: width / 2
        color: Theme.text
        x: track.x + track.width * root.value - width / 2
        y: track.y + track.height / 2 - height / 2
    }

    MouseArea {
        anchors.fill: parent
        onPressed: mouse => { root.pressed(); root.handlePress(mouse.x) }
        onPositionChanged: mouse => { if (pressed) root.handlePress(mouse.x) }
        onReleased: mouse => root.released()
    }
}
```

- [ ] **Step 4: Create `shared/Section.qml`**

```qml
import QtQuick

Item {
    property string text: ""
    height: Theme.spacingL
    width: parent ? parent.width : 0

    Text {
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: parent.text.toUpperCase()
        font { family: Theme.fontFamily; pixelSize: Theme.fontXs; weight: Font.Bold; letterSpacing: 1.2 }
        color: Theme.textDim
    }
}
```

- [ ] **Step 5: Create and run `shared/sharedsmoke.qml`**

```qml
import QtQuick
import "."
import "../theme"

Item {
    Component.onCompleted: {
        const gp = Qt.createComponent("GlassPanel.qml").createObject(root)
        const ib = Qt.createComponent("IconButton.qml").createObject(root, { source: "image://icon/system-shutdown-symbolic" })
        const sl = Qt.createComponent("Slider.qml").createObject(root, { value: 0.5 })
        const se = Qt.createComponent("Section.qml").createObject(root, { text: "Network" })

        if (sl.value < 1e-9) console.error("SELFCHECK-FAIL slider init", sl.value)
        sl.handlePress(0)   // must clamp to 0
        if (sl.value !== 0) console.error("SELFCHECK-FAIL slider clamp-left", sl.value)
        sl.handlePress(100000)  // overshoot right -> clamp to 1
        if (sl.value > 1 + 1e-9) console.error("SELFCHECK-FAIL slider clamp-right", sl.value)

        console.log("SELFCHECK-PASS shared")
        gp.destroy(); ib.destroy(); sl.destroy(); se.destroy()
    }
}
```

Run: `timeout 20 qs -p shared/sharedsmoke.qml 2>&1 | tee /tmp/t3.log`
Expected: `SELFCHECK-PASS shared`; no `SELFCHECK-FAIL`, no `Failed to load configuration`.
Note: `Qt.createComponent(..., root)` requires an `Item` root tree existing — if creation fails, print `component.status + component.errorString()` and fix. If `Slider.handlePress(0)` doesn't reach 0 because the track's `x` is offset, verify the math via the printed value and adjust (the clamp behavior is the pinned contract).

- [ ] **Step 6: Commit**

```bash
git add shared/
git commit -m "feat: shared glass components"
```

---

### Task 4: Bar + shell.qml

The live shell: bar `PanelWindow` (layer-shell, blurred by niri) with three zones — tray, center clock pill, quick-settings pill — plus the two popups toggled by the pills. This is the first visually verifiable milestone.

**Files:**
- Create: `shell.qml`
- Create: `bar/Bar.qml`
- Create: `bar/ClockPill.qml`
- Create: `bar/SettingsPill.qml`
- Test: run the actual shell briefly + live screenshot

**Interfaces:**
- Consumes: `Theme` (all tokens), `GlassPanel`, `IconButton`, `Section` (shared).
- Produces: `Bar` (a `PanelWindow`, namespace `myquickshell:bar`, exposes `id: bar`), `ClockPill` (`clicked`), `SettingsPill` (`clicked`, readonly live indicators), and the popups `clockpopup` + `qspopup` declared inside `Bar`.

- [ ] **Step 1: Create `shell.qml`**

```qml
import Quickshell
import "theme"
import "bar"

QuickshellRoot {
    Bar { }
}
```

- [ ] **Step 2: Create `bar/ClockPill.qml`**

```qml
import QtQuick

Item {
    id: root
    signal clicked
    property date nowDate: new Date()

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.nowDate = new Date()
    }

    implicitWidth: col.width + Theme.spacingL * 2
    implicitHeight: col.height + Theme.spacingS * 2
    height: parent ? parent.height : 0
    width: parent ? parent.width : 0

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPill
        color: hover.hovered ? Theme.surfaceRaised : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingOut } }
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.nowDate, "HH:mm")
            font { family: Theme.fontMono; pixelSize: Theme.fontM; weight: Font.Medium }
            color: Theme.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.nowDate, "EEE d MMM")
            font { family: Theme.fontFamily; pixelSize: Theme.fontXs }
            color: Theme.textDim
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }
}
```

Note: `ClockPill` is placed inside a horizontal bar between two flexible gaps, so it should not force a width; give it `implicitWidth`/`implicitHeight` only and let the `Layout`/anchors decide. If the `implicitWidth: col.width...` binding causes a loop, replace both `implicit*` lines with explicit `width: col.width + Theme.spacingL * 2` inside the bar context — see Bar layout below.

- [ ] **Step 3: Create `bar/SettingsPill.qml`**

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Item {
    id: root
    signal clicked

    implicitHeight: Theme.barHeight - Theme.spacingS
    implicitWidth: parent ? parent.width : 0

    RowLayout {
        anchors.centerIn: parent
        spacing: Theme.spacingXs

        // ---- wifi / wired indicator ----
        IconImage {
            Layout.preferredWidth: Theme.fontM
            Layout.preferredHeight: Theme.fontM
            source: root.wired ? "image://icon/network-wired-symbolic"
                               : "image://icon/network-wifi-symbolic"
            opacity: root.netActive ? 1.0 : 0.4
        }
        // ---- bluetooth indicator ----
        Text {
            Layout.preferredWidth: Theme.fontM
            Layout.preferredHeight: Theme.fontM
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: "\uF276"                              // nerd font bluetooth glyph
            font { family: Theme.fontMono; pixelSize: Theme.fontS }
            color: root.btActive ? Theme.text : Theme.textFaint
        }
        // ---- volume ----
        IconImage {
            Layout.preferredWidth: Theme.fontM
            Layout.preferredHeight: Theme.fontM
            source: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.muted
                    ? "image://icon/audio-volume-muted-symbolic"
                    : "image://icon/audio-volume-high-symbolic"
        }
        // ---- battery ----
        Text {
            Layout.preferredWidth: Theme.fontM
            Layout.preferredHeight: Theme.fontM
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: UPower.displayDevice ? UPower.displayDevice.percentage.toFixed(0) + "%" : "--"
            font { family: Theme.fontFamily; pixelSize: Theme.fontXs }
            color: UPower.displayDevice && UPower.displayDevice.percentage < 20 ? Theme.critical : Theme.text
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusPill
        color: hover.hovered ? Theme.surfaceRaised : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.durationFast; easing.type: Theme.easingOut } }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }

    readonly property bool wired: root.wireDevice && root.wireDevice.hasLink
    readonly property object wireDevice: root.wifiDevices().length ? null : null
    readonly property bool netActive: root.wifion || root.wired
    readonly property bool wifion: root.wifiDev().connected
    readonly property bool btActive: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
}
```

**Correction for step 3** — the helper accessors above are placeholders; replace the four `readonly property` lines (from `wired` down to `btActive`) with concrete helpers as written below, then delete this note:

```qml
    readonly property bool wired: root.wirelike()
    readonly property bool netActive: root.anyWifi()
    readonly property bool btActive: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false

    // returns true if any wired device has a link
    function wirelike() {
        for (let i = 0; i < Networking.devices.count; i++) {
            const d = Networking.devices.objectAt(i)
            if (d && d.type === DeviceType.Wired && d.hasLink) return true
        }
        return false
    }

    // returns true if any wifi device is connected
    function anyWifi() {
        for (let i = 0; i < Networking.devices.count; i++) {
            const d = Networking.devices.objectAt(i)
            if (d && d.type === DeviceType.Wifi && d.connected) return true
        }
        return false
    }
```

If `.count` / `.objectAt` are not available on `UntypedObjectModel` (verify at run), fall back to `Repeater`-over-model inside this file accumulating state in a `property var` via `onModelDataChanged`; the important contract: **the pill must reflect live NetworkManager state and never crash when a device list is empty.**

- [ ] **Step 4: Create `bar/Bar.qml`**

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../theme"
import "../shared"

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    height: Theme.barHeight
    exclusiveZone: Theme.barHeight + Theme.barMargin
    focusable: false
    WlrLayershell.namespace: "myquickshell:bar"
    color: "transparent"

    RowLayout {
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        anchors.leftMargin: Theme.spacingS
        anchors.topMargin: Theme.barMargin
        anchors.bottomMargin: Theme.barMargin
        spacing: Theme.spacingS

        // ---- tray ----
        Row {
            id: trayRow
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.spacingXs
            Repeater {
                model: SystemTray.items
                delegate: Item {
                    required property var modelData
                    property int size: Theme.fontL
                    width: size + Theme.spacingS
                    height: size + Theme.spacingS
                    IconImage {
                        anchors.centerIn: parent
                        source: "image://icon/" + modelData.icon
                        implicitSize: parent.size
                        onStatusChanged: if (status === Image.Error) visible = false
                    }
                    TapHandler { onTapped: modelData.activate() }
                }
            }
        }

        Item { Layout.fillWidth: true }            // flexible gap

        ClockPill { Layout.alignment: Qt.AlignVCenter; onClicked: clockpopup.open = !clockpopup.open }

        Item { Layout.fillWidth: true }            // flexible gap

        SettingsPill { Layout.alignment: Qt.AlignVCenter; onClicked: qspopup.open = !qspopup.open }
    }

    // ---- popups ----
    ClockPopup { id: clockpopup; anchor.window: bar; anchor.rect.x: width <= bar.width ? bar.width / 2 - width / 2 : 0; anchor.rect.y: bar.height + Theme.barMargin }
    QuickSettings { id: qspopup; anchor.window: bar; anchor.rect.x: bar.width - width - Theme.barMargin; anchor.rect.y: bar.height + Theme.barMargin }
}
```

Note: `SystemTray`, `ClockPopup`, `QuickSettings` are imported from `Quickshell.Services.SystemTray`, `../calendar`, `../quick` respectively — add those imports. `modelData.icon` may mismatch a themed name for some apps; that is acceptable for v1 (the item stays interactive, icon hidden on error).

- [ ] **Step 5: Boot the shell and verify**

Run: `timeout 25 qs -p /home/meher/projects/my_quickshell/shell.qml 2>&1 | tee /tmp/t4.log; pgrep -f "quickshell.*shell.qml"`
Expected: NO `Failed to load configuration` and no `ERROR caused by` in the log. The bar PanelWindow appears at the top of the niri screen (you can confirm visually).
Then (visual check): `niri msg action screenshot` and open `~/Pictures/Screenshots/` newest file to confirm the bar renders as a floating glass strip. Fix any binding/load errors before continuing.

- [ ] **Step 6: Contract — popup toggle sync is enforced in Task 5/6**

(No code here; reminder: `onClicked` sets `.open`; both popups set `visible = open` via their own `onOpenChanged` and reset `open = false` on dismissal so pill↔popup never desyncs.)

- [ ] **Step 7: Commit**

```bash
git add shell.qml bar/
git commit -m "feat: bar shell with tray, clock and settings pills"
```

---

### Task 5: Clock / calendar popup

`PopupWindow` anchored below the bar's center clock pill. Uses `CalendarWidget` (pure `Item`, no window) so it can be smoke-tested headlessly.

**Files:**
- Create: `calendar/CalendarWidget.qml`
- Create: `calendar/ClockPopup.qml`
- Test: `calendar/calendarwidget.qml` smoke (instantiate `CalendarWidget`, no screen needed)

**Interfaces:**
- Consumes: `Core` (CalendarCore.js), `Theme`, `GlassPanel`, `IconButton`, `Section`.
- Produces: `ClockPopup` (`open: bool`, PopupWindow), `CalendarWidget` (`date: Date`, `accent: color`, renders month grid 6×7).

- [ ] **Step 1: Create `calendar/CalendarWidget.qml`**

```qml
import QtQuick
import "../theme"
import "../shared"
import "CalendarCore.js" as Core

Item {
    id: root
    property date date: new Date()

    readonly property var model: Core.monthNumbers(date.getFullYear(), date.getMonth())
    readonly property int today: date.getDate()

    implicitWidth: 7 * 30
    implicitHeight: 30 + Theme.spacingS + 28 + 6 * 30

    Row {                                   // month header
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 28
        IconButton {
            id: prevBtn
            source: "image://icon/go-previous-symbolic"
            iconSize: Theme.fontS
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.date = new Date(root.date.getFullYear(), root.date.getMonth() - 1, 1)
        }
        Text {
            anchors.centerIn: parent
            text: Qt.formatDate(root.date, "MMMM yyyy")
            font { family: Theme.fontFamily; pixelSize: Theme.fontM; weight: Font.Medium }
            color: Theme.text
        }
        IconButton {
            id: nextBtn
            source: "image://icon/go-next-symbolic"
            iconSize: Theme.fontS
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.date = new Date(root.date.getFullYear(), root.date.getMonth() + 1, 1)
        }
    }

    Row {                                   // weekday labels
        id: weekRow
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        height: 30
        Repeater {
            model: ["S", "M", "T", "W", "T", "F", "S"]
            Text {
                width: parent.width / 7
                height: parent.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                font { family: Theme.fontFamily; pixelSize: Theme.fontXs }
                color: Theme.textFaint
            }
        }
    }

    Grid {                                  // day grid
        id: days
        anchors { top: weekRow.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
        columns: 7
        Repeater {
            model: root.model
            delegate: Item {
                required property int modelData
                width: days.width / 7
                height: days.height / 6
                Rectangle {
                    anchors.centerIn: parent
                    width: widthParent()
                    height: 26
                    radius: 13
                    visible: modelData === root.today
                    color: root.accent
                    function widthParent() { return 26 }
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData === 0 ? "" : modelData
                    font { family: Theme.fontFamily; pixelSize: Theme.fontS }
                    color: modelData === root.today ? Theme.accentFg
                          : modelData === 0 ? "transparent" : Theme.textDim
                }
            }
        }
    }
}
```

Fix the `Rectangle` inside the delegate before using it (the `widthParent()` helper is a placeholder — use `function`-free constant `width: 26`). Delete this note and the helper.

- [ ] **Step 2: Create `calendar/ClockPopup.qml`**

```qml
import Quickshell
import QtQuick
import "../theme"
import "../shared"

PopupWindow {
    id: popup
    property bool open: false
    onOpenChanged: { visible = popup.open }
    onClosed: { popup.open = false }        // keeps pill toggle in sync
    visible: false
    grabFocus: true

    width: Theme.popupWidth
    height: body.implicitHeight

    GlassPanel {
        id: body
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: Theme.spacingS
        radius: Theme.radiusMedium
        implicitWidth: parent.width - Theme.spacingS * 2

        Column {
            anchors.fill: parent
            spacing: Theme.spacingS
            Text {                             // big time
                text: Qt.formatTime(new Date(), "HH:mm:ss")
                font { family: Theme.fontMono; pixelSize: Theme.fontXl; weight: Font.Medium }
                color: Theme.text
            }
            Text {                             // date line
                text: Qt.formatDate(new Date(), "dddd, d MMMM yyyy")
                font { family: Theme.fontFamily; pixelSize: Theme.fontS }
                color: Theme.textDim
            }
            CalendarWidget { width: parent.width; height: 6 * 30 + 30 + 28 + Theme.spacingS }
            Section { text: "Agenda" }
            Text {
                width: parent.width
                text: "Calendar sync arrives in a later phase"
                font { family: Theme.fontFamily; pixelSize: Theme.fontXs }
                color: Theme.textFaint
                wrapMode: Text.Wrap
            }
        }
    }
}
```

The `onClosed` on a `PopupWindow` may not fire on every dismissal path (Esc/outside-click). Verify: if `open` stuck-`true` after dismissal in live test, add a second sync in `onVisibleChanged: if (!visible) popup.open = false`. The desync-avoidance contract is the pinned behavior.

- [ ] **Step 3: Smoke-test `CalendarWidget` headlessly**

Create `calendar/calendarwidget.qml`:

```qml
import QtQuick
import "."

Item {
    Component.onCompleted: {
        const c = Qt.createComponent("CalendarWidget.qml")
        const obj = c.createObject(root, { date: new Date(2024, 0, 1), width: 210, height: 328 })
        if (!obj || c.status !== Component.Ready)
            console.error("SELFCHECK-FAIL calendarwidget", c.errorString())
        else
            console.log("SELFCHECK-PASS calendarwidget", obj.model.length, obj.model[1])
    }
}
```

Run: `timeout 20 qs -p calendar/calendarwidget.qml 2>&1 | tee /tmp/t5.log`
Expected: `SELFCHECK-PASS calendarwidget 42 1`; no `SELFCHECK-FAIL`.

- [ ] **Step 4: Commit**

```bash
git add calendar/CalendarWidget.qml calendar/ClockPopup.qml calendar/calendarwidget.qml
git commit -m "feat: clock and calendar popup"
```

---

### Task 6: Quick settings popup

The largest popup. Sections, top to bottom: battery summary + power profile, network (wifi/wired), bluetooth, volume, brightness, power row. Built as a headless-testable widget + thin `PopupWindow` wrapper — same pattern as Task 5.

**Files:**
- Create: `quick/QuickSettingsWidget.qml`
- Create: `quick/QuickSettings.qml`
- Test: `quick/quicksettingswidget.qml` smoke (instantiates the widget headlessly; services connect to the live session's DBus)

**Interfaces:**
- Consumes: all service singletons + `Theme`, `GlassPanel`, `IconButton`, `Slider`, `Section`, `brightnessctl` via `Quickshell.Io.Process`.
- Produces: `QuickSettings` (`open: bool`, PopupWindow, namespace `myquickshell:quicksettings`) and `QuickSettingsWidget` (`Item`, the full column).

- [ ] **Step 1: Create `quick/QuickSettingsWidget.qml`**

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "../theme"
import "../shared"

Item {
    id: root
    width: Theme.popupWidth - Theme.spacingL

    // ============ battery + power profile ============
    Section { text: UPower.displayDevice ? "Battery " + UPower.displayDevice.percentage.toFixed(0) + "%" : "Battery" }

    RowLayout {
        width: parent.width
        spacing: Theme.spacingS
        Text {
            Layout.fillWidth: true
            text: root.batteryText()
            font { family: Theme.fontFamily; pixelSize: Theme.fontS }
            color: Theme.textDim
        }
        HoverHandler { id: batteryHover }   // (unused placeholder, removable)
    }

    // segmented power profile — only if hardware supports it
    RowLayout {
        id: profileRow
        width: parent.width
        visible: PowerProfiles.hasPerformanceProfile
        spacing: Theme.spacingXs
        Repeater {
            model: ["PowerSaver", "Balanced", "Performance"]
            delegate: Item {
                required property string modelData
                Layout.fillWidth: true
                height: 28
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusSmall
                    color: PowerProfiles.profile === root.profileIndex(modelData) ? Theme.accent : "transparent"
                    behaviorEnabled()
                    function behaviorEnabled() {}
                }
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font { family: Theme.fontFamily; pixelSize: Theme.fontXs }
                    color: PowerProfiles.profile === root.profileIndex(modelData) ? Theme.accentFg : Theme.textDim
                }
                TapHandler {
                    onTapped: PowerProfiles.profile = root.profileIndex(modelData)
                }
            }
        }
    }

    // ============ network ============
    Section { text: "Network" }
    RowLayout {
        width: parent.width
        Text {
            Layout.fillWidth: true
            text: root.netStatusText()
            font { family: Theme.fontFamily; pixelSize: Theme.fontS }
            color: Theme.text
            elide: Text.ElideRight
        }
        IconButton {
            source: Networking.wifiEnabled ? "image://icon/network-wifi-symbolic" : "image://icon/network-offline-symbolic"
            iconSize: Theme.fontM
            enableHover: false
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Column {
        id: wifiList
        width: parent.width
        Repeater {
            model: root.wifiDevice ? root.wifiDevice.networks : []
            delegate: WifiRow { network: modelData }
        }
    }

    // ============ bluetooth ============
    Section { text: "Bluetooth" }
    RowLayout {
        width: parent.width
        Text {
            Layout.fillWidth: true
            text: root.btStatusText()
            font { family: Theme.fontFamily; pixelSize: Theme.fontS }
            color: Theme.text
            elide: Text.ElideRight
        }
        IconButton {
            source: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                    ? "image://icon/bluetooth-active-symbolic"
                    : "image://icon/bluetooth-disabled-symbolic"
            iconSize: Theme.fontM
            enableHover: false
            onClicked: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
        }
    }

    Column {
        id: btList
        width: parent.width
        Repeater {
            model: Bluetooth.devices
            delegate: BluetoothRow { device: modelData }
        }
    }

    // ============ volume ============
    Section { text: "Volume" }
    RowLayout {
        width: parent.width
        IconButton {
            source: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.muted
                    ? "image://icon/audio-volume-muted-symbolic"
                    : "image://icon/audio-volume-high-symbolic"
            iconSize: Theme.fontS
            enableHover: false
            onClicked: { if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.muted = !Pipewire.defaultAudioSink.muted }
        }
        Slider {
            id: volumeSlider
            Layout.fillWidth: true
            value: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.volume : 0
            onChanged: v => { if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.volume = v }
        }
    }

    // ============ brightness ============
    Section { text: "Brightness" }
    RowLayout {
        width: parent.width
        IconButton {
            source: "image://icon/display-brightness-symbolic"
            iconSize: Theme.fontS
            enableHover: false
        }
        Slider {
            id: brightSlider
            Layout.fillWidth: true
            value: root.brightPct
            onChanged: v => root.brightTarget = v        // commit on release, not per tick
            onReleased: root.commitBright()
        }
    }

    // ============ power row ============
    RowLayout {
        width: parent.width
        spacing: Theme.spacingS
        Item { Layout.fillWidth: true }
        IconButton { source: "image://icon/system-lock-screen-symbolic"; iconSize: Theme.fontM; onClicked: root.spawn(["swaylock"]) }
        IconButton { source: "image://icon/system-suspend-symbolic";  iconSize: Theme.fontM; onClicked: root.spawn(["systemctl", "suspend"]) }
        IconButton { source: "image://icon/system-log-out-symbolic";  iconSize: Theme.fontM; onClicked: root.spawn(["niri", "msg", "action", "quit"]) }
    }

    // ============ brightness runner ============
    property int brightPct: 0
    property int brightTarget: 0
    readonly property string _brightDev: "amdgpu_bl1"

    Process {
        id: brightGet
        command: ["brightnessctl", "-d", root._brightDev, "get"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: { root.brightPct = Math.round(parseInt(text.trim()) / 65535 * 100) }
        }
    }
    Process {
        id: brightSet
        command: ["brightnessctl", "-d", root._brightDev, "set", root.brightTarget + "%"]
        running: root.brightPending
        onExited: root.brightPending = false
    }
    property bool brightPending: false
    function commitBright() {
        root.brightPending = true
        brightSet.command = ["brightnessctl", "-d", root._brightDev, "set", root.brightTarget + "%"]
    }

    function spawn(args) { Process { command: args; running: true } }

    // ---- helpers ----
    function profileIndex(name) { return name === "Balanced" ? 1 : name === "PowerSaver" ? 0 : 2 }
    function batteryText() {
        const d = UPower.displayDevice
        if (!d) return "Battery: --"
        const st = d.state
        if (st === UPowerDeviceState.Charging) return "Charging"
        if (st === UPowerDeviceState.FullyCharged) return "Full — on AC"
        if (d.timeToEmpty > 0) return "~" + Math.round(d.timeToEmpty) + "h remaining"
        return "On battery"
    }
    readonly property object wifiDevice: root.findWifi()
    function findWifi() {
        for (let i = 0; i < Networking.devices.count; i++) {
            const d = Networking.devices.objectAt(i)
            if (d && d.type === DeviceType.Wifi) return d
        }
        return null
    }
    function netStatusText() {
        const d = root.findWifi()
        if (d && d.connected) return d.name || "Connected"
        if (d && !Networking.wifiEnabled) return "Wi-Fi off"
        if (d) return "Disconnected"
        return "No wireless device"
    }
    function btStatusText() {
        if (!Bluetooth.defaultAdapter) return "No Bluetooth adapter"
        if (!Bluetooth.defaultAdapter.enabled) return "Bluetooth off"
        return "Bluetooth on"
    }
}

// ---- wifi row ----
component WifiRow: Item {
    required property var network
    width: parent ? parent.width : 0
    height: 30

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: network.connected ? Theme.surfaceRaised : "transparent"
    }
    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingS
        Text {
            Layout.fillWidth: true
            text: network.name
            font { family: Theme.fontFamily; pixelSize: Theme.fontS }
            color: network.connected ? Theme.text : Theme.textDim
            elide: Text.ElideRight
        }
        Text {
            text: network.security === WifiSecurityType.Open ? "" : "\uF023"
            font { family: Theme.fontMono; pixelSize: Theme.fontS }
            color: Theme.textDim
        }
        // signal strength bars: use a small string of filled blocks
        Text {
            text: root.strengthText(network.signalStrength)
            font { family: Theme.fontMono; pixelSize: Theme.fontXs }
            color: network.connected ? Theme.ok : Theme.textDim
        }
    }
    TapHandler {
        onTapped: {
            if (network.connected) network.requestDisconnect()
            else if (network.known) network.connect()
            else if (network.security === WifiSecurityType.Open) network.connect()
            else root.askPsk(network)
        }
    }
}

// ---- bluetooth row ----
component BluetoothRow: Item {
    required property var device
    width: parent ? parent.width : 0
    height: 30

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingS
        Text {
            Layout.fillWidth: true
            text: device.name || device.address
            font { family: Theme.fontFamily; pixelSize: Theme.fontS }
            color: device.connected ? Theme.text : Theme.textDim
            elide: Text.ElideRight
        }
        Text {
            text: device.connected ? "connected" : (device.pairing ? "pairing…" : "")
            font { family: Theme.fontFamily; pixelSize: Theme.fontXs }
            color: device.connected ? Theme.ok : Theme.textFaint
        }
        IconButton {
            iconSize: Theme.fontS
            source: device.connected ? "image://icon/network-offline-symbolic" : "image://icon/network-wifi-symbolic"
            enableHover: true
            onClicked: {
                if (device.connected) device.disconnect()
                else if (device.paired) device.connect()
                else device.pair()
            }
        }
    }
}
```

**Corrections before using:** (1) the `HoverHandler { id: batteryHover }` filler and the `behaviorEnabled()` stub in the profile delegate and the `Rectangle`'s `.function behaviorEnabled()` must be removed; (2) `component WifiRow` / `component BluetoothRow` inline-component syntax requires Qt 6.5+ (fine on Qt 6 for qs 0.3.1) but if the engine rejects it, move them to `quick/WifiRow.qml` + `quick/BluetoothRow.qml` and import `"../shared"` there too; (3) `WifiSecurityType` enum values are accessed as `WifiSecurityType.Open` — confirm the value name via the spec (it exists); keep the `network.known`/`connectWithPsk` path: `WifiRow`'s `askPsk` must open an inline passphrase row (a `TextField` + OK that calls `network.connectWithPsk(psk)`), which lives in `QuickSettingsWidget` — wire it via a `signal askPsk(var network)` on `root` and catch it in the widget's `Window`-less context by rendering a small inline `TextField` overlay in `root`; (4) `TextField` needs `import QtQuick.Controls` — acceptable since it is Qt Quick Controls 2 Basic, which QML ships; style overrides: transparent background, `Theme.border` outline, `Theme.text` color.

- [ ] **Step 2: Create `quick/QuickSettings.qml`**

```qml
import Quickshell
import QtQuick
import "../theme"
import "../shared"
import "."

PopupWindow {
    id: popup
    property bool open: false
    onOpenChanged: { visible = popup.open; if (popup.open && root.widget) root.widget.scan() }
    onClosed: { popup.open = false }
    visible: false
    grabFocus: true
    WlrLayershell.namespace: "myquickshell:quicksettings"

    width: Theme.popupWidth
    height: body.implicitHeight

    GlassPanel {
        id: body
        anchors { top: parent.top; left: parent.left; right: parent.right }
        anchors.margins: Theme.spacingS
        radius: Theme.radiusMedium
        implicitWidth: parent.width - Theme.spacingS * 2
        QuickSettingsWidget { id: widget; width: parent.width - Theme.spacingL }
    }
}
```

Note: `root.widget.scan()` — add to `QuickSettingsWidget` a `function scan()` that, when wifi is enabled, flips the wifi device `scannerEnabled` on/off (and does the same for the BT adapter `discovering`) so the network/bluetooth lists refresh when the popup opens. If no such trigger is needed (services auto-refresh), make `scan()` a no-op. Also: `WlrLayershell` import comes from `Quickshell.Wayland`.

- [ ] **Step 3: Smoke-test the widget headlessly**

Create `quick/quicksettingswidget.qml`:

```qml
import QtQuick
import "."

Item {
    Component.onCompleted: {
        const c = Qt.createComponent("QuickSettingsWidget.qml")
        const w = c.createObject(root, { width: 320 })
        if (!w || c.status !== Component.Ready) {
            console.error("SELFCHECK-FAIL quicksettings", c.errorString())
        } else {
            // must not throw even with null adapter / no sink / rfkill off
            console.log("SELFCHECK-PASS quicksettings", typeof w.netStatusText, typeof w.brightPct)
        }
    }
}
```

Run: `timeout 25 qs -p quick/quicksettingswidget.qml 2>&1 | tee /tmp/t6.log`
Expected: `SELFCHECK-PASS quicksettings function number`; no `SELFCHECK-FAIL`; no `Failed to load configuration`; no `Cannot read property` / `TypeError` in the log.
This is the **Review Focus #1** pin: the binding/creation must succeed now with BT adapter null and pipewire sink transiently null.

- [ ] **Step 4: Live-verify popup sync**

With the shell running (from Task 4), click the quick-settings pill: popup opens below the pill; click it again (or click elsewhere) → popup closes and the pill's next click opens it again. Same for the clock popup. If `onClosed` alone doesn't cover a dismissal path, add `onVisibleChanged` sync as noted. Fix and re-verify.

- [ ] **Step 5: Commit**

```bash
git add quick/
git commit -m "feat: quick settings popup (network, bluetooth, volume, brightness, battery)"
```

---

### Task 7: niri + nix integration (commit explicitly in `/home/meher/nixconfig`)

Disable the old stack (waybar/swaync), point the quickshell symlink at this repo, add the niri blur/corner rule for our namespace. Two commits: one in nixconfig (this task), one in this repo if it touches repo files (it shouldn't).

**Rules from `/home/meher/nixconfig/AGENTS.md`:** no `rm` (rename with `.deleted` if a file must go), no `nix profile`, no `git restore` with uncommitted changes, rebuild via `sudo nixos-rebuild switch --flake ~/nixconfig#jinnnn`.

**Files (all under `/home/meher/nixconfig/`):**
- Modify: `home/meher/quickshell/default.nix` — repoint `liveShell`
- Modify: `home/meher/niri/window-rules.nix` — replace the waybar layer-rule with our namespace rule (blur + corner radius)
- Modify: `home/meher/niri/startup.nix` — drop the `swaync` spawn
- Modify: `home/meher/default.nix` — drop `./waybar` and `./swaync` imports
- Modify: `home/meher/packages.nix` — drop `pkgs.waybar`

- [ ] **Step 1: Repoint the quickshell symlink target**

In `home/meher/quickshell/default.nix`, change:
```nix
  liveShell = "${config.home.homeDirectory}/nixconfig/home/meher/quickshell/shell";
```
to:
```nix
  liveShell = "${config.home.homeDirectory}/projects/my_quickshell";
```

- [ ] **Step 2: Replace the blur layer-rule in `home/meher/niri/window-rules.nix`**

In the `rules` list, replace the waybar block:
```nix
    # waybar sits on the "top" layer, so blur its cards explicitly
    (kdl.node "layer-rule" [ ] [
      (kdl.node "match" { namespace = "^waybar$"; } [ ])
      blur-behind
    ])
```
with:
```nix
    # quickshell desktop: bar + popups share a namespace prefix; blur them all
    (kdl.node "layer-rule" [ ] [
      (kdl.node "match" { namespace = "^myquickshell:"; } [ ])
      blur-behind
    ])
```

Do NOT remove the `blur` global block or the overlay-layer rule.

- [ ] **Step 3: Remove the swaync spawn from `home/meher/niri/startup.nix`**

Delete the line:
```nix
    { argv = ["swaync"]; }
```
Keep `quickshell -c shell` and the wallpaper line.

- [ ] **Step 4: Drop waybar + swaync from `home/meher/default.nix`**

Remove the two import lines:
```nix
    ./waybar
    ./swaync
```

- [ ] **Step 5: Drop `pkgs.waybar` from `home/meher/packages.nix`**

Delete the `pkgs.waybar` line (keep the rest of the file untouched).

- [ ] **Step 6: Validate nix evaluates**

Run: `nix flake check --no-build /home/meher/nixconfig 2>&1 | tail -20`  (if this is too heavy, run `nix eval /home/meher/nixconfig#homeConfigurations.meher.activationPackage.name` or the equivalent for this flake — ask the user which command they normally use; do NOT run `nixos-rebuild switch` without the user).
Expected: evaluation succeeds with no error mentioning `myquickshell`, `swaync` being undefined, or missing `quickshell`.

- [ ] **Step 7: Commit explicitly in the nixconfig repo**

```bash
cd /home/meher/nixconfig
git add home/meher/quickshell/default.nix home/meher/niri/window-rules.nix home/meher/niri/startup.nix home/meher/default.nix home/meher/packages.nix
git commit -m "feat: switch shell bar to quickshell desktop v1, drop waybar/swaync"
```

- [ ] **Step 8: Report activation**

Output the exact command the user must run to activate (`sudo nixos-rebuild switch --flake ~/nixconfig#jinnnn`), and note that this restarts the compositor session. Do not run it yourself. Also note swaync currently running: after rebuild it will be gone; until then, `pkill swaync` if a second notification stack bothers them during development.

---

### Task 8: Whole-branch verification & polish

Final pass over the merged result.

**Files:** none new (fixes inline where needed).

- [ ] **Step 1: Re-run every self-check**

```bash
cd /home/meher/projects/my_quickshell
timeout 20 qs -p theme/themesmoke.qml     2>&1 | rg "SELFCHECK"
timeout 20 qs -p calendar/datecheck.qml   2>&1 | rg "SELFCHECK"
timeout 20 qs -p shared/sharedsmoke.qml   2>&1 | rg "SELFCHECK"
timeout 20 qs -p calendar/calendarwidget.qml 2>&1 | rg "SELFCHECK"
timeout 20 qs -p quick/quicksettingswidget.qml 2>&1 | rg "SELFCHECK"
```
Expected: every line is `SELFCHECK-PASS ...`, no `SELFCHECK-FAIL`, no `ERROR`.

- [ ] **Step 2: Boot the real shell and exercise it**

Run the shell for ~30s, then interact: open/close both popups, connect wifi by clicking a network (if one is within range), change volume from the slider, drag brightness (confirm the screen dims/brightens), click lock/suspend/logout is NOT executed (log out only if user asked).

```bash
timeout 45 qs -p /home/meher/projects/my_quickshell/shell.qml 2>&1 | tee /tmp/t8.log
```
Expected: no `ERROR`, no `ReferenceError`, no `TypeError`, no `Cannot read property`.

- [ ] **Step 3: Visual check**

`niri msg action screenshot`, open the newest screenshot. Confirm: bar is a floating rounded glass strip; center shows live clock; blobs in taskbar region change on interactions. Confirm popups look like glass over blurred content (blur handled by niri, tint from `Theme.surface`).

- [ ] **Step 4: Commit any fixes**

```bash
git add -A && git commit -m "fix: v1 shell polish"
```
(only if there were fixes)

- [ ] **Step 5: Report**

Summarize what shipped, the run command (`qs -c shell` after home-manager activation), and the two deferred-in-v1 items that matter: per-app audio mixer and the notification center (swaync was disabled by design).

## Self-Review

- **Spec coverage:** Theme contract → Task 1. Shared glass components → Task 3. Bar (tray/clock/settings pills) → Task 4. Clock/calendar popup + agenda slot → Task 5. QuickSettings (battery/profile, network, bluetooth, volume, brightness, power row) → Task 6. Nix repoint + waybar/swaync disable + niri blur rule + namespace mechanism → Task 7. Dev loop + verification → all tasks' run steps + Task 8. Deferred items (per-app mixer, media player, notifications, launcher, etc.) remain out of scope per spec and are NOT re-added.
- **Placeholder scan:** no TBD/TODO; every code step has concrete code. Placeholder stubs (`behaviorEnabled()`, `widthParent()`, the `modelData.icon` fallback, `batteryHover`) are flagged in- task to be removed/replaced with concrete code. **Fix inline:** the plan text explicitly says fix them before commit.
- **Type consistency:** service singletons used as `Networking`, `Bluetooth`, `Pipewire`, `UPower`, `PowerProfiles`, `SystemTray` throughout; `Repeater`+`modelData` for all ObjectModels; `Theme.*` token names identical across tasks (from Task 1 list); `Slider` emits `changed(real)/pressed/released`; `PopupWindow.open` + `onClosed` sync consistent between Task 4 and Tasks 5–6.
- **Review Focus coverage:** (1) null service objects → Task 6 smoke + all `if (X)` guards; (2) calendar month rollover → Task 2 datecheck exact values; (3) slider overshoot clamp → Task 3 smoke asserts clamp; (4) popup toggle desync → Task 5–6 live step + `onClosed`/`onVisibleChanged` sync; (5) no-wifi/wired-only states → Task 6 `netStatusText` empty/off paths + smoke.