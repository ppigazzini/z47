// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/exponential.c: the exponential distribution
// commands and the WP34S kernels behind them. The four commands hand their row of
// the descriptor table to fnDistribution, which loads register X and the rate in
// register R, runs the domain rule below and picks the kernel; the kernels keep
// upstream's names at the export boundary (frontier.zig exports them while
// OPTION_DIST_EXPON is on). Tagged linksection(dr.code_section) so the code runs
// from QSPI on the flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// exponentialCheckDomain: x may not be NaN and the rate must be positive and finite.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = second;
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;

    if (dr.realIsNaN(x)) {
        if (!dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function exponentialCheckDomain:", "x is NaN", null, null);
        }
        return false;
    } else if (dr.realIsSpecial(i) or dr.realCompareLessEqual(i, dr.const0())) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function exponentialCheckDomain:", "the parameter must be \x83\xbb > 0", null, null);
        return false;
    }
    return true;
}

pub fn exponentialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_EXPON * 4 + dr.DIST_P);
}

pub fn exponentialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_EXPON * 4 + dr.DIST_L);
}

pub fn exponentialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_EXPON * 4 + dr.DIST_R);
}

pub fn exponentialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_EXPON * 4 + dr.DIST_I);
}

/// WP34S_Pdf_Expon: lambda e^(-lambda x), through the logarithm once lambda x passes 10000.
pub fn wp34sPdfExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var scaled: real_t = undefined;
    var value: real_t = undefined;

    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(lambda)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realLessThan(x, dr.const0()) or dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsZero(x)) {
        dr.realCopy(lambda, res);
        return;
    }
    dr.realMultiply(x, lambda, &scaled, real_context);
    if (dr.realCompareLessEqual(&scaled, dr.const10000())) {
        dr.realMinus(&scaled, &value, real_context);
        dr.realExponential(&value, &value, real_context);
        if (dr.realEqual(&value, dr.const1())) {
            dr.realNextToward(&value, dr.const0(), &value, real_context);
        }
        dr.realMultiply(&value, lambda, res, real_context);
    } else {
        dr.WP34S_Ln(lambda, &value, real_context);
        dr.realSubtract(&value, &scaled, &value, real_context);
        dr.realExponential(&value, res, real_context);
        dr.WP34S_MarkPositive(res, real_context);
    }
}

pub fn wp34sCdfuExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(lambda)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    dr.realMultiply(x, lambda, res, real_context);
    dr.realChangeSign(res);
    dr.realExponential(res, res, real_context);
    dr.WP34S_MarkProbability(res, real_context);
}

pub fn wp34sCdfExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(lambda)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    dr.realMultiply(x, lambda, res, real_context);
    dr.realChangeSign(res);
    dr.WP34S_ExpM1(res, res, real_context);
    dr.realChangeSign(res);
    dr.WP34S_MarkProbability(res, real_context);
}

pub fn wp34sQfExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;

    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(lambda) or dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, dr.const1())) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realEqual(x, dr.const1())) {
        dr.setPlusInfinity(res);
        return;
    }
    dr.realMinus(x, &p, real_context);
    dr.WP34S_Ln1P(&p, &p, real_context);
    dr.realChangeSign(&p);
    dr.realDivide(&p, lambda, res, real_context);
    dr.WP34S_MarkPositive(res, real_context);
}
