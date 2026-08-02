#!/usr/bin/env python3
"""snap.py - snap glyph points to the C47 font grid.

The grid differs per font (Numeric/Numeric Bold = 32 on a 1024 UPM body, Tiny = 32 on 256, Standard = 50
on 1000), so by default snap() auto-detects it. The only grids the C47 fonts legitimately use are 32 and 50,
so when auto-detecting, anything else is treated as a wrong font or a detection failure and snap() refuses.
Pass grid=<n> explicitly to override the guard.
"""

from fontTools.ttLib import TTFont

ALLOWED_GRIDS = (32, 50)                                            # the only grids the C47 fonts use; auto-detect must hit one of these or snap() refuses


def _all_coord_values(glyf):
    """Yield every x and y value from every simple glyph in the font."""
    for name in glyf.keys():
        g = glyf[name]
        if g.numberOfContours > 0:                                  # skip empty (==0) and composite (<0) glyphs, they carry no points of their own
            coords, _, _ = g.getCoordinates(glyf)
            for x, y in coords:
                yield x
                yield y


def detect_grid(font, threshold=0.99, verbose=True):
    """Detect the design grid of a font.

    The grid is taken to be the largest divisor of the UPM on which at least <threshold> of all coordinate
    values land. A handful of stray sub-grid points (the very residue snap() exists to remove) will not move
    the answer, because they are a tiny fraction of the total. Returns the grid in font units, or 1 if no
    divisor clears the threshold (i.e. the font has no recoverable grid).

    font : a TTFont, or a path to a .ttf
    """
    if not isinstance(font, TTFont):
        font = TTFont(font)
    upm = font["head"].unitsPerEm
    glyf = font["glyf"]
    values = list(_all_coord_values(glyf))
    total = len(values) or 1
    divisors = sorted((d for d in range(2, upm + 1) if upm % d == 0), reverse=True)
    for d in divisors:
        on = sum(1 for v in values if v % d == 0)
        if on / total >= threshold:
            if verbose:
                print(f"detect_grid: UPM {upm}, grid {d} ({100 * on / total:.2f}% on grid)")
            return d
    if verbose:
        print(f"detect_grid: UPM {upm}, no grid clears {100 * threshold:.0f}%, returning 1")
    return 1


def snap(font_path, grid=None, out_path=None, verbose=True):
    """Snap all simple-glyph points to the nearest grid position.

    font_path : path to the input .ttf
    grid      : grid spacing in font units. None (default) auto-detects it via detect_grid() and refuses
                with a ValueError if the result is not one of ALLOWED_GRIDS. Passing an integer overrides
                both the detection and the guard, as the original fixed-grid script did.
    out_path  : output path; defaults to overwriting font_path (only written when something moves)
    verbose   : print the grid in use and a per-glyph summary of how many points were moved

    Returns the total number of points moved across the whole font.
    """
    font = TTFont(font_path)
    glyf = font["glyf"]

    if grid is None:
        grid = detect_grid(font, verbose=verbose)
        if grid not in ALLOWED_GRIDS:                               # auto-detected something the C47 fonts never use, so refuse rather than guess
            raise ValueError(
                f"detected grid {grid} is not one of {ALLOWED_GRIDS}; refusing to snap. "
                f"Pass grid=<n> explicitly to override."
            )
    elif verbose:
        print(f"snap: grid {grid} (override)")

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
            g.recalcBounds(glyf)                                    # coordinates changed, so refresh the cached glyph bounding box before save
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
        sys.exit("usage: snap.py <font.ttf> [grid|auto] [out.ttf]")
    path = sys.argv[1]
    grid = None
    if len(sys.argv) > 2 and sys.argv[2] != "auto":
        grid = int(sys.argv[2])
    out_path = sys.argv[3] if len(sys.argv) > 3 else None
    try:
        snap(path, grid=grid, out_path=out_path)
    except ValueError as e:
        sys.exit(f"snap: {e}")
