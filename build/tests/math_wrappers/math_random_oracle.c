// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#include <string.h>

uint32_t oracle_pcg32_random_r(pcg32_random_t *rng);

#define pcg32_srandom_r oracle_pcg32_srandom_r
#define pcg32_srandom oracle_pcg32_srandom
#define pcg32_random_r oracle_pcg32_random_r
#include "../../../upstream/src/c47/mathematics/pcg_basic.c"
#undef pcg32_random_r
#undef pcg32_srandom
#undef pcg32_srandom_r

#define pcg32_srandom oracle_pcg32_srandom
#define pcg32_random_r oracle_pcg32_random_r
#define realRandomU01 oracle_realRandomU01
#define fnRandomI oracle_fnRandomI
#define fnRandom oracle_fnRandom
#define fnSeed oracle_fnSeed
#include "../../../upstream/src/c47/mathematics/random.c"
#undef fnSeed
#undef fnRandom
#undef fnRandomI
#undef realRandomU01
#undef pcg32_random_r
#undef pcg32_srandom
