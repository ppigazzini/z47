// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/t.c: the Student t distribution commands
// and the WP34S kernels behind them. The commands hand their descriptor row to
// fnDistribution, which loads register X and the degrees of freedom in M. The
// probabilities go through the regularised beta of x^2 / (x^2 + nu) with a
// Lanczos normalisation, the normal with a 1/nu correction series past nu =
// 1E17, and the quantile brackets and refines a root from a normal or a
// power-law estimate; nu below 1 gets its own inverse in the tail variable
// s = ln(1 + x^2 / nu). Tagged linksection(dr.code_section) so the code runs
// from QSPI on the flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// studentTCheckDomain: nu must be positive and not NaN.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = x;
    _ = second;
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;

    if (dr.realIsNaN(i) or dr.realIsZero(i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function studentTCheckDomain:", "cannot calculate for \x83\xbd \xa2\x64 0", null, null);
        return false;
    }
    return true;
}

pub fn tP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_T * 4 + dr.DIST_P);
}

pub fn tL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_T * 4 + dr.DIST_L);
}

pub fn tR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_T * 4 + dr.DIST_R);
}

pub fn tI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_T * 4 + dr.DIST_I);
}

// The context the t works at: the caller's above 51 digits, else 51.
fn tCalculationContext(real_context: *realContext_t) linksection(dr.code_section) *realContext_t {
    return if (real_context.digits > 51) real_context else &dr.ctxtReal51;
}

// ln(a B(a, 1/2)) / a as a series in a, for a tiny half nu.
fn studentTLogASeriesOverA(a: *const real_t, res: *real_t) linksection(dr.code_section) void {
    var term: real_t = undefined;
    var squared: real_t = undefined;
    var cubed: real_t = undefined;
    var zeta3: real_t = undefined;
    var three: real_t = undefined;

    dr.realCopy(dr.const51TwoLn2(), res);
    dr.realMultiply(a, a, &squared, &dr.ctxtReal51);
    dr.realMultiply(&squared, a, &cubed, &dr.ctxtReal51);
    dr.realMultiply(dr.const51Zeta2(), a, &term, &dr.ctxtReal51);
    dr.realSubtract(res, &term, res, &dr.ctxtReal51);
    dr.int32ToReal(3, &three);
    dr.WP34S_Zeta(&three, &zeta3, &dr.ctxtReal51);
    dr.realMultiply(&zeta3, &squared, &term, &dr.ctxtReal51);
    dr.realMultiply(&term, dr.const2(), &term, &dr.ctxtReal51);
    dr.realAdd(res, &term, res, &dr.ctxtReal51);
    dr.realMultiply(dr.const51SevenZeta2SqOn5(), &cubed, &term, &dr.ctxtReal51);
    dr.realSubtract(res, &term, res, &dr.ctxtReal51);
}

// ln(Gamma((nu + 1) / 2) / (sqrt(nu pi) Gamma(nu / 2))), the density's normalisation.
fn studentTLogNormalisation(nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var half_nu: real_t = undefined;
    var x: real_t = undefined;
    var shifted_x: real_t = undefined;
    var sum: real_t = undefined;
    var shifted_sum: real_t = undefined;
    var r: real_t = undefined;
    var term: real_t = undefined;
    var value: real_t = undefined;
    const calculation_context = tCalculationContext(real_context);

    dr.realMultiply(nu, dr.const1on2(), &half_nu, calculation_context);
    if (dr.realCompareLessEqual(&half_nu, dr.const1e_12())) {
        studentTLogASeriesOverA(&half_nu, &value);
        dr.realMultiply(&half_nu, &value, &value, calculation_context);
        dr.WP34S_Ln(nu, &term, calculation_context);
        dr.realMultiply(&term, dr.const1on2(), &term, calculation_context);
        dr.realSubtract(&term, dr.const75Ln2(), &term, calculation_context);
        dr.realSubtract(&term, &value, res, calculation_context);
        return;
    }
    dr.realSubtract(&half_nu, dr.const1(), &x, calculation_context);
    dr.realAdd(&x, dr.const1on2(), &shifted_x, calculation_context);
    dr.WP34S_LanczosSum(&x, dr.const29(), &sum, calculation_context);
    dr.WP34S_LanczosSum(&shifted_x, dr.const29(), &shifted_sum, calculation_context);

    dr.realDivide(&shifted_sum, &sum, &value, calculation_context);
    dr.WP34S_Ln(&value, &value, calculation_context);

    dr.realAdd(&x, dr.constGammaR(), &r, calculation_context);
    dr.realDivide(dr.const1on2(), &r, &term, calculation_context);
    dr.WP34S_Ln1P(&term, &term, calculation_context);
    dr.realMultiply(&half_nu, &term, &term, calculation_context);
    dr.realSubtract(&term, dr.const1on2(), &term, calculation_context);
    dr.realAdd(&value, &term, &value, calculation_context);

    dr.realDivide(&r, nu, &term, calculation_context);
    dr.realDivide(&term, dr.const75Pi(), &term, calculation_context);
    dr.WP34S_Ln(&term, &term, calculation_context);
    dr.realMultiply(&term, dr.const1on2(), &term, calculation_context);
    dr.realAdd(&value, &term, res, calculation_context);
}

