#!/usr/bin/env python3
"""Resolve imported-upstream paths for the governance gates.

WHY THIS EXISTS. The imported upstream tree is not mounted at the repo root: it
lives under the directory named by ``UPSTREAM_ROOT`` in ``upstream-pin.env`` so
that z47's own owners can hold the canonical ``src/`` and ``docs/`` names. A gate
that reads an upstream file therefore cannot join its relative path onto the repo
root -- ``repo_root / "src/c47"`` is a z47 path, not an upstream one.

WHAT STAYS UPSTREAM-RELATIVE. Every path recorded *as data* -- the correspondence
TSVs, the port ledger, the dependency baselines, generated seam comments -- keeps
naming files the way upstream names them (``src/c47/foo.c``), because that is what
upstream calls them and the ledgers describe upstream's tree. Likewise a git
pathspec aimed at a sibling clone of the upstream repository stays
upstream-relative: it is resolved by *that* repository, not by this one.

So the rule is: resolve at the point of filesystem access, and only there. This
keeps every baseline stable across a layout change and confines the layout itself
to one place -- the pin file, which the Zig build already reads via
``build/common.zig:upstreamRootString``.
"""

from __future__ import annotations

from pathlib import Path

PIN_FILE_RELATIVE = ".github/project/upstream-pin.env"

_KEY = "UPSTREAM_ROOT"


def _read_pin_value(pin_file: Path, key: str) -> str:
    for raw_line in pin_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        name, _, value = line.partition("=")
        if name.strip() == key:
            return value.strip()
    raise SystemExit(f"missing {key} in {pin_file}")


def upstream_root(repo_root: Path | str) -> Path:
    """Absolute path of the imported upstream tree inside ``repo_root``."""
    root = Path(repo_root)
    value = _read_pin_value(root / PIN_FILE_RELATIVE, _KEY)
    if value in {"", "."}:
        return root
    return root / value


def upstream_path(repo_root: Path | str, relative: str) -> Path:
    """Absolute path of an upstream-relative path such as ``src/c47/items.c``."""
    return upstream_root(repo_root) / relative
