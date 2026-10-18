// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/uniform.c: the continuous and discrete
// uniform distribution commands. The parameter selects the discrete form. The
// entry points load register X and the limits in M and N through
// WP34S_CheckDistributionParameters, whose domain rule also orders the limits,
// and keep their own bodies since the uniform has no row in the descriptor
// table. Tagged linksection(dr.code_section) so the code runs from QSPI on the
// flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;

// uniformCheckDomain: finite limits, integers for the discrete form and distinct
// for the continuous one; a reversed pair is swapped into order.
fn checkDomain(registers_valid: bool, x: *real_t, low: ?*real_t, high: ?*real_t, third: ?*real_t, discrete: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = third;
    if (!registers_valid) {
        return false;
    }
    const l = low.?;
    const h = high.?;

    if (dr.realIsNaN(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function uniformCheckDomain:", "given NaN argument", null, null);
        return false;
    }
    if (dr.realIsSpecial(l) or dr.realIsSpecial(h)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function uniformCheckDomain:", "given non-finite limits", null, null);
        return false;
    }
    if (discrete != 0) {
        if (!dr.isAnInteger(l)) {
            dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function uniformCheckDomain:", "given non-integer lower limit", null, null);
            return false;
        }
        if (!dr.isAnInteger(h)) {
            dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function uniformCheckDomain:", "given non-integer upper limit", null, null);
            return false;
        }
    }

    if (dr.realGreaterThan(l, h)) {
        var t: real_t = undefined;
        dr.realCopy(l, &t);
        dr.realCopy(h, l);
        dr.realCopy(&t, h);
    }
    if (discrete == 0 and dr.realEqual(l, h)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function uniformCheckDomain:", "equal continuous limits", null, null);
        return false;
    }
    return true;
}

// The registers, the width of the support (counting both ends when discrete)
// and where x sits relative to it: -1 below, 0 inside, 1 above.
fn uniformParameters(x: *real_t, low: *real_t, high: *real_t, range: ?*real_t, cmp: ?*i32, discrete: u16) linksection(dr.code_section) bool {
    if (!dr.WP34S_CheckDistributionParameters(x, dr.REGISTER_M, low, dr.REGISTER_N, high, 0, null, discrete, checkDomain)) {
        return false;
    }
    if (range) |r| {
        dr.realSubtract(high, low, r, &dr.ctxtReal39);
        if (discrete != 0) {
            dr.realAdd(r, dr.const1(), r, &dr.ctxtReal39);
        }
    }
    if (cmp) |c| {
        c.* = if (dr.realLessThan(x, low)) -1 else if (dr.realGreaterThan(x, high)) 1 else 0;
    }
    return true;
}

pub fn uniformP(discrete: u16) linksection(dr.code_section) void {
    var x: real_t = undefined;
    var l: real_t = undefined;
    var h: real_t = undefined;
    var range: real_t = undefined;
    var res: *const real_t = &x;
    var cmp: i32 = undefined;

    if (uniformParameters(&x, &l, &h, &range, &cmp, discrete)) {
        if (cmp == 0) {
            if (dr.realIsZero(&range)) {
                res = dr.const1();
            } else if (discrete != 0 and !dr.isAnInteger(&x)) {
                res = dr.const0();
            } else {
                dr.realDivide(dr.const1(), &range, &x, &dr.ctxtReal39);
            }
        } else {
            res = dr.const0();
        }
        dr.convertRealToResultRegister(res, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn uniformL(discrete: u16) linksection(dr.code_section) void {
    var x: real_t = undefined;
    var low: real_t = undefined;
    var h: real_t = undefined;
    var range: real_t = undefined;
    var res: *const real_t = &x;
    var cmp: i32 = undefined;

    if (uniformParameters(&x, &low, &h, &range, &cmp, discrete)) {
        if (cmp < 0) {
            res = dr.const0();
        } else if (cmp > 0 or dr.realIsZero(&range)) {
            res = dr.const1();
        } else {
            const interior = dr.realLessThan(&x, &h);
            if (discrete != 0) {
                dr.toIntegralValue(&x, &h, dr.DEC_ROUND_FLOOR, &dr.ctxtReal39);
                dr.realSubtract(&h, &low, &h, &dr.ctxtReal39);
                dr.realAdd(&h, dr.const1(), &h, &dr.ctxtReal39);
            } else {
                dr.realSubtract(&x, &low, &h, &dr.ctxtReal39);
            }
            dr.realDivide(&h, &range, &x, &dr.ctxtReal39);
            if (interior and dr.realEqual(&x, dr.const1())) {
                dr.realNextToward(&x, dr.const0(), &x, &dr.ctxtReal39);
            }
        }
        dr.convertRealToResultRegister(res, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn uniformU(discrete: u16) linksection(dr.code_section) void {
    var x: real_t = undefined;
    var l: real_t = undefined;
    var high: real_t = undefined;
    var range: real_t = undefined;
    var res: *const real_t = &x;
    var cmp: i32 = undefined;

    if (uniformParameters(&x, &l, &high, &range, &cmp, discrete)) {
        if (cmp < 0 or dr.realIsZero(&range)) {
            res = dr.const1();
        } else if (cmp > 0) {
            res = dr.const0();
        } else {
            const interior = dr.realGreaterThan(&x, &l);
            if (discrete != 0) {
                dr.toIntegralValue(&x, &l, dr.DEC_ROUND_CEILING, &dr.ctxtReal39);
                dr.realSubtract(&high, &l, &l, &dr.ctxtReal39);
                dr.realAdd(&l, dr.const1(), &l, &dr.ctxtReal39);
            } else {
                dr.realSubtract(&high, &x, &l, &dr.ctxtReal39);
            }
            dr.realDivide(&l, &range, &x, &dr.ctxtReal39);
            if (interior and dr.realEqual(&x, dr.const1())) {
                dr.realNextToward(&x, dr.const0(), &x, &dr.ctxtReal39);
            }
        }
        dr.convertRealToResultRegister(res, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn uniformI(discrete: u16) linksection(dr.code_section) void {
    var x: real_t = undefined;
    var low: real_t = undefined;
    var high: real_t = undefined;
    var t: real_t = undefined;

    if (uniformParameters(&x, &low, &high, null, null, discrete)) {
        if (dr.realLessThan(&x, dr.const0()) or dr.realGreaterThan(&x, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function fnUniformI:", "the argument must be 0 <= x <= 1", null, null);
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.setNaN(&t);
                dr.convertRealToResultRegister(&t, dr.REGISTER_X, dr.amNone);
            }
            return;
        }
        if (dr.realIsZero(&x)) {
            dr.realCopy(&low, &x);
        } else if (dr.realEqual(&x, dr.const1())) {
            dr.realCopy(&high, &x);
        } else if (discrete != 0) {
            dr.realSubtract(&high, &low, &t, &dr.ctxtReal75);
            dr.realAdd(&t, dr.const1(), &t, &dr.ctxtReal75);
            dr.realMultiply(&x, &t, &t, &dr.ctxtReal75);
            dr.toIntegralValue(&t, &t, dr.DEC_ROUND_CEILING, &dr.ctxtReal75);
            dr.realSubtract(&t, dr.const1(), &t, &dr.ctxtReal75);
            dr.realAdd(&low, &t, &x, &dr.ctxtReal75);
        } else {
            dr.linearInterpolate(&low, &high, &x, &t);
            dr.realCopy(&t, &x);
        }
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}