// ln B(1/2, nu/2).
fn studentTLogBetaHalf(nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var log_normalisation: real_t = undefined;
    var log_nu: real_t = undefined;
    const calculation_context = tCalculationContext(real_context);

    studentTLogNormalisation(nu, &log_normalisation, calculation_context);
    dr.WP34S_Ln(nu, &log_nu, calculation_context);
    dr.realMultiply(&log_nu, dr.const1on2(), &log_nu, calculation_context);
    dr.realAdd(&log_normalisation, &log_nu, res, calculation_context);
    dr.realChangeSign(res);
}

// The upper regularised beta tail from whichever continued fraction converges.
fn studentTBetaUpper(a: *const real_t, b: *const real_t, x: *const real_t, one_minus_x: *const real_t, log_prefix: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var threshold: real_t = undefined;
    var fraction: real_t = undefined;
    var value: real_t = undefined;
    var term: real_t = undefined;

    if (dr.realIsZero(x)) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsZero(one_minus_x)) {
        dr.setZero(res);
        return;
    }

    dr.realExponential(log_prefix, &value, real_context);
    dr.realAdd(a, b, &term, real_context);
    dr.realAdd(&term, dr.const2(), &term, real_context);
    dr.realAdd(a, dr.const1(), &threshold, real_context);
    dr.realDivide(&threshold, &term, &threshold, real_context);

    if (dr.realLessThan(x, &threshold)) {
        if (!dr.WP34S_BetaFraction(a, b, x, -37, 500, &fraction, real_context)) {
            dr.setNaN(res);
            return;
        }
        dr.realDivide(&fraction, a, &fraction, real_context);
        dr.realMultiply(&value, &fraction, &value, real_context);
        dr.realSubtract(dr.const1(), &value, res, real_context);
    } else {
        if (!dr.WP34S_BetaFraction(b, a, one_minus_x, -37, 500, &fraction, real_context)) {
            dr.setNaN(res);
            return;
        }
        dr.realDivide(&fraction, b, &fraction, real_context);
        dr.realMultiply(&value, &fraction, res, real_context);
    }
}

// The lower regularised beta tail straight from its continued fraction.
fn studentTBetaLowerDirect(a: *const real_t, b: *const real_t, x: *const real_t, log_prefix: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var fraction: real_t = undefined;
    var value: real_t = undefined;

    if (dr.realIsZero(x)) {
        dr.setZero(res);
        return;
    }
    if (!dr.WP34S_BetaFraction(a, b, x, -37, 500, &fraction, real_context)) {
        dr.setNaN(res);
        return;
    }
    dr.realExponential(log_prefix, &value, real_context);
    dr.realDivide(&fraction, a, &fraction, real_context);
    dr.realMultiply(&value, &fraction, res, real_context);
}

// x P(x^2) / denominator for an integer polynomial P in Horner form.
fn studentTPolynomial(x: *const real_t, x_squared: *const real_t, coefficients: []const i32, denominator: i32, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var coefficient: real_t = undefined;
    var value: real_t = undefined;
    var divisor: real_t = undefined;

    dr.int32ToReal(coefficients[0], &value);
    for (coefficients[1..]) |c| {
        dr.int32ToReal(c, &coefficient);
        dr.realFMA(&value, x_squared, &coefficient, &value, real_context);
    }
    dr.realMultiply(&value, x, &value, real_context);
    dr.int32ToReal(denominator, &divisor);
    dr.realDivide(&value, &divisor, res, real_context);
}

const q1 = [_]i32{ -1, -1 };
const q2 = [_]i32{ -3, 7, 5, 3 };
const q3 = [_]i32{ -1, 11, -14, -6, 3, 15 };
const q4 = [_]i32{ -15, 375, -2225, 2141, 939, 213, -915, -945 };

// The Cornish-Fisher correction, in powers of 1/nu, from the normal to the t probability.
fn studentTNormalAdjustment(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var x_squared: real_t = undefined;
    var inverse_nu: real_t = undefined;
    var p1: real_t = undefined;
    var p2: real_t = undefined;
    var p3: real_t = undefined;
    var p4: real_t = undefined;
    var correction: real_t = undefined;
    var density: real_t = undefined;

    dr.WP34S_Pdf_Q(x, &density, real_context);
    dr.realMultiply(x, x, &x_squared, real_context);
    dr.realDivide(dr.const1(), nu, &inverse_nu, real_context);
    studentTPolynomial(x, &x_squared, &q1, 4, &p1, real_context);
    studentTPolynomial(x, &x_squared, &q2, 96, &p2, real_context);
    studentTPolynomial(x, &x_squared, &q3, 384, &p3, real_context);
    studentTPolynomial(x, &x_squared, &q4, 92160, &p4, real_context);
    dr.realFMA(&p4, &inverse_nu, &p3, &correction, real_context);
    dr.realFMA(&correction, &inverse_nu, &p2, &correction, real_context);
    dr.realFMA(&correction, &inverse_nu, &p1, &correction, real_context);
    dr.realMultiply(&correction, &inverse_nu, &correction, real_context);
    dr.realMultiply(&density, &correction, res, real_context);
}

