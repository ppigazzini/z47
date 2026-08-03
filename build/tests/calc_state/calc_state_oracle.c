// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the calc-state lane: c43's OWN saveRestoreCalcState.c,
// compiled a second time into the full-core harness under `oracle_` names so it
// links beside the Zig owner that replaced it.
//
// WHAT THIS REPLACED (REPORT-31 M31-10). 194 hand-written lines that modelled
// save-file revision parsing and nothing else -- about 6% of a 2959-line file --
// under a lane named for the whole subsystem. The other 94% had never been
// compared to anything, and M31-1 had already established that
// `saveload_roundtrip`'s golden is a z47 self-portrait regenerated from z47's own
// writer. So NOTHING in the tree held z47's `.sav` FORMAT to c43's: a silent
// state-file incompatibility on the most externally visible artifact z47 writes,
// the file a user carries between a physical DM42 and the simulator.
//
// WHY A FULL-CORE DIFFERENTIAL AND NOT A LINKED UNIT ORACLE. M31-10 planned a unit
// harness: 96 globals defined once and shared, real in-memory file I/O, SHARED
// value codecs, counting stubs for the rest. Its own stop condition fired on step
// 3 -- "if the shared-codec requirement turns out to need more than a handful of
// real c43 files linked live, stop and re-plan; the honest shape may be a
// full-core differential". The measurement: 210 undefined symbols, and the codecs
// among them (decQuadToString/FromString, registerFMAOutputPlainString,
// longIntegerToAllocatedString, getRegisterDataPointer/Type/Tag, reallocateRegister,
// findOrAllocateNamedVariable, convert*Register*, utf8ToString) pull registers.c,
// memory.c, charString.c, registerValueConversions.c, longIntegerType, dateTime,
// decNumber and GMP. That is not a handful, and modelling any of them would mean
// the lane measures the codec instead of the section writer.
//
// In a full core every one of those 210 symbols is already defined and the codecs
// are shared by construction, because both implementations are literally calling
// the same ones. The stub burden is ZERO -- the same inversion Annex A.3 recorded
// for keyboard.c. `charstring_diff` is the in-tree precedent for the shape: lift
// c43 functions under `oracle_*` renames and link them beside the Zig owner that
// replaced them, in one binary, so the two can be diffed directly.
//
// Nothing here may be edited to make the lane pass. If the oracle and the Zig
// owner disagree, c43 is right by definition and the owner is the thing to fix --
// and a disagreement here is a `.sav` FORMAT divergence, not a cosmetic one.

// Every symbol saveRestoreCalcState.c gives external linkage, renamed so it does
// not collide with the Zig owner's export of the same c43 name. File-static
// helpers (`doSave`, `restoreOneSection`, `save_sections`, ...) need no rename:
// they are private to this translation unit either way, which is precisely why
// compiling the whole file is what reaches them.
//
// Derived mechanically:
//   nm -g --defined-only <saveRestoreCalcState.o> | awk '{print $3}'
// Re-derive it that way after a resync rather than reading the header -- the
// header does not list `strcmp2`, `fnSaveDataRegisters`, `savedCalcModel` or
// `aimBuffer1`, and a missed name is a duplicate-symbol link error at best and a
// silently shared global at worst.

#define fnSave oracle_fnSave
#define fnLoad oracle_fnLoad
#define fnSaveAuto oracle_fnSaveAuto
#define fnLoadAuto oracle_fnLoadAuto
#define fnLoadedFile oracle_fnLoadedFile
#define fnDeleteBackup oracle_fnDeleteBackup
#define doLoad oracle_doLoad

#define fnSaveStackRegisters oracle_fnSaveStackRegisters
#define fnSaveXFNRegister oracle_fnSaveXFNRegister
#define fnSaveLetteredRegisters oracle_fnSaveLetteredRegisters
#define fnSaveNRegisters oracle_fnSaveNRegisters
#define fnSaveRegister oracle_fnSaveRegister
#define fnSaveDataRegisters oracle_fnSaveDataRegisters
#define fnLoadRegisters oracle_fnLoadRegisters

#define save oracle_save
#define readLine oracle_readLine
#define read2Lines oracle_read2Lines
#define strcmp2 oracle_strcmp2
#define toInt32 oracle_toInt32
#define _updateConstantsInEquations oracle_updateConstantsInEquations
#define convert001090400T001090500 oracle_convert001090400T001090500

#define stringToUint8 oracle_stringToUint8
#define stringToUint16 oracle_stringToUint16
#define stringToUint32 oracle_stringToUint32
#define stringToUint64 oracle_stringToUint64
#define stringToInt8 oracle_stringToInt8
#define stringToInt16 oracle_stringToInt16
#define stringToInt32 oracle_stringToInt32
#define stringToInt64 oracle_stringToInt64
#define stringToFloat oracle_stringToFloat

// File-scope state the file owns. Renamed too, so the oracle keeps its own copy
// rather than sharing the owner's -- both are private to saveRestoreCalcState.c
// in c43 (nothing else in src/c47 references either), so a shared one would be a
// coupling c43 does not have.
#define savedCalcModel oracle_savedCalcModel
#define aimBuffer1 oracle_aimBuffer1

#include "../../../upstream/src/c47/saveRestoreCalcState.c"
