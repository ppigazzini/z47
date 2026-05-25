// SPDX-License-Identifier: GPL-3.0-only

#include <stdint.h>

#include "c47.h"

#if defined(DMCP_BUILD)
#include <lft_ifc.h>
#endif

void z47_tone_refresh_display(void) {
#if defined(DMCP_BUILD)
	((void (*)(void))(uintptr_t)(LIBRARY_FN_BASE + 48))();
#else
	refreshLcd(NULL);
#endif
}
