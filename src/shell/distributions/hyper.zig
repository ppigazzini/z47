// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/hyper.c: the hypergeometric distribution
// commands and the kernels behind them. The entry points load register X, the
// population in M, the draws in N and the successes in Q through
// WP34S_CheckDistributionParameters and keep their own bodies, since the
// hypergeometric has no row in the descriptor table. The mass comes from log
// binomials, or from a saddle-point expansion with Stirling corrections once the
// population passes 1E12; the probabilities sum the smaller tail from the mode,
// or take the normal once the standard deviation passes 1E37. Tagged
// linksection(dr.code_section) so the code runs from QSPI on the flash-limited
// old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// hyperCheckDomain: integer N, n and K with 0 <= K <= N, 0 <= n <= N, and x not NaN.
fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = parameter;
    if (!registers_valid) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DATA_TYPE_FOR_OP, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function hyperCheckDomain:", "Values in register X, I, J and K must be of the real or long integer type", null, null);
        return false;
    }
    const i = first.?;
    const j = second.?;
    const k = third.?;

    if (!dr.checkRegisterNoFP(i) or !dr.checkRegisterNoFP(j) or !dr.checkRegisterNoFP(k) or dr.realIsSpecial(i) or dr.realIsSpecial(j) or dr.realIsSpecial(k)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function hyperCheckDomain:", "N, n and/or K is not an integer", null, null);
        return false;
    }
    if (dr.realIsNaN(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function hyperCheckDomain:", "x is NaN", null, null);
        return false;
    }
    if (dr.realIsNegative(k) or dr.realGreaterThan(k, i) or dr.realIsNegative(j) or dr.realGreaterThan(j, i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function hyperCheckDomain:", "the parameters must be integer, and 0 \xa2\x64 K \xa2\x64 N, 0 \xa2\x64 n \xa2\x64 N, and N \xa2\x65 0", null, null);
        return false;
    }
    return true;
}

fn hyperParameters(val: *real_t, batch: *real_t, samp: *real_t, spec: *real_t) linksection(dr.code_section) bool {
    return dr.WP34S_CheckDistributionParameters(val, dr.REGISTER_M, batch, dr.REGISTER_N, samp, dr.REGISTER_Q, spec, 0, checkDomain);
}

// The parameter error the three forward commands report on a NaN result.
fn hyperReportOrStore(ans: *const real_t, comptime function_name: [*:0]const u8) linksection(dr.code_section) void {
    if (dr.realIsNaN(ans)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError(function_name, "a parameter is invalid", null, null);
    } else {
        dr.convertRealToResultRegister(ans, dr.REGISTER_X, dr.amNone);
    }
    dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
}

pub fn hypergeometricP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (hyperParameters(&val, &batch, &samp, &spec)) {
        if (dr.isAnInteger(&val)) {
            pdfHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal39);
        } else {
            dr.setZero(&ans);
        }
        hyperReportOrStore(&ans, "In function fnHypergeometricP:");
    }
}

pub fn hypergeometricL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (hyperParameters(&val, &batch, &samp, &spec)) {
        cdfHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal39);
        hyperReportOrStore(&ans, "In function fnHypergeometricL:");
    }
}

pub fn hypergeometricR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (hyperParameters(&val, &batch, &samp, &spec)) {
        cdfuHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal39);
        hyperReportOrStore(&ans, "In function fnHypergeometricR:");
    }
}

pub fn hypergeometricI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (hyperParameters(&val, &batch, &samp, &spec)) {
        if (dr.realLessThan(&val, dr.const0()) or dr.realGreaterThan(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function fnHypergeometricI:", "the argument must be 0 \xa2\x64 x \xa2\x64 1", null, null);
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.setNaN(&ans);
                dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
            }
            return;
        }
        qfHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function fnHypergeometricI:", "WP34S_Qf_Binomial did not converge", null, null);
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
            }
            return;
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

// Whether K, n and N define a hypergeometric distribution.
fn hyperParametersAreValid(k0: *const real_t, n: *const real_t, n0: *const real_t) linksection(dr.code_section) bool {
    return !dr.realIsSpecial(k0) and !dr.realIsSpecial(n) and !dr.realIsSpecial(n0) and dr.isAnInteger(k0) and dr.isAnInteger(n) and dr.isAnInteger(n0) and
        dr.realCompareGreaterEqual(k0, dr.const0()) and dr.realCompareGreaterEqual(n, dr.const0()) and dr.realCompareGreaterEqual(n0, dr.const0()) and
        dr.realCompareLessEqual(k0, n0) and dr.realCompareLessEqual(n, n0);
}