fn studentTNormalUpper(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var adjustment: real_t = undefined;
    var tail: real_t = undefined;

    dr.WP34S_Cdfu_Q(x, &tail, real_context);
    studentTNormalAdjustment(x, nu, &adjustment, real_context);
    dr.realSubtract(&tail, &adjustment, res, real_context);
    if (dr.realCompareLessEqual(res, dr.const0())) {
        dr.realCopy(dr.const1e_10000(), res);
    }
}

fn studentTNormalCentral(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var root_two: real_t = undefined;
    var scaled: real_t = undefined;
    var central: real_t = undefined;
    var adjustment: real_t = undefined;

    dr.realSquareRoot(dr.const2(), &root_two, real_context);
    dr.realDivide(x, &root_two, &scaled, real_context);
    dr.WP34S_Erf(&scaled, &central, real_context);
    dr.realMultiply(&central, dr.const1on2(), &central, real_context);
    if (!dr.realIsInfinite(nu)) {
        studentTNormalAdjustment(x, nu, &adjustment, real_context);
        dr.realAdd(&central, &adjustment, &central, real_context);
    }
    dr.realCopy(&central, res);
}

// The log of the beta prefix x^2/(x^2+nu) ... shared by the upper and central tails.
fn studentTLogPrefix(x: *const real_t, nu: *const real_t, beta_x: *real_t, denominator: *real_t, half_nu: *real_t, log_prefix: *real_t, calculation_context: *realContext_t) linksection(dr.code_section) void {
    var x_squared: real_t = undefined;
    var ratio: real_t = undefined;
    var log_ratio: real_t = undefined;

    dr.realMultiply(x, x, &x_squared, calculation_context);
    dr.realAdd(&x_squared, nu, denominator, calculation_context);
    dr.realDivide(&x_squared, denominator, beta_x, calculation_context);
    dr.realDivide(&x_squared, nu, &ratio, calculation_context);
    dr.WP34S_Ln(&ratio, &log_ratio, calculation_context);
    dr.WP34S_Ln1P(&ratio, log_prefix, calculation_context);
    dr.realSubtract(&log_ratio, log_prefix, &log_ratio, calculation_context);
    dr.realMultiply(&log_ratio, dr.const1on2(), &log_ratio, calculation_context);
    dr.realMultiply(nu, dr.const1on2(), half_nu, calculation_context);
    dr.realMultiply(half_nu, log_prefix, log_prefix, calculation_context);
    dr.realChangeSign(log_prefix);
    dr.realAdd(&log_ratio, log_prefix, log_prefix, calculation_context);
}

// The upper tail P(T > |x|), with ln B(1/2, nu/2) taken from the caller when known.
fn studentTUpperMagnitudeKnownBeta(x: *const real_t, nu: *const real_t, known_log_beta: ?*const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var large_nu: real_t = undefined;
    var denominator: real_t = undefined;
    var beta_x: real_t = undefined;
    var beta_complement: real_t = undefined;
    var half_nu: real_t = undefined;
    var log_beta: real_t = undefined;
    var log_prefix: real_t = undefined;
    var tail: real_t = undefined;
    const calculation_context = tCalculationContext(real_context);

    if (dr.realIsNaN(x) or dr.realIsNaN(nu) or dr.realCompareLessEqual(nu, dr.const0())) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        dr.realCopy(dr.const1on2(), res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(nu)) {
        dr.WP34S_Cdfu_Q(x, res, real_context);
        return;
    }

    dr.WP34S_SetPowerOfTen(17, &large_nu);
    if (dr.realCompareGreaterEqual(nu, &large_nu)) {
        studentTNormalUpper(x, nu, res, calculation_context);
        return;
    }

    studentTLogPrefix(x, nu, &beta_x, &denominator, &half_nu, &log_prefix, calculation_context);
    dr.realDivide(nu, &denominator, &beta_complement, calculation_context);
    if (known_log_beta) |known| {
        dr.realCopy(known, &log_beta);
    } else {
        studentTLogBetaHalf(nu, &log_beta, calculation_context);
    }
    dr.realSubtract(&log_prefix, &log_beta, &log_prefix, calculation_context);
    studentTBetaUpper(dr.const1on2(), &half_nu, &beta_x, &beta_complement, &log_prefix, &tail, calculation_context);
    dr.realMultiply(&tail, dr.const1on2(), &tail, calculation_context);
    if (dr.realIsZero(&tail)) {
        dr.realCopy(dr.const1e_10000(), &tail);
    }
    dr.realPlus(&tail, res, real_context);
}

fn studentTUpperMagnitude(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    studentTUpperMagnitudeKnownBeta(x, nu, null, res, real_context);
}

