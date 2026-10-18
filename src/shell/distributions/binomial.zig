// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/binomial.c: the binomial distribution
// commands and the WP34S kernels behind them. The commands hand their descriptor
// row to fnDistribution, which loads register X, the probability in P and the
// trial count in N. The mass goes through the logarithm of the beta prefix, the
// probabilities through both regularised-beta tails, and the quantile through
// the Newton solver from a normal moment estimate. Tagged
// linksection(dr.code_section) so the code runs from QSPI on the flash-limited
// old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// binomialCheckDomain: an integer n at or above zero, p in [0, 1] and x not NaN.
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
        dr.moreInfoOnError("In function binomialCheckDomain:", "n is not a finite integer", null, null);
        return false;
    } else if (dr.realIsNaN(x)) {
        if (!dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function binomialCheckDomain:", "x is NaN", null, null);
        }
        return false;
    } else if (dr.realIsSpecial(i) or dr.realLessThan(i, dr.const0()) or dr.realGreaterThan(i, dr.const1()) or dr.realLessThan(j, dr.const0())) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function binomialCheckDomain:", "the parameters must be 0 \xa2\x64 p \xa2\x64 1 and n \xa2\x65 0", null, null);
        return false;
    }
    return true;
}

pub fn binomialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_BINOM * 4 + dr.DIST_P);
}

pub fn binomialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_BINOM * 4 + dr.DIST_L);
}

pub fn binomialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_BINOM * 4 + dr.DIST_R);
}

pub fn binomialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_BINOM * 4 + dr.DIST_I);
}

// Whether p and n define a binomial distribution.
fn binomialParametersAreValid(p: *const real_t, n: *const real_t) linksection(dr.code_section) bool {
    return !dr.realIsSpecial(p) and !dr.realIsSpecial(n) and dr.realCompareGreaterEqual(p, dr.const0()) and
        dr.realCompareLessEqual(p, dr.const1()) and dr.realCompareGreaterEqual(n, dr.const0()) and dr.isAnInteger(n);
}

pub fn wp34sPdfBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var log_p: real_t = undefined;
    var log_q: real_t = undefined;
    var logit: real_t = undefined;
    var log_mass: real_t = undefined;
    var n_plus_one: real_t = undefined;
    var q0: real_t = undefined;
    var value: real_t = undefined;
    const calculation_context = &dr.ctxtReal51;

    if (dr.realIsNaN(x) or !binomialParametersAreValid(p0, n)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, n)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsZero(n)) {
        dr.realCopy(if (dr.realIsZero(x)) dr.const1() else dr.const0(), res);
        return;
    }
    if (dr.realIsZero(p0)) {
        dr.realCopy(if (dr.realIsZero(x)) dr.const1() else dr.const0(), res);
        return;
    }
    if (dr.realEqual(p0, dr.const1())) {
        dr.realCopy(if (dr.realEqual(x, n)) dr.const1() else dr.const0(), res);
        return;
    }

    dr.realAdd(x, dr.const1(), &a, calculation_context);
    dr.realSubtract(n, x, &b, calculation_context);
    dr.realAdd(&b, dr.const1(), &b, calculation_context);
    dr.WP34S_DistributionProbabilityData(p0, &q0, &log_p, &log_q, &logit, calculation_context);
    if (dr.realIsZero(x)) {
        dr.realMultiply(n, &log_q, &log_mass, calculation_context);
    } else if (dr.realEqual(x, n)) {
        dr.realMultiply(n, &log_p, &log_mass, calculation_context);
    } else {
        dr.distributionLogBetaPrefix(&a, &b, p0, &q0, &logit, &log_mass, calculation_context);
        dr.realSubtract(&log_mass, &log_p, &log_mass, calculation_context);
        dr.realSubtract(&log_mass, &log_q, &log_mass, calculation_context);
        dr.realAdd(n, dr.const1(), &n_plus_one, calculation_context);
        dr.WP34S_Ln(&n_plus_one, &value, calculation_context);
        dr.realSubtract(&log_mass, &value, &log_mass, calculation_context);
    }
    dr.realExponential(&log_mass, &value, calculation_context);
    if (dr.realIsZero(&value)) {
        dr.realNextToward(&value, dr.const1(), &value, calculation_context);
    }
    dr.realPlus(&value, res, real_context);
}

