// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#include "../../src/c47/error.c"

#if !defined(PC_BUILD)
void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4) {
	(void)m1;
	(void)m2;
	(void)m3;
	(void)m4;
}
#endif
