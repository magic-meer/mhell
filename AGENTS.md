# AGENTS.md — my_quickshell

Agent/AI context for working on this project.

## What This Is

A Quickshell + QML desktop shell for Niri on NixOS. Everything visual is driven by `Settings.qml` (singleton). No separate config files — the settings GUI writes to a JSON state file.

## How to Run

```bash
# Start (or restart after code changes)
pkill quickshell; quickshell -c shell &

# Toggle settings window
quickshell -c shell ipc call toggleSettings toggleSettings

# Check IPC targets
quickshell -c shell ipc show
```

`~/.config/quickshell/shell` is a symlink to `~/projects/my_quickshell`. Quickshell hot-reloads QML file changes automatically — no restart needed for most edits.

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
- A Nerd Font glyph character (rendered as `Text`)
- A file path ending in `.svg`, `.png`, or `.ico` (rendered as `Image`)

Use `Settings.isIconPath(str)` to decide which to render.

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

- Never hardcode colors, sizes, or strings in module files — always go through `Settings.*`
- Never edit `~/.config/niri/config.kdl` directly — it is a read-only nix store symlink
- Don't use `spread` syntax (`...obj`) in QML JS — use `Object.assign({}, obj)` instead (QML's JS engine doesn't support object spread)
- Keep each QML file focused on one concern — no god objects
