// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define compareTypeError oracle_compareTypeError
#define compareTypeErrorX oracle_compareTypeErrorX
#define registerCmp oracle_registerCmp
#define registerMax oracle_registerMax
#define registerMin oracle_registerMin
#define fnXLessThan oracle_fnXLessThan
#define fnXLessEqual oracle_fnXLessEqual
#define fnXGreaterThan oracle_fnXGreaterThan
#define fnXGreaterEqual oracle_fnXGreaterEqual
#define fnXEqualsTo oracle_fnXEqualsTo
#define fnXNotEqual oracle_fnXNotEqual
#define fnXAlmostEqual oracle_fnXAlmostEqual
#define fnIsConverged oracle_fnIsConverged
#include "../../../src/c47/mathematics/compare.c"

#define fnCheckType oracle_fnCheckType
#define fnCheckReal oracle_fnCheckReal
#define fnCheckNumber oracle_fnCheckNumber
#define fnCheckAngle oracle_fnCheckAngle
#define fnCheckMatrix oracle_fnCheckMatrix
#define fnCheckMatrixSquare oracle_fnCheckMatrixSquare
#define fnCheckForZero oracle_fnCheckForZero
#define fnCheckIsVect2d oracle_fnCheckIsVect2d
#define fnCheckIsVect3d oracle_fnCheckIsVect3d
#define fnCheckNaN oracle_fnCheckNaN
#define fnCheckInfinite oracle_fnCheckInfinite
#define fnCheckSpecial oracle_fnCheckSpecial
#define fnCheckPlusZero oracle_fnCheckPlusZero
#define fnCheckMinusZero oracle_fnCheckMinusZero
#define fnGetType oracle_fnGetType
#include "../../../src/c47/mathematics/checkValue.c"

#define fnCheckInteger oracle_fnCheckInteger
#include "../../../src/c47/mathematics/int.c"

#undef fnCheckInteger
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
#undef fnIsConverged
#undef fnXAlmostEqual
#undef fnXNotEqual
#undef fnXEqualsTo
#undef fnXGreaterEqual
#undef fnXGreaterThan
#undef fnXLessEqual
#undef fnXLessThan
#undef registerMin
#undef registerMax
#undef registerCmp
#undef compareTypeErrorX
#undef compareTypeError

#define fnAdd oracle_fnAdd
#include "../../../src/c47/mathematics/addition.c"
#undef fnAdd

#define fnSubtract oracle_fnSubtract
#include "../../../src/c47/mathematics/subtraction.c"
#undef fnSubtract

#define fnMultiply oracle_fnMultiply
#include "../../../src/c47/mathematics/multiplication.c"
#undef fnMultiply

#define fnDivide oracle_fnDivide
#include "../../../src/c47/mathematics/division.c"
#undef fnDivide

#define fnIDiv oracle_fnIDiv
#include "../../../src/c47/mathematics/idiv.c"
#undef fnIDiv

#define fnIDivR oracle_fnIDivR
#include "../../../src/c47/mathematics/idivr.c"
#undef fnIDivR

#define fnDblMultiply oracle_fnDblMultiply
#include "../../../src/c47/mathematics/dblMultiplication.c"
#undef fnDblMultiply

#define dblDivide oracle_dblDivide
#define fnDblDivide oracle_fnDblDivide
#define fnDblDivideRemainder oracle_fnDblDivideRemainder
#include "../../../src/c47/mathematics/dblDivision.c"
#undef fnDblDivideRemainder
#undef fnDblDivide
#undef dblDivide

#define fnRound oracle_fnRound
#include "../../../src/c47/mathematics/round.c"
#undef fnRound

#define fnDecomp oracle_fnDecomp
#include "../../../src/c47/mathematics/decomp.c"
#undef fnDecomp

#define fnDec oracle_fnDec
#define fnInc oracle_fnInc
#include "../../../src/c47/mathematics/incDec.c"
#undef fnInc
#undef fnDec