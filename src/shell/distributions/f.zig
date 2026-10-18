// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/f.c: the F distribution commands, the
// WP34S kernels behind them, the regularised-beta machinery the binomial and
// negative binomial borrow (distributionLogBetaPrefix, distributionBetaPair) and
// the Newton quantile solver of the discrete distributions. The commands hand
// their descriptor row to fnDistribution, which loads register X and the degrees
// of freedom in M and N. The beta tails come from a Lanczos log prefix and a
// continued fraction, or from a tanh-sinh quadrature of the density in logit
// space once both shapes pass 1E5. Tagged linksection(dr.code_section) so the
// code runs from QSPI on the flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// fCheckDomain: integer positive d1 and d2, and x at or above zero.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;
    const j = second.?;

    if (!dr.checkRegisterNoFP(i) or !dr.checkRegisterNoFP(j) or dr.realIsSpecial(i) or dr.realIsSpecial(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function fCheckDomain:", "d1 or d2 is not an integer", null, null);
        return false;
    }
    if (dr.realIsNaN(x) or dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function fCheckDomain:", "cannot calculate for x < 0", null, null);
        return false;
    }
    if (dr.realIsZero(i) or dr.realIsNegative(i) or dr.realIsZero(j) or dr.realIsNegative(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function fCheckDomain:", "cannot calculate for d1 \xa2\x64 0 or d2 \xa2\x64 0", null, null);
        return false;
    }
    return true;
}

pub fn fP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_F * 4 + dr.DIST_P);
}

pub fn fL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_F * 4 + dr.DIST_L);
}

pub fn fR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_F * 4 + dr.DIST_R);
}

pub fn fI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_F * 4 + dr.DIST_I);
}

// Whether d1 and d2 define an F distribution.
fn fParametersAreValid(d1: *const real_t, d2: *const real_t) linksection(dr.code_section) bool {
    return !dr.realIsSpecial(d1) and !dr.realIsSpecial(d2) and dr.realGreaterThan(d1, dr.const0()) and dr.realGreaterThan(d2, dr.const0());
}

// A probability y and its complement z from the logit ln(y / z), each formed
// from the side that does not cancel.
fn fLogitToBetaPair(logit: *const real_t, y: *real_t, z: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var exponential: real_t = undefined;
    var denominator: real_t = undefined;
    var value: real_t = undefined;

    dr.realCopy(logit, &value);
    if (dr.realIsNegative(&value)) {
        dr.realExponential(&value, &exponential, real_context);
        dr.realAdd(dr.const1(), &exponential, &denominator, real_context);
        dr.realDivide(dr.const1(), &denominator, z, real_context);
        dr.realMultiply(&exponential, z, y, real_context);
    } else {
        dr.realChangeSign(&value);
        dr.realExponential(&value, &exponential, real_context);
        dr.realAdd(dr.const1(), &exponential, &denominator, real_context);
        dr.realDivide(dr.const1(), &denominator, y, real_context);
        dr.realMultiply(&exponential, y, z, real_context);
    }
}

