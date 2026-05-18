// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnPercentMRR z47_math_wrappers_retained_fnPercentMRR
#include "../../src/c47/mathematics/percentMRR.c"
#undef fnPercentMRR

#define fnPercentPlusMG z47_math_wrappers_retained_fnPercentPlusMG
#include "../../src/c47/mathematics/percentPlusMG.c"
#undef fnPercentPlusMG

#define fnPercentT z47_math_wrappers_retained_fnPercentT
#include "../../src/c47/mathematics/percentT.c"
#undef fnPercentT

#define fnDeltaPercent z47_math_wrappers_retained_fnDeltaPercent
#include "../../src/c47/mathematics/deltaPercent.c"
#undef fnDeltaPercent