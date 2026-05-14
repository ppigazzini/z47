// SPDX-License-Identifier: GPL-3.0-only

#define Z47_EXTERNAL_SET_LAST_KEY_CODE 1
#define Z47_EXTERNAL_KEYBOARD_TWEAK_REPLACEMENTS 1

#define btnPressed z47_keyboard_state_retained_btnPressed
#define btnClicked z47_keyboard_state_retained_btnClicked

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