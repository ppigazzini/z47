// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the keyboard lane: c43's OWN keyboard.c, compiled a
// second time into the full-core harness under `oracle_` names so it links beside
// the Zig owner that replaced it.
//
// WHAT THIS REPLACED. 238 hand-written lines modelling roughly
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

// ---------------------------------------------------------------------------
// c43's OWN keyboard layout tables, for the table differential.
//
// keyboard_entry_harness.c guarded kbd_std_C47 with a frozen FNV-1a checksum and a
// comment saying "the keyboard Zig owners have no compiled C oracle (the bridge was
// deleted), so an upstream change to the layout would otherwise be caught by
// nothing". That was true when it was written and is not any more: this lane
// compiles c43's keyboard.c, and assign.c -- where the tables actually live --
// compiles clean beside it. A checksum somebody has to re-pin by hand is a
// characterization test; the table itself is the reference.
// ---------------------------------------------------------------------------
#define kbd_std_C47 oracle_kbd_std_C47
#define kbd_std_D47 oracle_kbd_std_D47
#define kbd_std_DM42 oracle_kbd_std_DM42
#define kbd_std_E47 oracle_kbd_std_E47
#define kbd_std_N47 oracle_kbd_std_N47
#define kbd_std_V47 oracle_kbd_std_V47
#define kbd_std_R47bk_fg oracle_kbd_std_R47bk_fg
#define kbd_std_R47f_g oracle_kbd_std_R47f_g
#define kbd_std_R47fg_bk oracle_kbd_std_R47fg_bk
#define kbd_std_R47fg_g oracle_kbd_std_R47fg_g

#define _assignItem oracle_assignItem
#define assignEnterAlpha oracle_assignEnterAlpha
#define assignGetName1 oracle_assignGetName1
#define assignGetName2 oracle_assignGetName2
#define assignLeaveAlpha oracle_assignLeaveAlpha
#define assignToKey oracle_assignToKey
#define assignToMyAlpha oracle_assignToMyAlpha
#define assignToMyMenu oracle_assignToMyMenu
#define assignToUserMenu oracle_assignToUserMenu
#define createMenu oracle_createMenu
#define fnAssign oracle_fnAssign
#define fnClearUserMenus oracle_fnClearUserMenus
#define fnDeleteMenu oracle_fnDeleteMenu
#define fnDeleteUserMenus oracle_fnDeleteUserMenus
#define getUserKeyLabelString oracle_getUserKeyLabelString
#define initUserKeyArgument oracle_initUserKeyArgument
#define removeUserItemAssignments oracle_removeUserItemAssignments
#define setUserKeyArgument oracle_setUserKeyArgument
#define updateAssignTamBuffer oracle_updateAssignTamBuffer

// assign.c calls its own functions before defining them, and assign.h was already
// pulled in by c47.h above -- under the ORIGINAL names, before these renames -- so
// its include guard makes a re-include a no-op. Re-declare the prototypes the file
// forward-calls, under the renamed spellings. Copied from assign.h; re-derive with
//   grep -nE "^\s*(void|bool_t|int16_t)[^;]*\(" upstream/src/c47/assign.h
// after a resync rather than by hand.
void oracle_assignItem(userMenuItem_t *menuItem);
void oracle_assignEnterAlpha(void);
void oracle_assignGetName1(void);
void oracle_assignGetName2(void);
void oracle_assignLeaveAlpha(void);
void oracle_assignToKey(const char *data);
void oracle_assignToMyAlpha(uint16_t position);
void oracle_assignToMyMenu(uint16_t position);
void oracle_assignToUserMenu(uint16_t position);
void oracle_createMenu(const char *name);
void oracle_fnAssign(uint16_t mode);
void oracle_fnClearUserMenus(uint16_t confirmation);
void oracle_fnDeleteMenu(uint16_t id);
void oracle_fnDeleteUserMenus(uint16_t confirmation);
void oracle_initUserKeyArgument(void);
void oracle_removeUserItemAssignments(int16_t item, char *userItemName);
void oracle_setUserKeyArgument(uint16_t position, const char *name);
void oracle_updateAssignTamBuffer(void);
uint8_t *oracle_getUserKeyLabelString(int16_t n);

#include "../../../upstream/src/c47/assign.c"
