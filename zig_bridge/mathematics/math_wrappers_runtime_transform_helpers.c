// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_math_wrappers_legacy_fnToPolar2(uint16_t unusedButMandatoryParameter);
void z47_math_wrappers_legacy_fnToRect2(uint16_t unusedButMandatoryParameter);
static void z47_math_wrappers_legacy_fnToRect_impl(int8_t angleInY);

#define fnToPolar2 z47_math_wrappers_legacy_fnToPolar2
#include "../../src/c47/mathematics/toPolar.c"
#undef fnToPolar2

#define fnToRect2 z47_math_wrappers_legacy_fnToRect2
#define fnToRect z47_math_wrappers_legacy_fnToRect_impl
#include "../../src/c47/mathematics/toRect.c"
#undef fnToRect
#undef fnToRect2

void z47_math_wrappers_legacy_fnToRect(uint16_t angleInY) {
	z47_math_wrappers_legacy_fnToRect_impl((int8_t)angleInY);
}

#define fnParallel z47_math_wrappers_legacy_fnParallel
#include "../../src/c47/mathematics/parallel.c"
#undef fnParallel

#define fnUnitVector z47_math_wrappers_legacy_fnUnitVector
#include "../../src/c47/mathematics/unitVector.c"
#undef fnUnitVector

#define fnSdl z47_math_wrappers_legacy_fnSdl
#define fnSdr z47_math_wrappers_legacy_fnSdr
#include "../../src/c47/mathematics/shiftDigits.c"
#undef fnSdr
#undef fnSdl

#define fnSquareRoot z47_math_wrappers_legacy_fnSquareRoot
#include "../../src/c47/mathematics/squareRoot.c"
#undef fnSquareRoot

#define fnCubeRoot z47_math_wrappers_legacy_fnCubeRoot
#include "../../src/c47/mathematics/cubeRoot.c"
#undef fnCubeRoot