// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the system-flags lane: c43's OWN flags.c, compiled
// under `oracle_` names so it links beside the Zig owner's exports of the same
// c43 names.
//
// This file used to be 705 lines of hand-transliterated C reproducing four
// fifths of flags.c -- its own flagAction_t, its own copies of
// refreshStateFlags / clearStatusBarFlags / clearSetPairs / flipFlags. It could
// not detect c43 moving, because it WAS the reference and it stayed put; and it
// had already drifted (FLAG_IMPLOT was missing from two of
// those four tables, which the lane reported as parity).
//
// Nothing here may be edited to make the lane pass. If the oracle and the Zig
// owner disagree, c43 is right by definition and the owner is the thing to fix.

#include "c47.h"

// Rename every symbol flags.c gives external linkage. Function-like renaming is
// token-based, so the file-static `_setSystemFlag` is untouched by the
// `setSystemFlag` rename -- they are different identifiers.
#define systemFlags0Changed oracle_systemFlags0Changed
#define systemFlags1Changed oracle_systemFlags1Changed
#define systemFlags2Changed oracle_systemFlags2Changed
#define refreshStateFlags oracle_refreshStateFlags
#define clearStatusBarFlags oracle_clearStatusBarFlags
#define clearSetPairs oracle_clearSetPairs
#define flipFlags oracle_flipFlags

#define setSystemFlag oracle_setSystemFlag
#define clearSystemFlag oracle_clearSystemFlag
#define flipSystemFlag oracle_flipSystemFlag
#define getSystemFlag oracle_getSystemFlag
#define didSystemFlagChange oracle_didSystemFlagChange
#define setSystemFlagChanged oracle_setSystemFlagChanged
#define setAllSystemFlagChanged oracle_setAllSystemFlagChanged
#define forceSystemFlag oracle_forceSystemFlag
#define getFlag oracle_getFlag
#define fnGetSystemFlag oracle_fnGetSystemFlag
#define fnSetFlag oracle_fnSetFlag
#define fnClearFlag oracle_fnClearFlag
#define fnFlipFlag oracle_fnFlipFlag
#define fnClFAll oracle_fnClFAll
#define fnIsFlagClear oracle_fnIsFlagClear
#define fnIsFlagClearClear oracle_fnIsFlagClearClear
#define fnIsFlagClearSet oracle_fnIsFlagClearSet
#define fnIsFlagClearFlip oracle_fnIsFlagClearFlip
#define fnIsFlagSet oracle_fnIsFlagSet
#define fnIsFlagSetClear oracle_fnIsFlagSetClear
#define fnIsFlagSetSet oracle_fnIsFlagSetSet
#define fnIsFlagSetFlip oracle_fnIsFlagSetFlip
#define SetSetting oracle_SetSetting

#include "../../../upstream/src/c47/flags.c"
