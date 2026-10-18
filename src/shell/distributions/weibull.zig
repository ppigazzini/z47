// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/weibull.c: the Weibull distribution
// commands and the WP34S kernels behind them. The commands hand their descriptor
// row to fnDistribution, which loads register X, the scale in Q and the shape in
// S, and gives the kernels the shape before the scale. Every kernel goes through
// log((x / scale)^shape) so a ratio the context cannot hold is never formed.
// Tagged linksection(dr.code_section) so the code runs from QSPI on the
// flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// weibullCheckDomain: x may not be NaN; the shape and the scale must be positive and finite.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const shape = first.?;
    const scale = second.?;

    if (dr.realIsNaN(x)) {
        if (!dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function weibullCheckDomain:", "x is NaN", null, null);
        }
        return false;
    } else if (dr.realIsSpecial(shape) or dr.realCompareLessEqual(shape, dr.const0()) or dr.realIsSpecial(scale) or dr.realCompareLessEqual(scale, dr.const0())) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function weibullCheckDomain:", "cannot calculate for b \xa2\x64 0 or t \xa2\x64 0", null, null);
        return false;
    }
    return true;
}

pub fn weibullP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_WEIB * 4 + dr.DIST_P);
}

pub fn weibullL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_WEIB * 4 + dr.DIST_L);
}

pub fn weibullR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_WEIB * 4 + dr.DIST_R);
}

pub fn weibullI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_WEIB * 4 + dr.DIST_I);
}

// log(x / scale) without forming an unrepresentable ratio.
fn weibullLogRatio(x: *const real_t, scale: *const real_t, log_ratio: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var delta: real_t = undefined;

    dr.realSubtract(x, scale, log_ratio, real_context);
    dr.realDivide(log_ratio, scale, log_ratio, real_context);
    dr.realMinus(dr.const1on2(), &delta, real_context);
    if (!dr.realIsSpecial(log_ratio) and dr.realCompareGreaterEqual(log_ratio, &delta)) {
        dr.WP34S_Ln1P(log_ratio, log_ratio, real_context);
    } else {
        dr.WP34S_Ln(x, log_ratio, real_context);
        dr.WP34S_Ln(scale, &delta, real_context);
        dr.realSubtract(log_ratio, &delta, log_ratio, real_context);
    }
}

// log((x / scale)^shape).
fn weibullLogPower(x: *const real_t, scale: *const real_t, shape: *const real_t, log_power: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    weibullLogRatio(x, scale, log_power, real_context);
    dr.realMultiply(log_power, shape, log_power, real_context);
}

pub fn wp34sPdfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var log_power: real_t = undefined;
    var log_density: real_t = undefined;
    var work: real_t = undefined;

    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(b) or !dr.WP34S_IsPositiveFinite(t)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realLessThan(x, dr.const0()) or dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsZero(x)) {
        if (dr.realLessThan(t, dr.const1())) {
            dr.setPlusInfinity(res);
        } else if (dr.realEqual(t, dr.const1())) {
            dr.realDivide(dr.const1(), b, res, real_context);
            dr.WP34S_MarkPositive(res, real_context);
        } else {
            dr.setZero(res);
        }
        return;
    }

    weibullLogPower(x, b, t, &log_power, real_context);
    if (dr.realIsInfinite(&log_power)) {
        dr.setZero(res);
        dr.WP34S_MarkPositive(res, real_context);
        return;
    }
    dr.WP34S_Ln(t, &log_density, real_context);
    dr.WP34S_Ln(x, &work, real_context);
    dr.realSubtract(&log_density, &work, &log_density, real_context);
    dr.realAdd(&log_density, &log_power, &log_density, real_context);
    dr.realExponential(&log_power, &work, real_context);
    if (dr.realIsInfinite(&work)) {
        dr.setZero(res);
        dr.WP34S_MarkPositive(res, real_context);
        return;
    }
    dr.realSubtract(&log_density, &work, &log_density, real_context);
    dr.realExponential(&log_density, res, real_context);
    dr.WP34S_MarkPositive(res, real_context);
}

pub fn wp34sCdfuWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var log_power: real_t = undefined;
    var power: real_t = undefined;

    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(b) or !dr.WP34S_IsPositiveFinite(t)) {
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
    weibullLogPower(x, b, t, &log_power, real_context);
    dr.realExponential(&log_power, &power, real_context);
    dr.realChangeSign(&power);
    dr.realExponential(&power, res, real_context);
    dr.WP34S_MarkProbability(res, real_context);
}

pub fn wp34sCdfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var log_power: real_t = undefined;
    var power: real_t = undefined;

    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(b) or !dr.WP34S_IsPositiveFinite(t)) {
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
    weibullLogPower(x, b, t, &log_power, real_context);
    dr.realExponential(&log_power, &power, real_context);
    dr.realChangeSign(&power);
    dr.WP34S_ExpM1(&power, res, real_context);
    dr.realChangeSign(res);
    dr.WP34S_MarkProbability(res, real_context);
}

pub fn wp34sQfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var log_value: real_t = undefined;

    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(b) or !dr.WP34S_IsPositiveFinite(t) or dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, dr.const1())) {
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
    dr.WP34S_Ln(&p, &log_value, real_context);
    dr.realDivide(&log_value, t, &log_value, real_context);
    dr.WP34S_Ln(b, &p, real_context);
    dr.realAdd(&log_value, &p, &log_value, real_context);
    dr.realExponential(&log_value, res, real_context);
    dr.WP34S_MarkPositive(res, real_context);
}
