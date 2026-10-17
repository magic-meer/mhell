# AGENTS.md — my_quickshell

Agent/AI context for working on this project.

## What This Is

A Quickshell + QML desktop shell for Niri on NixOS. Everything visual is driven by `Settings.qml` (singleton). No separate config files — the settings GUI writes to a JSON state file.

## How to Run

```bash
# Restart — quickshell hot-reloads QML, so this is only for structural edits
pkill -x quickshell      # see the supervisor warning below

# Toggle settings window
quickshell -c shell ipc call toggleSettings toggleSettings

# Check IPC targets
quickshell -c shell ipc show
```

**Do not start a second quickshell by hand.** Niri autostarts a supervisor loop:

```
bash -c 'while true; do quickshell -c shell; sleep 2; done'
```

It restarts the shell ~2s after any exit, so `pkill quickshell; quickshell -c shell &`
leaves you with two processes and **two bars stacked on screen**. Kill and let the
supervisor bring it back; only start one manually if the supervisor is gone.
`pgrep -c quickshell` is unreliable here — it also matches the supervisor's `bash -c`
command line. Count with `ps -eo cmd | grep -c '[/]quickshell -c shell'` instead.

`~/.config/quickshell/shell` is a symlink to `~/projects/my_quickshell`.

## Architecture

```
Settings.qml (Singleton)
  └── all config defaults + JSON load/save

NiriIpc.qml (Singleton)
  └── niri event-stream → workspaces[], windows{}

shell.qml
  ├── Variants(screens) → PanelWindow → Bar
  └── SettingsWindow (IPC toggled)

Bar → BarSection → Loader(moduleData) → [module].qml
```

**Key rule:** Every module reads config exclusively from `Settings.<section>.<property>`. Never hardcode values in module files.

**Persistence:** `Settings.scheduleSave()` is called by every control widget automatically. It debounces 500ms then writes JSON to `Quickshell.stateDir + "/settings.json"`. On startup `FileView` loads that file and `_applyJson()` overlays saved values onto defaults.

## File Map

| File | Role |
|---|---|
| `shell.qml` | Entry point |
| `Settings.qml` | Config singleton + JSON persistence |
| `NiriIpc.qml` | Niri IPC singleton |
| `Bar.qml` | Bar layout container |
| `BarSection.qml` | Module name → Component loader |
| `Workspaces.qml` | Workspace dots/highlight |
| `Clock.qml` | Time/date display |
| `Volume.qml` | Pipewire volume |
| `Brightness.qml` | brightnessctl brightness |
| `Network.qml` | nmcli network state |
| `SystemTray.qml` | SNI tray items |
| `SettingsWindow.qml` | Floating settings window + IPC handler |
| `LauncherWindow.qml` | App launcher overlay (Spotlight-style, in progress) |
| `settings/SettingsSidebar.qml` | Nav sidebar |
| `settings/SettingsPage.qml` | Scrollable page base |
| `settings/controls/` | Reusable UI widgets (SToggle, SSlider, etc.) |
| `settings/pages/` | One page per module |

## Adding a New Module

1. Create `MyModule.qml` — read config from `Settings.myModule.*`
2. Add a `_myModule` QtObject block in `Settings.qml` with all defaults
3. Add serialization in `_writeJson()` and deserialization in `_applyJson()` in `Settings.qml`
4. Add `case "mymodule": return myModuleComp` in `BarSection.qml`
5. Add `Component { id: myModuleComp; MyModule {} }` in `BarSection.qml`
6. Create `settings/pages/PageMyModule.qml`
7. Add `{ icon: "…", label: "MyModule" }` to the pages array in `SettingsSidebar.qml`
8. Add the page to `pageStack` in `SettingsWindow.qml`

## Adding a New Settings Control

All controls in `settings/controls/` must call `Settings.scheduleSave()` on user interaction. See existing controls for the pattern.

## Icon Convention

Icon fields in `Settings.qml` accept either:
- A **Lucide ligature name** — plain ASCII like `"wifi"`, `"volume-2"`, `"battery-full"` (rendered as `Text`)
- A file path ending in `.svg`, `.png`, or `.ico` (rendered as `Image`)

