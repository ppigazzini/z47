// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnClPAll z47_frontier_retained_fnClPAll
#include "../../src/c47/programming/manage.c"

bool_t z47_frontier_program_current_program_in_ram(void) {
	return programList[currentProgramNumber - 1].step > 0;
}