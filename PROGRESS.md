# my_quickshell — Full Desktop Environment

## Vision
A fully animated, customizable, declarative Quickshell desktop environment with a modern blurs/liquid-glass UI, running on niri. Every standard desktop component, fully functional and visually cohesive.

## Architecture
Modular per-area QML. `shell.qml` composes `bar/Bar.qml` (layer-shell `PanelWindow`). Popups anchored to the bar via `PopupWindow`. Single `Theme` singleton carries every tunable token. All components import `Theme` and `shared` components.

**Tech stack:** QML (QtQuick 6), Quickshell 0.3.1, niri 26.04 (layer-rule blur), `brightnessctl`, built-in Quickshell singletons (NetworkManager, BlueZ, UPower, Pipewire).

## v1 Status: ✅ COMPLETE (Tasks 1–6)

| Task | Component | File | Status |
|------|-----------|------|--------|
| 1 | Theme singleton | `theme/Theme.qml`, `theme/qmldir` | ✅ committed |
| 2 | CalendarCore.js + datecheck | `calendar/CalendarCore.js`, `calendar/datecheck.qml` | ✅ committed |
| 3 | Shared components | `shared/GlassPanel.qml`, `shared/IconButton.qml`, `shared/Slider.qml`, `shared/Section.qml`, `shared/sharedsmoke.qml` | ✅ committed |
| 4 | Bar + shell | `shell.qml`, `bar/Bar.qml`, `bar/ClockPill.qml`, `bar/SettingsPill.qml` | ✅ committed |
| 5 | Clock/calendar popup | `calendar/CalendarWidget.qml`, `calendar/ClockPopup.qml` | ✅ committed |
| 6 | Quick settings popup | `quick/QuickSettingsWidget.qml`, `quick/QuickSettings.qml`, `smoke-quicksettings.qml` | ✅ committed |
| 7 | Notification center | `notifications/NotificationWidget.qml`, `notifications/NotificationCenter.qml`, `notifications/notifsmoke.qml`, `notifications/qmldir` | ✅ committed |
| 8 | Media player | `media/MediaPlayerWidget.qml`, `media/MediaPlayer.qml`, `media/MediaPlayerCore.js`, `media/mplayersmoke.qml`, `media/qmldir` | ✅ committed |

**v1 provides:** Theme tokens, shared primitives, bar (tray + clock pill + settings pill), clock/calendar popup, quick settings popup (wifi/bluetooth/volume/brightness/battery/power), notification center, media player. `shell.qml` boots via `QuickshellRoot`. niri `layer-rule` blur on `^myquickshell:` namespace.

## Remaining Components (build order)

### Phase 1 — Core missing desktop elements
1. **App Launcher** — PopupWindow with searchable app list, scans `/usr/share/applications/*.desktop`, launches via `Process`. [NEXT]
2. **Dock** — Bottom/horizontal taskbar + system tray + running app indicators.

### Phase 2 — Utilities
5. **Lock Screen** — Fullscreen lock with auth.
6. **Power Menu** — Suspend/hibernate/shutdown/restart dialog.
7. **Screenshot Tool** — Screenshot/crop/share flow.
8. **Weather** — Current conditions + forecast.

### Phase 3 — Advanced
9. **Full Settings App** — Deep settings for every Theme token, compositor config.
10. **Per-App Audio Mixer** — Pipewire per-client volume.
11. **Google Calendar/Tasks Sync** — CalDAV + Google Tasks API.
12. **Wallpaper-Sampled Accent** — Dynamic color extraction.
13. **Multi-Monitor Refinements** — Per-monitor layouts.

## How to Run

```bash
# Enter the feature worktree (authoritative per git)
cd /home/meher/projects/my_quickshell/.worktrees/v1

# Launch the shell
qs -p shell.qml

# Or launch a smoke test (headless, no screen needed)
qs -p smoke-calendar.qml
qs -p smoke-quicksettings.qml
qs -p notifications/notifsmoke.qml
```

## Design Reference
`docs/superpowers/specs/2026-09-20-quickshell-v1-design.md` — v1 design + contract.
`docs/superpowers/plans/2026-09-20-quickshell-v1.md` — v1 implementation plan (Tasks 1–6).

## Global Constraints (carry into all phases)
- All tokens in `Theme.qml`. No magic numbers.
- Icons via `image://icon/` + `IconImage`. Never add new binary deps.
- ObjectModels are NOT arrays — iterate with `Repeater { model: ...; delegate: Item { required property var modelData } }`.
- Quickshell services are singletons — reference directly, never construct.
- Guard all service bindings against null (`cond != null`).
- Panel/popup windows set `WlrLayershell.namespace: "myquickshell:*"`.
- Text: `Theme.fontMono` for time, `Theme.fontFamily` for body.
