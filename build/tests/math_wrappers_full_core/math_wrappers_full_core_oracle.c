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


// --- the circular and hyperbolic families (6 files) ---
#define sinComplex oracle_sinComplex
#define sinCosReal oracle_sinCosReal
#define sinCosCplx oracle_sinCosCplx
#define sinReal oracle_sinReal
#define sinCplx oracle_sinCplx
#define fnSin oracle_fnSin

#define cosComplex oracle_cosComplex
#define cosReal oracle_cosReal
#define cosCplx oracle_cosCplx
#define fnCos oracle_fnCos

#define tanReal oracle_tanReal
#define tanCplx oracle_tanCplx
#define TanComplex oracle_TanComplex
#define fnTan oracle_fnTan

#define sinhCoshReal oracle_sinhCoshReal
#define sinhCoshCplx oracle_sinhCoshCplx
#define sinhReal oracle_sinhReal
#define sinhCplx oracle_sinhCplx
#define fnSinh oracle_fnSinh

#define coshReal oracle_coshReal
#define coshCplx oracle_coshCplx
#define fnCosh oracle_fnCosh

#define tanhReal oracle_tanhReal
#define tanhCplx oracle_tanhCplx
#define TanhComplex oracle_TanhComplex
#define fnTanh oracle_fnTanh


// --- the logarithmic and exponential families (6 files) ---
#define lnComplex oracle_lnComplex
#define lnReal oracle_lnReal
#define lnCplx oracle_lnCplx
#define fnLn oracle_fnLn
#define lnP1Complex oracle_lnP1Complex
#define lnP1Real oracle_lnP1Real
#define lnP1Cplx oracle_lnP1Cplx
#define fnLnP1 oracle_fnLnP1
#define realLog10 oracle_realLog10
#define logxyReal oracle_logxyReal
#define logxyCplx oracle_logxyCplx
#define logxyLonI oracle_logxyLonI
#define log10LonI oracle_log10LonI
#define log10ShoI oracle_log10ShoI
#define log10Real oracle_log10Real
#define log10Cplx oracle_log10Cplx
#define fnLog10 oracle_fnLog10
#define log2LonI oracle_log2LonI
#define log2ShoI oracle_log2ShoI
#define log2Real oracle_log2Real
#define log2Cplx oracle_log2Cplx
#define fnLog2 oracle_fnLog2
#define realExpLimitCheck oracle_realExpLimitCheck
#define realExp oracle_realExp
#define expComplex oracle_expComplex
#define expReal oracle_expReal
#define expCplx oracle_expCplx
#define fnExp oracle_fnExp
#define expM1Complex oracle_expM1Complex
#define realExpM1 oracle_realExpM1
#define expM1Real oracle_expM1Real
#define expM1Cplx oracle_expM1Cplx
#define fnExpM1 oracle_fnExpM1


