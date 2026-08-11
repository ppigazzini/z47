// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

// The frequency table is renamed with the two commands: it is not static
// upstream, and tone.zig exports it under its own name, so both objects would
// otherwise define it. tone.c's own _tonePlay reads it through this name, so the
// oracle keeps reading the oracle's copy.
#define fnTone oracle_fnTone
#define fnBeep oracle_fnBeep
#define frequency oracle_frequency
#include "../../../upstream/src/c47/ui/tone.c"
#undef frequency
#undef fnBeep
#undef fnTone