// ln(y^a z^b / B(a, b)): directly through ln B below shapes of 1E5, else by the
// Lanczos sums with the powers folded into cancellation-free log1p terms.
fn fLogBetaPrefix(a: *const real_t, b: *const real_t, y: *const real_t, z: *const real_t, logit: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var x: real_t = undefined;
    var direct_threshold: real_t = undefined;
    var sum_a: real_t = undefined;
    var sum_b: real_t = undefined;
    var sum_ab: real_t = undefined;
    var r_a: real_t = undefined;
    var r_b: real_t = undefined;
    var r_ab: real_t = undefined;
    var log_a: real_t = undefined;
    var log_b: real_t = undefined;
    var term: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;

    dr.setOne(&direct_threshold);
    direct_threshold.exponent = 5;
    if (dr.realLessThan(a, &direct_threshold) or dr.realLessThan(b, &direct_threshold)) {
        dr.C47_LnBetaPositiveReal(a, b, &term);
        dr.realCopy(logit, &x);
        if (dr.realIsNegative(&x)) {
            dr.realExponential(&x, &v, real_context);
            dr.WP34S_Ln1P(&v, &v, real_context);
            dr.realSubtract(&x, &v, &u, real_context);
            dr.realChangeSign(&v);
        } else {
            dr.realChangeSign(&x);
            dr.realExponential(&x, &v, real_context);
            dr.WP34S_Ln1P(&v, &v, real_context);
            dr.realMinus(&v, &u, real_context);
            dr.realSubtract(&x, &v, &v, real_context);
        }
        dr.realMultiply(a, &u, &u, real_context);
        dr.realMultiply(b, &v, &v, real_context);
        dr.realAdd(&u, &v, &u, real_context);
        dr.realSubtract(&u, &term, res, real_context);
        return;
    }

    dr.realSubtract(a, dr.const1(), &x, real_context);
    dr.WP34S_LanczosSum(&x, dr.const29(), &sum_a, real_context);
    dr.realSubtract(b, dr.const1(), &x, real_context);
    dr.WP34S_LanczosSum(&x, dr.const29(), &sum_b, real_context);
    dr.realAdd(a, b, &r_ab, real_context);
    dr.realSubtract(&r_ab, dr.const1(), &x, real_context);
    dr.WP34S_LanczosSum(&x, dr.const29(), &sum_ab, real_context);
    dr.WP34S_Ln(&sum_a, &sum_a, real_context);
    dr.WP34S_Ln(&sum_b, &sum_b, real_context);
    dr.WP34S_Ln(&sum_ab, &sum_ab, real_context);

    dr.realAdd(a, dr.constGammaRm1(), &r_a, real_context);
    dr.realAdd(b, dr.constGammaRm1(), &r_b, real_context);
    dr.realAdd(&r_ab, dr.constGammaRm1(), &r_ab, real_context);

    dr.realMultiply(y, b, &u, real_context);
    dr.realMultiply(z, a, &v, real_context);
    dr.realSubtract(&u, &v, &u, real_context);
    dr.realFMA(dr.constMinusGammaRm1(), z, &u, &u, real_context);
    dr.realDivide(&u, &r_a, &u, real_context);
    dr.WP34S_Ln1P(&u, &log_a, real_context);

    dr.realMultiply(z, a, &u, real_context);
    dr.realMultiply(y, b, &v, real_context);
    dr.realSubtract(&u, &v, &u, real_context);
    dr.realFMA(dr.constMinusGammaRm1(), y, &u, &u, real_context);
    dr.realDivide(&u, &r_b, &u, real_context);
    dr.WP34S_Ln1P(&u, &log_b, real_context);

    dr.realMultiply(a, &log_a, &u, real_context);
    dr.realFMA(b, &log_b, &u, &u, real_context);
    dr.realDivide(b, &r_a, &v, real_context);
    dr.WP34S_Ln1P(&v, &v, real_context);
    dr.realMultiply(&v, dr.const1on2(), &v, real_context);
    dr.realSubtract(&u, &v, &u, real_context);
    dr.realDivide(a, &r_b, &v, real_context);
    dr.WP34S_Ln1P(&v, &v, real_context);
    dr.realMultiply(&v, dr.const1on2(), &v, real_context);
    dr.realSubtract(&u, &v, &u, real_context);
    dr.WP34S_Ln(&r_ab, &v, real_context);
    dr.realMultiply(&v, dr.const1on2(), &v, real_context);
    dr.realAdd(&u, &v, &u, real_context);
    dr.realAdd(&u, dr.constGammaRm1(), &u, real_context);
    dr.realAdd(&sum_ab, &u, &u, real_context);
    dr.realSubtract(&u, &sum_a, &u, real_context);
    dr.realSubtract(&u, &sum_b, res, real_context);
}

