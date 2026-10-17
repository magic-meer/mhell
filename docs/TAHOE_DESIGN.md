# TAHOE_DESIGN.md — macOS Tahoe design reference

This file is the single source of truth for the macOS Tahoe look-and-feel.
Every future AI agent working on this shell MUST read it before touching
module QML, Settings.qml, Bar.qml, or the settings UI.

## Goal

A one-to-one macOS Tahoe desktop shell running on **Niri** (not Hyprland),
with extreme customizability through the existing Settings singleton.

## Core visual language (Tahoe)

| Element | Value | Source |
|---|---|---|
| Bar height | 40 | Settings.bar.height |
| Bar corner radius | 14 (full pill) | Settings.bar.radius |
| Bar bg | `rgba(0,0,0,0.25)` frosted glass | Settings.bar.bgColor / bgOpacity |
| Bar border | `rgba(255,255,255,0.08)` hairline | Settings.bar.borderColor / borderWidth |
| Module spacing | 10 | Settings.bar.moduleSpacing |
| Bar padding sides | 14 | Settings.bar.paddingSides |
| Accent (system blue) | `#0A84FF` | Settings.settingsUI.accentColor |
| Text primary | `#FFFFFF` / 0.95 alpha | settingsUI.textPrimary |
| Text secondary | `#FFFFFF` / 0.55 alpha | settingsUI.textSecondary |
| Icon font | bundled Lucide (`assets/Lucide.ttf`) | settingsUI.iconFont |
| Text font | JetBrainsMono Nerd Font (override per section) | `<section>.fontFamily` |

**Glassmorphism rule:** Bar background should be translucent (alpha ~0.2–0.35) so Niri's blur shows through. Never paint the bar fully opaque unless the user disables blur in settings.

**Do NOT create fullscreen layer-shell surfaces.** Niri window-rules blur the `overlay` layer — a fullscreen PanelWindow/PopupWindow blurs and tints the entire monitor and swallows input. All popups (control center, notifications, launcher) are anchored, content-sized floating windows.

## Bar layout — Tahoe canonical order

macOS menu bar order (left → right):

1. **Apple menu** (app menu / "quickshell" icon) — left edge
2. **Workspaces** — active space indicator (dots or mini boxes)
3. **Clock** — centered
4. **Control Center** (system status) — right edge: Wi-Fi, Bluetooth, Sound, Battery, Focus, etc.

Default `Settings.bar.layout`:

```js
left:   ["applemenu", "workspaces"]
center: ["clock"]
right:  ["controlcenter"]
```

Add `"applemenu"` and `"controlcenter"` as supported names in `BarSection.qml` case statement + create `AppMenu.qml` and `ControlCenter.qml` modules.

## Module styling rules (extend AGENTS.md Module States)

Every module reads config exclusively from `Settings.<section>.<property>`. Never hardcode colors, sizes, or strings in module files.

Icon rule (from AGENTS.md Icon Convention):
- Lucide ligature name (e.g. `"wifi"`, `"volume-2"`) → `Text` rendered with `settingsUI.iconFont`
- File path (`.svg` / `.png` / `.ico`) → `Image`
- Use `Settings.isIconPath(str)` to decide
- **Lucide has no letters or digits.** Any text content ("Discharging 42%", "0.0 W", "✕") must use the section's `fontFamily`, never `iconFont`, or it renders as tofu boxes.

There is exactly one icon `Text` site per module — grep `Settings.settingsUI.iconFont` to find them. A new module's icon site must use `iconFont`; everything else keeps `cfg.fontFamily`.

State handling: every module must handle its full state space (absent/unknown/charging/etc.) with its own icon + label. Never a fallback that silently lies. New states require:
1. New `icon*` property in `Settings.qml`
2. Entry in that section's `_persistSchema` keys
3. An `SIconPicker` row on its settings page

## Adding a new module (Tahoe)

1. Create `MyModule.qml` — read config from `Settings.myModule.*`
2. Add `_myModule` QtObject block in `Settings.qml` with all defaults
3. Add serialization in `_writeJson()` and deserialization in `_applyJson()` (`_persistSchema`)
4. Add `case "mymodule": return myModuleComp` in `BarSection.qml`
5. Add `Component { id: myModuleComp; MyModule {} }` in `BarSection.qml`
6. Create `settings/pages/PageMyModule.qml`
7. Add `{ icon: "…", label: "MyModule" }` to pages array in `SettingsSidebar.qml`
8. Add page to `pageStack` in `SettingsWindow.qml`

## Adding a new settings control

All controls in `settings/controls/` must call `Settings.scheduleSave()` on user interaction.

## Popups / overlays (Tahoe)

- Control Center: anchored to the Control Center bar module, sized to content, slide-up/fade-in from bottom-right
- Notifications panel: anchored to bell icon, slide-in from right
- Launcher (Spotlight): centered pill, circles out from a point, results drop below
- Power menu: small centered overlay
- All are `PopupWindow` owned by their bar module — never standalone fullscreen windows

## Nix context

- Project: `~/projects/my_quickshell`
- Nix config: `~/nixconfig/home/meher/quickshell/default.nix` (symlink → here)
- Keybinds: `~/nixconfig/home/meher/niri/keybinds.nix` (symlink `keybinds/niri.nix`, never edit symlink)
- Apply: `sudo nixos-rebuild switch --flake ~/nixconfig#jinnnn`
- Symlink `~/.config/quickshell/shell` → `~/projects/my_quickshell` (update manually without rebuild)

## Verification

```bash
# qmllint (resolve from nixpkgs, not the broken store copy)
Q=$(nix eval --impure --raw \
    --expr '(builtins.getFlake "github:NixOS/nixpkgs/nixos-unstable").legacyPackages.x86_64-linux.qt6.qtdeclarative.outPath')/bin/qmllint
"$Q" -I . <file.qml>; echo "exit=$?"

# restart shell (supervisor brings it back ~2s later)
pkill -x quickshell; sleep 4
cat /run/user/$(id -u)/quickshell/by-id/*/log.qslog | grep -i error

# icon ligature validation — shape with HarfBuzz before committing; typo renders as blank box
python3 check_icons.py   # needs fontTools
```

`qmllint` exit 0 does NOT mean the file parses in the real loader — always restart the shell and check the log after structural changes.

## Rules (non-negotiable)

- Never hardcode colors, sizes, or strings in module files — always `Settings.*`
- Never `git checkout --` / `git restore` / `git stash` without `git status --short` + `git diff` first
- Don't use `spread` syntax (`...obj`) in QML JS — use `Object.assign({}, obj)`
- Keep each QML file focused on one concern — no god objects
- Bar UI is a reactive extension of its owning module — anchored, content-sized, appears/disappears with it

## Tahoe-specific TODOs (not yet built)

- [x] `AppMenu.qml` — Apple menu replacement (left of workspaces)
- [x] `ControlCenter.qml` — right-side system status dropdown
- [ ] PageAppearance.qml — accent color, blur, fonts, animation speed
- [ ] PageSystemTray.qml — icon size, spacing
- [ ] Per-monitor workspace filtering (`NiriIpc.workspaces` by `output`)
