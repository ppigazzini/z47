// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/negBinom.c: the negative binomial
// distribution commands and the kernels behind them. The commands hand their
// descriptor row to fnDistribution, which loads register X, the probability in P
// and the success count in N. Tagged linksection(dr.code_section) so the code
// runs from QSPI on the flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// negativeBinomialCheckDomain: an integer r above zero, p in [0, 1) and x not NaN.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;
    const j = second.?;

    if (!dr.checkRegisterNoFP(j) or dr.realIsSpecial(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function negativeBinomialCheckDomain:", "r is not a finite integer", null, null);
        return false;
    } else if (dr.realIsNaN(x)) {
        if (!dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function negativeBinomialCheckDomain:", "x is NaN", null, null);
        }
        return false;
    } else if (dr.realIsSpecial(i) or dr.realLessThan(i, dr.const0()) or dr.realCompareGreaterEqual(i, dr.const1()) or dr.realCompareLessEqual(j, dr.const0())) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function negativeBinomialCheckDomain:", "the parameters must be 0 \xa2\x64 p < 1 and r > 0", null, null);
        return false;
    }
    return true;
}

pub fn negBinomialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_NEGBINOM * 4 + dr.DIST_P);
}

pub fn negBinomialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_NEGBINOM * 4 + dr.DIST_L);
}

pub fn negBinomialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_NEGBINOM * 4 + dr.DIST_R);
}

pub fn negBinomialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_NEGBINOM * 4 + dr.DIST_I);
}

// Whether p and r define a negative binomial distribution.
fn negativeBinomialParametersAreValid(p: *const real_t, r: *const real_t) linksection(dr.code_section) bool {
    return !dr.realIsSpecial(p) and !dr.realIsSpecial(r) and dr.realCompareGreaterEqual(p, dr.const0()) and dr.realLessThan(p, dr.const1()) and
        dr.realGreaterThan(r, dr.const0()) and dr.isAnInteger(r);
}

/// pdf_NegBinomial: PDF[NB(r, p)](k) = [(k + r - 1) C k] p^k (1 - p)^r.
pub fn pdfNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var logit: real_t = undefined;
    var log_mass: real_t = undefined;
    var log_p: real_t = undefined;
    var log_q: real_t = undefined;
    var q0: real_t = undefined;
    var term: real_t = undefined;
    var value: real_t = undefined;
    const calculation_context = &dr.ctxtReal51;

    if (dr.realIsNaN(x) or !negativeBinomialParametersAreValid(p0, r)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsNegative(x) or dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsZero(p0)) {
        dr.realCopy(if (dr.realIsZero(x)) dr.const1() else dr.const0(), res);
        return;
    }

    dr.WP34S_DistributionProbabilityData(p0, &q0, &log_p, &log_q, &logit, calculation_context);
    if (dr.realIsZero(x)) {
        dr.realMultiply(r, &log_q, &log_mass, calculation_context);
    } else {
        dr.realAdd(x, dr.const1(), &a, calculation_context);
        dr.distributionLogBetaPrefix(&a, r, p0, &q0, &logit, &log_mass, calculation_context);
        dr.realSubtract(&log_mass, &log_p, &log_mass, calculation_context);
        dr.realAdd(x, r, &term, calculation_context);
        dr.WP34S_Ln(&term, &term, calculation_context);
        dr.realSubtract(&log_mass, &term, &log_mass, calculation_context);
    }
    dr.realExponential(&log_mass, &value, calculation_context);
    if (dr.realIsZero(&value)) {
        dr.realNextToward(&value, dr.const1(), &value, calculation_context);
    }
    dr.realPlus(&value, res, real_context);
}

/// cdfu_NegBinomial: I[p](ceil(x), r).
pub fn cdfuNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var logit: real_t = undefined;
    var log_p: real_t = undefined;
    var log_q: real_t = undefined;
    var lower: real_t = undefined;
    var p: real_t = undefined;
    var q0: real_t = undefined;
    var upper: real_t = undefined;

    if (dr.realIsNaN(x) or !negativeBinomialParametersAreValid(p0, r)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, real_context);
    if (dr.realLessThan(&p, dr.const1())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(&p)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsZero(p0)) {
        dr.setZero(res);
        return;
    }

    const calculation_context = dr.WP34S_BetaCalculationContext(&p, r);
    dr.WP34S_DistributionProbabilityData(p0, &q0, &log_p, &log_q, &logit, calculation_context);
    if (!dr.distributionBetaPair(&p, r, p0, &q0, &logit, &lower, &upper, calculation_context)) {
        dr.setNaN(res);
        return;
    }
    dr.WP34S_MarkProbability(&lower, calculation_context);
    dr.realPlus(&lower, res, real_context);
}

/// cdf_NegBinomial: I[1-p](r, floor(x) + 1).
pub fn cdfNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;

    if (dr.realIsNaN(x) or !negativeBinomialParametersAreValid(p0, r)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, real_context);
    cdfNegBinomial2(&p, p0, r, res, real_context);
}

pub fn cdfNegBinomial2(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var b: real_t = undefined;
    var logit: real_t = undefined;
    var log_p: real_t = undefined;
    var log_q: real_t = undefined;
    var lower: real_t = undefined;
    var q0: real_t = undefined;
    var upper: real_t = undefined;

    if (dr.realIsNaN(x) or !negativeBinomialParametersAreValid(p0, r)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsZero(p0)) {
        dr.setOne(res);
        return;
    }

    dr.realAdd(x, dr.const1(), &b, &dr.ctxtReal51);
    const calculation_context = dr.WP34S_BetaCalculationContext(r, &b);
    dr.realAdd(x, dr.const1(), &b, calculation_context);
    dr.WP34S_DistributionProbabilityData(p0, &q0, &log_p, &log_q, &logit, calculation_context);
    dr.realChangeSign(&logit);
    if (!dr.distributionBetaPair(r, &b, &q0, p0, &logit, &lower, &upper, calculation_context)) {
        dr.setNaN(res);
        return;
    }
    dr.WP34S_MarkProbability(&lower, calculation_context);
    dr.realPlus(&lower, res, real_context);
}

pub fn qfNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var estimate: real_t = undefined;
    var mean: real_t = undefined;
    var pr: real_t = undefined;
    var q0: real_t = undefined;
    var standard_deviation: real_t = undefined;
    var variance: real_t = undefined;

    if (dr.realIsNaN(x) or !negativeBinomialParametersAreValid(p0, r)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsZero(p0)) {
        dr.setZero(res);
        return;
    }
    if (dr.realCompareGreaterEqual(x, dr.const1())) {
        dr.setPlusInfinity(res);
        return;
    }

    dr.realSubtract(dr.const1(), p0, &q0, real_context);
    dr.realMultiply(p0, r, &pr, real_context);
    dr.realDivide(&pr, &q0, &mean, real_context); // mean = pr / (1 - p)

    dr.realDivide(&mean, &q0, &variance, real_context); // variance = pr / (1 - p)^2
    dr.realSquareRoot(&variance, &standard_deviation, real_context);

    dr.WP34S_normal_moment_approx(x, &standard_deviation, &mean, &estimate, real_context);
    dr.WP34S_Qf_Newton(dr.QF_NEWTON_NEGBINOM, x, &estimate, p0, r, null, res, real_context);
}