// The central probability P(0 < T < |x|).
fn studentTCentralMagnitudeKnownBeta(x: *const real_t, nu: *const real_t, known_log_beta: ?*const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var large_nu: real_t = undefined;
    var denominator: real_t = undefined;
    var beta_x: real_t = undefined;
    var half_nu: real_t = undefined;
    var log_beta: real_t = undefined;
    var log_prefix: real_t = undefined;
    var central: real_t = undefined;
    const calculation_context = tCalculationContext(real_context);

    if (dr.realIsZero(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.realCopy(dr.const1on2(), res);
        return;
    }
    dr.WP34S_SetPowerOfTen(17, &large_nu);
    if (dr.realIsInfinite(nu) or dr.realCompareGreaterEqual(nu, &large_nu)) {
        studentTNormalCentral(x, nu, res, calculation_context);
        return;
    }

    studentTLogPrefix(x, nu, &beta_x, &denominator, &half_nu, &log_prefix, calculation_context);
    if (known_log_beta) |known| {
        dr.realCopy(known, &log_beta);
    } else {
        studentTLogBetaHalf(nu, &log_beta, calculation_context);
    }
    dr.realSubtract(&log_prefix, &log_beta, &log_prefix, calculation_context);
    studentTBetaLowerDirect(dr.const1on2(), &half_nu, &beta_x, &log_prefix, &central, calculation_context);
    dr.realMultiply(&central, dr.const1on2(), &central, calculation_context);
    dr.realPlus(&central, res, real_context);
}

// The residual the quantile search drives to zero: central against delta below
// 1, upper tail against the probability above.
fn studentTInverseResidual(value: *const real_t, nu: *const real_t, known_log_beta: *const real_t, probability: *const real_t, delta: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var probability_value: real_t = undefined;

    if (dr.realLessThan(value, dr.const1())) {
        studentTCentralMagnitudeKnownBeta(value, nu, known_log_beta, &probability_value, real_context);
        dr.realSubtract(delta, &probability_value, res, real_context);
    } else {
        studentTUpperMagnitudeKnownBeta(value, nu, known_log_beta, &probability_value, real_context);
        dr.realSubtract(&probability_value, probability, res, real_context);
    }
}

pub fn wp34sPdfT(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var x_squared: real_t = undefined;
    var ratio: real_t = undefined;
    var exponent: real_t = undefined;
    var coefficient: real_t = undefined;
    var log_normalisation: real_t = undefined;
    const calculation_context = tCalculationContext(real_context);

    if (dr.realIsNaN(x) or dr.realIsNaN(nu) or dr.realCompareLessEqual(nu, dr.const0())) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsInfinite(nu)) {
        dr.WP34S_Pdf_Q(x, res, real_context);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }

    studentTLogNormalisation(nu, &log_normalisation, calculation_context);
    dr.realMultiply(x, x, &x_squared, calculation_context);
    dr.realDivide(&x_squared, nu, &ratio, calculation_context);
    dr.WP34S_Ln1P(&ratio, &exponent, calculation_context);
    dr.realAdd(nu, dr.const1(), &coefficient, calculation_context);
    dr.realMultiply(&coefficient, dr.const1on2(), &coefficient, calculation_context);
    dr.realMultiply(&exponent, &coefficient, &exponent, calculation_context);
    dr.realSubtract(&log_normalisation, &exponent, &exponent, calculation_context);
    dr.realExponential(&exponent, &exponent, calculation_context);
    if (dr.realIsZero(&exponent)) {
        dr.realCopy(dr.const1e_10000(), &exponent);
    }
    dr.realPlus(&exponent, res, real_context);
}

fn cdfT(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var magnitude: real_t = undefined;
    var tail: real_t = undefined;
    var value: real_t = undefined;
    const calculation_context = tCalculationContext(real_context);

    dr.realCopy(x, &magnitude);
    dr.realSetPositiveSign(&magnitude);
    studentTUpperMagnitude(&magnitude, nu, &tail, calculation_context);
    if (dr.realIsNegative(x)) {
        dr.realCopy(&tail, &value);
    } else {
        dr.realSubtract(dr.const1(), &tail, &value, calculation_context);
    }
    dr.realPlus(&value, res, real_context);
}

pub fn wp34sCdfuT(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var xn: real_t = undefined;

    dr.realMinus(x, &xn, real_context);
    cdfT(&xn, nu, res, real_context);
}

pub fn wp34sCdfT(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    cdfT(x, nu, res, real_context);
}

// ln(a B(a, 1/2)) / a and a B(a, 1/2) itself, for the small-nu inverse.
fn studentTLogAOverA(nu: *const real_t, a: *const real_t, a_beta: *real_t, res: *real_t) linksection(dr.code_section) void {
    var log_beta: real_t = undefined;
    var log_a: real_t = undefined;

    if (dr.realCompareLessEqual(a, dr.const1e_12())) {
        studentTLogASeriesOverA(a, res);
        dr.realMultiply(a, res, &log_a, &dr.ctxtReal51);
    } else {
        studentTLogBetaHalf(nu, &log_beta, &dr.ctxtReal51);
        dr.WP34S_Ln(a, &log_a, &dr.ctxtReal51);
        dr.realAdd(&log_a, &log_beta, &log_a, &dr.ctxtReal51);
        dr.realDivide(&log_a, a, res, &dr.ctxtReal51);
    }
    dr.realExponential(&log_a, a_beta, &dr.ctxtReal51);
}

