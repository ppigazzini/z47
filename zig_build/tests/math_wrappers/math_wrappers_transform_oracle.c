// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void oracle_fnToPolar2(uint16_t unusedButMandatoryParameter);
void oracle_fnToRect2(uint16_t unusedButMandatoryParameter);
static void oracle_fnToRect_impl(int8_t angleInY);

#define real34RectangularToPolar oracle_real34RectangularToPolar
#define fnToPolar2 oracle_fnToPolar2
#include "../../../src/c47/mathematics/toPolar.c"
#undef fnToPolar2
#undef real34RectangularToPolar

#define realPolarToRectangular oracle_realPolarToRectangular
#define fnToRect2 oracle_fnToRect2
#define fnToRect oracle_fnToRect_impl
#include "../../../src/c47/mathematics/toRect.c"
#undef fnToRect
#undef fnToRect2
#undef realPolarToRectangular

void oracle_fnToRect(uint16_t angleInY) {
	oracle_fnToRect_impl((int8_t)angleInY);
}

#define fnParallel oracle_fnParallel
#include "../../../src/c47/mathematics/parallel.c"
#undef fnParallel

#define unitVectorCplx oracle_unitVectorCplx
#define unitVectorRema oracle_unitVectorRema
#define unitVectorCxma oracle_unitVectorCxma
#define fnUnitVector oracle_fnUnitVector
#include "../../../src/c47/mathematics/unitVector.c"
#undef fnUnitVector
#undef unitVectorCxma
#undef unitVectorRema
#undef unitVectorCplx

#define fnSdl oracle_fnSdl
#define fnSdr oracle_fnSdr
#include "../../../src/c47/mathematics/shiftDigits.c"
#undef fnSdr
#undef fnSdl

#define rootLonI oracle_rootLonI
#define sqrtComplex75 oracle_sqrtComplex75
#define sqrtComplex159 oracle_sqrtComplex159
#define sqrtComplex oracle_sqrtComplex
#define fnSquareRoot oracle_fnSquareRoot
#include "../../../src/c47/mathematics/squareRoot.c"
#undef fnSquareRoot
#undef sqrtComplex
#undef sqrtComplex159
#undef sqrtComplex75
#undef rootLonI

#define curtReal oracle_curtReal
#define curtCplx oracle_curtCplx
#define curtComplex75 oracle_curtComplex75
#define curtComplex159 oracle_curtComplex159
#define curtComplex oracle_curtComplex
#define fnCubeRoot oracle_fnCubeRoot
#include "../../../src/c47/mathematics/cubeRoot.c"
#undef fnCubeRoot
#undef curtComplex
#undef curtComplex159
#undef curtComplex75
#undef curtCplx
#undef curtReal