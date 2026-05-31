// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#include "../../src/c47/mathematics/comparisonReals.c"

#define fnXLessThan z47_math_wrappers_legacy_fnXLessThan
#define fnXLessEqual z47_math_wrappers_legacy_fnXLessEqual
#define fnXGreaterThan z47_math_wrappers_legacy_fnXGreaterThan
#define fnXGreaterEqual z47_math_wrappers_legacy_fnXGreaterEqual
#define fnXEqualsTo z47_math_wrappers_legacy_fnXEqualsTo
#define fnXNotEqual z47_math_wrappers_legacy_fnXNotEqual
#define fnXAlmostEqual z47_math_wrappers_legacy_fnXAlmostEqual
#define fnIsConverged z47_math_wrappers_legacy_fnIsConverged
#include "../../src/c47/mathematics/compare.c"
#undef fnIsConverged
#undef fnXAlmostEqual
#undef fnXNotEqual
#undef fnXEqualsTo
#undef fnXGreaterEqual
#undef fnXGreaterThan
#undef fnXLessEqual
#undef fnXLessThan

#define fnCheckType z47_math_wrappers_legacy_fnCheckType
#define fnCheckReal z47_math_wrappers_legacy_fnCheckReal
#define fnCheckNumber z47_math_wrappers_legacy_fnCheckNumber
#define fnCheckAngle z47_math_wrappers_legacy_fnCheckAngle
#define fnCheckMatrix z47_math_wrappers_legacy_fnCheckMatrix
#define fnCheckMatrixSquare z47_math_wrappers_legacy_fnCheckMatrixSquare
#define fnCheckForZero z47_math_wrappers_legacy_fnCheckForZero
#define fnCheckIsVect2d z47_math_wrappers_legacy_fnCheckIsVect2d
#define fnCheckIsVect3d z47_math_wrappers_legacy_fnCheckIsVect3d
#define fnCheckNaN z47_math_wrappers_legacy_fnCheckNaN
#define fnCheckInfinite z47_math_wrappers_legacy_fnCheckInfinite
#define fnCheckSpecial z47_math_wrappers_legacy_fnCheckSpecial
#define fnCheckPlusZero z47_math_wrappers_legacy_fnCheckPlusZero
#define fnCheckMinusZero z47_math_wrappers_legacy_fnCheckMinusZero
#define fnGetType z47_math_wrappers_legacy_fnGetType
#include "../../src/c47/mathematics/checkValue.c"
#undef fnGetType
#undef fnCheckMinusZero
#undef fnCheckPlusZero
#undef fnCheckSpecial
#undef fnCheckInfinite
#undef fnCheckNaN
#undef fnCheckIsVect3d
#undef fnCheckIsVect2d
#undef fnCheckForZero
#undef fnCheckMatrixSquare
#undef fnCheckMatrix
#undef fnCheckAngle
#undef fnCheckNumber
#undef fnCheckReal
#undef fnCheckType

#define fnCheckInteger z47_math_wrappers_legacy_fnCheckInteger
#include "../../src/c47/mathematics/int.c"
#undef fnCheckInteger

#define fnAdd z47_math_wrappers_legacy_fnAdd
#include "../../src/c47/mathematics/addition.c"
#undef fnAdd

#define fnSubtract z47_math_wrappers_legacy_fnSubtract
#include "../../src/c47/mathematics/subtraction.c"
#undef fnSubtract

#define fnMultiply z47_math_wrappers_legacy_fnMultiply
#include "../../src/c47/mathematics/multiplication.c"
#undef fnMultiply

#define fnDivide z47_math_wrappers_legacy_fnDivide
#include "../../src/c47/mathematics/division.c"
#undef fnDivide

#define fnIDiv z47_math_wrappers_legacy_fnIDiv
#include "../../src/c47/mathematics/idiv.c"
#undef fnIDiv

#define fnIDivR z47_math_wrappers_legacy_fnIDivR
#include "../../src/c47/mathematics/idivr.c"
#undef fnIDivR

#define fnDblMultiply z47_math_wrappers_legacy_fnDblMultiply
#include "../../src/c47/mathematics/dblMultiplication.c"
#undef fnDblMultiply

#define fnDblDivide z47_math_wrappers_legacy_fnDblDivide
#define fnDblDivideRemainder z47_math_wrappers_legacy_fnDblDivideRemainder
#include "../../src/c47/mathematics/dblDivision.c"
#undef fnDblDivideRemainder
#undef fnDblDivide

#define fnRound z47_math_wrappers_legacy_fnRound
#include "../../src/c47/mathematics/round.c"
#undef fnRound

#define fnDecomp z47_math_wrappers_legacy_fnDecomp
#include "../../src/c47/mathematics/decomp.c"
#undef fnDecomp

#define fnDec z47_math_wrappers_legacy_fnDec
#define fnInc z47_math_wrappers_legacy_fnInc
#include "../../src/c47/mathematics/incDec.c"
#undef fnInc
#undef fnDec