// The beta density in logit space at `scale` mode widths from the mode, relative
// to the density at the mode.
fn fLargeBetaDensity(scaled_value: *const real_t, scale: *const real_t, a: *const real_t, b: *const real_t, mode_prefix: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var value: real_t = undefined;
    var logit: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var sum: real_t = undefined;
    var term_a: real_t = undefined;
    var term_b: real_t = undefined;
    var ratio_a: real_t = undefined;
    var ratio_b: real_t = undefined;
    var relative_a: real_t = undefined;
    var relative_b: real_t = undefined;
    var factor: real_t = undefined;
    var n: real_t = undefined;
    var old: real_t = undefined;
    var divergence: real_t = undefined;
    var total: real_t = undefined;
    var small: real_t = undefined;

    dr.realMultiply(scaled_value, scale, &value, real_context);
    dr.WP34S_Ln(a, &logit, real_context);
    dr.realAdd(&value, &logit, &logit, real_context);
    dr.WP34S_Ln(b, &value, real_context);
    dr.realSubtract(&logit, &value, &logit, real_context);
    fLogitToBetaPair(&logit, &y, &z, real_context);
    dr.realAdd(a, b, &total, real_context);
    dr.realDivide(a, &total, &ratio_a, real_context);
    dr.realDivide(b, &total, &ratio_b, real_context);
    dr.realSubtract(&y, &ratio_a, &factor, real_context);
    dr.realDivide(&factor, &ratio_a, &relative_a, real_context);
    dr.realDivide(&factor, &ratio_b, &relative_b, real_context);
    dr.setOne(&value);
    value.exponent = 20;
    dr.int32ToReal(100, &small);
    dr.realDivide(dr.const1(), &small, &small, real_context);
    if (dr.realGreaterThan(&total, &value) and dr.realCompareAbsLessThan(&relative_a, &small) and dr.realCompareAbsLessThan(&relative_b, &small)) {
        dr.realMultiply(&factor, &relative_a, &term_a, real_context);
        dr.realMultiply(&term_a, dr.const1on2(), &term_a, real_context);
        dr.realMultiply(&factor, &relative_b, &term_b, real_context);
        dr.realMultiply(&term_b, dr.const1on2(), &term_b, real_context);
        dr.realAdd(&term_a, &term_b, &sum, real_context);
        dr.int32ToReal(2, &n);
        while (true) {
            dr.realCopy(&sum, &old);
            dr.realAdd(&n, dr.const1(), &n, real_context);
            dr.realSubtract(&n, dr.const1(), &value, real_context);
            dr.realDivide(&value, &n, &value, real_context);
            dr.realMultiply(&term_a, &relative_a, &term_a, real_context);
            dr.realChangeSign(&term_a);
            dr.realMultiply(&term_a, &value, &term_a, real_context);
            dr.realMultiply(&term_b, &relative_b, &term_b, real_context);
            dr.realMultiply(&term_b, &value, &term_b, real_context);
            dr.realAdd(&term_a, &term_b, &value, real_context);
            dr.realAdd(&sum, &value, &sum, real_context);
            if (dr.realEqual(&sum, &old)) {
                break;
            }
        }
        dr.realMultiply(&sum, &total, &divergence, real_context);
    } else {
        dr.WP34S_Ln1P(&relative_a, &term_a, real_context);
        dr.realMultiply(a, &term_a, &term_a, real_context);
        dr.realMinus(&relative_b, &term_b, real_context);
        dr.WP34S_Ln1P(&term_b, &term_b, real_context);
        dr.realMultiply(b, &term_b, &term_b, real_context);
        dr.realAdd(&term_a, &term_b, &divergence, real_context);
        dr.realChangeSign(&divergence);
    }
    dr.realSubtract(mode_prefix, &divergence, &value, real_context);
    dr.realExponential(&value, res, real_context);
    dr.realMultiply(res, scale, res, real_context);
}

