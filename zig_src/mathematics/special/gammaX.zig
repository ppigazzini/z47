// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/gammaX.c: the GAMMAxy command (incomplete
// gamma, lower/upper, optionally regularised — selected by the gammaType
// parameter). Faithful line-by-line translation preserving the exact order of
// every real_t operation (gammaXyLower.txt / gammaXyUpper.txt check results to
// the last ULP). Exports fnGammaX with C linkage. The EXTRA_INFO_ON_CALC_ERROR
// sprintf hint becomes a fixed moreInfoOnError string (no-op under TESTSUITE/
// DMCP).

const runtime = @import("../math_command_wrappers_runtime.zig");
const math_comparison_reals = @import("../math_comparison_reals.zig"); // M-callconv: Zig-to-Zig
const math_wp34s = @import("wp34s.zig"); // M-callconv: Zig-to-Zig

const real_t = runtime.real_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;

const FLAG_SPCRES: i32 = 0x8017;

// const_0 has a runtime accessor.
inline fn const_0() *const real_t {
    return runtime.z47_math_wrappers_const_0();
}

// WP34S_GammaP from the wp34s owner.

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

pub export fn fnGammaX(gammaType: u16) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var res: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y) or !runtime.saveLastX()) {
        return;
    }

    if (!runtime.getSystemFlag(FLAG_SPCRES) and (math_comparison_reals.realCompareLessEqual(&x, const_0()) or math_comparison_reals.realCompareLessThan(&y, const_0()))) {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function fnGammaX:", "Y must be non-negative and X must be positive", null, null);
    } else {
        math_wp34s.WP34S_GammaP(&y, &x, &res, &runtime.ctxtReal39, (gammaType >> 1) != 0, (gammaType & 0x0001) != 0);
        runtime.convertRealToResultRegister(&res, REGISTER_X, amNone);
    }

    runtime.adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
}