pub fn wp34sCdfuBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var log_p: real_t = undefined;
    var log_q: real_t = undefined;
    var logit: real_t = undefined;
    var lower: real_t = undefined;
    var p: real_t = undefined;
    var q0: real_t = undefined;
    var upper: real_t = undefined;

    if (dr.realIsNaN(x) or !binomialParametersAreValid(p0, n)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, real_context);
    if (dr.realCompareLessEqual(&p, dr.const0())) {
        dr.setOne(res);
        return;
    }
    if (dr.realGreaterThan(&p, n) or dr.realIsZero(p0)) {
        dr.setZero(res);
        return;
    }
    if (dr.realEqual(p0, dr.const1())) {
        dr.setOne(res);
        return;
    }

    dr.realCopy(&p, &a);
    dr.realSubtract(n, &p, &b, &dr.ctxtReal51);
    dr.realAdd(&b, dr.const1(), &b, &dr.ctxtReal51);
    const calculation_context = dr.WP34S_BetaCalculationContext(&a, &b);
    dr.realCopy(&p, &a);
    dr.realSubtract(n, &p, &b, calculation_context);
    dr.realAdd(&b, dr.const1(), &b, calculation_context);
    dr.WP34S_DistributionProbabilityData(p0, &q0, &log_p, &log_q, &logit, calculation_context);
    if (!dr.distributionBetaPair(&a, &b, p0, &q0, &logit, &lower, &upper, calculation_context)) {
        dr.setNaN(res);
        return;
    }
    dr.WP34S_MarkProbability(&lower, calculation_context);
    dr.realPlus(&lower, res, real_context);
}

pub fn wp34sCdfBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;

    if (dr.realIsNaN(x) or !binomialParametersAreValid(p0, n)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, real_context);
    wp34sCdfBinomial2(&p, p0, n, res, real_context);
}

pub fn wp34sCdfBinomial2(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var log_p: real_t = undefined;
    var log_q: real_t = undefined;
    var logit: real_t = undefined;
    var lower: real_t = undefined;
    var q0: real_t = undefined;
    var upper: real_t = undefined;

    if (dr.realIsNaN(x) or !binomialParametersAreValid(p0, n)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realCompareGreaterEqual(x, n) or dr.realIsZero(p0)) {
        dr.setOne(res);
        return;
    }
    if (dr.realEqual(p0, dr.const1())) {
        dr.setZero(res);
        return;
    }

    dr.realSubtract(n, x, &a, &dr.ctxtReal51);
    dr.realAdd(x, dr.const1(), &b, &dr.ctxtReal51);
    const calculation_context = dr.WP34S_BetaCalculationContext(&a, &b);
    dr.realSubtract(n, x, &a, calculation_context);
    dr.realAdd(x, dr.const1(), &b, calculation_context);
    dr.WP34S_DistributionProbabilityData(p0, &q0, &log_p, &log_q, &logit, calculation_context);
    dr.realChangeSign(&logit);
    if (!dr.distributionBetaPair(&a, &b, &q0, p0, &logit, &lower, &upper, calculation_context)) {
        dr.setNaN(res);
        return;
    }
    dr.WP34S_MarkProbability(&lower, calculation_context);
    dr.realPlus(&lower, res, real_context);
}

pub fn wp34sQfBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var estimate: real_t = undefined;
    var mean: real_t = undefined;
    var q: real_t = undefined;
    var standard_deviation: real_t = undefined;
    var variance: real_t = undefined;

    if (!binomialParametersAreValid(p0, n) or dr.realIsNaN(x)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realCompareGreaterEqual(x, dr.const1()) or dr.realEqual(p0, dr.const1())) {
        dr.realCopy(n, res);
        return;
    }
    if (dr.realIsZero(n) or dr.realIsZero(p0)) {
        dr.setZero(res);
        return;
    }

    dr.realMultiply(p0, n, &mean, real_context);
    dr.realSubtract(dr.const1(), p0, &q, real_context);
    dr.realMultiply(&q, &mean, &variance, real_context);
    dr.realSquareRoot(&variance, &standard_deviation, real_context);
    dr.WP34S_normal_moment_approx(x, &standard_deviation, &mean, &estimate, real_context);
    dr.WP34S_Qf_Newton(dr.QF_NEWTON_BINOMIAL, x, &estimate, p0, n, null, &mean, real_context);
    if (dr.realIsNaN(&mean)) {
        dr.setNaN(res);
    } else {
        dr.realCopy(if (dr.realCompareLessEqual(&mean, n)) &mean else n, res);
    }
}
