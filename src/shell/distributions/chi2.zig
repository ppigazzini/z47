// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/chi2.c: the chi-square distribution
// commands and the WP34S kernels behind them, plus checkRegisterNoFP, the
// integer test the binomial, F, hypergeometric and negative binomial domain
// rules share. The commands hand their descriptor row to fnDistribution, which
// loads register X and the degrees of freedom in M. The density goes through its
// logarithm with the Lanczos sum, the probabilities through the regularised
// incomplete gamma, and the quantile brackets log x and refines it by Newton
// steps that fall back to bisection. Tagged linksection(dr.code_section) so the
// code runs from QSPI on the flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// checkRegisterNoFP: the value has no fractional part.
pub fn checkRegisterNoFP(reg: *const real_t) linksection(dr.code_section) callconv(.c) bool {
    var floored_i: real_t = undefined;

    dr.toIntegralValue(reg, &floored_i, dr.DEC_ROUND_FLOOR, &dr.ctxtReal39);
    return dr.realEqual(reg, &floored_i);
}

/// chi2CheckDomain: an integer positive k and a finite x at or above zero.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = second;
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;

    if (!checkRegisterNoFP(i) or dr.realIsSpecial(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function chi2CheckDomain:", "k is not an integer", null, null);
        return false;
    }
    if (dr.realIsNaN(x) or (dr.realIsNegative(x) and !dr.realIsZero(x))) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function chi2CheckDomain:", "cannot calculate for x < 0", null, null);
        return false;
    }
    if (dr.realIsZero(i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function chi2CheckDomain:", "cannot calculate for k \xa2\x64 0", null, null);
        return false;
    }
    return true;
}

pub fn chi2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CHI2 * 4 + dr.DIST_P);
}

pub fn chi2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CHI2 * 4 + dr.DIST_L);
}

pub fn chi2R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CHI2 * 4 + dr.DIST_R);
}

pub fn chi2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CHI2 * 4 + dr.DIST_I);
}

// The logarithm of the density, with the Lanczos sum for the gamma of k/2 and
// a cancellation-free form of (k/2 - 1) ln(x/2) - x/2 next to the mode.
fn chi2LogDensity(x: *const real_t, k: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var a: real_t = undefined;
    var y: real_t = undefined;
    var argument: real_t = undefined;
    var sum: real_t = undefined;
    var r: real_t = undefined;
    var delta: real_t = undefined;
    var logarithm: real_t = undefined;
    var term: real_t = undefined;
    var coefficient: real_t = undefined;

    dr.realMultiply(k, dr.const1on2(), &a, real_context);
    dr.realMultiply(x, dr.const1on2(), &y, real_context);
    dr.realSubtract(&a, dr.const1(), &argument, real_context);
    dr.WP34S_LanczosSum(&argument, dr.const29(), &sum, real_context);
    dr.WP34S_Ln(&sum, &sum, real_context);
    dr.realAdd(&a, dr.constGammaRm1(), &r, real_context);
    dr.realSubtract(&y, &r, &delta, real_context);
    dr.realDivide(&delta, &r, &delta, real_context);

    if (dr.realCompareAbsLessThan(&delta, dr.const1e_6())) {
        dr.WP34S_Ln1P(&delta, &logarithm, real_context);
        dr.WP34S_Log1pMinus(&delta, &term, real_context);
        dr.realMultiply(&a, &term, res, real_context);
        dr.realSubtract(res, &logarithm, res, real_context);
        dr.realMultiply(dr.constGammaRm1(), &delta, &term, real_context);
        dr.realSubtract(res, &term, res, real_context);
    } else {
        dr.realDivide(&y, &r, &logarithm, real_context);
        dr.WP34S_Ln(&logarithm, &logarithm, real_context);
        dr.realSubtract(&a, dr.const1(), &coefficient, real_context);
        dr.realMultiply(&coefficient, &logarithm, res, real_context);
        dr.realSubtract(&r, &y, &term, real_context);
        dr.realAdd(res, &term, res, real_context);
    }
    dr.WP34S_Ln(&r, &term, real_context);
    dr.realMultiply(&term, dr.const1on2(), &term, real_context);
    dr.realSubtract(res, &term, res, real_context);
    dr.realSubtract(res, &sum, res, real_context);
    dr.realSubtract(res, dr.const75Ln2(), res, real_context);
}

fn chi2ProbabilityWide(x: *const real_t, k: *const real_t, res: *real_t, upper: bool, real_context: *realContext_t) linksection(dr.code_section) void {
    var argument: real_t = undefined;
    var shape: real_t = undefined;

    dr.realMultiply(x, dr.const1on2(), &argument, real_context);
    dr.realMultiply(k, dr.const1on2(), &shape, real_context);
    dr.WP34S_GammaP(&argument, &shape, res, real_context, upper, true);
}

