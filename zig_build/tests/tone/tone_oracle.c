// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnTone oracle_fnTone
#define fnBeep oracle_fnBeep
#include "../../../src/c47/ui/tone.c"
#undef fnTone
#undef fnBeep