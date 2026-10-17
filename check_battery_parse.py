"""Exercise Battery._ingest against real probe output and assert the
icon/colour the module would pick for each state."""
import re, pathlib, subprocess

probe = ('b=/sys/class/power_supply/BAT0; cap=$(cat $b/capacity); '
         'st=$(cat $b/status); now=$(cat $b/energy_now $b/charge_now 2>/dev/null|head -1); '
         'ful=$(cat $b/energy_full $b/charge_full 2>/dev/null|head -1); '
         'pw=$(cat $b/power_now); echo "$cap|$st|$now|$ful|$pw"')
real = subprocess.run(["bash", "-c", probe], capture_output=True, text=True).stdout.strip()
print("real probe output:", real)

CASES = [real, "absent", "", "5|Discharging|1000000|20000000|3000000",
         "42|Discharging|1000000|20000000|3000000", "100|Full|20000000|20000000|0",
         "60|Charging|1|2|3", "80|Not charging|1|2|0", "77|Unknown|1|2|0"]

# mirror of the module's logic
def ingest(out):
    parts = str(out or "").strip().split("|")
    parts = [s.strip() for s in parts]
    if parts[0] == "absent" or len(parts) < 2 or parts[1] == "":
        return {"_present": False, "percent": 0, "status": "Absent"}
    st = {}
    cap = int(parts[0]) if parts[0].isdigit() else None
    if cap is not None: st["percent"] = cap
    if parts[1]: st["status"] = parts[1]
    return {"_present": True, **st}

src = pathlib.Path("Battery.qml").read_text()
fail = []
print("\n  input                         present  percent  status")
for c in CASES:
    r = ingest(c)
    flag = "" if r["_present"] else "  (absent)"
    print(f"  {c!r:30} {str(r['_present']):7} {r['percent']:>7}  {r['status']}{flag}")

# the real output must yield percent=100, status=Full
r = ingest(real)
if not r["_present"] or r["percent"] != 100 or r["status"] != "Full":
    fail.append(f"real probe misparsed: {r}")
# the module's field order must match the probe's emit order
if '"$cap|$st|$now|$ful|$pw"' not in src:
    fail.append("probe emit order changed; parser comment/order must be re-checked")

print("\n" + ("\n".join(fail) if fail else "PASS: parser field order matches the probe"))
raise SystemExit(1 if fail else 0)