// Both regularised-beta tails for shapes of 1E5 and more, by a tanh-sinh
// quadrature of the density from the point to the far end of its tail.
fn fLargeBetaPair(a: *const real_t, b: *const real_t, y: *const real_t, logit: *const real_t, lower: *real_t, upper: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var total: real_t = undefined;
    var ratio_a: real_t = undefined;
    var ratio_b: real_t = undefined;
    var mode_logit: real_t = undefined;
    var mode_prefix: real_t = undefined;
    var scale: real_t = undefined;
    var value: real_t = undefined;
    var scaled_value: real_t = undefined;
    var left: real_t = undefined;
    var right: real_t = undefined;
    var midpoint: real_t = undefined;
    var half_width: real_t = undefined;
    var h: real_t = undefined;
    var u: real_t = undefined;
    var sinh_u: real_t = undefined;
    var cosh_u: real_t = undefined;
    var argument: real_t = undefined;
    var tanh_argument: real_t = undefined;
    var cosh_argument: real_t = undefined;
    var node: real_t = undefined;
    var jacobian: real_t = undefined;
    var density: real_t = undefined;
    var term: real_t = undefined;
    var sum: real_t = undefined;
    var bound: real_t = undefined;

    dr.realAdd(a, b, &total, real_context);
    dr.realDivide(a, &total, &ratio_a, real_context);
    dr.realDivide(b, &total, &ratio_b, real_context);
    dr.WP34S_Ln(a, &mode_logit, real_context);
    dr.WP34S_Ln(b, &value, real_context);
    dr.realSubtract(&mode_logit, &value, &mode_logit, real_context);
    fLogBetaPrefix(a, b, &ratio_a, &ratio_b, &mode_logit, &mode_prefix, real_context);
    dr.realMultiply(a, b, &value, real_context);
    dr.realDivide(&total, &value, &scale, real_context);
    dr.realSquareRoot(&scale, &scale, real_context);
    dr.realSubtract(logit, &mode_logit, &value, real_context);
    dr.realDivide(&value, &scale, &scaled_value, real_context);

    const calculate_lower = dr.realCompareLessEqual(&scaled_value, dr.const0());
    // m, the slope of the log density at v in mode widths, sets the step to the far end: over sqrt(m^2 + 180) - m a Gaussian log density falls by 90, and for shapes
    // of 1E5 and more the logit density falls by at least 88 there while the tail is above 1E-6176, so the mass left out is below e^-88 of the tail.
    dr.realMultiply(&total, y, &value, real_context);
    dr.realSubtract(&value, a, &value, real_context);
    dr.realMultiply(&value, &scale, &value, real_context);
    dr.realCopyAbs(&value, &value);
    dr.realFMA(&value, &value, dr.const180(), &bound, real_context);
    dr.realSquareRoot(&bound, &bound, real_context);
    dr.realSubtract(&bound, &value, &bound, real_context);
    if (calculate_lower) {
        dr.realSubtract(&scaled_value, &bound, &left, real_context);
        dr.realCopy(&scaled_value, &right);
    } else {
        dr.realCopy(&scaled_value, &left);
        dr.realAdd(&scaled_value, &bound, &right, real_context);
    }
    dr.realAdd(&left, &right, &midpoint, real_context);
    dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, real_context);
    dr.realSubtract(&right, &left, &half_width, real_context);
    dr.realMultiply(&half_width, dr.const1on2(), &half_width, real_context);
    dr.int32ToReal(32, &value);
    dr.realDivide(dr.const1(), &value, &h, real_context);
    dr.setZero(&sum);
    var k: i32 = -192;
    while (k <= 192) : (k += 1) {
        dr.int32ToReal(k, &u);
        dr.realMultiply(&u, &h, &u, real_context);
        dr.WP34S_SinhCosh(&u, &sinh_u, &cosh_u, real_context);
        dr.realMultiply(dr.const75PiOn2(), &sinh_u, &argument, real_context);
        dr.WP34S_Tanh(&argument, &tanh_argument, real_context);
        if (dr.realCompareAbsEqual(&tanh_argument, dr.const1())) {
            continue;
        }
        dr.realFMA(&half_width, &tanh_argument, &midpoint, &node, real_context);
        dr.WP34S_SinhCosh(&argument, &value, &cosh_argument, real_context);
        dr.realMultiply(&cosh_argument, &cosh_argument, &value, real_context);
        dr.realMultiply(&half_width, dr.const75PiOn2(), &jacobian, real_context);
        dr.realMultiply(&jacobian, &cosh_u, &jacobian, real_context);
        dr.realDivide(&jacobian, &value, &jacobian, real_context);
        fLargeBetaDensity(&node, &scale, a, b, &mode_prefix, &density, real_context);
        dr.realMultiply(&density, &jacobian, &term, real_context);
        dr.realAdd(&sum, &term, &sum, real_context);
    }
    dr.realMultiply(&sum, &h, &sum, real_context);
    if (calculate_lower) {
        dr.realCopy(&sum, lower);
        dr.realSubtract(dr.const1(), lower, upper, real_context);
    } else {
        dr.realCopy(&sum, upper);
        dr.realSubtract(dr.const1(), upper, lower, real_context);
    }
}

// Both regularised-beta tails I_y(a, b) and I_z(b, a) from y, z = 1 - y and
// their logit; false when neither continued fraction converges.
fn fBetaPair(a: *const real_t, b: *const real_t, y: *const real_t, z: *const real_t, logit: *const real_t, lower: *real_t, upper: *real_t, real_context: *realContext_t) linksection(dr.code_section) bool {
    var fraction: real_t = undefined;
    var large_threshold: real_t = undefined;
    var log_prefix: real_t = undefined;
    var threshold: real_t = undefined;
    var value: real_t = undefined;
    var term: real_t = undefined;
    var wide_y: real_t = undefined;
    var wide_z: real_t = undefined;

    if (dr.realIsZero(y)) {
        dr.setZero(lower);
        dr.setOne(upper);
        return true;
    }
    if (dr.realIsZero(z)) {
        dr.setOne(lower);
        dr.setZero(upper);
        return true;
    }
    if (dr.realEqual(a, b) and dr.realEqual(y, z)) {
        dr.realCopy(dr.const1on2(), lower);
        dr.realCopy(dr.const1on2(), upper);
        return true;
    }
    dr.setOne(&large_threshold);
    large_threshold.exponent = 5;
    if (dr.realCompareGreaterEqual(a, &large_threshold) and dr.realCompareGreaterEqual(b, &large_threshold)) {
        fLargeBetaPair(a, b, y, logit, lower, upper, real_context);
        return true;
    }

    fLogBetaPrefix(a, b, y, z, logit, &log_prefix, real_context);
    dr.realExponential(&log_prefix, &value, real_context);
    dr.realAdd(a, b, &term, real_context);
    dr.realAdd(&term, dr.const2(), &term, real_context);
    dr.realAdd(a, dr.const1(), &threshold, real_context);
    dr.realDivide(&threshold, &term, &threshold, real_context);
    if (dr.realLessThan(y, &threshold)) { // next to 1 a step of the fraction cancels as many digits as the larger shape has: past about 5E14 it settles at p75 only
        if (!dr.WP34S_BetaFraction(a, b, y, -42, 1000, &fraction, real_context)) {
            // The retry cancels its argument against 1 as well, which leaves the digits below its leading nines, so it takes y from the logit at p75. For a shape of
            // 5E39 its change stalls between 1E-41 and 1E-39 while the value is good to 1E-35, so it settles at 1E-39.
            fLogitToBetaPair(logit, &wide_y, &wide_z, &dr.ctxtReal75);
            if (!dr.WP34S_BetaFraction(a, b, &wide_y, -39, 1000, &fraction, &dr.ctxtReal75)) {
                return false;
            }
        }
        dr.realDivide(&fraction, a, &fraction, real_context);
        dr.realMultiply(&value, &fraction, lower, real_context);
        dr.realSubtract(dr.const1(), lower, upper, real_context);
    } else {
        if (!dr.WP34S_BetaFraction(b, a, z, -42, 1000, &fraction, real_context)) {
            fLogitToBetaPair(logit, &wide_y, &wide_z, &dr.ctxtReal75); // z to 75 digits and 1E-39, as for the lower tail
            if (!dr.WP34S_BetaFraction(b, a, &wide_z, -39, 1000, &fraction, &dr.ctxtReal75)) {
                return false;
            }
        }
        dr.realDivide(&fraction, b, &fraction, real_context);
        dr.realMultiply(&value, &fraction, upper, real_context);
        dr.realSubtract(dr.const1(), upper, lower, real_context);
    }
    return true;
}

