# Quickshell Desktop — v1 Design

Date: 2026-09-20

## Context

The user runs NixOS 26.11 with the **niri** scrollable-tiling compositor
(session type wayland), Quickshell 0.3.1, swaync + waybar today. The
long-term goal is a full, declarative, animated desktop environment on
Quickshell (launcher, notification center, media, weather, settings app,
lockscreen, power menu, dock, calendar/tasks sync with Google, …).

**v1 milestone** (agreed): the shell foundation plus the bar, a quick
settings popup (wifi / bluetooth / brightness / volume / battery), and a
clock+calendar popup — designed so every later component slots in without
rework.

Verified environment findings:

- Compositor blur is **real**: niri 26.04 supports `background-effect {
  blur true }` on layer surfaces; the current niri config already blurs the
  `overlay` layer and the `waybar` namespace. Translucent Quickshell
  surfaces will therefore get genuine wallpaper/window blur behind them.
- Backends are all built into this Quickshell build:
  - `Quickshell.Networking` → NetworkManager (wifi, wired). Confirmed in
    `quickshell-network.qmltypes` (`Networking` singleton, `WifiDevice`,
    `WifiNetwork.connect()` / `connectWithPsk()`, strength, security,
    scanner).
  - `Quickshell.Bluetooth` → BlueZ (adapter on/off, device list,
    pair/connect/disconnect/forget, device battery).
  - `Quickshell.Services.UPower` → battery display device + power profiles.
  - `Quickshell.Services.Pipewire` → default sink volume/mute.
  - No built-in brightness service → drive `brightnessctl` (installed,
    `amdgpu_bl1` backlight) via `QsProcess`.
- Running daemons confirmed: NetworkManager + wpa_supplicant, bluetoothd,
  pipewire + wireplumber, power-profiles-daemon; `BAT0` + `ADP1` present.
- `PanelWindow` (wlr-layer-shell) works on niri — the current minimal bar
  already uses it. `PopupWindow` (anchored to a panel, dismiss on outside
  click) is the popup primitive; a known niri layer-popup dismissal bug was
  fixed upstream.
- The nix config symlinks the live config dir
  (`xdg.configFile."quickshell/shell"` → a `mkOutOfStoreSymlink` to a live
  path) so `qs -c shell` hot-reloads on edit. The symlink target must be
  switched from the old nixconfig path to **this repo**.

## Contract: everything is configurable

Every tunable value lives in one place, `Theme.qml` — no magic numbers in
components. Colors, radii, spacing, margins, bar height, popup sizes,
blur/tint values, animation durations, easing. A future settings app (and a
wallpaper-sampled accent) rewrites/extends `Theme.qml` without touching
components. This is a hard requirement of the design.

## Architecture: modular per-area components (chosen approach)

One QML file per shell area, each a small component that consumes `Theme`
and a handful of shared components. `shell.qml` composes them into windows.

```
shell.qml                     QuickshellRoot; composes bar; hosts popups
Theme.qml                     pragma Singleton — ALL tokens
bar/Bar.qml                   PanelWindow: tray | center clock pill | quick-settings pill
bar/ClockPill.qml             time + date, hover anim, click -> ClockPopup
bar/SettingsPill.qml          wifi·bt·vol·batt mini indicators, click -> QuickSettings
quick/QuickSettings.qml       PopupWindow: battery/profile, network, bluetooth, volume, brightness, power
calendar/ClockPopup.qml       PopupWindow: time header + month grid + agenda slot
shared/GlassPanel.qml         rounded translucent glass container (tint + hairline + highlight)
shared/IconButton.qml         hover/press-animated icon button
shared/Slider.qml             custom glass slider (accent track, animated knob)
shared/Section.qml            section header for popup rows
```

Rejected: single monolith `shell.qml` (dies at the second popup), and a
JS-based theme block (not reactive, no bindings/animations).

## Theme system

`Theme.qml` exposes (naming sketched):

- Layout: `barHeight 42`, `radius { small 8, medium 12, large 18, pill 999 }`,
  `spacing { xs 4, s 8, m 12, l 16 }`, `margin`.
- Colors: `background` (dark base), `surface / surfaceRaised / surfaceBorder`
  (alpha-carrying glass tints), `accent` + `accentFg`, `text / textDim /
  textFaint`, `ok / warn / critical`.
- Glass: `glassTint`, `glassBorder`, `glassHighlightOpacity`, blur is
  compositor-side (niri rule), so surfaces just need `glassOpacity` + border.
- Motion: `duration { fast 120, base 200, slow 320 }`, `easing` (one token,
  `Easing.OutCubic`), used by every `Behavior`.
- Status glyph helpers where pure (e.g., contrast text color chosen from
  accent luminance).

`Theme.qml` is a `pragma Singleton` exposed via a `qmldir` (`singleton
Theme Theme.qml`) in the config directory, imported by all components.

## Shared components