Use `Settings.isIconPath(str)` to decide which to render.

The font ships **inside this repo** at `assets/Lucide.ttf` (ISC — see
`assets/LICENSE`, regenerate via `assets/VERSION`). Nothing is installed
system-wide; there is no icon font in `fonts.nix`. `shell.qml` owns the
`FontLoader` and publishes the family to `Settings.settingsUI.iconFont`,
which is why that property is assigned imperatively rather than by a binding.

Browse names at <https://lucide.dev/icons>.

**Two different fonts — never mix them up:**

| | property | used for |
|---|---|---|
| icons | `Settings.settingsUI.iconFont` | icon `Text` elements only |
| text | `<section>.fontFamily` | labels, popups, percentages, clock, settings UI |

Lucide contains **no letters or digits**. A `Text` element whose content is
text (e.g. `"Discharging 42%"`, `"0.0 W"`, `"✕"`) must use the section's
`fontFamily`, never `iconFont`, or it renders as tofu/fallback boxes.

There is exactly one icon `Text` site per module — grep for
`Settings.settingsUI.iconFont` to find them. When adding a module, that new site
must use `iconFont`; everything else keeps `cfg.fontFamily`.

SF Symbols (Apple) is **not** usable here — proprietary, macOS-only, not
redistributable. Lucide is the lookalike you can legally ship.

## Module States

Every module must handle the full state space of its data source, not just the
common case. A state that cannot be rendered gets its own icon + label, never a
fallback that silently lies. Grep a module for its `state`/`status` property to
see what it claims to support.

| module | states |
|---|---|
| `Battery` | absent · unknown · charging · not-charging · full · discharging (0-9 critical, 10-19, 20-39, 40-59, 60-79, 80-99, 100) |
| `Volume` | no-device · muted · 0% · 1-33 · 34-66 · 67-100 · boosted (>100%) |
| `Brightness` | no-device (no backlight) · 0-24 · 25-49 · 50-74 · 75-99 · 100 |
| `Network` | checking · airplane (radio off) · limited/portal · connected (wifi or wired) · disconnected · unknown |
| `ServiceMonitor` | undefined (not polled) · active · activating · reloading · deactivating · inactive · failed · maintenance · not-found |

Rules when adding a state:

- New states get a new `icon*` property in `Settings.qml` **and** an entry in
  that section's `_persistSchema` keys, **and** an `SIconPicker` row on its
  settings page. A config value with no UI to edit it is a dead value.
- An absent device is not a zero reading. `Brightness` with no backlight must
  show `iconNoDevice` and hide the slider, not sit at 50%.
- Only translate a raw value when the raw word is jargon: `not-found` → "no such
  unit" is fine, `Discharging` → "Discharging" is not needed. See
  `ServiceMonitor._statusLabel`.
- Validate new ligature names with the HarfBuzz check before committing —
  a typo renders as a blank box with no error anywhere.

SF Symbols (Apple) is **not** usable here — proprietary, macOS-only, not
redistributable. Material Symbols is the Apache-2.0 lookalike.

## Nix Context

- This project lives at `~/projects/my_quickshell`
- Nix config at `~/nixconfig/home/meher/quickshell/default.nix` points the symlink here
- Keybinds at `~/nixconfig/home/meher/niri/keybinds.nix` — `keybinds/niri.nix` is just a symlink to it for discoverability, never edit the symlink directly
- Niri startup at `~/nixconfig/home/meher/niri/startup.nix`
- Apply nix changes: `sudo nixos-rebuild switch --flake ~/nixconfig#jinnnn`
- The symlink `~/.config/quickshell/shell` → `~/projects/my_quickshell` can be updated manually without a rebuild

## Known Issues / Watch Out For