/// distributionLogBetaPrefix: the logarithm of the regularised-beta prefix.
pub fn distributionLogBetaPrefix(a: *const real_t, b: *const real_t, y: *const real_t, z: *const real_t, logit: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    fLogBetaPrefix(a, b, y, z, logit, res, real_context);
}

/// distributionBetaPair: both regularised-beta tails from a probability pair and its logit.
pub fn distributionBetaPair(a: *const real_t, b: *const real_t, y: *const real_t, z: *const real_t, logit: *const real_t, lower: *real_t, upper: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) bool {
    return fBetaPair(a, b, y, z, logit, lower, upper, real_context);
}

// The F probabilities and the log of the density prefix at x, whichever the
// caller asked for; 75 digits once both degrees of freedom reach 2E5.
fn fEvaluate(x: *const real_t, d1: *const real_t, d2: *const real_t, lower: ?*real_t, upper: ?*real_t, log_prefix: ?*real_t) linksection(dr.code_section) bool {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var logit: real_t = undefined;
    var term: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var large_threshold: real_t = undefined;
    var calculation_context: *realContext_t = &dr.ctxtReal51;

    dr.int32ToReal(2, &large_threshold);
    large_threshold.exponent = 5;
    if (dr.realCompareGreaterEqual(d1, &large_threshold) and dr.realCompareGreaterEqual(d2, &large_threshold)) {
        calculation_context = &dr.ctxtReal75;
    }
    dr.WP34S_Ln(x, &logit, calculation_context);
    dr.WP34S_Ln(d1, &term, calculation_context);
    dr.realAdd(&logit, &term, &logit, calculation_context);
    dr.WP34S_Ln(d2, &term, calculation_context);
    dr.realSubtract(&logit, &term, &logit, calculation_context);
    fLogitToBetaPair(&logit, &y, &z, calculation_context);
    dr.realMultiply(d1, dr.const1on2(), &a, calculation_context);
    dr.realMultiply(d2, dr.const1on2(), &b, calculation_context);
    if (log_prefix) |prefix| {
        fLogBetaPrefix(&a, &b, &y, &z, &logit, prefix, calculation_context);
    }
    if (lower != null and upper != null) {
        return fBetaPair(&a, &b, &y, &z, &logit, lower.?, upper.?, calculation_context);
    }
    return true;
}

pub fn wp34sPdfF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var log_density: real_t = undefined;
    var log_x: real_t = undefined;

    if (dr.realIsNaN(x) or !fParametersAreValid(d1, d2) or dr.realIsNegative(x)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        if (dr.realLessThan(d1, dr.const2())) {
            dr.setPlusInfinity(res);
        } else if (dr.realEqual(d1, dr.const2())) {
            dr.setOne(res);
        } else {
            dr.setZero(res);
        }
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }

    _ = fEvaluate(x, d1, d2, null, null, &log_density);
    dr.WP34S_Ln(x, &log_x, &dr.ctxtReal75);
    dr.realSubtract(&log_density, &log_x, &log_density, &dr.ctxtReal75);
    dr.realExponential(&log_density, &log_density, &dr.ctxtReal75);
    dr.realPlus(&log_density, res, real_context);
}

pub fn wp34sCdfuF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var lower: real_t = undefined;
    var upper: real_t = undefined;

    if (dr.realIsNaN(x) or !fParametersAreValid(d1, d2) or dr.realIsNegative(x)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    if (!fEvaluate(x, d1, d2, &lower, &upper, null)) {
        dr.setNaN(res);
        return;
    }
    dr.realPlus(&upper, res, real_context);
}