// The hypergeometric series of the central probability in q = r^2; false when
// it has not settled in 500 terms.
fn studentTCentralSeries(a: *const real_t, q: *const real_t, res: *real_t) linksection(dr.code_section) bool {
    var sum: real_t = undefined;
    var old: real_t = undefined;
    var term: real_t = undefined;
    var k: real_t = undefined;
    var factor: real_t = undefined;
    var numerator: real_t = undefined;
    var denominator: real_t = undefined;

    dr.setOne(&sum);
    dr.setOne(&term);
    var i: i32 = 1;
    while (i <= 500) : (i += 1) {
        dr.realCopy(&sum, &old);
        dr.int32ToReal(i, &k);
        dr.realSubtract(&k, dr.const1on2(), &factor, &dr.ctxtReal51);
        dr.realSubtract(&k, a, &numerator, &dr.ctxtReal51);
        dr.realMultiply(&factor, &numerator, &numerator, &dr.ctxtReal51);
        dr.realMultiply(&numerator, q, &numerator, &dr.ctxtReal51);
        dr.realAdd(&k, dr.const1on2(), &factor, &dr.ctxtReal51);
        dr.realMultiply(&factor, &k, &denominator, &dr.ctxtReal51);
        dr.realDivide(&numerator, &denominator, &factor, &dr.ctxtReal51);
        dr.realMultiply(&term, &factor, &term, &dr.ctxtReal51);
        dr.realAdd(&sum, &term, &sum, &dr.ctxtReal51);
        if (dr.realEqual(&old, &sum)) {
            dr.realCopy(&sum, res);
            return true;
        }
    }
    dr.setNaN(res);
    return false;
}

// The tail series in z = e^-s: ln(1 + a J) / a and the derivative of the tail
// equation; false when it has not settled in 500 terms.
fn studentTTailSeries(a: *const real_t, z: *const real_t, log_h_over_a: *real_t, derivative: *real_t) linksection(dr.code_section) bool {
    var j: real_t = undefined;
    var weighted: real_t = undefined;
    var old: real_t = undefined;
    var base: real_t = undefined;
    var term: real_t = undefined;
    var k: real_t = undefined;
    var factor: real_t = undefined;
    var denominator: real_t = undefined;
    var a_j: real_t = undefined;
    var h: real_t = undefined;

    dr.setZero(&j);
    dr.setZero(&weighted);
    dr.setOne(&base);
    var i: i32 = 1;
    while (i <= 500) : (i += 1) {
        dr.realCopy(&j, &old);
        dr.int32ToReal(i, &k);
        dr.realSubtract(&k, dr.const1on2(), &factor, &dr.ctxtReal51);
        dr.realMultiply(&factor, z, &factor, &dr.ctxtReal51);
        dr.realDivide(&factor, &k, &factor, &dr.ctxtReal51);
        dr.realMultiply(&base, &factor, &base, &dr.ctxtReal51);
        dr.realAdd(a, &k, &denominator, &dr.ctxtReal51);
        dr.realDivide(&base, &denominator, &term, &dr.ctxtReal51);
        dr.realAdd(&j, &term, &j, &dr.ctxtReal51);
        dr.realFMA(&k, &term, &weighted, &weighted, &dr.ctxtReal51);
        if (dr.realEqual(&old, &j)) {
            dr.realMultiply(a, &j, &a_j, &dr.ctxtReal51);
            dr.realAdd(dr.const1(), &a_j, &h, &dr.ctxtReal51);
            dr.WP34S_Ln1P(&a_j, log_h_over_a, &dr.ctxtReal51);
            dr.realDivide(log_h_over_a, a, log_h_over_a, &dr.ctxtReal51);
            dr.realDivide(&weighted, &h, derivative, &dr.ctxtReal51);
            dr.realAdd(derivative, dr.const1(), derivative, &dr.ctxtReal51);
            return true;
        }
    }
    dr.setNaN(log_h_over_a);
    dr.setNaN(derivative);
    return false;
}

// The tail equation in s and its derivative; false when the series fails.
fn studentTTailEquation(s: *const real_t, a: *const real_t, log_a_over_a: *const real_t, log_two_p_over_a: *const real_t, value: *real_t, derivative: *real_t) linksection(dr.code_section) bool {
    var z: real_t = undefined;
    var log_h_over_a: real_t = undefined;

    dr.realMinus(s, &z, &dr.ctxtReal51);
    dr.realExponential(&z, &z, &dr.ctxtReal51);
    if (!studentTTailSeries(a, &z, &log_h_over_a, derivative)) {
        dr.setNaN(value);
        return false;
    }
    dr.realAdd(s, log_a_over_a, value, &dr.ctxtReal51);
    dr.realSubtract(value, &log_h_over_a, value, &dr.ctxtReal51);
    dr.realAdd(value, log_two_p_over_a, value, &dr.ctxtReal51);
    return true;
}

