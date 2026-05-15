// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_keyboard_state_runtime_standard_key(uint16_t index, calcKey_t *key) {
	*key = kbd_std[index];
}