pub fn wp34sCdfF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var lower: real_t = undefined;
    var upper: real_t = undefined;

    if (dr.realIsNaN(x) or !fParametersAreValid(d1, d2) or dr.realIsNegative(x)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    if (!fEvaluate(x, d1, d2, &lower, &upper, null)) {
        dr.setNaN(res);
        return;
    }
    dr.realPlus(&lower, res, real_context);
}

// The lower F quantile by a bracketed Newton search in ln x; false when it
// does not settle in 320 steps.
fn fInverseLower(target: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t) linksection(dr.code_section) bool {
    var a: real_t = undefined;
    var accuracy: real_t = undefined;
    var b: real_t = undefined;
    var bound: real_t = undefined;
    var derivative: real_t = undefined;
    var estimate_tolerance: real_t = undefined;
    var high: real_t = undefined;
    var large_threshold: real_t = undefined;
    var log_d1: real_t = undefined;
    var log_d2: real_t = undefined;
    var logit: real_t = undefined;
    var low: real_t = undefined;
    var lower: real_t = undefined;
    var upper: real_t = undefined;
    var midpoint: real_t = undefined;
    var proposal: real_t = undefined;
    var residual: real_t = undefined;
    var step: real_t = undefined;
    var tolerance: real_t = undefined;
    var value: real_t = undefined;
    var width: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var calculation_context: *realContext_t = &dr.ctxtReal51;

    dr.int32ToReal(2, &large_threshold);
    large_threshold.exponent = 5;
    if (dr.realCompareGreaterEqual(d1, &large_threshold) and dr.realCompareGreaterEqual(d2, &large_threshold)) {
        calculation_context = &dr.ctxtReal75;
    }
    dr.realMultiply(d1, dr.const1on2(), &a, calculation_context);
    dr.realMultiply(d2, dr.const1on2(), &b, calculation_context);
    dr.WP34S_Ln(d1, &log_d1, calculation_context);
    dr.WP34S_Ln(d2, &log_d2, calculation_context);
    dr.int32ToReal(16000, &bound);
    dr.realMinus(&bound, &low, calculation_context);
    dr.realCopy(&bound, &high);
    dr.setZero(&value);
    dr.setOne(&tolerance);
    tolerance.exponent = -40;
    dr.setOne(&estimate_tolerance);
    estimate_tolerance.exponent = -38;

    var i: i32 = 0;
    while (i < 320) : (i += 1) {
        dr.realAdd(&value, &log_d1, &logit, calculation_context);
        dr.realSubtract(&logit, &log_d2, &logit, calculation_context);
        fLogitToBetaPair(&logit, &y, &z, calculation_context);
        if (!fBetaPair(&a, &b, &y, &z, &logit, &lower, &upper, calculation_context)) {
            return false;
        }
        dr.realSubtract(&lower, target, &residual, calculation_context);
        dr.realMultiply(target, &tolerance, &accuracy, calculation_context);
        if (dr.realIsZero(&residual) or dr.realCompareAbsLessThan(&residual, &accuracy)) {
            dr.realExponential(&value, res, calculation_context);
            return true;
        }
        if (dr.realIsNegative(&residual)) {
            dr.realCopy(&value, &low);
        } else {
            dr.realCopy(&value, &high);
        }
        dr.realSubtract(&high, &low, &width, calculation_context);
        if (dr.realCompareAbsLessThan(&width, &tolerance)) {
            dr.realAdd(&low, &high, &value, calculation_context);
            dr.realMultiply(&value, dr.const1on2(), &value, calculation_context);
            dr.realExponential(&value, res, calculation_context);
            return true;
        }

        fLogBetaPrefix(&a, &b, &y, &z, &logit, &derivative, calculation_context);
        dr.realExponential(&derivative, &derivative, calculation_context);
        dr.realAdd(&low, &high, &midpoint, calculation_context);
        dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, calculation_context);
        if (i >= 24 or dr.realIsZero(&derivative)) {
            dr.realCopy(&midpoint, &proposal);
        } else {
            dr.realDivide(&residual, &derivative, &step, calculation_context);
            dr.realSubtract(&value, &step, &proposal, calculation_context);
            if (dr.realCompareLessEqual(&proposal, &low) or dr.realCompareGreaterEqual(&proposal, &high)) {
                dr.realCopy(&midpoint, &proposal);
            }
        }
        dr.realSubtract(&proposal, &value, &step, calculation_context);
        if (dr.realCompareAbsLessThan(&step, &estimate_tolerance)) {
            dr.realExponential(&proposal, res, calculation_context);
            return true;
        }
        dr.realCopy(&proposal, &value);
    }
    return false;
}

