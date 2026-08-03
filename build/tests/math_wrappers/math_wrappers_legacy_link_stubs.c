// SPDX-License-Identifier: GPL-3.0-only

#include <stdint.h>
#include <string.h>

// addition.c (addStriReal/addStriCplx) trims a leading space from its result.
// Faithful definition (master uses stringByteLength/xcopy; memmove/strlen are
// equivalent here) so the oracle matches the Zig port if that path is hit.
void trimLeadingSpace(char *stringToTrim) {
    if (stringToTrim[0] == ' ') {
        memmove(stringToTrim, stringToTrim + 1, strlen(stringToTrim));
    }
}

void z47_math_wrappers_legacy_fnAdd(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnSubtract(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnMultiply(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDivide(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnIDiv(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnIDivR(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDblMultiply(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDblDivide(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDblDivideRemainder(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnRound(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDecomp(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckInteger(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDec(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnInc(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnXLessThan(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnXLessEqual(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnXGreaterThan(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnXGreaterEqual(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnXEqualsTo(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnXNotEqual(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnXAlmostEqual(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnIsConverged(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckType(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckReal(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckNumber(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckAngle(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckMatrix(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckMatrixSquare(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckForZero(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckIsVect2d(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckIsVect3d(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckNaN(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckInfinite(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckSpecial(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckPlusZero(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCheckMinusZero(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnGetType(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnPercentMRR(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnPercentPlusMG(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnPercentT(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDeltaPercent(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnFib(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnLINPOL(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnCross(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnDot(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }
void z47_math_wrappers_legacy_fnLogXY(uint16_t unusedButMandatoryParameter) { (void)unusedButMandatoryParameter; }

// get_type.zig forms its result in decQuad, reading const34_1000 out of the
// generated constant blob, exactly as checkValue.c does. This lane links neither
// decNumber nor the blob, so both symbols are filled in here.
//
// Nothing in this lane calls them: fnGetType is compared in the full-core
// math-wrapper differential, where the real decQuad and the real blob are
// present. A stub that is reached would silently answer 0; if a case is ever
// added here that reaches one, it will read this comment first.
uint8_t constants[1];

void *decQuadFromUInt32(void *res, uint32_t value) {
    (void)value;
    return res;
}
