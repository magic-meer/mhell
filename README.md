# my_quickshell

A fully custom Wayland desktop shell built with [Quickshell](https://quickshell.org) and QML, running on the [Niri](https://github.com/YaLTeR/niri) compositor.

## Goal

Build a complete, self-contained desktop environment shell from scratch — starting with a status bar and growing into a full DE experience. Everything is configured through a live settings GUI with no config file editing required.

## Features

### Bar
- Per-screen panel window (one per monitor)
- Three-section layout: left / center / right
- Fully configurable via settings GUI — height, position, background, border, radius, separators
- Module order is drag-configurable via text input (comma-separated list)

### Modules
| Module | Description |
|---|---|
| `workspaces` | Niri workspace indicator — sliding highlight, presence dots, click-to-switch |
| `clock` | Time + date display, configurable format, hover scale |
| `volume` | Pipewire integration — scroll to change, click to mute, glyph/image icons |
| `brightness` | `brightnessctl` — scroll to change, poll-based read |
| `network` | `nmcli` polling, `iwgtk` on click, connected/disconnected/unknown states |
| `systemtray` | SNI system tray items, left/right click support |

### Settings Window
- Opened via `Mod+I`, desktop entry, or IPC call
- Animated open/close (scale + fade)
- Animated page transitions (slide)
- 6 pages: Bar, Workspaces, Clock, Volume, Brightness, Network
- Full widget library: toggle, slider, spinbox, color picker (RGBA), dropdown, icon picker, text input
- **Settings persist** to `~/.local/state/quickshell/by-shell/<id>/settings.json` — survive restarts

## Running

The shell is managed by NixOS/home-manager. On login, Niri spawns it automatically via:

```
quickshell -c shell
```

`~/.config/quickshell/shell` is a symlink → `~/projects/my_quickshell` (set in `~/nixconfig/home/meher/quickshell/default.nix`).

### Manual start (testing)

```bash
quickshell -c shell
```

### Toggle settings window

```bash
# From terminal
quickshell -c shell ipc call toggleSettings toggleSettings

# Keybind
Mod+I

# Desktop entry
Shell Settings (in app launcher)
```

### Rebuild after nix changes

```bash
sudo nixos-rebuild switch --flake ~/nixconfig#jinnnn
```

## Project Structure

```
my_quickshell/
├── shell.qml               # Entry point — PanelWindow per screen + SettingsWindow
├── Bar.qml                 # Bar container (left/center/right sections)
├── BarSection.qml          # Module loader by name string
├── Settings.qml            # Singleton — all config defaults + JSON persistence
├── NiriIpc.qml             # Singleton — Niri event-stream IPC (workspaces/windows)
│
├── Workspaces.qml          # Workspace indicator module
├── Clock.qml               # Clock module
├── Volume.qml              # Volume module (Pipewire)
├── Brightness.qml          # Brightness module (brightnessctl)
├── Network.qml             # Network module (nmcli)
├── SystemTray.qml          # System tray module (SNI)
│
├── SettingsWindow.qml      # Settings FloatingWindow with IPC handler
└── settings/
    ├── SettingsSidebar.qml # Animated nav sidebar
    ├── SettingsPage.qml    # Base page wrapper (scrollable)
    ├── controls/           # Reusable UI widgets
    │   ├── SToggle.qml
    │   ├── SSlider.qml
    │   ├── SSpinBox.qml
    │   ├── SColorSwatch.qml
    │   ├── SDropDown.qml
    │   ├── SIconPicker.qml
    │   ├── STextInput.qml
    │   ├── SettingsGroup.qml
    │   └── SettingsRow.qml
    └── pages/              # One file per settings page
        ├── PageBar.qml
        ├── PageWorkspaces.qml
        ├── PageClock.qml
        ├── PageVolume.qml
        ├── PageBrightness.qml
        └── PageNetwork.qml
```

## Dependencies

| Dependency | Purpose |
|---|---|
| `quickshell` ≥ 0.3.1 | Shell framework |
| `niri` | Compositor (IPC event stream) |
| `pipewire` / `wireplumber` | Volume control |
| `brightnessctl` | Brightness read/write |
| `nmcli` (NetworkManager) | Network state polling |
| `iwgtk` | Wi-Fi GUI (launched on network click) |
| JetBrainsMono Nerd Font | Default font for all glyphs |

## Nix Integration

- **Location:** `~/projects/my_quickshell`
- **Nix config:** `~/nixconfig/home/meher/quickshell/default.nix`
- **Symlink:** `~/.config/quickshell/shell` → `~/projects/my_quickshell`
- **Startup:** `~/nixconfig/home/meher/niri/startup.nix` — `quickshell -c shell`
- **Keybind:** `~/nixconfig/home/meher/keybinds/niri.nix` — `Mod+I` → `toggleSettings`
- **Desktop entry:** `shell-settings.desktop` (copy to `~/.local/share/applications/` to register)

## What's Next

See [ROADMAP.md](./ROADMAP.md) for planned features.
