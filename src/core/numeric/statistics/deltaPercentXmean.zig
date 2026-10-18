// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_1 = consts.const_1;
//
// Zig owner for src/c47/mathematics/deltaPercentXmean.c: Delta% relative to the
// statistical mean: r = (n*x - Sum(x)) * 100 / Sum(x), formed as one fused
// multiply-add so the difference is exact before the single division rounds at
// the result context. UNCOVERED by the testSuite (no gate); this is a faithful
// line-by-line translation preserving the exact real_t operation order.
//
// deltaPercentXmeanReal() is exported with C linkage because
// percentSigmaDeltaPercentXmean.c (now also a Zig owner) calls it via the
// math_percentSigmaDeltaPercentXmean.zig owner. fnDeltaPercentXmean is
// the only .h-declared command. The EXTRA_INFO_ON_CALC_ERROR hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE/DMCP).
//
// statisticalSumsPointer is extern (real_t *): SIGMA_N = ptr[0], SIGMA_X =
// ptr[1], strided by sizeof(real_t)==60. Verified against defines.h SUM_N==0,
// SUM_X==1. FLAG_SPCRES==0x8017 (runtime value is correct here). TI_PERCD==69
// (real value); ERROR_NO_SUMMATION_DATA==28; const_1 blob offset 4368.

const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const FLAG_SPCRES = runtime.FLAG_SPCRES;
const amNone = runtime.amNone;

const ERROR_NO_SUMMATION_DATA: u8 = 28;
const TI_PERCD: u8 = 69;

const realIsZero = runtime.realIsZero;
const getSystemFlag = runtime.getSystemFlag;
const realSetZero = runtime.realSetZero;
const getRegisterAsReal = runtime.getRegisterAsReal;
const setRegisterTag = runtime.setRegisterTag;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;

extern fn checkMinimumDataPoints(n: *const real_t) bool;
extern var statisticalSumsPointer: ?[*]real_t;

const SUM_N: usize = 0;
const SUM_X: usize = 1;
inline fn SIGMA_N() *real_t {
    return &statisticalSumsPointer.?[SUM_N];
}
inline fn SIGMA_X() *real_t {
    return &statisticalSumsPointer.?[SUM_X];
}

const realDivide = runtime.realDivide;

// Blob constants.
const cstR = abi.constants.cstRAligned;

pub export fn deltaPercentXmeanReal(xReal: *real_t, rReal: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) bool {
    var negativeSum: real_t = undefined;

    // Check x and y
    if (realIsZero(xReal) and realIsZero(SIGMA_X()) and !getSystemFlag(FLAG_SPCRES)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnError("In function deltaPercentXmeanReal:", "cannot divide 0 by 0", null, null);
        return false;
    } else if (realIsZero(SIGMA_X()) and !getSystemFlag(FLAG_SPCRES)) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        moreInfoOnError("In function deltaPercentXmeanReal:", "cannot divide a real by y=0", null, null);
        return false;
    } else {
        negativeSum = SIGMA_X().*;
        runtime.realChangeSign(&negativeSum);
        runtime.realFMA(SIGMA_N(), xReal, &negativeSum, rReal, &ctxtReal39); // r = n*x - Sum(x)
        rReal.exponent += 2; // r = (n*x - Sum(x)) * 100
        realDivide(rReal, SIGMA_X(), rReal, realContext); // r = (n*x - Sum(x)) * 100 / Sum(x)
    }
    return true;
}

pub export fn fnDeltaPercentXmean(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var xReal: real_t = undefined;
    var rReal: real_t = undefined;

    if (!checkMinimumDataPoints(const_1())) {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE);
        moreInfoOnError("In function fnDeltaPercentXmean:", "There is no statistical data available!", null, null);
        return;
    }

    if (!getRegisterAsReal(REGISTER_X, &xReal)) {
        return;
    }

    if (!saveLastX()) {
        return;
    }

    realSetZero(&rReal);
    if (deltaPercentXmeanReal(&xReal, &rReal, &ctxtReal34)) {
        runtime.convertRealToResultRegister(&rReal, REGISTER_X, amNone);
        setRegisterTag(REGISTER_X, @intCast(amNone)); // setRegisterAngularMode(REGISTER_X, amNone)
    }

    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);

    runtime.temporaryInformation = TI_PERCD;
}
