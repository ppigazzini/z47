// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnConstant oracle_fnConstant
#define fnPi oracle_fnPi
#include "../../../src/c47/constants.c"
#undef fnPi
#undef fnConstant