// The quantile for nu below 1: a bisection in r = x / sqrt(x^2 + nu) when the
// target sits in the central series, else a bracketed Newton search in
// s = ln(1 + x^2 / nu).
fn studentTSmallNuInverse(probability: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var a: real_t = undefined;
    var a_beta: real_t = undefined;
    var log_a_over_a: real_t = undefined;
    var delta: real_t = undefined;
    var target: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var series: real_t = undefined;
    var boundary: real_t = undefined;
    var low: real_t = undefined;
    var high: real_t = undefined;
    var midpoint: real_t = undefined;
    var value: real_t = undefined;
    var tolerance: real_t = undefined;
    var one_minus_q: real_t = undefined;
    var root_nu: real_t = undefined;
    var denominator: real_t = undefined;
    var log_two_p: real_t = undefined;
    var log_two_p_over_a: real_t = undefined;
    var base: real_t = undefined;
    var low_s: real_t = undefined;
    var high_s: real_t = undefined;
    var estimate: real_t = undefined;
    var derivative: real_t = undefined;
    var step: real_t = undefined;
    var ln_nu: real_t = undefined;
    var limit: real_t = undefined;
    var maximum: real_t = undefined;
    var exponent_term: real_t = undefined;

    dr.realMultiply(nu, dr.const1on2(), &a, &dr.ctxtReal51);
    studentTLogAOverA(nu, &a, &a_beta, &log_a_over_a);
    dr.realSubtract(dr.const1on2(), probability, &delta, &dr.ctxtReal51);
    dr.realMultiply(&delta, &a_beta, &target, &dr.ctxtReal51);
    dr.realDivide(&target, &a, &target, &dr.ctxtReal51);
    dr.realCopy(dr.const1on4(), &q);
    dr.realCopy(dr.const1on2(), &r);
    if (!studentTCentralSeries(&a, &q, &series)) {
        dr.setNaN(res);
        return;
    }
    dr.realMultiply(&r, &series, &boundary, &dr.ctxtReal51);
    dr.WP34S_SetPowerOfTen(-40, &tolerance);

    if (dr.realCompareLessEqual(&target, &boundary)) {
        dr.setZero(&low);
        dr.realCopy(dr.const1on2(), &high);
        var iterations: i32 = 0;
        while (iterations < 300) : (iterations += 1) {
            dr.realAdd(&low, &high, &midpoint, &dr.ctxtReal51);
            dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, &dr.ctxtReal51);
            dr.realMultiply(&midpoint, &midpoint, &q, &dr.ctxtReal51);
            if (!studentTCentralSeries(&a, &q, &series)) {
                dr.setNaN(res);
                return;
            }
            dr.realMultiply(&midpoint, &series, &value, &dr.ctxtReal51);
            if (dr.realLessThan(&value, &target)) {
                dr.realCopy(&midpoint, &low);
            } else {
                dr.realCopy(&midpoint, &high);
            }
            if (dr.WP34S_RelativeError(&high, &low, &tolerance, &dr.ctxtReal51)) {
                break;
            }
        }
        dr.realAdd(&low, &high, &r, &dr.ctxtReal51);
        dr.realMultiply(&r, dr.const1on2(), &r, &dr.ctxtReal51);
        dr.realMultiply(&r, &r, &q, &dr.ctxtReal51);
        dr.realSubtract(dr.const1(), &q, &one_minus_q, &dr.ctxtReal51);
        dr.realSquareRoot(nu, &root_nu, &dr.ctxtReal51);
        dr.realSquareRoot(&one_minus_q, &denominator, &dr.ctxtReal51);
        dr.realMultiply(&root_nu, &r, &value, &dr.ctxtReal51);
        dr.realDivide(&value, &denominator, &value, &dr.ctxtReal51);
        dr.realPlus(&value, res, real_context);
        return;
    }

    if (dr.realLessThan(probability, dr.const1on4())) {
        dr.WP34S_Ln(probability, &log_two_p, &dr.ctxtReal51);
        dr.realAdd(&log_two_p, dr.const75Ln2(), &log_two_p, &dr.ctxtReal51);
    } else {
        dr.realMultiply(&delta, dr.const2(), &log_two_p, &dr.ctxtReal51);
        dr.realChangeSign(&log_two_p);
        dr.WP34S_Ln1P(&log_two_p, &log_two_p, &dr.ctxtReal51);
    }
    dr.realDivide(&log_two_p, &a, &log_two_p_over_a, &dr.ctxtReal51);
    dr.realAdd(&log_a_over_a, &log_two_p_over_a, &base, &dr.ctxtReal51);
    dr.realChangeSign(&base);

    dr.WP34S_Ln(nu, &ln_nu, &dr.ctxtReal51);
    dr.int32ToReal(12290, &limit);
    dr.realMultiply(&limit, dr.const75Ln10(), &limit, &dr.ctxtReal51);
    dr.realAdd(&ln_nu, &base, &exponent_term, &dr.ctxtReal51);
    dr.realSubtract(&exponent_term, dr.const1(), &exponent_term, &dr.ctxtReal51);
    if (dr.realGreaterThan(&exponent_term, &limit)) {
        dr.WP34S_SetPowerOfTen(10000, &maximum);
        dr.realCopy(&maximum, res);
        return;
    }

    dr.realCopy(dr.const51OneOn3(), &low_s);
    dr.WP34S_Ln1P(&low_s, &low_s, &dr.ctxtReal51);
    dr.realAdd(&base, dr.const10(), &high_s, &dr.ctxtReal51);
    if (dr.realCompareLessEqual(&high_s, &low_s)) {
        dr.realMultiply(&low_s, dr.const2(), &high_s, &dr.ctxtReal51);
    }
    var iterations: i32 = 0;
    while (iterations < 100) : (iterations += 1) {
        if (!studentTTailEquation(&high_s, &a, &log_a_over_a, &log_two_p_over_a, &value, &derivative)) {
            dr.setNaN(res);
            return;
        }
        if (!dr.realIsNegative(&value)) {
            break;
        }
        dr.realMultiply(&high_s, dr.const2(), &high_s, &dr.ctxtReal51);
    }
    if (iterations == 100) {
        dr.setNaN(res);
        return;
    }

    dr.realAdd(&low_s, &high_s, &estimate, &dr.ctxtReal51);
    dr.realMultiply(&estimate, dr.const1on2(), &estimate, &dr.ctxtReal51);
    iterations = 0;
    while (iterations < 200) : (iterations += 1) {
        if (!studentTTailEquation(&estimate, &a, &log_a_over_a, &log_two_p_over_a, &value, &derivative)) {
            dr.setNaN(res);
            return;
        }
        if (dr.realIsZero(&value)) {
            break;
        }
        if (dr.realIsNegative(&value)) {
            dr.realCopy(&estimate, &low_s);
        } else {
            dr.realCopy(&estimate, &high_s);
        }
        if (dr.WP34S_RelativeError(&high_s, &low_s, &tolerance, &dr.ctxtReal51)) {
            dr.realAdd(&low_s, &high_s, &estimate, &dr.ctxtReal51);
            dr.realMultiply(&estimate, dr.const1on2(), &estimate, &dr.ctxtReal51);
            break;
        }
        if (iterations < 24) {
            dr.realDivide(&value, &derivative, &step, &dr.ctxtReal51);
            dr.realSubtract(&estimate, &step, &midpoint, &dr.ctxtReal51);
        }
        if (iterations >= 24 or dr.realCompareLessEqual(&midpoint, &low_s) or dr.realCompareGreaterEqual(&midpoint, &high_s)) {
            dr.realAdd(&low_s, &high_s, &midpoint, &dr.ctxtReal51);
            dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, &dr.ctxtReal51);
        }
        dr.realCopy(&midpoint, &estimate);
    }

    dr.WP34S_ExpM1(&estimate, &value, &dr.ctxtReal51);
    dr.realMultiply(nu, &value, &value, &dr.ctxtReal51);
    dr.realSquareRoot(&value, &value, &dr.ctxtReal51);
    dr.realPlus(&value, res, real_context);
}

