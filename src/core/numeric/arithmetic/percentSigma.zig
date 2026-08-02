// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_1 = consts.const_1;
//
// Zig owner for src/c47/mathematics/percentSigma.c: %Sigma = x/Sum(x)*100.
// Faithful line-by-line translation; covered by percentSigma.txt. The
// percentSigma() helper is exported with C linkage and is also called by the
// sibling owner percentSigmaDeltaPercentXmean.zig; the static
// percentSigmaReal helper is replicated as a private fn but, because
// elementwiseRema needs a C-callable function pointer, it is exported. fnPercentSigma
// is exported with C linkage. The EXTRA_INFO_ON_CALC_ERROR hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE/DMCP).
//
// statisticalSumsPointer is extern (real_t *). SIGMA_X = statisticalSumsPointer
// + SUM_X (SUM_X == 1), strided by sizeof(real_t) == 60 bytes, verified against
// defines.h. TI_PERC == 68 (real value; the runtime's TI_PERC is the fake one).

const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const FLAG_SPCRES = runtime.FLAG_SPCRES;
const amNone = runtime.amNone;
const dtReal34 = runtime.dtReal34;
const dtReal34Matrix = runtime.dtReal34Matrix;
const DECNEG = runtime.DECNEG;

const ERROR_NO_SUMMATION_DATA: u8 = 28;
const TI_PERC: u8 = 68;

const realIsZero = runtime.realIsZero;
const realIsNegative = runtime.realIsNegative;
const realDivide = runtime.realDivide;
const getSystemFlag = runtime.getSystemFlag;
const getRegisterAsReal = runtime.getRegisterAsReal;
const reallocateRegister = runtime.reallocateRegister;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const getRegisterDataType = runtime.getRegisterDataType;
const elementwiseRema = runtime.elementwiseRema;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

extern var ctxtReal39: realContext_t;

// realCopy / realSetPlusInfinity are not in runtime; extern the underlying C.
extern fn decNumberCopy(res: *real_t, source: *const real_t) *real_t;
inline fn realCopy(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
extern fn realSetPlusInfinity(r: *real_t) void;

// checkMinimumDataPoints / statisticalSumsPointer.
extern fn checkMinimumDataPoints(n: *const real_t) bool;
extern var statisticalSumsPointer: ?[*]real_t;

const SUM_X: usize = 1;
inline fn SIGMA_X() *real_t {
    return &statisticalSumsPointer.?[SUM_X];
}

// Blob constants.
const cstR = abi.constants.cstRAligned;

pub export fn percentSigma(xReal: *real_t, rReal: *real_t, realContext: *realContext_t) linksection(runtime.code_section) callconv(.c) bool {
    realCopy(SIGMA_X(), rReal); // r = Sum(x)
    if (realIsZero(rReal)) {
        if (getSystemFlag(FLAG_SPCRES)) {
            realSetPlusInfinity(rReal);
            rReal.bits |= DECNEG * @as(u8, @intFromBool(realIsNegative(rReal)));
        } else {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function percentSigma:", "cannot divide a real by 0", null, null);
            return false;
        }
    }

    realDivide(xReal, rReal, rReal, realContext); // r = x/Sum(x)
    rReal.exponent += 2; // r = x/Sum(x) * 100

    return true;
}

export fn percentSigmaReal() linksection(runtime.code_section) callconv(.c) void {
    var xReal: real_t = undefined;
    var rReal: real_t = undefined;

    if (!getRegisterAsReal(REGISTER_X, &xReal) or !percentSigma(&xReal, &rReal, &ctxtReal39)) {
        return;
    }

    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(&rReal, REGISTER_X);
}

pub export fn fnPercentSigma(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (!checkMinimumDataPoints(const_1())) {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnPercentSigma:", "There is no statistical data available!", null, null);
        return;
    }

    if (!saveLastX()) {
        return;
    }

    if (getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
        elementwiseRema(percentSigmaReal);
    } else {
        percentSigmaReal();
    }

    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
    runtime.temporaryInformation = TI_PERC;
}
