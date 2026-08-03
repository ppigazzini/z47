// SPDX-License-Identifier: GPL-3.0-only
//
// The parity reference for the math-wrapper differential: c43's own
// mathematics/*.c, compiled a second time into the full-core harness under
// `oracle_` names so they link beside the Zig owners that replaced them.
//
// The harness is a full core because these wrappers cannot be compared in
// isolation from the arithmetic they dispatch into. addFullCoreHarness supplies
// real decNumber, the real register file, the real constant blob and the Zig math
// owner, so both sides compute with the same arithmetic and the differential is
// about results. A unit harness would have to model that arithmetic, and the lane
// would then be measuring the model.
//
// Nothing here may be edited to make the lane pass.

// Every symbol these files give external linkage, derived mechanically:
//   nm -g --defined-only <file>.o | awk '{print $3}'
//
// 96 names across 14 files, no name exported by two of them. The five marked
// STATE are c43's type-dispatch TABLES -- `void (*const idiv[N][N])(void)` and
// friends -- not functions. They need renaming for the same reason: a missed one
// links silently against the owner's table, where a missed function would at
// least give a duplicate-symbol error.

// The five per-file `*Error` handlers are deliberately NOT renamed. When
// EXTRA_INFO_ON_CALC_ERROR is not 1 -- which is this harness's configuration --
// c43's own headers reduce them to the shared handler with `#define roundError
// typeError` (round.h:15, and the same line in idiv.h, idivr.h, atan2.h and
// unitVector.h). In that build they are not functions and there is nothing to
// rename; the dispatch tables' error slots resolve to `typeError`, which the Zig
// owner provides and both sides share. Renaming them anyway silently redefines
// c43's macro and makes the tables disagree about which handler they hold.

// --- checkValue.c (17 functions) ---
#define fnCheckAngle oracle_fnCheckAngle
#define fnCheckForZero oracle_fnCheckForZero
#define fnCheckGreaterEqualPlusZero oracle_fnCheckGreaterEqualPlusZero
#define fnCheckInfinite oracle_fnCheckInfinite
#define fnCheckIsVect2d oracle_fnCheckIsVect2d
#define fnCheckIsVect3d oracle_fnCheckIsVect3d
#define fnCheckLessEqualMinusZero oracle_fnCheckLessEqualMinusZero
#define fnCheckMatrix oracle_fnCheckMatrix
#define fnCheckMatrixSquare oracle_fnCheckMatrixSquare
#define fnCheckMinusZero oracle_fnCheckMinusZero
#define fnCheckNaN oracle_fnCheckNaN
#define fnCheckNumber oracle_fnCheckNumber
#define fnCheckPlusZero oracle_fnCheckPlusZero
#define fnCheckReal oracle_fnCheckReal
#define fnCheckSpecial oracle_fnCheckSpecial
#define fnCheckType oracle_fnCheckType
#define fnGetType oracle_fnGetType

// --- compare.c (13 functions) ---
#define compareTypeError oracle_compareTypeError
#define compareTypeErrorX oracle_compareTypeErrorX
#define fnIsConverged oracle_fnIsConverged
#define fnXAlmostEqual oracle_fnXAlmostEqual
#define fnXEqualsTo oracle_fnXEqualsTo
#define fnXGreaterEqual oracle_fnXGreaterEqual
#define fnXGreaterThan oracle_fnXGreaterThan
#define fnXLessEqual oracle_fnXLessEqual
#define fnXLessThan oracle_fnXLessThan
#define fnXNotEqual oracle_fnXNotEqual
#define registerCmp oracle_registerCmp
#define registerMax oracle_registerMax
#define registerMin oracle_registerMin

// --- int.c (1 functions) ---
#define fnCheckInteger oracle_fnCheckInteger

// --- idiv.c (11 functions, 1 STATE) ---
#define idiv oracle_idiv  // dispatch table, not a function
#define fnIDiv oracle_fnIDiv
#define idivLonILonI oracle_idivLonILonI
#define idivLonIReal oracle_idivLonIReal
#define idivLonIShoI oracle_idivLonIShoI
#define idivRealLonI oracle_idivRealLonI
#define idivRealReal oracle_idivRealReal
#define idivRealShoI oracle_idivRealShoI
#define idivShoILonI oracle_idivShoILonI
#define idivShoIReal oracle_idivShoIReal
#define idivShoIShoI oracle_idivShoIShoI

// --- idivr.c (11 functions, 1 STATE) ---
#define idivr oracle_idivr  // dispatch table, not a function
#define fnIDivR oracle_fnIDivR
#define idivrLonILonI oracle_idivrLonILonI
#define idivrLonIReal oracle_idivrLonIReal
#define idivrLonIShoI oracle_idivrLonIShoI
#define idivrRealLonI oracle_idivrRealLonI
#define idivrRealReal oracle_idivrRealReal
#define idivrRealShoI oracle_idivrRealShoI
#define idivrShoILonI oracle_idivrShoILonI
#define idivrShoIReal oracle_idivrShoIReal
#define idivrShoIShoI oracle_idivrShoIShoI

// --- round.c (8 functions, 1 STATE) ---
#define Round oracle_Round  // dispatch table, not a function
#define fnRound oracle_fnRound
#define roundCplx oracle_roundCplx
#define roundCxma oracle_roundCxma
#define roundDate oracle_roundDate
#define roundReal oracle_roundReal
#define roundRema oracle_roundRema
#define roundTime oracle_roundTime

// --- toPolar.c (5 functions) ---
#define fnToPolar2 oracle_fnToPolar2
#define fnToPolar_CX oracle_fnToPolar_CX
#define fnToPolar_HP oracle_fnToPolar_HP
#define real34RectangularToPolar oracle_real34RectangularToPolar
#define realRectangularToPolar oracle_realRectangularToPolar