// --- the four arithmetic dispatchers (4 files, 4 STATE tables) ---
// The largest dispatch tables in the tree: every wrapper above leans on these, and
// none of them had a result-level comparison anywhere. They are added AFTER the
// fixture set gained its sign partition, because they dispatch on the types of two
// operands and then compute with them -- driving them over an all-positive shape
// table would have repeated the mistake with the four highest-traffic wrappers in
// the port.
#define addition oracle_addition              // dispatch table, not a function
#define subtraction oracle_subtraction        // dispatch table, not a function
#define multiplication oracle_multiplication  // dispatch table, not a function
#define division oracle_division              // dispatch table, not a function
// --- addition.c ---
#define fnAdd oracle_fnAdd
#define addRegYStri oracle_addRegYStri
#define addLonILonI oracle_addLonILonI
#define addLonITime oracle_addLonITime
#define addTimeLonI oracle_addTimeLonI
#define addLonIDate oracle_addLonIDate
#define addDateLonI oracle_addDateLonI
#define addLonIShoI oracle_addLonIShoI
#define addShoILonI oracle_addShoILonI
#define addLonIReal oracle_addLonIReal
#define addRealLonI oracle_addRealLonI
#define addLonICplx oracle_addLonICplx
#define addCplxLonI oracle_addCplxLonI
#define addTimeTime oracle_addTimeTime
#define addTimeReal oracle_addTimeReal
#define addRealTime oracle_addRealTime
#define addDateReal oracle_addDateReal
#define addRealDate oracle_addRealDate
#define _addString oracle__addString
#define addStriLonI oracle_addStriLonI
#define addStriTime oracle_addStriTime
#define addStriDate oracle_addStriDate
#define addStriStri oracle_addStriStri
#define addStriRema oracle_addStriRema
#define addStriCxma oracle_addStriCxma
#define addStriShoI oracle_addStriShoI
#define addStriReal oracle_addStriReal
#define addStriCplx oracle_addStriCplx
#define addRemaLonI oracle_addRemaLonI
#define addLonIRema oracle_addLonIRema
#define addRemaRema oracle_addRemaRema
#define addRemaCxma oracle_addRemaCxma
#define addCxmaRema oracle_addCxmaRema
#define addRemaShoI oracle_addRemaShoI
#define addShoIRema oracle_addShoIRema
#define addRemaReal oracle_addRemaReal
#define addRealRema oracle_addRealRema
#define addRemaCplx oracle_addRemaCplx
#define addCplxRema oracle_addCplxRema
#define addCxmaLonI oracle_addCxmaLonI
#define addLonICxma oracle_addLonICxma
#define addCxmaCxma oracle_addCxmaCxma
#define addCxmaShoI oracle_addCxmaShoI
#define addShoICxma oracle_addShoICxma
#define addCxmaReal oracle_addCxmaReal
#define addRealCxma oracle_addRealCxma
#define addCxmaCplx oracle_addCxmaCplx
#define addCplxCxma oracle_addCplxCxma
#define addShoIShoI oracle_addShoIShoI
#define addShoIReal oracle_addShoIReal
#define addRealShoI oracle_addRealShoI
#define addShoICplx oracle_addShoICplx
#define addCplxShoI oracle_addCplxShoI
#define addRealReal oracle_addRealReal
#define addRealCplx oracle_addRealCplx
#define addCplxReal oracle_addCplxReal
#define addComplex oracle_addComplex
#define addCplxCplx oracle_addCplxCplx
// --- subtraction.c ---
#define fnSubtract oracle_fnSubtract
#define subLonILonI oracle_subLonILonI
#define subLonITime oracle_subLonITime
#define subTimeLonI oracle_subTimeLonI
#define subDateLonI oracle_subDateLonI
#define subLonIShoI oracle_subLonIShoI
#define subShoILonI oracle_subShoILonI
#define subLonIReal oracle_subLonIReal
#define subRealLonI oracle_subRealLonI
#define subLonICplx oracle_subLonICplx
#define subCplxLonI oracle_subCplxLonI
#define subTimeTime oracle_subTimeTime
#define subTimeReal oracle_subTimeReal
#define subRealTime oracle_subRealTime
#define subDateDate oracle_subDateDate
#define subDateReal oracle_subDateReal
#define subRemaLonI oracle_subRemaLonI
#define subLonIRema oracle_subLonIRema
#define subRemaRema oracle_subRemaRema
#define subRemaCxma oracle_subRemaCxma
#define subCxmaRema oracle_subCxmaRema
#define subRemaShoI oracle_subRemaShoI
#define subShoIRema oracle_subShoIRema
#define subRemaReal oracle_subRemaReal
#define subRealRema oracle_subRealRema
#define subRemaCplx oracle_subRemaCplx
#define subCplxRema oracle_subCplxRema
#define subCxmaLonI oracle_subCxmaLonI
#define subLonICxma oracle_subLonICxma
#define subCxmaCxma oracle_subCxmaCxma
#define subCxmaShoI oracle_subCxmaShoI
#define subShoICxma oracle_subShoICxma
#define subCxmaReal oracle_subCxmaReal
#define subRealCxma oracle_subRealCxma
#define subCxmaCplx oracle_subCxmaCplx
#define subCplxCxma oracle_subCplxCxma
#define subShoIShoI oracle_subShoIShoI
#define subShoIReal oracle_subShoIReal
#define subRealShoI oracle_subRealShoI
#define subShoICplx oracle_subShoICplx
#define subCplxShoI oracle_subCplxShoI
#define subRealReal oracle_subRealReal
#define subRealCplx oracle_subRealCplx
#define subCplxReal oracle_subCplxReal
#define subComplex oracle_subComplex
#define subCplxCplx oracle_subCplxCplx
// --- multiplication.c ---
#define fnMultiply oracle_fnMultiply
#define mulComplexi oracle_mulComplexi
#define mulComplexComplex75 oracle_mulComplexComplex75
#define mulComplexComplex159 oracle_mulComplexComplex159
#define mulComplexComplex oracle_mulComplexComplex
#define mulComplexReal oracle_mulComplexReal
#define mulLonILonI oracle_mulLonILonI
#define mulLonITime oracle_mulLonITime
#define mulTimeLonI oracle_mulTimeLonI
#define mulLonIRema oracle_mulLonIRema
#define mulRemaLonI oracle_mulRemaLonI
#define mulLonICxma oracle_mulLonICxma
#define mulCxmaLonI oracle_mulCxmaLonI
#define mulLonIShoI oracle_mulLonIShoI
#define mulShoILonI oracle_mulShoILonI
#define mulLonIReal oracle_mulLonIReal
#define mulRealLonI oracle_mulRealLonI
#define mulLonICplx oracle_mulLonICplx
#define mulCplxLonI oracle_mulCplxLonI
#define mulTimeShoI oracle_mulTimeShoI
#define mulShoITime oracle_mulShoITime
#define mulTimeReal oracle_mulTimeReal
#define mulRealTime oracle_mulRealTime
#define mulRemaRema oracle_mulRemaRema
#define mulRemaCxma oracle_mulRemaCxma
#define mulCxmaRema oracle_mulCxmaRema
#define mulRemaShoI oracle_mulRemaShoI
#define mulShoIRema oracle_mulShoIRema
#define mulRemaReal oracle_mulRemaReal
#define mulRealRema oracle_mulRealRema
#define mulRemaCplx oracle_mulRemaCplx
#define mulCplxRema oracle_mulCplxRema
#define mulCxmaCxma oracle_mulCxmaCxma
#define mulCxmaShoI oracle_mulCxmaShoI
#define mulShoICxma oracle_mulShoICxma
#define mulCxmaReal oracle_mulCxmaReal
#define mulRealCxma oracle_mulRealCxma
#define mulCxmaCplx oracle_mulCxmaCplx
#define mulCplxCxma oracle_mulCplxCxma
#define mulShoIShoI oracle_mulShoIShoI
#define mulShoIReal oracle_mulShoIReal
#define mulRealShoI oracle_mulRealShoI
#define mulShoICplx oracle_mulShoICplx
#define mulCplxShoI oracle_mulCplxShoI
#define mulRealReal oracle_mulRealReal
#define mulRealCplx oracle_mulRealCplx
#define mulCplxReal oracle_mulCplxReal
#define mulCplxCplx oracle_mulCplxCplx
// --- division.c ---
#define fnDivide oracle_fnDivide
#define divComplexComplex75 oracle_divComplexComplex75
#define divComplexComplex159 oracle_divComplexComplex159
#define divComplexComplex oracle_divComplexComplex
#define divRealComplex oracle_divRealComplex
#define divComplexReal oracle_divComplexReal
#define divLonILonI oracle_divLonILonI
#define divLonIShoI oracle_divLonIShoI
#define divShoILonI oracle_divShoILonI
#define divLonIReal oracle_divLonIReal
#define divRealLonI oracle_divRealLonI
#define divLonICplx oracle_divLonICplx
#define divCplxLonI oracle_divCplxLonI
#define divTimeLonI oracle_divTimeLonI
#define divLonITime oracle_divLonITime
#define divTimeShoI oracle_divTimeShoI
#define divShoITime oracle_divShoITime
#define divTimeReal oracle_divTimeReal
#define divRealTime oracle_divRealTime
#define divTimeTime oracle_divTimeTime
#define divRemaLonI oracle_divRemaLonI
#define divLonIRema oracle_divLonIRema
#define divRemaRema oracle_divRemaRema
#define divRemaCxma oracle_divRemaCxma
#define divRemaShoI oracle_divRemaShoI
#define divShoIRema oracle_divShoIRema
#define divRemaReal oracle_divRemaReal
#define divRealRema oracle_divRealRema
#define divRemaCplx oracle_divRemaCplx
#define divCplxRema oracle_divCplxRema
#define divCxmaLonI oracle_divCxmaLonI
#define divLonICxma oracle_divLonICxma
#define divCxmaRema oracle_divCxmaRema
#define divCxmaCxma oracle_divCxmaCxma
#define divCxmaShoI oracle_divCxmaShoI
#define divShoICxma oracle_divShoICxma
#define divCxmaReal oracle_divCxmaReal
#define divRealCxma oracle_divRealCxma
#define divCxmaCplx oracle_divCxmaCplx
#define divCplxCxma oracle_divCplxCxma
#define divShoIShoI oracle_divShoIShoI
#define divShoIReal oracle_divShoIReal
#define divRealShoI oracle_divRealShoI
#define divShoICplx oracle_divShoICplx
#define divCplxShoI oracle_divCplxShoI
#define divRealReal oracle_divRealReal
#define divRealCplx oracle_divRealCplx
#define divCplxReal oracle_divCplxReal
#define divCplxCplx oracle_divCplxCplx

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
#include "../../../upstream/src/c47/mathematics/sin.c"
#include "../../../upstream/src/c47/mathematics/cos.c"
#include "../../../upstream/src/c47/mathematics/tan.c"
#include "../../../upstream/src/c47/mathematics/sinh.c"
#include "../../../upstream/src/c47/mathematics/cosh.c"
#include "../../../upstream/src/c47/mathematics/tanh.c"
#include "../../../upstream/src/c47/mathematics/ln.c"
#include "../../../upstream/src/c47/mathematics/lnPOne.c"
#include "../../../upstream/src/c47/mathematics/log10.c"
#include "../../../upstream/src/c47/mathematics/log2.c"
#include "../../../upstream/src/c47/mathematics/exp.c"
#include "../../../upstream/src/c47/mathematics/expMOne.c"
#include "../../../upstream/src/c47/mathematics/addition.c"
#include "../../../upstream/src/c47/mathematics/subtraction.c"
#include "../../../upstream/src/c47/mathematics/multiplication.c"
#include "../../../upstream/src/c47/mathematics/division.c"

// The one function in this file that is not c43's own body. c43's fnToRect is
// static, so the harness cannot call it across a translation unit; this hands it
// its int8_t through the same truncation the Zig owner performs on the way in.
void oracleFnToRectEntry(uint16_t angleInY) {
  oracle_fnToRect_impl((int8_t)angleInY);
}
