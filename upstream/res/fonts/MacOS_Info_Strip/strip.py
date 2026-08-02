from fontTools.ttLib import TTFont
import sys

if len(sys.argv) < 2:
    print("usage: python3 strip.py <font.ttf>")
    sys.exit(1)

path = sys.argv[1]
f = TTFont(path)

before = len(f["name"].names)
removed = [(r.platformID, r.nameID) for r in f["name"].names if r.platformID != 3]

if not removed:
    print(f"{path}: already Windows-only ({before} records). Nothing to strip.")
    sys.exit(0)

f["name"].names = [r for r in f["name"].names if r.platformID == 3]
f.save(path)
print(f"{path}: removed {len(removed)} non-Windows name records ({before} -> {len(f['name'].names)}).")
print("  removed (platformID, nameID):", removed)