- `GlassPanel`: base glass look — `radius`/`color` (with alpha) tokens, a
  1px hairline `glassBorder` around it, and a 1px `glassHighlight` gradient
  along the top edge for the reflection. All styling from `Theme`; no blur
  logic (compositor owns blur).
- `IconButton`: `icon` (string) + `size`, hover scale/color animation, press
  feedback, `onClicked`; supports `enabled`. Uses `Quickshell.Widgets`
  `IconImage` / `QsTextIcon`-style icon loading.
- `Slider`: token-styled track (recessed surface), accent fill + animated
  knob; `value` 0-1, drag on mouse, optional `onValueChanged`; sized to
  `spacing`. Not QtQuick.Controls (visual mismatch).
- `Section`: small uppercase-dims caption row used to head popup sections.

## Bar

`PanelWindow` (top, left+right anchored, `exclusiveZone: barHeight`,
`focusable: false`, `WlrLayershell.namespace: "myquickshell:bar"` — the
niri `layer-rule` matches this namespace). Full-width glass strip
(`GlassPanel`-style background).

Layout `[tray group][center clock pill][quick-settings pill]`:

- Tray: `Quickshell.Services.SystemTray` (`tooltip`, left-click, hosted
  menu handled by the built-in service).
- Clock pill: two-line (time, weekday + date), token typography, hover
  underline/opacity animation; click toggles `ClockPopup`.
- Quick-settings pill: inline wifi / bt / volume / battery mini-indicators,
  live-bound to the services (wifi strength bars or wired glyph; bt on/off
  and hue when connected; volume level or muted slash; battery % with bolt
  when charging). Whole pill = one `IconButton`; click toggles
  `QuickSettings`.
- Popups are `PopupWindow`s anchored to the bar at the two click targets,
  dismissing on outside click.

## Quick settings popup

`PopupWindow` anchored below the quick-settings pill. `GlassPanel` body,
column of `Section`-text sections.

- Battery: percentage + state; power-profile segmented control
  (Performance / Balanced / Power Saver) from `UPower` — hide sections the
  hardware/service doesn't support (`hasPerformanceProfile`).
- Network: current connection name; wifi toggle; network list from wifi
  device (`networks`): signal-strength bar, lock glyph per `security`,
  check mark when connected, click to connect (known) / show inline
  passphrase field → `connectWithPsk()` (open). Scanning empty state.
  Wired device → single ethernet row instead.
- Bluetooth: adapter toggle; devices list with state (connected / pairing /
  discovered), per device `connect()` / `disconnect()` / `forget()`;
  scan-on-open with spinner (`discovering`); device `battery` when offered.
- Volume: default-sink slider + mute toggle. (Per-app mixer deferred.)
- Brightness: slider reading/writing `brightnessctl` via `QsProcess`.
- Power row: Lock (`swaylock`) · Suspend (`systemctl suspend`) · Logout
  (`niri msg action quit`). Minimal; replaced by the power-menu phase later.

## Clock / calendar popup

`PopupWindow` anchored below the clock pill. Glass body:

- Time header (1 s `Timer`), date line, theme typography.
- Month calendar built in QML/JS only: header with prev/next month buttons,
  weekday row, 6×7 grid, today + selected emphasized with accent, weekend
  dimming, token radii on the day cells.
- Agenda strip placeholder: layout reserves a slot with an empty "Calendar
  sync — later phase" note, so a Google/CalDAV agenda can drop in without
  restructuring.

## Composition & shell.qml

`QuickshellRoot` -> `Bar` (which declares its two popups). All imports
resolve within the config dir module. Nothing else in v1.

## Nix / niri integration

- Nix home: repoint the existing `xdg.configFile."quickshell/shell"`
  `mkOutOfStoreSymlink` target from the old nixconfig path to this repo.
- Disable `waybar` and `swaync` (nix modules + kill running processes) so
  exactly one bar and no competing notifier remain. `swaylock` stays.
- niri: add a `layer-rule { match namespace="^myquickshell:"; }` with
  `background-effect { blur true; xray false }` so the bar and its popups
  (namespace `myquickshell:bar` / `myquickshell:quicksettings` /
  `myquickshell:clock`) get real compositor blur. Keep one consistent
  global `blur {}`.

## Dev loop & verification

- Hot reload: edits to the live repo are picked up by running `qs -c shell`
  (that is the whole point of the out-of-store symlink).
- Checks before a task is "done":
  - `qmlformat --write` passes on all touched files (Qt6 tooling).
  - `qs -c shell` starts with zero QML errors/warnings and stays running.
  - Visual: `niri msg action screenshot` for manual eyeball of glass/blur.
  - The calendar month-math pure function carries a tiny assert/tests self
    check runnable in isolation.
- The existing user niri keybinds for media volume etc. keep working; the
  Quickshell shell does not re-implement global media keys in v1.

## Out of scope (later phases)

Launcher, notification center, media player widget, per-app audio mixer,
weather, Google calendar/tasks sync, full settings app, lockscreen, power
menu, dock, wallpaper-sampled accent, multi-monitor policy refinements.
The v1 structure is the scaffold these land on.