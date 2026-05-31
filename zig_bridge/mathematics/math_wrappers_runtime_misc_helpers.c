// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnFib z47_math_wrappers_legacy_fnFib
#include "../../src/c47/mathematics/fib.c"
#undef fnFib

#define fnLINPOL z47_math_wrappers_legacy_fnLINPOL
#include "../../src/c47/mathematics/linpol.c"
#undef fnLINPOL

#define fnCross z47_math_wrappers_legacy_fnCross
#include "../../src/c47/mathematics/cross.c"
#undef fnCross

#define fnDot z47_math_wrappers_legacy_fnDot
#include "../../src/c47/mathematics/dot.c"
#undef fnDot

#define fnLogXY z47_math_wrappers_legacy_fnLogXY
#include "../../src/c47/mathematics/logxy.c"
#undef fnLogXY