// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the keyboard lane: c43's OWN keyboard.c, compiled a
// second time into the full-core harness under `oracle_` names so it links beside
// the Zig owner that replaced it.
//
// WHAT THIS REPLACED (REPORT-31 M31-13). 238 hand-written lines modelling roughly
// 4% of a 4982-line file, under a lane named for the whole subsystem -- and, by
// its own driver's admission, the handler cases had already been deleted because
// the simplified oracle no longer matched the ported handlers. What was left was
// four pure translation helpers with a hand-written reference, which is the shape
// this report exists to remove.
//
// WHY THE FULL CORE IS THE ONLY SHAPE THAT WORKS HERE (Annex A.3). keyboard.c is
// the one file the compile-from-c43 unit recipe fails on: it reads `GdkEvent`
// FIELDS and declares a `GdkEventButton` BY VALUE, so the six placeholder typedefs
// in build/tests/common are not enough and it needs real gtk+-3.0 headers -- and
// even then it leaves 313 undefined symbols. As a unit harness that is the worst
// of the five: a GUI toolkit dragged into a lane whose point is to be small and
// headless, 313 stubs, to replace an oracle covering 4%.
//
// In a FULL CORE the same number costs nothing: addFullCoreHarness already links
// GTK, GMP, libm and the entire core object graph, so every one of those 313
// symbols is already defined. The stub burden is ZERO, and the environment
// keyboard.c demands is exactly the environment the harness already has.
//
// Nothing here may be edited to make the lane pass.

// Every symbol keyboard.c gives external linkage. Derived mechanically:
//   nm -g --defined-only <keyboard.o> | awk '{print $3}'
//
// `key`, `asnKey` and `CatalogMenus` are FILE-SCOPE STATE, not functions, and
// nothing outside keyboard.c references them (checked across src/c47), so the
// oracle keeps its own copies. The harness zeroes both sides' copies when it
// seeds, because they persist across calls and an un-reset one would make case
// N+1 depend on case N.
//
// `key` is also a struct member name (`tamState_t.key`). Renaming it here renames
// the member consistently within THIS translation unit -- same layout, same
// offsets, no ABI effect -- which is why the rename is safe despite how common
// the token is.

#define CatalogMenus oracle_CatalogMenus
#define asnKey oracle_asnKey
#define key oracle_key

#define btnClicked oracle_btnClicked
#define btnClickedP oracle_btnClickedP
#define btnClickedR oracle_btnClickedR
#define btnFnClicked oracle_btnFnClicked
#define btnFnClickedP oracle_btnFnClickedP
#define btnFnClickedR oracle_btnFnClickedR
#define btnFnPressed oracle_btnFnPressed
#define btnFnReleased oracle_btnFnReleased
#define btnPressed oracle_btnPressed
#define btnReleased oracle_btnReleased
#define checkKeyShifts oracle_checkKeyShifts
#define determineFunctionKeyItem_C47 oracle_determineFunctionKeyItem_C47
#define execAutoRepeat oracle_execAutoRepeat
#define frmCalcMouseButtonPressed oracle_frmCalcMouseButtonPressed
#define frmCalcMouseButtonReleased oracle_frmCalcMouseButtonReleased
#define leavePem oracle_leavePem
#define nimWhenButtonPressed oracle_nimWhenButtonPressed
#define processAimInput oracle_processAimInput
#define processKeyAction oracle_processKeyAction
#define releaseOverride oracle_releaseOverride
#define shiftKeyClearsError oracle_shiftKeyClearsError
#define showScreenDismissed oracle_showScreenDismissed

// The eight entry points the deleted oracle modelled, and the ones this lane
// drives directly.
#define fnKeyBackspace oracle_fnKeyBackspace
#define fnKeyCC oracle_fnKeyCC
#define fnKeyDotD oracle_fnKeyDotD
#define fnKeyDown oracle_fnKeyDown
#define fnKeyEnter oracle_fnKeyEnter
#define fnKeyExit oracle_fnKeyExit
#define fnKeyUp oracle_fnKeyUp
#define setLastKeyCode oracle_setLastKeyCode

#include "../../../upstream/src/c47/keyboard.c"
