// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnPercentMRR oracle_fnPercentMRR
#include "../../../upstream/src/c47/mathematics/percentMRR.c"
#undef fnPercentMRR

#define fnPercentPlusMG oracle_fnPercentPlusMG
#include "../../../upstream/src/c47/mathematics/percentPlusMG.c"
#undef fnPercentPlusMG

#define fnPercentT oracle_fnPercentT
#include "../../../upstream/src/c47/mathematics/percentT.c"
#undef fnPercentT

#define fnDeltaPercent oracle_fnDeltaPercent
#include "../../../upstream/src/c47/mathematics/deltaPercent.c"
#undef fnDeltaPercent