pub fn wp34sQfF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var probability: real_t = undefined;
    var value: real_t = undefined;

    if (dr.realIsNaN(x) or !fParametersAreValid(d1, d2) or dr.realCompareLessEqual(x, dr.const0()) or dr.realCompareGreaterEqual(x, dr.const1())) {
        dr.setNaN(res);
        return;
    }
    const reciprocal = dr.realGreaterThan(x, dr.const1on2());
    if (reciprocal) {
        dr.realSubtract(dr.const1(), x, &probability, &dr.ctxtReal75);
        if (!fInverseLower(&probability, d2, d1, &value)) {
            dr.setNaN(res);
            return;
        }
        dr.realDivide(dr.const1(), &value, &value, &dr.ctxtReal75);
    } else {
        dr.realCopy(x, &probability);
        if (!fInverseLower(&probability, d1, d2, &value)) {
            dr.setNaN(res);
            return;
        }
    }
    dr.realPlus(&value, res, real_context);
}

/// WP34S_Qf_Newton: the Newton-step quantile solver. Target value in Y, function
/// identifier in X, estimate in Z. The estimate is refined between the bounds
/// r_low and r_high, bisecting whenever a step leaves them, and a discrete
/// distribution finishes by walking to the integer.
pub fn wp34sQfNewton(r_dist: u32, target: *const real_t, estimate: *const real_t, p1: [*c]const real_t, p2: [*c]const real_t, p3: [*c]const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r_p: real_t = undefined;
    var r_low: real_t = undefined;
    var r_high: real_t = undefined;
    var r_maxstep: real_t = undefined;
    var r_r: real_t = undefined;
    var r_z: real_t = undefined;
    var r_w: real_t = undefined;
    var r_iterations: u32 = undefined;
    var f_discrete = false;
    var f_nobisect = false;
    const f_nonnegative = true;
    const f_limitjump = true;

    // qf_newton
    dr.realCopy(target, &r_p);
    dr.realCopy(estimate, &r_r);

    // f_newton_setflags: everything but the F is discrete.
    if (r_dist != dr.QF_NEWTON_F) {
        f_discrete = true;
    }

    // qf_f_flags
    dr.realMultiply(dr.const3on2(), dr.const1on2(), &p, real_context);
    dr.realMultiply(&p, &r_r, &p, real_context);
    dr.realCopy(&p, &r_maxstep);

    r_iterations = 100;
    dr.setPlusInfinity(&r_high);
    dr.realCopy(if (f_nonnegative) dr.const0() else dr.constMinusInfinity(), &r_low);

    // The upstream labels qf_newton_done (take r_r) and qf_newton_done2 (p is
    // already set) both end in the discrete finish, so the search leaves its
    // result in p and signals which path it took.
    var done = false;
    search: while (true) { // qf_newton_search
        if (dr.realCompareGreaterEqual(&r_r, &r_high) or dr.realCompareLessEqual(&r_r, &r_low)) { // qf_newton_try_bisect
            // The estimate is out of the (low, high) bounds. Check to see if we can bisect instead.
            if (dr.realIsInfinite(&r_high)) { // qf_newton_overlow
                dr.realMultiply(&r_low, dr.const2(), &r_r, real_context);
            } else if (dr.realIsInfinite(&r_low)) { // qf_newton_underhigh
                dr.realMultiply(&r_high, dr.const2(), &r_r, real_context);
            } else { // qf_newton_do_bisect
                dr.realAdd(&r_low, &r_high, &r_r, real_context);
                dr.realMultiply(&r_r, dr.const1on2(), &r_r, real_context);
                f_nobisect = true;
            }
        }
        // qf_newton_no_bisect: the CDF of the distribution being searched, bisecting again until the estimate sits within the bounds.
        while (true) {
            switch (r_dist) { // qf_newton_cdf
                dr.QF_NEWTON_F => wp34sCdfF(&r_r, p1, p2, &r_w, real_context),
                dr.QF_NEWTON_POISSON => dr.WP34S_Cdf_Poisson2(&r_r, p1, &r_w, real_context),
                dr.QF_NEWTON_BINOMIAL => dr.WP34S_Cdf_Binomial2(&r_r, p1, p2, &r_w, real_context),
                dr.QF_NEWTON_NEGBINOM => dr.cdf_NegBinomial2(&r_r, p1, p2, &r_w, real_context),
                dr.QF_NEWTON_HYPERGEOMETRIC => dr.cdf_Hypergeometric2(&r_r, p1, p2, p3, &r_w, &dr.ctxtReal75),
                else => {},
            }
            dr.realSubtract(&r_w, &r_p, &r_z, real_context);
            if (dr.realCompareGreaterEqual(&r_z, dr.const0())) { // qf_newton_fix_high
                if (f_nobisect or dr.realLessThan(&r_r, &r_high) or dr.realIsInfinite(&r_low)) {
                    f_nobisect = false;
                    if (dr.realLessThan(&r_r, &r_high)) { // qf_newton_fix_high2
                        dr.realCopy(&r_r, &r_high);
                    }
                    break;
                }
            } else { // qf_newton_fix_low
                if (f_nobisect or dr.realGreaterThan(&r_r, &r_low) or dr.realIsInfinite(&r_high)) {
                    f_nobisect = false;
                    if (dr.realGreaterThan(&r_r, &r_low)) { // qf_newton_fix_low2
                        dr.realCopy(&r_r, &r_low);
                    }
                    break;
                }
            }
            // qf_newton_do_bisect
            dr.realAdd(&r_low, &r_high, &r_r, real_context);
            dr.realMultiply(&r_r, dr.const1on2(), &r_r, real_context);
            f_nobisect = true;
        }
        // qf_newton_fixed: the CDF is within the bounds, so take the PDF for the step.
        switch (r_dist) { // qf_newton_pdf
            dr.QF_NEWTON_F => wp34sPdfF(&r_r, p1, p2, &q, real_context),
            dr.QF_NEWTON_POISSON => dr.WP34S_Pdf_Poisson(&r_r, p1, &q, real_context),
            dr.QF_NEWTON_BINOMIAL => dr.WP34S_Pdf_Binomial(&r_r, p1, p2, &q, real_context),
            dr.QF_NEWTON_NEGBINOM => dr.pdf_NegBinomial(&r_r, p1, p2, &q, real_context),
            dr.QF_NEWTON_HYPERGEOMETRIC => dr.pdf_Hypergeometric(&r_r, p1, p2, p3, &q, real_context),
            else => {},
        }
        if (dr.realIsZero(&q)) { // the function is flat, so nothing can be estimated
            dr.realCopy(&r_r, &p);
            done = true;
            break :search;
        }
        dr.realDivide(&r_z, &q, &r_w, real_context);
        dr.realCopyAbs(&r_w, &q);
        if (f_limitjump and dr.realCompareGreaterEqual(&q, &r_maxstep)) {
            if (dr.realLessThan(&r_w, dr.const0())) { // qf_newton_neg_limit
                dr.realMinus(&r_maxstep, &r_w, real_context);
            } else { // qf_newton_fin_limit
                dr.realCopy(&r_maxstep, &r_w);
            }
        }
        // qf_newton_no_limit: update the estimate.
        dr.realCopy(&r_r, &r_z);
        dr.realSubtract(&r_r, &r_w, &r_r, real_context);

        // A distribution that takes no negative values keeps the estimate positive.
        if (f_nonnegative and dr.realLessThan(&r_r, dr.const0())) {
            dr.realCopy(&r_z, &r_r);
            r_r.exponent -= 5;
        }

        // qf_newton_nosign: bounds close enough together end the search.
        if (!dr.realIsSpecial(&r_high) and !dr.realIsSpecial(&r_low) and dr.WP34S_RelativeError(&r_low, &r_high, dr.const1e_37(), real_context)) {
            // qf_newton_bounds_cnvg
            dr.realAdd(&r_high, &r_low, &p, real_context);
            dr.realMultiply(&p, dr.const1on2(), &p, real_context);
            done = true;
            break :search;
        } else { // qf_newton_nobounds: convergence of the estimates
            if (f_discrete) { // qf_newton_dis_end
                dr.realSubtract(&r_z, &r_r, &p, real_context);
                dr.realSetPositiveSign(&p);
                if (dr.realGreaterThan(dr.const1on10(), &p)) {
                    dr.realCopy(&r_r, &p);
                    done = true;
                    break :search;
                }
            } else if (dr.WP34S_RelativeError(&r_r, &r_z, dr.const1e_37(), real_context)) {
                dr.realCopy(&r_r, &p);
                done = true;
                break :search;
            }
        }
        // qf_newton_again
        r_iterations -= 1;
        if (r_iterations == 0) {
            break;
        }
    }
    if (!done) {
        if (f_discrete) {
            dr.realCopy(&r_r, &p); // the final search reaches the integer from wherever the iteration stops
        } else {
            dr.setNaN(res);
            return;
        }
    }

    // qf_newton_done2: a discrete distribution has a bit more to do.
    if (f_discrete) { // qf_discrete_exit
        dr.toIntegralValue(&p, &q, dr.DEC_ROUND_FLOOR, real_context);
        dr.WP34S_qf_discrete_final(@intCast(r_dist - 1), &q, &r_p, p1, p2, p3, &p, real_context);
    }
    dr.realCopy(&p, res);
}
