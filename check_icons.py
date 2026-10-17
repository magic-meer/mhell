#!/usr/bin/env python3
"""Assert every icon setting is a real Lucide ligature.

    python3 tools_check_icons.py          # needs fontTools

Run after adding or renaming any icon* setting. A typo renders as a blank
box at runtime with no error anywhere.
"""
import re, sys, pathlib
from fontTools.ttLib import TTFont

font = TTFont("assets/Lucide.ttf")
names = set()
for lookup in font["GSUB"].table.LookupList.Lookup:
    for st in lookup.SubTable:
        ligs = getattr(st, "ligatures", None)
        if not ligs:
            continue
        for first, group in ligs.items():
            for lig in group:
                comp = lig.Component
                names.add((first + ("".join(comp) if isinstance(comp, list)
                                    else comp)).strip())
names.discard("")

bad = []
for prop, val in re.findall(r'property string (icon\w*):\s*"([^"]*)"',
                            pathlib.Path("Settings.qml").read_text()):
    if prop == "iconFont":
        continue
    if val not in names:
        bad.append(f"Settings.qml  {prop} = {val!r}")

for path in pathlib.Path(".").rglob("*.qml"):
    text = path.read_text()
    if "settingsUI.iconFont" not in text:
        continue
    for ico in re.findall(r'icon:\s*"([^"]*)"', text):
        if ico not in names:
            bad.append(f"{path}  icon = {ico!r}")

if bad:
    print("\n".join(sorted(set(bad))))
    sys.exit(1)
print(f"PASS: all icons are valid Lucide ligatures ({len(names)} in font)")
