#!/usr/bin/env python3
"""snap.py - snap glyph points to the C47 font grid
"""

from fontTools.ttLib import TTFont


def snap(font_path, grid=32, out_path=None, verbose=True):
    """Snap all simple-glyph points to the nearest grid position.

    font_path : path to the input .ttf
    grid      : grid spacing in font units (default 32, i.e. 1024 UPM / 32)
    out_path  : output path; defaults to overwriting font_path (only written when something moves)
    verbose   : print a per-glyph summary of how many points were moved

    Returns the total number of points moved across the whole font.
    """
    font = TTFont(font_path)
    glyf = font["glyf"]
    moved_total = 0

    for name in glyf.keys():
        g = glyf[name]
        if g.numberOfContours <= 0:                                 # empty or composite glyph, no coordinates of its own to snap
            continue
        coords = g.coordinates
        moved = 0
        for i in range(len(coords)):
            x, y = coords[i]
            sx = grid * round(x / grid)
            sy = grid * round(y / grid)
            if sx != x or sy != y:
                coords[i] = (sx, sy)
                moved += 1
        if moved:
            g.recalcBounds(glyf)                                     # coordinates changed, so refresh the cached glyph bounding box before save
            moved_total += moved
            if verbose:
                print(f"  {name}: snapped {moved} point(s)")

    if moved_total:
        font.save(out_path or font_path)
    if verbose:
        print(f"snap: {moved_total} point(s) moved on a {grid}-unit grid")
    return moved_total


if __name__ == "__main__":
    import sys
    if len(sys.argv) < 2:
        sys.exit("usage: snap.py <font.ttf> [grid] [out.ttf]")
    path = sys.argv[1]
    grid = int(sys.argv[2]) if len(sys.argv) > 2 else 32
    out_path = sys.argv[3] if len(sys.argv) > 3 else None
    snap(path, grid=grid, out_path=out_path)