fn chi2MarkInterior(value: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    dr.WP34S_AdjustPositiveUnderflow(value);
    if (dr.realEqual(value, dr.const1())) {
        dr.realNextToward(value, dr.const0(), value, real_context);
    }
}

pub fn wp34sPdfChi2(x: *const real_t, k: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var logarithm: real_t = undefined;
    var value: real_t = undefined;
    const calculation_context = dr.WP34S_AtLeastContext(real_context, &dr.ctxtReal51);

    if (!dr.WP34S_IsPositiveFinite(k) or dr.realIsNaN(x) or (dr.realIsNegative(x) and !dr.realIsZero(x))) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        if (dr.realLessThan(k, dr.const2())) {
            dr.setPlusInfinity(res);
        } else if (dr.realEqual(k, dr.const2())) {
            dr.realCopy(dr.const1on2(), res);
        } else {
            dr.setZero(res);
        }
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }

    chi2LogDensity(x, k, &logarithm, calculation_context);
    dr.realExponential(&logarithm, &value, calculation_context);
    dr.WP34S_AdjustPositiveUnderflow(&value);
    dr.realPlus(&value, res, real_context);
}

fn chi2Probability(x: *const real_t, k: *const real_t, res: *real_t, upper: bool, real_context: *realContext_t) linksection(dr.code_section) void {
    var value: real_t = undefined;
    const calculation_context = dr.WP34S_AtLeastContext(real_context, &dr.ctxtReal39);

    if (!dr.WP34S_IsPositiveFinite(k) or dr.realIsNaN(x) or (dr.realIsNegative(x) and !dr.realIsZero(x))) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        if (upper) {
            dr.setOne(res);
        } else {
            dr.setZero(res);
        }
        return;
    }
    if (dr.realIsInfinite(x)) {
        if (upper) {
            dr.setZero(res);
        } else {
            dr.setOne(res);
        }
        return;
    }

    chi2ProbabilityWide(x, k, &value, upper, calculation_context);
    if (!dr.realIsNaN(&value)) {
        chi2MarkInterior(&value, calculation_context);
    }
    dr.realPlus(&value, res, real_context);
}

pub fn wp34sCdfuChi2(x: *const real_t, k: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    chi2Probability(x, k, res, true, real_context);
}

pub fn wp34sCdfChi2(x: *const real_t, k: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    chi2Probability(x, k, res, false, real_context);
}

// The probability at e^logValue less the target, and the derivative of that
// residual with respect to logValue; false where the probability is NaN.
fn chi2InverseResidual(log_value: *const real_t, k: *const real_t, target: *const real_t, upper: bool, value: *real_t, residual: *real_t, derivative: *real_t) linksection(dr.code_section) bool {
    var probability: real_t = undefined;
    var log_density: real_t = undefined;

    dr.realExponential(log_value, value, &dr.ctxtReal51);
    chi2ProbabilityWide(value, k, &probability, upper, &dr.ctxtReal51);
    if (dr.realIsNaN(&probability)) {
        return false;
    }
    if (upper) {
        dr.realSubtract(target, &probability, residual, &dr.ctxtReal51);
    } else {
        dr.realSubtract(&probability, target, residual, &dr.ctxtReal51);
    }
    chi2LogDensity(value, k, &log_density, &dr.ctxtReal51);
    dr.realExponential(&log_density, derivative, &dr.ctxtReal51);
    dr.realMultiply(value, derivative, derivative, &dr.ctxtReal51);
    return true;
}

// A bracket in log x around the quantile, grown from the initial guess by
// doubling steps of sqrt(2/k).
fn chi2InverseBracket(initial: *const real_t, k: *const real_t, target: *const real_t, upper: bool, low: *real_t, high: *real_t) linksection(dr.code_section) bool {
    var value: real_t = undefined;
    var residual: real_t = undefined;
    var derivative: real_t = undefined;
    var distance: real_t = undefined;
    var proposal: real_t = undefined;
    var low_bound: real_t = undefined;
    var high_bound: real_t = undefined;

    dr.int32ToReal(-30000, &low_bound);
    dr.int32ToReal(16000, &high_bound);
    if (!chi2InverseResidual(initial, k, target, upper, &value, &residual, &derivative)) {
        return false;
    }
    if (dr.realIsNegative(&residual)) {
        dr.realCopy(initial, low);
        dr.realDivide(dr.const2(), k, &distance, &dr.ctxtReal51);
        dr.realSquareRoot(&distance, &distance, &dr.ctxtReal51);
        var iteration: i32 = 0;
        while (iteration < 20) : (iteration += 1) {
            dr.realAdd(initial, &distance, &proposal, &dr.ctxtReal51);
            if (dr.realGreaterThan(&proposal, &high_bound)) {
                dr.realCopy(&high_bound, &proposal);
            }
            if (!chi2InverseResidual(&proposal, k, target, upper, &value, &residual, &derivative)) {
                return false;
            }
            if (!dr.realIsNegative(&residual)) {
                dr.realCopy(&proposal, high);
                return true;
            }
            dr.realCopy(&proposal, low);
            if (dr.realEqual(&proposal, &high_bound)) {
                return false;
            }
            dr.realMultiply(&distance, dr.const2(), &distance, &dr.ctxtReal51);
        }
    } else {
        dr.realCopy(initial, high);
        dr.realDivide(dr.const2(), k, &distance, &dr.ctxtReal51);
        dr.realSquareRoot(&distance, &distance, &dr.ctxtReal51);
        var iteration: i32 = 0;
        while (iteration < 20) : (iteration += 1) {
            dr.realSubtract(initial, &distance, &proposal, &dr.ctxtReal51);
            if (dr.realLessThan(&proposal, &low_bound)) {
                dr.realCopy(&low_bound, &proposal);
            }
            if (!chi2InverseResidual(&proposal, k, target, upper, &value, &residual, &derivative)) {
                return false;
            }
            if (!dr.realIsPositive(&residual) or dr.realIsZero(&residual)) {
                dr.realCopy(&proposal, low);
                return true;
            }
            dr.realCopy(&proposal, high);
            if (dr.realEqual(&proposal, &low_bound)) {
                return false;
            }
            dr.realMultiply(&distance, dr.const2(), &distance, &dr.ctxtReal51);
        }
    }
    return false;
}

