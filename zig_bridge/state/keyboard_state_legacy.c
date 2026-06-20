// SPDX-License-Identifier: GPL-3.0-only

#define setLastKeyCode z47_keyboard_state_setLastKeyCode
#define caseReplacements z47_keyboard_state_caseReplacements
#define keyReplacements z47_keyboard_state_keyReplacements
#define numlockReplacements z47_keyboard_state_numlockReplacements

#if defined(PC_BUILD)
#define processKeyAction z47_keyboard_state_processKeyAction
#define fnKeyEnter z47_keyboard_state_fnKeyEnter
#define fnKeyExit z47_keyboard_state_fnKeyExit
#define fnKeyCC z47_keyboard_state_fnKeyCC
#define fnKeyBackspace z47_keyboard_state_fnKeyBackspace
#define fnKeyUp z47_keyboard_state_fnKeyUp
#define fnKeyDown z47_keyboard_state_fnKeyDown
#define fnKeyDotD z47_keyboard_state_fnKeyDotD
#endif

#define btnPressed z47_keyboard_state_btnPressed
#define btnClicked z47_keyboard_state_btnClicked

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

// _assignToMenu is static inside keyboard.c, so the Zig fnKeyBackspace/Up/Down
// owners cannot link it directly.  Expose a thin external trampoline from inside
// this translation unit (where the static is in scope).
bool_t z47_keyboard_state_assignToMenu(uint8_t *data) {
  return _assignToMenu(data);
}

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