// The working context: the caller's above 51 digits, else 51 up to a population
// of 1E6 and 75 beyond.
fn hyperCalculationContext(n0: *const real_t, real_context: *realContext_t) linksection(dr.code_section) *realContext_t {
    var threshold: real_t = undefined;

    dr.setOne(&threshold);
    threshold.exponent = 6;
    if (real_context.digits > 51) {
        return real_context;
    }
    return if (dr.realCompareLessEqual(n0, &threshold)) &dr.ctxtReal51 else &dr.ctxtReal75;
}

// The support [max(0, K + n - N), min(K, n)].
fn hyperSupport(k0: *const real_t, n: *const real_t, n0: *const real_t, lower: *real_t, upper: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    dr.realAdd(k0, n, lower, real_context);
    dr.realSubtract(lower, n0, lower, real_context);
    if (dr.realIsNegative(lower)) {
        dr.setZero(lower);
    }
    dr.realCopy(if (dr.realLessThan(k0, n)) k0 else n, upper);
}

// Reflect K and n below N/2, mirroring x each time, so the smaller tail is summed.
fn hyperStandardise(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, standard_x: *real_t, standard_k: *real_t, standard_n: *real_t, reflected: *bool, real_context: *realContext_t) linksection(dr.code_section) void {
    var half: real_t = undefined;

    dr.realCopy(x, standard_x);
    dr.realCopy(k0, standard_k);
    dr.realCopy(n, standard_n);
    reflected.* = false;
    dr.realMultiply(n0, dr.const1on2(), &half, real_context);
    if (dr.realGreaterThan(standard_k, &half)) {
        dr.realSubtract(standard_n, standard_x, standard_x, real_context);
        dr.realSubtract(n0, standard_k, standard_k, real_context);
        reflected.* = !reflected.*;
    }
    if (dr.realGreaterThan(standard_n, &half)) {
        dr.realSubtract(standard_k, standard_x, standard_x, real_context);
        dr.realSubtract(n0, standard_n, standard_n, real_context);
        reflected.* = !reflected.*;
    }
}

// ln C(total, selected): logCyx up to 51 digits, the log beta above.
fn hyperLogCombination(total: *const real_t, selected: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var logarithm: real_t = undefined;

    if (real_context.digits <= 51) {
        dr.realCopy(total, &a);
        dr.realCopy(selected, &b);
        dr.logCyxReal(&a, &b, res, real_context);
        return;
    }
    dr.realAdd(selected, dr.const1(), &a, &dr.ctxtReal75);
    dr.realSubtract(total, selected, &b, &dr.ctxtReal75);
    dr.realAdd(&b, dr.const1(), &b, &dr.ctxtReal75);
    dr.C47_LnBetaPositiveReal(&a, &b, res);
    dr.realAdd(total, dr.const1(), &a, &dr.ctxtReal75);
    dr.WP34S_Ln(&a, &logarithm, &dr.ctxtReal75);
    dr.realAdd(res, &logarithm, res, &dr.ctxtReal75);
    dr.realChangeSign(res);
}

// (1 + v) ln(1 + v) - v, by its series below |v| = 1E-6.
fn hyperLogOnePlusProduct(value: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var factor: real_t = undefined;
    var index_real: real_t = undefined;
    var next_index: real_t = undefined;
    var previous: real_t = undefined;
    var term: real_t = undefined;

    if (!dr.realCompareAbsLessThan(value, dr.const1e_6())) {
        dr.WP34S_Ln1P(value, &term, real_context);
        dr.realAdd(dr.const1(), value, &factor, real_context);
        dr.realMultiply(&factor, &term, res, real_context);
        dr.realSubtract(res, value, res, real_context);
        return;
    }
    dr.realMultiply(value, value, &term, real_context);
    dr.realMultiply(&term, dr.const1on2(), &term, real_context);
    dr.realCopy(&term, res);
    var index: i32 = 2;
    while (index < 160) : (index += 1) {
        dr.realCopy(res, &previous);
        dr.realMultiply(&term, value, &term, real_context);
        dr.realChangeSign(&term);
        dr.int32ToReal(index - 1, &index_real);
        dr.int32ToReal(index + 1, &next_index);
        dr.realMultiply(&term, &index_real, &term, real_context);
        dr.realDivide(&term, &next_index, &term, real_context);
        dr.realAdd(res, &term, res, real_context);
        if (dr.realEqual(res, &previous)) {
            break;
        }
    }
}

// Numerator and denominator of the Stirling series coefficients, highest order first.
const stirling_coefficients = [_][2]i32{
    .{ 43867, 244188 },
    .{ -3617, 122400 },
    .{ 7, 1092 },
    .{ -691, 360360 },
    .{ 1, 1188 },
    .{ -1, 1680 },
    .{ 1, 1260 },
    .{ -1, 360 },
    .{ 1, 12 },
};