pub fn wp34sQfChi2(x: *const real_t, k: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var target: real_t = undefined;
    var initial: real_t = undefined;
    var low: real_t = undefined;
    var high: real_t = undefined;
    var log_value: real_t = undefined;
    var value: real_t = undefined;
    var residual: real_t = undefined;
    var derivative: real_t = undefined;
    var width: real_t = undefined;
    var tolerance: real_t = undefined;
    var step: real_t = undefined;
    var proposal: real_t = undefined;
    var midpoint: real_t = undefined;
    var large_k: real_t = undefined;

    if (dr.realIsNaN(x) or !dr.WP34S_IsPositiveFinite(k) or dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, dr.const1())) {
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
    dr.WP34S_SetPowerOfTen(80, &large_k);
    if (dr.realCompareGreaterEqual(k, &large_k)) {
        dr.realNextToward(k, if (dr.realGreaterThan(x, dr.const1on2())) dr.constPlusInfinity() else dr.const0(), &value, &dr.ctxtReal39);
        dr.realPlus(&value, res, real_context);
        return;
    }

    const upper = dr.realGreaterThan(x, dr.const1on2());
    if (upper) {
        dr.realSubtract(dr.const1(), x, &target, &dr.ctxtReal51);
    } else {
        dr.realCopy(x, &target);
    }
    dr.WP34S_Ln(k, &initial, &dr.ctxtReal51);
    if (!chi2InverseBracket(&initial, k, &target, upper, &low, &high)) {
        dr.setNaN(res);
        return;
    }

    dr.setOne(&tolerance);
    tolerance.exponent = -40;
    dr.realAdd(&low, &high, &log_value, &dr.ctxtReal51);
    dr.realMultiply(&log_value, dr.const1on2(), &log_value, &dr.ctxtReal51);
    var iteration: i32 = 0;
    while (iteration < 240) : (iteration += 1) {
        if (!chi2InverseResidual(&log_value, k, &target, upper, &value, &residual, &derivative)) {
            dr.setNaN(res);
            return;
        }
        if (dr.realIsNegative(&residual)) {
            dr.realCopy(&log_value, &low);
        } else {
            dr.realCopy(&log_value, &high);
        }
        dr.realSubtract(&high, &low, &width, &dr.ctxtReal51);
        if (dr.realCompareAbsLessThan(&width, &tolerance)) {
            dr.realAdd(&low, &high, &log_value, &dr.ctxtReal51);
            dr.realMultiply(&log_value, dr.const1on2(), &log_value, &dr.ctxtReal51);
            dr.realExponential(&log_value, &value, &dr.ctxtReal51);
            dr.WP34S_AdjustPositiveUnderflow(&value);
            dr.realPlus(&value, res, real_context);
            return;
        }

        dr.realAdd(&low, &high, &midpoint, &dr.ctxtReal51);
        dr.realMultiply(&midpoint, dr.const1on2(), &midpoint, &dr.ctxtReal51);
        if (iteration >= 24 or dr.realIsZero(&derivative) or dr.realIsSpecial(&derivative)) {
            dr.realCopy(&midpoint, &proposal);
        } else {
            dr.realDivide(&residual, &derivative, &step, &dr.ctxtReal51);
            dr.realSubtract(&log_value, &step, &proposal, &dr.ctxtReal51);
            if (dr.realCompareLessEqual(&proposal, &low) or dr.realCompareGreaterEqual(&proposal, &high)) {
                dr.realCopy(&midpoint, &proposal);
            }
        }
        dr.realCopy(&proposal, &log_value);
    }
    dr.setNaN(res);
}
