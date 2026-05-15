// SPDX-License-Identifier: GPL-3.0-only

#define Z47_EXTERNAL_SET_LAST_KEY_CODE 1
#define Z47_EXTERNAL_KEYBOARD_TWEAK_REPLACEMENTS 1

#if defined(PC_BUILD)
#define Z47_KEYBOARD_PROCESS_KEY_ACTION_NAME z47_keyboard_state_retained_processKeyAction
#define Z47_KEYBOARD_FN_KEY_ENTER_NAME z47_keyboard_state_retained_fnKeyEnter
#define Z47_KEYBOARD_FN_KEY_EXIT_NAME z47_keyboard_state_retained_fnKeyExit
#define Z47_KEYBOARD_FN_KEY_CC_NAME z47_keyboard_state_retained_fnKeyCC
#define Z47_KEYBOARD_FN_KEY_BACKSPACE_NAME z47_keyboard_state_retained_fnKeyBackspace
#define Z47_KEYBOARD_FN_KEY_UP_NAME z47_keyboard_state_retained_fnKeyUp
#define Z47_KEYBOARD_FN_KEY_DOWN_NAME z47_keyboard_state_retained_fnKeyDown
#define Z47_KEYBOARD_FN_KEY_DOTD_NAME z47_keyboard_state_retained_fnKeyDotD
#endif

#define btnPressed z47_keyboard_state_retained_btnPressed
#define btnClicked z47_keyboard_state_retained_btnClicked

#include "../../src/c47/keyboard.c"

#if defined(PC_BUILD)
#undef Z47_KEYBOARD_FN_KEY_DOTD_NAME
#undef Z47_KEYBOARD_FN_KEY_DOWN_NAME
#undef Z47_KEYBOARD_FN_KEY_UP_NAME
#undef Z47_KEYBOARD_FN_KEY_BACKSPACE_NAME
#undef Z47_KEYBOARD_FN_KEY_CC_NAME
#undef Z47_KEYBOARD_FN_KEY_EXIT_NAME
#undef Z47_KEYBOARD_FN_KEY_ENTER_NAME
#undef Z47_KEYBOARD_PROCESS_KEY_ACTION_NAME
#endif

#undef btnClicked
#undef btnPressed

#if defined(PC_BUILD)
extern void btnClicked(GtkWidget *notUsed, gpointer data);
#endif

#if defined(DMCP_BUILD)
extern void btnClicked(void *unused, void *data);
#endif

#include "../../src/c47/c47Extensions/keyboardTweak.c"