// The Stirling series correction ln Gamma(v + 1) - (v + 1/2) ln v + v - ln sqrt(2 pi), in 1/v.
fn hyperStirlingCorrection(value: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var coefficient: real_t = undefined;
    var denominator: real_t = undefined;
    var inverse: real_t = undefined;
    var inverse_square: real_t = undefined;

    dr.realDivide(dr.const1(), value, &inverse, real_context);
    dr.realMultiply(&inverse, &inverse, &inverse_square, real_context);
    dr.int32ToReal(stirling_coefficients[0][0], res);
    dr.int32ToReal(stirling_coefficients[0][1], &denominator);
    dr.realDivide(res, &denominator, res, real_context);
    for (stirling_coefficients[1..]) |pair| {
        dr.int32ToReal(pair[0], &coefficient);
        dr.int32ToReal(pair[1], &denominator);
        dr.realDivide(&coefficient, &denominator, &coefficient, real_context);
        dr.realFMA(res, &inverse_square, &coefficient, res, real_context);
    }
    dr.realMultiply(res, &inverse, res, real_context);
}

// One cell's contribution to the deviance: expected ((1 + r) ln(1 + r) - r) with r = +-delta / expected.
fn hyperDevianceContribution(expected: *const real_t, delta: *const real_t, negative: bool, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var ratio: real_t = undefined;

    dr.realDivide(delta, expected, &ratio, real_context);
    if (negative) {
        dr.realChangeSign(&ratio);
    }
    hyperLogOnePlusProduct(&ratio, res, real_context);
    dr.realMultiply(res, expected, res, real_context);
}

