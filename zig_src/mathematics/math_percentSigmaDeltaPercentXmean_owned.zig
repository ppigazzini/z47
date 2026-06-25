// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/percentSigmaDeltaPercentXmean.c:
// combined command putting %Sigma(x) in Y and Delta%(x vs mean) in X.
// UNCOVERED by the testSuite (no gate); faithful line-by-line translation
// preserving the exact real_t operation order.
//
// percentSigma() is the committed Zig owner (math_percentSigma_owned.zig);
// deltaPercentXmeanReal() is the sibling Zig owner
// (math_deltaPercentXmean_owned.zig). Both are exported with C linkage, so
// they are extern'd here exactly as the C called them. fnPcSigmaDeltaPcXmean
// is the only .h-declared command. The EXTRA_INFO_ON_CALC_ERROR hint becomes
// a fixed moreInfoOnError string (no-op under TESTSUITE/DMCP).
//
// ERROR_NO_SUMMATION_DATA==28; TI_PERCD2==70 (real value); const_1 blob
// offset 4368.

const runtime = @import("math_command_wrappers_runtime.zig");

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_L = runtime.REGISTER_L;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const amNone = runtime.amNone;
const dtReal34 = runtime.dtReal34;

const ERROR_NO_SUMMATION_DATA: u8 = 28;
const TI_PERCD2: u8 = 70;

const getRegisterAsReal = runtime.getRegisterAsReal;
const reallocateRegister = runtime.reallocateRegister;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const liftStack = runtime.liftStack;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

extern var ctxtReal75: realContext_t;

extern fn checkMinimumDataPoints(n: *const real_t) bool;

// Sibling Zig owners, exported with C linkage.
extern fn percentSigma(xReal: *real_t, rReal: *real_t, realContext: *realContext_t) bool;
extern fn deltaPercentXmeanReal(xReal: *real_t, rReal: *real_t, realContext: *realContext_t) bool;

// Blob constants.
const constants = @extern([*]align(4) const u8, .{ .name = "constants" });
inline fn cstR(comptime off: u32) *const real_t {
    return @ptrCast(@alignCast(constants + off));
}
const OFF_const_1: u32 = 4856;
inline fn const_1() *const real_t {
    return cstR(OFF_const_1);
}

pub export fn fnPcSigmaDeltaPcXmean(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var xReal: real_t = undefined;
    var rReal: real_t = undefined;

    if (!checkMinimumDataPoints(const_1())) {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnPcSigmaDeltaPcXmean:", "There is no statistical data available!", null, null);
        return;
    }

    if (!getRegisterAsReal(REGISTER_X, &xReal)) {
        return;
    }

    if (!saveLastX()) {
        return;
    }

    liftStack();

    if (percentSigma(&xReal, &rReal, &ctxtReal75)) {
        reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&rReal, REGISTER_Y);
    }

    if (deltaPercentXmeanReal(&xReal, &rReal, &ctxtReal75)) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    }

    adjustResult(REGISTER_X, false, true, REGISTER_L, -1, -1);
    adjustResult(REGISTER_Y, false, true, REGISTER_L, -1, -1);

    runtime.temporaryInformation = TI_PERCD2;
}