- **Bar position change** (`top` ↔ `bottom`) requires a quickshell restart — `anchors.top/bottom` on `PanelWindow` cannot be rebound live
- **`instantApply: true`** in settingsUI means `STextInput` fires `committed` on every keystroke — be careful with expensive operations in `onCommitted` handlers
- **NiriIpc** reconnects automatically on crash (2s timer) — don't add a second event-stream process
- **Workspace `focusWorkspace(idx)`** passes `modelData.idx` (the Niri workspace index, 1-based) not the array index
- **`Mod+Q` on settings window** is handled by `onClosed` in SettingsWindow — hides instead of destroying. If you remove that handler the window will be destroyed and toggle breaks until restart
- **Niri keybind `Mod+I`** has `repeat = false` in nixconfig — takes effect after rebuild. The QML debounce (600ms) handles it until then
- **Desktop entry and keybind** use full path `/etc/profiles/per-user/meher/bin/quickshell` — fuzzel/niri don't inherit the user PATH

## Rules

- **Bar UI must be a reactive extension of the bar** — anchored to the module
  that owns it, sized to its content, appearing/disappearing with that module.
  Never a standalone window, never a fullscreen or screen-height surface, unless
  the user explicitly asks for one. A bar module owns its own `PopupWindow`
  (see `Clock.qml`, `NotifIndicator.qml`) and nothing else.
- **Never create a fullscreen layer-shell surface.** `home/meher/niri/window-rules.nix`
  applies blur to the `overlay` layer, so any fullscreen `PanelWindow`/`PopupWindow`
  blurs (and tints) the entire monitor and swallows all input.
- Never hardcode colors, sizes, or strings in module files — always go through `Settings.*`
- Never edit `~/.config/niri/config.kdl` directly — it is a read-only nix store symlink
- Don't use `spread` syntax (`...obj`) in QML JS — use `Object.assign({}, obj)` instead (QML's JS engine doesn't support object spread)
- Keep each QML file focused on one concern — no god objects
- **Never `git checkout --` / `git restore` / `git stash` a file without running
  `git status --short` and `git diff` on it first.** This repo routinely has
  uncommitted work in progress (new modules mid-build). A restore silently
  deletes it and there is no recovery — the editor snapshots that might have
  covered it are usually from a different, older revision. If a scripted edit
  damages a file, repair it in place or ask; do not reach for git to reset.
- Before rewriting a file with a script, dry-run the diff and confirm the file
  has no uncommitted changes you would clobber.

## Verification

No build tooling — `qmllint` and the live shell are the checks.

```bash
# parse + type check every file. qmllint is not on PATH and is not in your
# system profile — pull it from nixpkgs (`qtdeclarative` has no top-level
# attribute; it lives under `qt6`):
Q=$(nix eval --impure --raw \
    --expr '(builtins.getFlake "github:NixOS/nixpkgs/nixos-unstable").legacyPackages.x86_64-linux.qt6.qtdeclarative.outPath')/bin/qmllint
"$Q" -I . <file.qml>; echo "exit=$?"

# restart and read the log — quickshell reports QML errors here, qmllint may not.
# `pkill -x` only, then WAIT: the niri supervisor restarts it. Starting one
# yourself gives you two bars.
pkill -x quickshell; sleep 4
cat /run/user/$(id -u)/quickshell/by-id/*/log.qslog | grep -i error

# screenshot the result (niri's own tool; NIRI_SOCKET must be set)
export NIRI_SOCKET=$(ls /run/user/$(id -u)/niri.wayland-*.sock)
niri msg action screenshot-screen      # lands in ~/Pictures/Screenshots

# in-repo checks
python3 check_icons.py                # needs fontTools
```

Note the `qtdeclarative-6.11.1` copy already in your store is **unusable** —
its glib needs `GLIBC_2.43` and your system glibc is older. Always resolve the
path from nixpkgs rather than `find`-ing the store.

`qmllint` exiting 0 does **not** mean the file parses in the real loader —
it tolerated a stray `}` that stopped the shell entirely. Always restart the
shell and check the log after touching a module's structure.

A typo'd ligature name renders as a blank box with no error anywhere. Assert
icon names against the real font by shaping them with HarfBuzz before
committing; grep the module for its `state`/`status` property when auditing
whether every state is actually handled.