pub fn wp34sQfT(x: *const real_t, nu: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var probability: real_t = undefined;
    var log_probability: real_t = undefined;
    var log_nu: real_t = undefined;
    var log_beta: real_t = undefined;
    var log_estimate: real_t = undefined;
    var estimate: real_t = undefined;
    var normal_estimate: real_t = undefined;
    var log_test: real_t = undefined;
    var low: real_t = undefined;
    var high: real_t = undefined;
    var value: real_t = undefined;
    var density: real_t = undefined;
    var residual: real_t = undefined;
    var step: real_t = undefined;
    var correction: real_t = undefined;
    var denominator: real_t = undefined;
    var midpoint: real_t = undefined;
    var tolerance: real_t = undefined;
    var maximum: real_t = undefined;
    var delta: real_t = undefined;
    var neg = false;
    const work_context = &dr.ctxtReal39;

    if (dr.realIsNaN(x) or dr.realCompareLessEqual(x, dr.const0()) or dr.realCompareGreaterEqual(x, dr.const1()) or dr.realIsNaN(nu) or dr.realCompareLessEqual(nu, dr.const0())) {
        dr.setNaN(res);
        return;
    }
    if (dr.realEqual(x, dr.const1on2())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(nu)) {
        dr.WP34S_Qf_Q(x, res, real_context);
        return;
    }
    dr.WP34S_SetPowerOfTen(10000, &maximum);

    dr.realSubtract(dr.const1(), x, &probability, work_context);
    if (dr.realLessThan(x, &probability)) {
        neg = true;
        dr.realCopy(x, &probability);
    }
    if (dr.realLessThan(nu, dr.const1())) {
        studentTSmallNuInverse(&probability, nu, res, &dr.ctxtReal51);
        if (neg) {
            dr.realChangeSign(res);
        }
        dr.realPlus(res, res, real_context);
        return;
    }
    dr.realSubtract(dr.const1on2(), &probability, &delta, work_context);

    dr.WP34S_qf_q_est(&probability, &normal_estimate, null, work_context);
    dr.realSetPositiveSign(&normal_estimate);
    studentTLogBetaHalf(nu, &log_beta, work_context);
    dr.WP34S_Ln(nu, &log_nu, work_context);
    dr.WP34S_Ln(&probability, &log_probability, work_context);
    dr.realAdd(&log_nu, &log_beta, &log_estimate, work_context);
    dr.realAdd(&log_estimate, &log_probability, &log_estimate, work_context);
    dr.realDivide(&log_estimate, nu, &log_estimate, work_context);
    dr.realMultiply(&log_nu, dr.const1on2(), &estimate, work_context);
    dr.realSubtract(&estimate, &log_estimate, &log_estimate, work_context);
    dr.realMultiply(&log_estimate, dr.const2(), &log_test, work_context);
    dr.realAdd(&log_nu, dr.const75Ln10(), &estimate, work_context);
    if (dr.realGreaterThan(&log_test, &estimate)) {
        dr.realExponential(&log_estimate, &estimate, work_context);
        if (dr.realIsInfinite(&estimate)) {
            dr.realCopy(&maximum, &estimate);
        }
    } else {
        dr.realCopy(&normal_estimate, &estimate);
    }

    // Every exit from here passes through the sign fix at the end.
    search: {
        studentTInverseResidual(&estimate, nu, &log_beta, &probability, &delta, &residual, work_context);
        if (dr.realIsNaN(&residual)) {
            dr.setNaN(res);
            break :search;
        }
        if (dr.realIsZero(&residual)) {
            dr.realCopy(&estimate, res);
            break :search;
        }
        if (dr.realIsPositive(&residual)) {
            dr.realCopy(&estimate, &low);
            while (true) {
                dr.realMultiply(&estimate, dr.const2(), &high, work_context);
                if (dr.realCompareGreaterEqual(&high, &maximum)) {
                    dr.realCopy(&maximum, &high);
                }
                studentTInverseResidual(&high, nu, &log_beta, &probability, &delta, &residual, work_context);
                if (dr.realIsNaN(&residual)) {
                    dr.setNaN(res);
                    break :search;
                }
                if (!dr.realIsPositive(&residual)) {
                    break;
                }
                if (dr.realEqual(&high, &maximum)) {
                    dr.realCopy(&high, res);
                    break :search;
                }
                dr.realCopy(&high, &low);
                dr.realCopy(&high, &estimate);
            }
        } else {
            dr.realCopy(&estimate, &high);
            while (true) {
                dr.realMultiply(&estimate, dr.const1on2(), &low, work_context);
                studentTInverseResidual(&low, nu, &log_beta, &probability, &delta, &residual, work_context);
                if (dr.realIsNaN(&residual)) {
                    dr.setNaN(res);
                    break :search;
                }
                if (!dr.realIsNegative(&residual) or dr.realIsZero(&low)) {
                    break;
                }
                dr.realCopy(&low, &high);
                dr.realCopy(&low, &estimate);
            }
        }

        dr.realCopy(&estimate, &value);
        dr.WP34S_SetPowerOfTen(-37, &tolerance);
        var iterations: i32 = 0;
        while (iterations < 160) : (iterations += 1) {
            studentTInverseResidual(&value, nu, &log_beta, &probability, &delta, &residual, work_context);
            if (dr.realIsNaN(&residual)) {
                dr.setNaN(res);
                break :search;
            }
            if (dr.realIsZero(&residual)) {
                dr.realCopy(&value, res);
                break :search;
            }
            if (dr.realIsPositive(&residual)) {
                dr.realCopy(&value, &low);
            } else {
                dr.realCopy(&value, &high);
            }
            if (dr.WP34S_RelativeError(&high, &low, &tolerance, work_context)) {
                dr.realAdd(&low, &high, &midpoint, work_context);
                dr.realMultiply(&midpoint, dr.const1on2(), res, work_context);
                break :search;
            }

            wp34sPdfT(&value, nu, &density, work_context);
            var use_bisection = iterations >= 24 or dr.realIsZero(&density) or dr.realIsSpecial(&density);
            if (!use_bisection) {
                dr.realDivide(&residual, &density, &step, work_context);
                dr.realAdd(nu, dr.const1(), &correction, work_context);
                dr.realMultiply(&correction, &value, &correction, work_context);
                dr.realMultiply(&correction, &step, &correction, work_context);
                dr.realMultiply(&value, &value, &denominator, work_context);
                dr.realAdd(&denominator, nu, &denominator, work_context);
                dr.realMultiply(&denominator, dr.const2(), &denominator, work_context);
                dr.realDivide(&correction, &denominator, &correction, work_context);
                dr.realSubtract(dr.const1(), &correction, &correction, work_context);
                dr.realDivide(&step, &correction, &step, work_context);
                dr.realAdd(&value, &step, &estimate, work_context);
                use_bisection = dr.realIsSpecial(&estimate) or dr.realCompareLessEqual(&estimate, &low) or dr.realCompareGreaterEqual(&estimate, &high);
            }
            if (use_bisection) {
                dr.realAdd(&low, &high, &estimate, work_context);
                dr.realMultiply(&estimate, dr.const1on2(), &estimate, work_context);
            }
            dr.realCopy(&estimate, &value);
        }

        dr.realAdd(&low, &high, &midpoint, work_context);
        dr.realMultiply(&midpoint, dr.const1on2(), res, work_context);
    }

    // qf_t_exit
    if (neg) {
        dr.realChangeSign(res);
    }
}
