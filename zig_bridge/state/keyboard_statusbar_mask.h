// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_KEYBOARD_STATUSBAR_MASK_H
#define Z47_KEYBOARD_STATUSBAR_MASK_H

#include <stdint.h>

#include "defines.h"

static inline uint8_t clearStatusbarUpdateFlags(uint8_t mode) {
	return (uint8_t)(mode & (uint8_t)~(SCRUPD_MANUAL_STATUSBAR | SCRUPD_SKIP_STATUSBAR_ONE_TIME));
}

#endif