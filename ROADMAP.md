# ROADMAP.md — my_quickshell

Planned features and known gaps, roughly in priority order.

## In Progress / Recently Done

- [x] Status bar with left/center/right layout
- [x] Workspaces module (Niri IPC, sliding highlight, dots)
- [x] Clock, Volume, Brightness, Network, SystemTray modules
- [x] Full settings GUI (6 pages, animated nav, page transitions)
- [x] Settings persistence (JSON, auto-save on change, debounced 500ms)
- [x] Workspace click-to-switch (`niri msg action focus-workspace`)
- [x] SystemTray wired into bar layout (`"systemtray"` module name)
- [x] Clock timer fix (60s interval when seconds hidden, was hardcoded 1000ms)
- [x] IPC toggle (`Mod+I`, desktop entry, fuzzel)
- [x] Nix integration (`~/nixconfig` wired, symlink, keybind, auto-restart loop)
- [x] Settings controls get `import "../.."` for Settings singleton access
- [x] `FileView.watchFiles` → `watchChanges` (correct Quickshell 0.3.1 API)
- [x] `pageStack.pages` array replaced with `pageAt(i)` function (was undefined at init → segfault)
- [x] `SettingsWindow.onClosed` — intercepts `Mod+Q` compositor close, hides instead of destroying
- [x] Toggle debounce (600ms) — prevents key-repeat flood crashing the shell
- [x] `niri keybind Mod+I` — `repeat = false` + full path to quickshell binary
- [x] Desktop entry — full path to quickshell binary (not in PATH for fuzzel/compositor children)
- [x] Volume `ready` guard — prevents writing to unbound pipewire nodes
- [x] `STextInput` ready guard — prevents `onTextChanged` firing during component init
- [x] `SettingsRow` control vertical centering fix (`childrenRect.height` not `parent.height`)
- [x] Niri startup uses restart loop (`while true; do qs; sleep 2; done`)
- [x] Settings page switching fixed — pages use manual show/hide, not `visible` bindings
- [x] `SettingsPage` — removed `QtQuick.Controls` import (Adwaita theme was painting over it)
- [x] **App launcher** (`LauncherWindow.qml`) — grid launcher with search, icon loading, keyboard nav
- [x] Launcher replaces fuzzel (`Mod+D` / `Mod+Space` → `toggleLauncher` IPC)

---

## Short Term

### Launcher — Spotlight-style redesign
Current launcher is a basic grid. Planned redesign inspired by macOS Spotlight:

**Animation sequence:**
1. Trigger (`Mod+D`) → a pill/bar "circles out" from screen center (scale + fade from a point)
2. The pill is just a search bar at first — minimal, centered, floating
3. As you type, results "drop" below the search bar like a water droplet separating from the pill
4. Results panel slides/fades in beneath the search bar, detached
5. Close → results retract back up, bar collapses back to a point

**Layout:**
- Search bar: centered, ~600px wide, pill-shaped, large icon + text input
- Results: appear below the bar, in a clean list (not grid) with icon + name + category
- Top results highlighted, arrow keys navigate, Enter launches
- No backdrop dimming — the bar floats over whatever is on screen

### Settings — missing pages
The settings window has no page for the SystemTray or the global SettingsUI appearance (accent color, fonts, blur). These should be added:
- `PageSystemTray.qml` — icon size, spacing
- `PageAppearance.qml` — accent color, window bg, blur toggle, font family, animation speed

---

## Medium Term

### App Launcher overlay
A fullscreen or floating overlay triggered by `Mod+D` (currently goes to fuzzel). Options:
- Embed fuzzel as-is (keep it external)
- Build a native QML launcher reading `.desktop` files via `Process`

### Notification center
Integration with `swaync` — a slide-in panel showing notification history, triggered by clicking a bell icon in the bar. The bar module just needs to show unread count; swaync handles the backend.

### OSD (On-Screen Display)
Temporary overlay for volume/brightness changes made via keyboard shortcuts — shows current level for ~1.5s then fades. Triggered by an IPC signal from the keybind handler.

### Power menu
A small centered overlay with Shutdown / Reboot / Logout / Lock buttons. Triggered by a bar button or keybind.

---

## Long Term

### Wallpaper management
A settings page to pick a wallpaper file/directory and rotation interval. Drives `awww` or `swww` via `Process`.

### Per-monitor workspace filtering
Currently all Niri workspaces from all outputs are shown in one row. Filter `NiriIpc.workspaces` by `output` so each bar only shows workspaces belonging to its screen.

### Theme presets
Save/load named settings snapshots. A "Presets" section in the settings sidebar with built-in dark/light/minimal themes and user-saved slots.

### Lock screen
Integration with `swaylock` — a settings page for background, blur, clock style.

### Media player widget
An MPRIS bar module showing current track + playback controls. Read from `playerctl` or Quickshell's built-in MPRIS service.

---

## Known Bugs

| Bug | File | Notes |
|---|---|---|
| Bar position change needs restart | `shell.qml` | `PanelWindow` anchor bindings are static |
| `STextInput` fires on every keystroke | `STextInput.qml` | `instantApply` + `onTextChanged` combo — can cause rapid saves |
| No save indicator | `SettingsWindow.qml` | User has no feedback that settings were persisted |