// --- toRect.c (4 functions) ---
#define fnToRect2 oracle_fnToRect2
#define fnToRect_CX oracle_fnToRect_CX
#define fnToRect_HP oracle_fnToRect_HP
#define realPolarToRectangular oracle_realPolarToRectangular
// c43's fnToRect is static and takes an int8_t, so renaming it is not enough to
// reach it: it needs a definition with external linkage in this translation unit.
// oracleFnToRectEntry below is that, and it is deliberately NOT called
// oracle_fnToRect -- the oracle_ prefix means "c43's own body", and this is an
// adapter over one.
#define fnToRect oracle_fnToRect_impl

// --- squareRoot.c (5 functions) ---
// Compiled for rootLonI, which cubeRoot.c calls and the Zig owner keeps internal.
// Under the renames below cubeRoot.c's call resolves to c43's own definition here
// rather than to a symbol the owner does not export.
#define fnSquareRoot oracle_fnSquareRoot
#define rootLonI oracle_rootLonI
#define sqrtComplex oracle_sqrtComplex
#define sqrtComplex159 oracle_sqrtComplex159
#define sqrtComplex75 oracle_sqrtComplex75

// --- cubeRoot.c (6 functions) ---
#define curtComplex oracle_curtComplex
#define curtComplex159 oracle_curtComplex159
#define curtComplex75 oracle_curtComplex75
#define curtCplx oracle_curtCplx
#define curtReal oracle_curtReal
#define fnCubeRoot oracle_fnCubeRoot

// --- atan2.c (7 functions, 1 STATE) ---
#define arctan2 oracle_arctan2  // dispatch table, not a function
#define atan2LonIRema oracle_atan2LonIRema
#define atan2RealReal oracle_atan2RealReal
#define atan2RealRema oracle_atan2RealRema
#define atan2RemaReal oracle_atan2RemaReal
#define atan2RemaRema oracle_atan2RemaRema
#define fnAtan2 oracle_fnAtan2

// --- conjugate.c (2 functions) ---
#define conjCplx oracle_conjCplx
#define fnConjugate oracle_fnConjugate

// --- swapRealImaginary.c (1 functions) ---
#define fnSwapRealImaginary oracle_fnSwapRealImaginary

// --- unitVector.c (5 functions, 1 STATE) ---
#define unitVector oracle_unitVector  // dispatch table, not a function
#define fnUnitVector oracle_fnUnitVector
#define unitVectorCplx oracle_unitVectorCplx
#define unitVectorCxma oracle_unitVectorCxma
#define unitVectorRema oracle_unitVectorRema

// --- the inverse-circular and inverse-hyperbolic family (6 files) ---
// These wrappers had no result-level comparison anywhere: the unit lane drives
// them over a fake numeric core, which compares the paths they take and not the
// numbers they produce. Here both sides run on real decNumber.
#define arcsinCplx oracle_arcsinCplx
#define arcsinReal oracle_arcsinReal
#define ArcsinComplex oracle_ArcsinComplex
#define fnArcsin oracle_fnArcsin

#define arccosCplx oracle_arccosCplx
#define arccosReal oracle_arccosReal
#define fnArccos oracle_fnArccos

#define arctanReal oracle_arctanReal
#define arctanCplx oracle_arctanCplx
#define ArctanComplex oracle_ArctanComplex
#define fnArctan oracle_fnArctan

#define arcsinhReal oracle_arcsinhReal
#define arcsinhCplx oracle_arcsinhCplx
#define ArcsinhReal oracle_ArcsinhReal
#define ArcsinhComplex oracle_ArcsinhComplex
#define fnArcsinh oracle_fnArcsinh

#define arccoshCplx oracle_arccoshCplx
#define arccoshReal oracle_arccoshReal
#define realArcosh oracle_realArcosh
#define fnArccosh oracle_fnArccosh

#define arctanhCplx oracle_arctanhCplx
#define arctanhReal oracle_arctanhReal
#define fnArctanh oracle_fnArctanh

#include "../../../upstream/src/c47/mathematics/checkValue.c"
#include "../../../upstream/src/c47/mathematics/compare.c"
#include "../../../upstream/src/c47/mathematics/int.c"
#include "../../../upstream/src/c47/mathematics/idiv.c"
#include "../../../upstream/src/c47/mathematics/idivr.c"
#include "../../../upstream/src/c47/mathematics/round.c"
#include "../../../upstream/src/c47/mathematics/toPolar.c"
#include "../../../upstream/src/c47/mathematics/toRect.c"
#include "../../../upstream/src/c47/mathematics/squareRoot.c"
#include "../../../upstream/src/c47/mathematics/cubeRoot.c"
#include "../../../upstream/src/c47/mathematics/atan2.c"
#include "../../../upstream/src/c47/mathematics/conjugate.c"
#include "../../../upstream/src/c47/mathematics/swapRealImaginary.c"
#include "../../../upstream/src/c47/mathematics/unitVector.c"
#include "../../../upstream/src/c47/mathematics/arcsin.c"
#include "../../../upstream/src/c47/mathematics/arccos.c"
#include "../../../upstream/src/c47/mathematics/arctan.c"
#include "../../../upstream/src/c47/mathematics/arcsinh.c"
#include "../../../upstream/src/c47/mathematics/arccosh.c"
#include "../../../upstream/src/c47/mathematics/arctanh.c"

// The one function in this file that is not c43's own body. c43's fnToRect is
// static, so the harness cannot call it across a translation unit; this hands it
// its int8_t through the same truncation the Zig owner performs on the way in.
void oracleFnToRectEntry(uint16_t angleInY) {
  oracle_fnToRect_impl((int8_t)angleInY);
}
