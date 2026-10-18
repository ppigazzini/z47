// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/poisson.c: the Poisson distribution
// commands, the WP34S kernels behind them and the normal moment estimate the
// discrete quantiles start from. The commands hand their descriptor row to
// fnDistribution, which loads register X and the rate in R. The mass goes
// through its logarithm, with the Lanczos sum past x = 205, the probabilities
// through the regularised incomplete gamma, and the quantile brackets the
// integer by doubling and halving. Tagged linksection(dr.code_section) so the
// code runs from QSPI on the flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// poissonCheckDomain: x may not be NaN and the rate must be positive and finite.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = second;
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;

    if (dr.realIsNaN(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function poissonCheckDomain:", "x is NaN", null, null);
        return false;
    } else if (dr.realIsSpecial(i) or dr.realIsZero(i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function poissonCheckDomain:", "the parameter must be \x83\xbb > 0", null, null);
        return false;
    }
    return true;
}

pub fn poissonP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_POISSON * 4 + dr.DIST_P);
}

pub fn poissonL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_POISSON * 4 + dr.DIST_L);
}

pub fn poissonR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_POISSON * 4 + dr.DIST_R);
}

pub fn poissonI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_POISSON * 4 + dr.DIST_I);
}

/// WP34S_normal_moment_approx: a normal approximation to a quantile from the
/// probability, the variance and the mean.
pub fn wp34sNormalMomentApprox(prob: *const real_t, variance: *const real_t, mean: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    dr.WP34S_qf_q_est(prob, &p, null, real_context);
    dr.realMultiply(&p, &p, &q, real_context);
    dr.realSubtract(&q, dr.const1(), &q, real_context);
    dr.realDivide(&q, dr.const6(), &q, real_context);
    dr.realDivide(&q, variance, &q, real_context);
    dr.realAdd(&p, &q, &p, real_context);
    dr.realMultiply(&p, variance, &p, real_context);
    dr.realAdd(&p, mean, res, real_context);
}

// The logarithm of the mass: x ln(lambda) - lambda - ln(x!) below x = 205, the
// Lanczos sum with a cancellation-free (x ln(lambda / r) + r - lambda) above.
fn poissonLogDensity(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var argument: real_t = undefined;
    var sum: real_t = undefined;
    var r: real_t = undefined;
    var delta: real_t = undefined;
    var logarithm: real_t = undefined;
    var term: real_t = undefined;

    if (dr.realLessThan(x, dr.const205())) {
        dr.WP34S_Ln(lambda, &logarithm, real_context);
        dr.realMultiply(&logarithm, x, res, real_context);
        dr.realSubtract(res, lambda, res, real_context);
        dr.realAdd(x, dr.const1(), &argument, real_context);
        dr.WP34S_LnGamma(&argument, &term, real_context);
        dr.realSubtract(res, &term, res, real_context);
        return;
    }

    dr.WP34S_LanczosSum(x, dr.const29(), &sum, real_context);
    dr.WP34S_Ln(&sum, &sum, real_context);
    dr.realAdd(x, dr.constGammaR(), &r, real_context);
    dr.realSubtract(lambda, &r, &delta, real_context);
    dr.realDivide(&delta, &r, &delta, real_context);
    if (dr.realCompareAbsLessThan(&delta, dr.const1e_6())) {
        dr.WP34S_Log1pMinus(&delta, &term, real_context);
        dr.realMultiply(x, &term, res, real_context);
        dr.realMultiply(dr.constGammaR(), &delta, &term, real_context);
        dr.realSubtract(res, &term, res, real_context);
    } else {
        dr.realDivide(lambda, &r, &logarithm, real_context);
        dr.WP34S_Ln(&logarithm, &logarithm, real_context);
        dr.realMultiply(x, &logarithm, res, real_context);
        dr.realSubtract(&r, lambda, &term, real_context);
        dr.realAdd(res, &term, res, real_context);
    }
    dr.WP34S_Ln(&r, &term, real_context);
    dr.realMultiply(&term, dr.const1on2(), &term, real_context);
    dr.realSubtract(res, &term, res, real_context);
    dr.realSubtract(res, &sum, res, real_context);
}

pub fn wp34sPdfPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var logarithm: real_t = undefined;
    var value: real_t = undefined;

    if (!dr.WP34S_IsPositiveFinite(lambda) or dr.realIsNaN(x)) {
        dr.setNaN(res);
        return;
    }
    if ((dr.realIsNegative(x) and !dr.realIsZero(x)) or !dr.isAnInteger(x) or dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    const calculation_context = if (dr.realLessThan(x, dr.const205())) dr.WP34S_AtLeastContext(real_context, &dr.ctxtReal39) else dr.WP34S_AtLeastContext(real_context, &dr.ctxtReal51);
    poissonLogDensity(x, lambda, &logarithm, calculation_context);
    dr.realExponential(&logarithm, &value, calculation_context);
    dr.WP34S_AdjustPositiveUnderflow(&value);
    dr.realPlus(&value, res, real_context);
}

// The lower probability at an integer x: Q(x + 1, lambda), or Q(x, lambda) plus
// the mass at x once x + 1 is no longer exact.
fn poissonCdfAtInteger(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var shape: real_t = undefined;
    var difference: real_t = undefined;
    var previous: real_t = undefined;
    var logarithm: real_t = undefined;
    var mass: real_t = undefined;

    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    dr.realAdd(x, dr.const1(), &shape, real_context);
    dr.realSubtract(&shape, x, &difference, real_context);
    if (dr.realEqual(&difference, dr.const1())) {
        dr.WP34S_GammaP(lambda, &shape, res, real_context, true, true);
    } else {
        dr.WP34S_GammaP(lambda, x, &previous, real_context, true, true);
        poissonLogDensity(x, lambda, &logarithm, &dr.ctxtReal51);
        dr.realExponential(&logarithm, &mass, &dr.ctxtReal51);
        dr.realAdd(&previous, &mass, res, real_context);
    }
}

