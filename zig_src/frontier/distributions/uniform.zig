// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the (continuous and discrete) Uniform distribution commands,
// porting `src/c47/distributions/uniform.c`. The four fn* entry points each take
// a `discrete` flag (0 = continuous, non-zero = discrete) and are dispatched
// from the items.c function table via frontier.zig. All decNumber/register
// access goes through frontier_distribution_runtime. The testSuite has no
// Uniform dispatch entry, so these are verified by the distributions parity
// harness.

const dr = @import("../frontier_distribution_runtime.zig");
const real_t = dr.real_t;

// Reads X, low (REGISTER_M) and high (REGISTER_N); validates and, when
// requested, computes the range and the position of X relative to [low, high].
fn checkParamUniform(x: *real_t, low: *real_t, high: *real_t, range: ?*real_t, cmp: ?*c_int, discrete: u16) linksection(dr.code_section) bool {
    const ctx = &dr.ctxtReal39;
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, low) or !dr.getRegisterAsReal(dr.REGISTER_N, high)) {
        dr.specialResultNaN();
        return false;
    }
    if (dr.realIsSpecial(x) or dr.realIsSpecial(low) or dr.realIsSpecial(high)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamUniform:", "given non-number inputs", null, null);
        dr.specialResultNaN();
        return false;
    }
    if (discrete != 0) {
        if (!dr.isAnInteger(low)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_M);
            dr.moreInfoOnError("In function checkParamUniform:", "given non-integer lower limit", null, null);
            dr.specialResultNaN();
            return false;
        }
        if (!dr.isAnInteger(high)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_N);
            dr.moreInfoOnError("In function checkParamUniform:", "given non-integer upper limit", null, null);
            dr.specialResultNaN();
            return false;
        }
    }

    if (dr.realGreaterThan(low, high)) {
        const tmp = low.*;
        low.* = high.*;
        high.* = tmp;
    }
    if (range) |r| {
        dr.realSubtract(high, low, r, ctx);
        if (discrete != 0) {
            dr.realAdd(r, dr.const1(), r, ctx);
        }
    }
    if (cmp) |c| {
        c.* = if (dr.realLessThan(x, low)) @as(c_int, -1) else if (dr.realGreaterThan(x, high)) @as(c_int, 1) else @as(c_int, 0);
    }
    return true;
}

pub fn uniformP(discrete: u16) linksection(dr.code_section) void {
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var l: real_t = undefined;
    var h: real_t = undefined;
    var range: real_t = undefined;
    var cmp: c_int = undefined;
    var res: *const real_t = &x;

    if (checkParamUniform(&x, &l, &h, &range, &cmp, discrete)) {
        if (cmp == 0) {
            if (dr.realIsZero(&range)) {
                res = dr.const1();
            } else if (discrete != 0 and !dr.isAnInteger(&x)) {
                res = dr.const0();
            } else {
                dr.realDivide(dr.const1(), &range, &x, ctx);
            }
        } else {
            res = dr.const0();
        }
        dr.storeResult(res);
    }
}

pub fn uniformL(discrete: u16) linksection(dr.code_section) void {
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var low: real_t = undefined;
    var h: real_t = undefined;
    var range: real_t = undefined;
    var cmp: c_int = undefined;
    var res: *const real_t = &x;

    if (checkParamUniform(&x, &low, &h, &range, &cmp, discrete)) {
        if (cmp < 0) {
            res = dr.const0();
        } else if (cmp > 0 or dr.realIsZero(&range)) {
            res = dr.const1();
        } else {
            if (discrete != 0) {
                dr.toIntegralValue(&x, &h, dr.DEC_ROUND_FLOOR, ctx);
                dr.realAdd(&h, dr.const1(), &x, ctx);
            }
            dr.realSubtract(&x, &low, &h, ctx);
            dr.realDivide(&h, &range, &x, ctx);
        }
        dr.storeResult(res);
    }
}

pub fn uniformU(discrete: u16) linksection(dr.code_section) void {
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var l: real_t = undefined;
    var high: real_t = undefined;
    var range: real_t = undefined;
    var cmp: c_int = undefined;
    var res: *const real_t = &x;

    if (checkParamUniform(&x, &l, &high, &range, &cmp, discrete)) {
        if (cmp < 0 or dr.realIsZero(&range)) {
            res = dr.const1();
        } else if (cmp > 0) {
            res = dr.const0();
        } else {
            if (discrete != 0) {
                dr.toIntegralValue(&x, &l, dr.DEC_ROUND_CEILING, ctx);
                dr.realSubtract(&l, dr.const1(), &x, ctx);
            }
            dr.realSubtract(&high, &x, &l, ctx);
            dr.realDivide(&l, &range, &x, ctx);
        }
        dr.storeResult(res);
    }
}

pub fn uniformI(discrete: u16) linksection(dr.code_section) void {
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var low: real_t = undefined;
    var high: real_t = undefined;
    var t: real_t = undefined;

    if (checkParamUniform(&x, &low, &high, null, null, discrete)) {
        if (dr.realLessThan(&x, dr.const0()) or dr.realGreaterThan(&x, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnUniformI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        // Adjust an exact unity input to not go out of range.
        if (dr.realEqual(&x, dr.const1())) {
            dr.realCopy(&high, &x);
        } else {
            dr.realAdd(&high, dr.const1(), &high, ctx);
            dr.linearInterpolate(&low, &high, &x, &t);
            dr.toIntegralValue(&t, &x, dr.DEC_ROUND_FLOOR, ctx);
        }
        dr.storeResult(&x);
    }
}