// The log mass by the saddle-point expansion of the 2x2 table at 75 digits.
fn hyperSaddleLogMass(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t) linksection(dr.code_section) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var correction: real_t = undefined;
    var d: real_t = undefined;
    var delta: real_t = undefined;
    var deviance: real_t = undefined;
    var expected: real_t = undefined;
    var logarithm: real_t = undefined;
    var n_minus_k: real_t = undefined;
    var n_minus_n: real_t = undefined;
    var term: real_t = undefined;
    const real_context = &dr.ctxtReal75;

    dr.realSubtract(k0, x, &b, real_context);
    dr.realSubtract(n, x, &c, real_context);
    dr.realSubtract(n0, k0, &n_minus_k, real_context);
    dr.realSubtract(n0, n, &n_minus_n, real_context);
    dr.realSubtract(&n_minus_k, &c, &d, real_context);
    dr.realMultiply(k0, n, &expected, real_context);
    dr.realDivide(&expected, n0, &expected, real_context);
    dr.realSubtract(x, &expected, &delta, real_context);
    hyperDevianceContribution(&expected, &delta, false, &deviance, real_context);
    dr.realMultiply(k0, &n_minus_n, &expected, real_context);
    dr.realDivide(&expected, n0, &expected, real_context);
    hyperDevianceContribution(&expected, &delta, true, &term, real_context);
    dr.realAdd(&deviance, &term, &deviance, real_context);
    dr.realMultiply(&n_minus_k, n, &expected, real_context);
    dr.realDivide(&expected, n0, &expected, real_context);
    hyperDevianceContribution(&expected, &delta, true, &term, real_context);
    dr.realAdd(&deviance, &term, &deviance, real_context);
    dr.realMultiply(&n_minus_k, &n_minus_n, &expected, real_context);
    dr.realDivide(&expected, n0, &expected, real_context);
    hyperDevianceContribution(&expected, &delta, false, &term, real_context);
    dr.realAdd(&deviance, &term, &deviance, real_context);

    dr.WP34S_Ln(dr.const75TwoPi(), res, real_context);
    dr.realChangeSign(res);
    dr.WP34S_Ln(k0, &logarithm, real_context);
    dr.realAdd(res, &logarithm, res, real_context);
    dr.WP34S_Ln(&n_minus_k, &logarithm, real_context);
    dr.realAdd(res, &logarithm, res, real_context);
    dr.WP34S_Ln(n, &logarithm, real_context);
    dr.realAdd(res, &logarithm, res, real_context);
    dr.WP34S_Ln(&n_minus_n, &logarithm, real_context);
    dr.realAdd(res, &logarithm, res, real_context);
    dr.WP34S_Ln(n0, &logarithm, real_context);
    dr.realSubtract(res, &logarithm, res, real_context);
    dr.realCopy(x, &a);
    dr.WP34S_Ln(&a, &logarithm, real_context);
    dr.realSubtract(res, &logarithm, res, real_context);
    dr.WP34S_Ln(&b, &logarithm, real_context);
    dr.realSubtract(res, &logarithm, res, real_context);
    dr.WP34S_Ln(&c, &logarithm, real_context);
    dr.realSubtract(res, &logarithm, res, real_context);
    dr.WP34S_Ln(&d, &logarithm, real_context);
    dr.realSubtract(res, &logarithm, res, real_context);
    dr.realMultiply(res, dr.const1on2(), res, real_context);
    dr.realSubtract(res, &deviance, res, real_context);

    dr.setZero(&correction);
    hyperStirlingCorrection(k0, &term, real_context);
    dr.realAdd(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(&n_minus_k, &term, real_context);
    dr.realAdd(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(n, &term, real_context);
    dr.realAdd(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(&n_minus_n, &term, real_context);
    dr.realAdd(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(n0, &term, real_context);
    dr.realSubtract(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(&a, &term, real_context);
    dr.realSubtract(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(&b, &term, real_context);
    dr.realSubtract(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(&c, &term, real_context);
    dr.realSubtract(&correction, &term, &correction, real_context);
    hyperStirlingCorrection(&d, &term, real_context);
    dr.realSubtract(&correction, &term, &correction, real_context);
    dr.realAdd(res, &correction, res, real_context);
}

// The log mass: the saddle point once the population passes 1E12 and every cell
// 1000 at 75 digits, else the three log binomials.
fn hyperLogMass(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var d: real_t = undefined;
    var minimum: real_t = undefined;
    var n_minus_k: real_t = undefined;
    var threshold: real_t = undefined;

    dr.realSubtract(k0, x, &b, &dr.ctxtReal75);
    dr.realSubtract(n, x, &c, &dr.ctxtReal75);
    dr.realSubtract(n0, k0, &n_minus_k, &dr.ctxtReal75);
    dr.realSubtract(&n_minus_k, &c, &d, &dr.ctxtReal75);
    dr.realCopy(x, &minimum);
    if (dr.realLessThan(&b, &minimum)) {
        dr.realCopy(&b, &minimum);
    }
    if (dr.realLessThan(&c, &minimum)) {
        dr.realCopy(&c, &minimum);
    }
    if (dr.realLessThan(&d, &minimum)) {
        dr.realCopy(&d, &minimum);
    }
    dr.setOne(&threshold);
    threshold.exponent = 12;
    if (real_context.digits > 51 and dr.realCompareGreaterEqual(n0, &threshold) and dr.realCompareGreaterEqual(&minimum, dr.const1000())) {
        hyperSaddleLogMass(x, k0, n, n0, res);
        return;
    }
    hyperLogCombination(k0, x, res, real_context);
    hyperLogCombination(&n_minus_k, &c, &a, real_context);
    dr.realAdd(res, &a, res, real_context);
    hyperLogCombination(n0, n, &a, real_context);
    dr.realSubtract(res, &a, res, real_context);
}

fn hyperMassStandard(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var logarithm: real_t = undefined;

    hyperLogMass(x, k0, n, n0, &logarithm, real_context);
    dr.realExponential(&logarithm, res, real_context);
    if (dr.realIsZero(res)) {
        dr.realNextToward(res, dr.const1(), res, real_context);
    }
}

// Round a value below the smallest 39-digit real to it or to zero as the
// current rounding mode directs.
fn hyperAdjustPositiveUnderflow(value: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var half_minimum: real_t = undefined;
    var minimum: real_t = undefined;
    var round_up = false;

    if (real_context.digits > 39) {
        return;
    }
    dr.WP34S_SetPowerOfTen(-6176, &minimum);
    if (!dr.realIsZero(value) and dr.realCompareGreaterEqual(value, &minimum)) {
        return;
    }
    dr.realMultiply(&minimum, dr.const1on2(), &half_minimum, &dr.ctxtReal39);
    switch (dr.roundingModeTable[dr.roundingMode]) {
        dr.DEC_ROUND_HALF_EVEN, dr.DEC_ROUND_HALF_DOWN => round_up = !dr.realIsZero(value) and dr.realGreaterThan(value, &half_minimum),
        dr.DEC_ROUND_HALF_UP => round_up = !dr.realIsZero(value) and dr.realCompareGreaterEqual(value, &half_minimum),
        dr.DEC_ROUND_UP, dr.DEC_ROUND_CEILING => round_up = true,
        else => {},
    }
    dr.realCopy(if (round_up) &minimum else dr.const0(), value);
}

// Shorten a probability into the result, keeping a value that is not 1/2 off it.
fn hyperRoundProbability(value: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var adjusted: real_t = undefined;

    dr.realCopy(value, &adjusted);
    hyperAdjustPositiveUnderflow(&adjusted, real_context);
    dr.realPlus(&adjusted, res, real_context);
    if (dr.realEqual(res, dr.const1on2()) and !dr.realEqual(value, dr.const1on2())) {
        dr.realNextToward(res, if (dr.realGreaterThan(value, dr.const1on2())) dr.const1() else dr.const0(), res, real_context);
    }
}

// The mode floor((K + 1)(n + 1) / (N + 2)).
fn hyperMode(k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var denominator: real_t = undefined;
    var product: real_t = undefined;

    dr.realAdd(k0, dr.const1(), &product, real_context);
    dr.realAdd(n, dr.const1(), &denominator, real_context);
    dr.realMultiply(&product, &denominator, &product, real_context);
    dr.realAdd(n0, dr.const2(), &denominator, real_context);
    dr.realDivide(&product, &denominator, &product, real_context);
    dr.toIntegralValue(&product, res, dr.DEC_ROUND_FLOOR, real_context);
}

fn hyperMoments(k0: *const real_t, n: *const real_t, n0: *const real_t, mean: *real_t, standard_deviation: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var factor: real_t = undefined;
    var variance: real_t = undefined;

    dr.realMultiply(k0, n, mean, real_context);
    dr.realDivide(mean, n0, mean, real_context);
    dr.realSubtract(n0, k0, &factor, real_context);
    dr.realDivide(&factor, n0, &factor, real_context);
    dr.realMultiply(mean, &factor, &variance, real_context);
    dr.realSubtract(n0, n, &factor, real_context);
    dr.realSubtract(n0, dr.const1(), standard_deviation, real_context);
    dr.realDivide(&factor, standard_deviation, &factor, real_context);
    dr.realMultiply(&variance, &factor, &variance, real_context);
    dr.realSquareRoot(&variance, standard_deviation, real_context);
}

// Whether the standard deviation has reached 1E37, where the normal takes over.
fn hyperUseNormalApproximation(k0: *const real_t, n: *const real_t, n0: *const real_t, mean: *real_t, standard_deviation: *real_t) linksection(dr.code_section) bool {
    var threshold: real_t = undefined;

    hyperMoments(k0, n, n0, mean, standard_deviation, &dr.ctxtReal75);
    dr.setOne(&threshold);
    threshold.exponent = 37;
    return dr.realCompareGreaterEqual(standard_deviation, &threshold);
}

fn hyperNormalProbability(x: *const real_t, mean: *const real_t, standard_deviation: *const real_t, upper: bool, res: *real_t) linksection(dr.code_section) void {
    var z: real_t = undefined;

    dr.realSubtract(x, mean, &z, &dr.ctxtReal75);
    dr.realDivide(&z, standard_deviation, &z, &dr.ctxtReal75);
    if (upper) {
        dr.WP34S_Cdfu_Q(&z, res, &dr.ctxtReal75);
    } else {
        dr.WP34S_Cdf_Q(&z, res, &dr.ctxtReal75);
    }
    if (dr.realIsZero(&z) and dr.realEqual(res, dr.const1on2())) {
        dr.realNextToward(res, dr.const1(), res, &dr.ctxtReal75);
    }
    dr.WP34S_MarkProbability(res, &dr.ctxtReal75);
}

// The tail from `start` outward by the mass recurrence; false when the integers
// are too far apart for the step to move.
fn hyperTailSum(start: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, upward: bool, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) bool {
    var current: real_t = undefined;
    var denominator: real_t = undefined;
    var factor: real_t = undefined;
    var former: real_t = undefined;
    var numerator: real_t = undefined;
    var previous: real_t = undefined;
    var ratio: real_t = undefined;
    var term: real_t = undefined;

    dr.realCopy(start, &current);
    hyperMassStandard(&current, k0, n, n0, &term, real_context);
    dr.realCopy(&term, res);
    while (true) {
        dr.realCopy(res, &previous);
        dr.realCopy(&current, &former);
        if (upward) {
            if (dr.realCompareGreaterEqual(&current, if (dr.realLessThan(k0, n)) k0 else n)) {
                return true;
            }
            dr.realSubtract(k0, &current, &numerator, real_context);
            dr.realSubtract(n, &current, &factor, real_context);
            dr.realMultiply(&numerator, &factor, &numerator, real_context);
            dr.realAdd(&current, dr.const1(), &denominator, real_context);
            dr.realSubtract(n0, k0, &factor, real_context);
            dr.realSubtract(&factor, n, &factor, real_context);
            dr.realAdd(&factor, &current, &factor, real_context);
            dr.realAdd(&factor, dr.const1(), &factor, real_context);
            dr.realMultiply(&denominator, &factor, &denominator, real_context);
            dr.realDivide(&numerator, &denominator, &ratio, real_context);
            dr.realAdd(&current, dr.const1(), &current, real_context);
        } else {
            if (dr.realIsZero(&current)) {
                return true;
            }
            dr.realSubtract(n0, k0, &numerator, real_context);
            dr.realSubtract(&numerator, n, &numerator, real_context);
            dr.realAdd(&numerator, &current, &numerator, real_context);
            dr.realMultiply(&numerator, &current, &numerator, real_context);
            dr.realSubtract(k0, &current, &denominator, real_context);
            dr.realAdd(&denominator, dr.const1(), &denominator, real_context);
            dr.realSubtract(n, &current, &factor, real_context);
            dr.realAdd(&factor, dr.const1(), &factor, real_context);
            dr.realMultiply(&denominator, &factor, &denominator, real_context);
            dr.realDivide(&numerator, &denominator, &ratio, real_context);
            dr.realSubtract(&current, dr.const1(), &current, real_context);
        }
        if (dr.realEqual(&current, &former)) {
            return false;
        }
        dr.realMultiply(&term, &ratio, &term, real_context);
        dr.realAdd(res, &term, res, real_context);
        if (dr.realEqual(res, &previous)) {
            return true;
        }
    }
}

// At the mean of a symmetric distribution (K or n equal to N/2) both tails are
// 1/2 plus half the mass there.
fn hyperSymmetricCentre(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) bool {
    var mean: real_t = undefined;
    var mass: real_t = undefined;
    var twice: real_t = undefined;

    dr.realMultiply(k0, dr.const2(), &twice, real_context);
    if (!dr.realEqual(&twice, n0)) {
        dr.realMultiply(n, dr.const2(), &twice, real_context);
        if (!dr.realEqual(&twice, n0)) {
            return false;
        }
    }
    dr.realMultiply(k0, n, &mean, real_context);
    dr.realDivide(&mean, n0, &mean, real_context);
    if (!dr.realEqual(x, &mean)) {
        return false;
    }
    hyperMassStandard(x, k0, n, n0, &mass, real_context);
    dr.realMultiply(&mass, dr.const1on2(), &mass, real_context);
    dr.realAdd(dr.const1on2(), &mass, res, real_context);
    return true;
}

// The median of a symmetric distribution is the mean rounded up.
fn hyperSymmetricMedian(k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) bool {
    var mean: real_t = undefined;
    var twice: real_t = undefined;

    dr.realMultiply(k0, dr.const2(), &twice, &dr.ctxtReal75);
    if (!dr.realEqual(&twice, n0)) {
        dr.realMultiply(n, dr.const2(), &twice, &dr.ctxtReal75);
        if (!dr.realEqual(&twice, n0)) {
            return false;
        }
    }
    dr.realMultiply(k0, n, &mean, &dr.ctxtReal75);
    dr.realDivide(&mean, n0, &mean, &dr.ctxtReal75);
    dr.toIntegralValue(&mean, res, dr.DEC_ROUND_CEILING, real_context);
    return true;
}

// The lower probability of the standardised distribution: the smaller tail
// summed from the mode outward, or one minus the other.
fn hyperLowerStandard(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var mean: real_t = undefined;
    var mode: real_t = undefined;
    var standard_deviation: real_t = undefined;
    var start: real_t = undefined;
    var tail: real_t = undefined;
    var upper: real_t = undefined;

    dr.realCopy(if (dr.realLessThan(k0, n)) k0 else n, &upper);
    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realCompareGreaterEqual(x, &upper)) {
        dr.setOne(res);
        return;
    }
    if (hyperSymmetricCentre(x, k0, n, n0, res, real_context)) {
        return;
    }
    if (hyperUseNormalApproximation(k0, n, n0, &mean, &standard_deviation)) {
        hyperNormalProbability(x, &mean, &standard_deviation, false, res);
        return;
    }
    hyperMode(k0, n, n0, &mode, real_context);
    if (dr.realLessThan(x, &mode)) {
        if (!hyperTailSum(x, k0, n, n0, false, res, real_context)) {
            dr.setNaN(res);
        }
        return;
    }
    dr.realAdd(x, dr.const1(), &start, real_context);
    if (!hyperTailSum(&start, k0, n, n0, true, &tail, real_context)) {
        dr.setNaN(res);
        return;
    }
    dr.realSubtract(dr.const1(), &tail, res, real_context);
    dr.WP34S_MarkProbability(res, real_context);
}

fn hyperUpperStandard(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var mean: real_t = undefined;
    var mode: real_t = undefined;
    var standard_deviation: real_t = undefined;
    var start: real_t = undefined;
    var tail: real_t = undefined;
    var upper: real_t = undefined;

    dr.realCopy(if (dr.realLessThan(k0, n)) k0 else n, &upper);
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setOne(res);
        return;
    }
    if (dr.realGreaterThan(x, &upper)) {
        dr.setZero(res);
        return;
    }
    if (hyperSymmetricCentre(x, k0, n, n0, res, real_context)) {
        return;
    }
    if (hyperUseNormalApproximation(k0, n, n0, &mean, &standard_deviation)) {
        hyperNormalProbability(x, &mean, &standard_deviation, true, res);
        return;
    }
    hyperMode(k0, n, n0, &mode, real_context);
    if (dr.realGreaterThan(x, &mode)) {
        if (!hyperTailSum(x, k0, n, n0, true, res, real_context)) {
            dr.setNaN(res);
        }
        return;
    }
    dr.realSubtract(x, dr.const1(), &start, real_context);
    if (!hyperTailSum(&start, k0, n, n0, false, &tail, real_context)) {
        dr.setNaN(res);
        return;
    }
    dr.realSubtract(dr.const1(), &tail, res, real_context);
    dr.WP34S_MarkProbability(res, real_context);
}

pub fn pdfHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var lower: real_t = undefined;
    var standard_k: real_t = undefined;
    var standard_n: real_t = undefined;
    var standard_x: real_t = undefined;
    var upper: real_t = undefined;
    var value: real_t = undefined;
    var reflected: bool = undefined;

    if (dr.realIsNaN(x) or !hyperParametersAreValid(k0, n, n0)) {
        dr.setNaN(res);
        return;
    }
    hyperSupport(k0, n, n0, &lower, &upper, &dr.ctxtReal75);
    if (!dr.isAnInteger(x) or dr.realIsInfinite(x) or dr.realLessThan(x, &lower) or dr.realGreaterThan(x, &upper)) {
        dr.setZero(res);
        return;
    }
    if (dr.realEqual(&lower, &upper)) {
        dr.setOne(res);
        return;
    }
    const calculation_context = hyperCalculationContext(n0, real_context);
    hyperStandardise(x, k0, n, n0, &standard_x, &standard_k, &standard_n, &reflected, calculation_context);
    hyperMassStandard(&standard_x, &standard_k, &standard_n, n0, &value, calculation_context);
    hyperRoundProbability(&value, res, real_context);
}

pub fn cdfuHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var integer: real_t = undefined;
    var lower: real_t = undefined;
    var standard_k: real_t = undefined;
    var standard_n: real_t = undefined;
    var standard_x: real_t = undefined;
    var upper: real_t = undefined;
    var value: real_t = undefined;
    var reflected: bool = undefined;

    if (dr.realIsNaN(x) or !hyperParametersAreValid(k0, n, n0)) {
        dr.setNaN(res);
        return;
    }
    const calculation_context = hyperCalculationContext(n0, real_context);
    dr.toIntegralValue(x, &integer, dr.DEC_ROUND_CEILING, calculation_context);
    hyperSupport(k0, n, n0, &lower, &upper, calculation_context);
    if (dr.realCompareLessEqual(&integer, &lower)) {
        dr.setOne(res);
        return;
    }
    if (dr.realGreaterThan(&integer, &upper) or dr.realIsInfinite(&integer)) {
        dr.setZero(res);
        return;
    }
    hyperStandardise(&integer, k0, n, n0, &standard_x, &standard_k, &standard_n, &reflected, calculation_context);
    if (reflected) {
        hyperLowerStandard(&standard_x, &standard_k, &standard_n, n0, &value, calculation_context);
    } else {
        hyperUpperStandard(&standard_x, &standard_k, &standard_n, n0, &value, calculation_context);
    }
    hyperRoundProbability(&value, res, real_context);
}

pub fn cdfHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var integer: real_t = undefined;

    if (dr.realIsNaN(x) or !hyperParametersAreValid(k0, n, n0)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &integer, dr.DEC_ROUND_FLOOR, hyperCalculationContext(n0, real_context));
    cdfHypergeometric2(&integer, k0, n, n0, res, real_context);
}

pub fn cdfHypergeometric2(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var lower: real_t = undefined;
    var standard_k: real_t = undefined;
    var standard_n: real_t = undefined;
    var standard_x: real_t = undefined;
    var upper: real_t = undefined;
    var value: real_t = undefined;
    var reflected: bool = undefined;

    if (dr.realIsNaN(x) or !hyperParametersAreValid(k0, n, n0)) {
        dr.setNaN(res);
        return;
    }
    const calculation_context = hyperCalculationContext(n0, real_context);
    hyperSupport(k0, n, n0, &lower, &upper, calculation_context);
    if (dr.realLessThan(x, &lower)) {
        dr.setZero(res);
        return;
    }
    if (dr.realCompareGreaterEqual(x, &upper) or dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    hyperStandardise(x, k0, n, n0, &standard_x, &standard_k, &standard_n, &reflected, calculation_context);
    if (reflected) {
        hyperUpperStandard(&standard_x, &standard_k, &standard_n, n0, &value, calculation_context);
    } else {
        hyperLowerStandard(&standard_x, &standard_k, &standard_n, n0, &value, calculation_context);
    }
    hyperRoundProbability(&value, res, real_context);
}

pub fn qfHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var cdf: real_t = undefined;
    var high: real_t = undefined;
    var low: real_t = undefined;
    var lower: real_t = undefined;
    var mean: real_t = undefined;
    var midpoint: real_t = undefined;
    var step: real_t = undefined;
    var tolerance: real_t = undefined;
    var upper: real_t = undefined;
    var width: real_t = undefined;

    if (dr.realIsNaN(x) or !hyperParametersAreValid(k0, n, n0) or dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, dr.const1())) {
        dr.setNaN(res);
        return;
    }
    hyperSupport(k0, n, n0, &lower, &upper, &dr.ctxtReal75);
    if (dr.realEqual(&lower, &upper) or dr.realIsZero(x)) {
        dr.realCopy(&lower, res);
        return;
    }
    if (dr.realEqual(x, dr.const1())) {
        dr.realCopy(&upper, res);
        return;
    }
    if (dr.realEqual(x, dr.const1on2()) and hyperSymmetricMedian(k0, n, n0, res, real_context)) {
        return;
    }
    cdfHypergeometric2(&lower, k0, n, n0, &cdf, &dr.ctxtReal75);
    if (dr.realCompareGreaterEqual(&cdf, x)) {
        dr.realCopy(&lower, res);
        return;
    }
    dr.realMultiply(k0, n, &mean, &dr.ctxtReal75);
    dr.realDivide(&mean, n0, &mean, &dr.ctxtReal75);
    dr.toIntegralValue(&mean, &high, dr.DEC_ROUND_CEILING, &dr.ctxtReal39);
    if (dr.realCompareLessEqual(&high, &lower)) {
        dr.realAdd(&lower, dr.const1(), &high, &dr.ctxtReal39);
    }
    if (dr.realGreaterThan(&high, &upper)) {
        dr.realCopy(&upper, &high);
    }
    dr.realCopy(&lower, &low);
    var iteration: i32 = 0;
    while (iteration < 64) : (iteration += 1) {
        cdfHypergeometric2(&high, k0, n, n0, &cdf, &dr.ctxtReal75);
        if (dr.realCompareGreaterEqual(&cdf, x)) {
            break;
        }
        dr.realSubtract(&high, &low, &step, &dr.ctxtReal39);
        if (dr.realLessThan(&step, dr.const1())) {
            dr.setOne(&step);
        }
        dr.realCopy(&high, &low);
        dr.realAdd(&high, &step, &high, &dr.ctxtReal39);
        if (dr.realCompareGreaterEqual(&high, &upper) or iteration == 63) {
            dr.realCopy(&upper, &high);
            break;
        }
    }
    dr.WP34S_SetPowerOfTen(-37, &tolerance);
    iteration = 0;
    while (iteration < 200) : (iteration += 1) {
        dr.realSubtract(&high, &low, &width, &dr.ctxtReal39);
        if (dr.realCompareLessEqual(&width, dr.const1())) {
            dr.realCopy(&high, res);
            return;
        }
        if (!dr.realIsZero(&low) and dr.WP34S_RelativeError(&low, &high, &tolerance, &dr.ctxtReal39)) {
            dr.realAdd(&low, &high, &midpoint, &dr.ctxtReal39);
            dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, &dr.ctxtReal39);
            dr.realCopy(&midpoint, res);
            return;
        }
        dr.realAdd(&low, &high, &midpoint, &dr.ctxtReal39);
        dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, &dr.ctxtReal39);
        dr.toIntegralValue(&midpoint, &midpoint, dr.DEC_ROUND_FLOOR, &dr.ctxtReal39);
        cdfHypergeometric2(&midpoint, k0, n, n0, &cdf, &dr.ctxtReal75);
        if (dr.realCompareGreaterEqual(&cdf, x)) {
            dr.realCopy(&midpoint, &high);
        } else {
            dr.realCopy(&midpoint, &low);
        }
    }
    dr.setNaN(res);
}
