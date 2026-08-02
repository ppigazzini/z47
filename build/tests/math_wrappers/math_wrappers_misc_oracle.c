// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnFib oracle_fnFib
#include "../../../upstream/src/c47/mathematics/fib.c"
#undef fnFib

#define linpol oracle_linpol
#define fnLINPOL oracle_fnLINPOL
#include "../../../upstream/src/c47/mathematics/linpol.c"
#undef fnLINPOL
#undef linpol

#define fnCross oracle_fnCross
#include "../../../upstream/src/c47/mathematics/cross.c"
#undef fnCross

#define fnDot oracle_fnDot
#include "../../../upstream/src/c47/mathematics/dot.c"
#undef fnDot

#define fnLogXY oracle_fnLogXY
#include "../../../upstream/src/c47/mathematics/logxy.c"
#undef fnLogXY
