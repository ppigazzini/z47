// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const_1 = consts.const_1;
//
// Zig owner for src/c47/mathematics/mean.c: arithmetic / geometric / harmonic /
// RMS / weighted means. UNCOVERED by the testSuite (no gate); this is a faithful
// line-by-line translation preserving the exact real_t operation order. The
// static calculateMean / geometricMeanTransform / RMSMeanTransform helpers stay
// private; fnMeanXY/fnMeanX/fnGeometricMeanXY/fnHarmonicMeanXY/fnRMSMeanXY/
// fnWeightedMeanX are exported with C linkage. The EXTRA_INFO_ON_CALC_ERROR
// hints become fixed moreInfoOnError strings (no-op under TESTSUITE/DMCP).
//
// Statistical-sum register accessors (statisticalSumsPointer is real_t *):
//   SIGMA_N = ptr[0], SIGMA_X = ptr[1], SIGMA_Y = ptr[2], SIGMA_X2 = ptr[3],
//   SIGMA_Y2 = ptr[5], SIGMA_XY = ptr[6], SIGMA_lnX = ptr[8], SIGMA_lnY = ptr[11],
//   SIGMA_1onX = ptr[17], SIGMA_1onY = ptr[20]; strided by sizeof(real_t)==60.
//   Indices verified against defines.h SUM_* (N=0,X=1,Y=2,X2=3,Y2=5,XY=6,
//   lnX=8,lnY=11,1onX=17,1onY=20).
// Real ops used: realDivide, realExp, realSquareRoot (all &ctxtReal39),
//   realCompareLessThan, convertRealToReal34ResultRegister.
// FLAG_ASLIFT == 0xc023 (real value; runtime's 0x8019 is stale).
// TI_* values are the real defines.h values.

const runtime = @import("../command_wrappers/runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;

const FLAG_ASLIFT: i32 = 0xc023;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_TOO_FEW_DATA: u8 = 15;

const TI_MEANX_MEANY: u8 = 17;
const TI_MEANX: u8 = 18;
const TI_GEOMMEANX_GEOMMEANY: u8 = 19;
const TI_WEIGHTEDMEANX: u8 = 20;
const TI_HARMMEANX_HARMMEANY: u8 = 21;
const TI_RMSMEANX_RMSMEANY: u8 = 22;

const realDivide = runtime.realDivide;
const realSquareRoot = runtime.realSquareRoot;
const realCompareLessThan = runtime.realCompareLessThan;
const liftStack = runtime.liftStack;
const setSystemFlag = runtime.setSystemFlag;
const convertRealToReal34ResultRegister = runtime.convertRealToReal34ResultRegister;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

extern var ctxtReal39: realContext_t;

extern fn checkMinimumDataPoints(n: *const real_t) bool;
extern var statisticalSumsPointer: ?[*]real_t;

const IDX_SIGMA_N: usize = 0;
const IDX_SIGMA_X: usize = 1;
const IDX_SIGMA_Y: usize = 2;
const IDX_SIGMA_X2: usize = 3;
const IDX_SIGMA_Y2: usize = 5;
const IDX_SIGMA_lnX: usize = 8;
const IDX_SIGMA_lnY: usize = 11;
const IDX_SIGMA_1onX: usize = 17;
const IDX_SIGMA_1onY: usize = 20;

inline fn sigma(index: usize) *real_t {
    return &statisticalSumsPointer.?[index];
}
inline fn SIGMA_Y() *real_t {
    return sigma(IDX_SIGMA_Y);
}
inline fn SIGMA_XY() *real_t {
    return sigma(6);
}

// Blob constants.
const cstR = abi.constants.cstRAligned;

const TransformFn = ?*const fn (operand: *const real_t, result: *real_t) callconv(.c) void;

// The sums are named by index rather than by pointer so that nothing reaches into
// statisticalSumsPointer before checkMinimumDataPoints has established there is
// summation data at all. The C passes address-of macros, which compute an address
// without loading through it; resolving indices after the guard is the same order.
fn calculateMean(displayInfo: u8, sumX: usize, numberX: usize, sumY: ?usize, numberY: ?usize, transform: TransformFn) linksection(runtime.code_section) void {
    if (checkMinimumDataPoints(const_1())) {
        var tempReal1: real_t = undefined;
        var tempReal2: real_t = undefined;

        liftStack();

        if (sumY != null) {
            setSystemFlag(FLAG_ASLIFT);
            liftStack();
        }

        realDivide(sigma(sumX), sigma(numberX), &tempReal1, &ctxtReal39);
        if (transform != null) {
            transform.?(&tempReal1, &tempReal2);
        }
        const mean: *real_t = if (transform == null) &tempReal1 else &tempReal2;
        convertRealToReal34ResultRegister(mean, REGISTER_X);

        if (sumY != null) {
            realDivide(sigma(sumY.?), sigma(numberY.?), &tempReal1, &ctxtReal39);
            if (transform != null) {
                transform.?(&tempReal1, &tempReal2);
            }
            convertRealToReal34ResultRegister(mean, REGISTER_Y);
        }

        runtime.temporaryInformation = displayInfo;
    }
}

pub export fn fnMeanXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateMean(TI_MEANX_MEANY, IDX_SIGMA_X, IDX_SIGMA_N, IDX_SIGMA_Y, IDX_SIGMA_N, null);
}

pub export fn fnMeanX(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateMean(TI_MEANX, IDX_SIGMA_X, IDX_SIGMA_N, null, null, null);
}

fn geometricMeanTransform(operand: *const real_t, result: *real_t) linksection(runtime.code_section) callconv(.c) void {
    math_command_wrappers.realExp(operand, result, &ctxtReal39);
}

pub export fn fnGeometricMeanXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateMean(TI_GEOMMEANX_GEOMMEANY, IDX_SIGMA_lnX, IDX_SIGMA_N, IDX_SIGMA_lnY, IDX_SIGMA_N, &geometricMeanTransform);
}

pub export fn fnHarmonicMeanXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateMean(TI_HARMMEANX_HARMMEANY, IDX_SIGMA_N, IDX_SIGMA_1onX, IDX_SIGMA_N, IDX_SIGMA_1onY, null);
}

fn RMSMeanTransform(operand: *const real_t, result: *real_t) linksection(runtime.code_section) callconv(.c) void {
    realSquareRoot(operand, result, &ctxtReal39);
}

pub export fn fnRMSMeanXY(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calculateMean(TI_RMSMEANX_RMSMEANY, IDX_SIGMA_X2, IDX_SIGMA_N, IDX_SIGMA_Y2, IDX_SIGMA_N, &RMSMeanTransform);
}

pub export fn fnWeightedMeanX(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var mean: real_t = undefined;

    if (statisticalSumsPointer == null) {
        displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnWeightedMeanX:", "There is no statistical data available!", null, null);
    } else if (realCompareLessThan(SIGMA_Y(), const_1())) {
        displayCalcErrorMessage(ERROR_TOO_FEW_DATA, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnWeightedMeanX:", "There is insufficient statistical data available!", null, null);
    } else {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);

        realDivide(SIGMA_XY(), SIGMA_Y(), &mean, &ctxtReal39);
        convertRealToReal34ResultRegister(&mean, REGISTER_X);

        runtime.temporaryInformation = TI_WEIGHTEDMEANX;
    }
}