fn poissonMarkInterior(value: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    dr.WP34S_AdjustPositiveUnderflow(value);
    if (dr.realCompareGreaterEqual(value, dr.const1())) {
        dr.realCopy(dr.const1(), value);
        dr.realNextToward(value, dr.const0(), value, real_context);
    }
}

fn poissonMarkCentralSide(integer: *const real_t, lambda: *const real_t, value: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    if (dr.realEqual(integer, lambda) and dr.realEqual(value, dr.const1on2())) {
        dr.realNextToward(value, dr.const1(), value, real_context);
    }
}

pub fn wp34sCdfuPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var integer: real_t = undefined;
    var value: real_t = undefined;
    const calculation_context = dr.WP34S_AtLeastContext(real_context, &dr.ctxtReal39);

    if (!dr.WP34S_IsPositiveFinite(lambda) or dr.realIsNaN(x)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &integer, dr.DEC_ROUND_CEILING, calculation_context);
    if (dr.realLessThan(&integer, dr.const1())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(&integer)) {
        dr.setZero(res);
        return;
    }
    dr.WP34S_GammaP(lambda, &integer, &value, calculation_context, false, true);
    poissonMarkCentralSide(&integer, lambda, &value, calculation_context);
    poissonMarkInterior(&value, calculation_context);
    dr.realPlus(&value, res, real_context);
}

pub fn wp34sCdfPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var integer: real_t = undefined;

    if (!dr.WP34S_IsPositiveFinite(lambda) or dr.realIsNaN(x)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &integer, dr.DEC_ROUND_FLOOR, dr.WP34S_AtLeastContext(real_context, &dr.ctxtReal39));
    wp34sCdfPoisson2(&integer, lambda, res, real_context);
}

pub fn wp34sCdfPoisson2(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var value: real_t = undefined;
    const calculation_context = dr.WP34S_AtLeastContext(real_context, &dr.ctxtReal39);

    if (!dr.WP34S_IsPositiveFinite(lambda) or dr.realIsNaN(x)) {
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
    poissonCdfAtInteger(x, lambda, &value, calculation_context);
    poissonMarkCentralSide(x, lambda, &value, calculation_context);
    poissonMarkInterior(&value, calculation_context);
    dr.realPlus(&value, res, real_context);
}

pub fn wp34sQfPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var probability: real_t = undefined;
    var low: real_t = undefined;
    var high: real_t = undefined;
    var width: real_t = undefined;
    var midpoint: real_t = undefined;
    var difference: real_t = undefined;
    var tolerance: real_t = undefined;
    var large_lambda: real_t = undefined;
    var value: real_t = undefined;

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
    if (dr.realEqual(x, dr.const1on2()) and dr.isAnInteger(lambda)) {
        dr.realCopy(lambda, res);
        return;
    }

    dr.WP34S_SetPowerOfTen(74, &large_lambda);
    if (dr.realCompareGreaterEqual(lambda, &large_lambda)) {
        if (dr.realEqual(x, dr.const1on2())) {
            dr.realCopy(lambda, res);
        } else {
            dr.realNextToward(lambda, if (dr.realGreaterThan(x, dr.const1on2())) dr.constPlusInfinity() else dr.const0(), &value, &dr.ctxtReal39);
            dr.realCopy(&value, res);
        }
        return;
    }

    poissonCdfAtInteger(dr.const0(), lambda, &probability, &dr.ctxtReal51);
    if (dr.realCompareGreaterEqual(&probability, x)) {
        dr.setZero(res);
        return;
    }
    dr.setZero(&low);
    dr.toIntegralValue(lambda, &high, dr.DEC_ROUND_CEILING, &dr.ctxtReal39);
    if (dr.realLessThan(&high, dr.const1())) {
        dr.setOne(&high);
    }
    var iteration: i32 = 0;
    while (iteration < 32) : (iteration += 1) {
        poissonCdfAtInteger(&high, lambda, &probability, &dr.ctxtReal51);
        if (dr.realCompareGreaterEqual(&probability, x)) {
            break;
        }
        dr.realCopy(&high, &low);
        dr.realMultiply(&high, dr.const2(), &high, &dr.ctxtReal39);
        if (iteration == 31 or dr.realIsSpecial(&high)) {
            dr.setNaN(res);
            return;
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
            dr.realAdd(&low, &high, &value, &dr.ctxtReal39);
            dr.realMultiply(&value, dr.const1on2(), &value, &dr.ctxtReal39);
            dr.realCopy(&value, res);
            return;
        }
        dr.realAdd(&low, &high, &midpoint, &dr.ctxtReal39);
        dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, &dr.ctxtReal39);
        dr.toIntegralValue(&midpoint, &midpoint, dr.DEC_ROUND_FLOOR, &dr.ctxtReal39);
        dr.realSubtract(&midpoint, &low, &difference, &dr.ctxtReal39);
        if (dr.realIsZero(&difference)) {
            dr.realCopy(&high, res);
            return;
        }
        poissonCdfAtInteger(&midpoint, lambda, &probability, &dr.ctxtReal51);
        if (dr.realCompareGreaterEqual(&probability, x)) {
            dr.realCopy(&midpoint, &high);
        } else {
            dr.realCopy(&midpoint, &low);
        }
    }

    dr.setNaN(res);
}
