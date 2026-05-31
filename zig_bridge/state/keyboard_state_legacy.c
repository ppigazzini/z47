// SPDX-License-Identifier: GPL-3.0-only

#define setLastKeyCode z47_keyboard_state_legacy_setLastKeyCode
#define caseReplacements z47_keyboard_state_legacy_caseReplacements
#define keyReplacements z47_keyboard_state_legacy_keyReplacements
#define numlockReplacements z47_keyboard_state_legacy_numlockReplacements

#if defined(PC_BUILD)
#define processKeyAction z47_keyboard_state_legacy_processKeyAction
#define fnKeyEnter z47_keyboard_state_legacy_fnKeyEnter
#define fnKeyExit z47_keyboard_state_legacy_fnKeyExit
#define fnKeyCC z47_keyboard_state_legacy_fnKeyCC
#define fnKeyBackspace z47_keyboard_state_legacy_fnKeyBackspace
#define fnKeyUp z47_keyboard_state_legacy_fnKeyUp
#define fnKeyDown z47_keyboard_state_legacy_fnKeyDown
#define fnKeyDotD z47_keyboard_state_legacy_fnKeyDotD
#endif

#define btnPressed z47_keyboard_state_legacy_btnPressed
#define btnClicked z47_keyboard_state_legacy_btnClicked

#include "../../src/c47/keyboard.c"

#undef btnClicked
#undef btnPressed

#if defined(PC_BUILD)
extern void btnClicked(GtkWidget *notUsed, gpointer data);
#endif

#if defined(DMCP_BUILD)
extern void btnClicked(void *unused, void *data);
#endif

#include "../../src/c47/c47Extensions/keyboardTweak.c"

#undef numlockReplacements
#undef keyReplacements
#undef caseReplacements
#undef setLastKeyCode
#if defined(PC_BUILD)
#undef fnKeyDotD
#undef fnKeyDown
#undef fnKeyUp
#undef fnKeyBackspace
#undef fnKeyCC
#undef fnKeyExit
#undef fnKeyEnter
#undef processKeyAction
#endif