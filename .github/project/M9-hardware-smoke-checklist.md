# M9 hardware-smoke checklist (Annex A4)

The host test suites exercise the portable calculator core, but **397
`dmcp_build`-gated regions across 39 Zig owners** (run
`report-firmware-host-gap.py` for the live inventory) compile on host yet only
**execute on the DM42/DM42n firmware**, plus the genuinely host-unreachable ROM
and LCD-DMA calls. This checklist is the **only catch** for that surface: each
ported firmware feature below must be smoke-tested on real hardware before M9
ships and before any M10 pin advance that touches a firmware-facing owner.

Run on **DM42 with C47**, **DM42 with R47**, and **DM42n** (the three targets the
build produces). For each: flash the freshly built `.pgm`, then walk the items.
A line is **PASS** only if behaviour matches the pinned upstream build; record the
firmware build hash and the date.

## Pre-flight
- [ ] Builds flash cleanly on all three targets; calculator boots to the home
      screen without a reset loop.
- [ ] `report-firmware-host-gap.py --owner-summary` reviewed — every owner below
      maps to at least one checklist item; new owners since last run get an item.

## Display & rendering  *(display, graph_text, graphs, fonts, martel_fonts,
## status_bar, screen_snap owners)*
- [ ] Numbers render in every display format (ALL/FIX/SCI/ENG) with correct
      digit grouping, radix mark, and exponent.
- [ ] Status bar: shift (f/g), angular mode, complex, battery, time all draw and
      update.
- [ ] A graph/plot (STAT plot or function) renders, axes/shading correct.
- [ ] Soft-menu labels render; long-press shows the secondary label.
- [ ] Screen snapshot (if exposed) writes a readable image to flash.

## Key input & modes  *(input, bufferize, assign, calc_mode, tam owners)*
- [ ] Full numeric entry incl. EEX, +/-, radix; backspace; CLx.
- [ ] f/g shift then a shifted function; long-press behaviour.
- [ ] NIM commit: `1 2 ENTER 3 +` = 15 (the path host harness-init could not
      reach — verify on device).
- [ ] TAM register-argument entry (STO/RCL nn, the host TAM init wall) — store
      and recall a register and a named variable.
- [ ] ASN: assign an item to a key and invoke it.

## Browsers & catalogs  *(asn_browser, flag_browser, font_browser,
## radio_button_catalog, register_value_conversions, matrix_editor owners)*
- [ ] Open each browser (flags, fonts, assignments); scroll; select; exit.
- [ ] Matrix editor: create/edit a small matrix; navigate cells; store.

## Date / time  *(date_time owner)*
- [ ] Set and read the clock; date arithmetic; a date in each date format.

## Storage, config & memory  *(config, manage, free_list, textfiles, addons
## owners)*
- [ ] **Save state to flash, power off, power on, restore** — the on-device
      counterpart of the host save/load golden; verify stack, registers, named
      variables, flags survive (covers the fields the host golden pins).
- [ ] RESET to defaults; confirm config (angular mode, formats, flags).
- [ ] Free-list / memory: allocate to near-full (many registers/programs), then
      free; no corruption or leak-induced reset.
- [ ] A text file / program write and read back.

## Items, dispatch & errors  *(items, lbl_gto_xeq, c47, decode, char_string,
## error, debug, jm owners)*
- [ ] Run a short program with LBL/GTO/XEQ; conditional skip; subroutine return.
- [ ] Trigger an error (e.g. 1/0, domain error); correct error message renders
      and clears.

## Sign-off
- [ ] All boxes PASS on DM42(C47), DM42(R47), DM42n. Firmware hashes + date
      recorded here.
- [ ] Any FAIL filed as an issue and triaged before merge/push (M9.1/M9.3).

_Maintenance: when `report-firmware-host-gap.py` reports a new owner or a large
region delta, add/repoint a checklist item so the firmware surface stays fully
accounted (the A4 invariant: host-executed OR on this list, never neither)._
