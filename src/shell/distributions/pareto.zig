// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/pareto.c: the type I and type II Pareto
// distribution commands. The entry points load register X, the location in M
// (type II only), the scale in S and the shape in Q through
// WP34S_CheckDistributionParameters and keep their own bodies, since the Pareto
// has no row in the descriptor table. Every probability is formed from the
// logarithm of the survival function at 51 digits; the type II quantile widens
// to 75 and then 159 digits as the location cancels the scaled term. Tagged
// linksection(dr.code_section) so the code runs from QSPI on the flash-limited
// old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// paretoCheckDomain: the variate and the parameters of a Pareto calculation.
fn checkDomain(registers_valid: bool, x: *real_t, mu: ?*real_t, sigma: ?*real_t, alpha: ?*real_t, qf: u16) linksection(dr.code_section) callconv(.c) bool {
    if (!registers_valid) {
        return false;
    }
    const scale = sigma.?;
    const shape = alpha.?;

    if (dr.realIsNaN(x) or (qf != 0 and dr.realIsInfinite(x))) {
        if (!dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function paretoCheckDomain:", "the argument is not finite", null, null);
        }
        return false;
    }
    if ((mu != null and dr.realIsSpecial(mu.?)) or dr.realIsSpecial(scale) or dr.realCompareLessEqual(scale, dr.const0()) or
        dr.realIsSpecial(shape) or dr.realCompareLessEqual(shape, dr.const0()))
    {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function paretoCheckDomain:", "location, scale, or shape parameter is invalid", null, null);
        return false;
    }
    if (qf == 0 and dr.realLessThan(x, if (mu) |location| location else scale)) {
        if (!dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function paretoCheckDomain:", "the argument is below the distribution support", null, null);
        }
        return false;
    }
    return true;
}

fn paretoParameters(x: *real_t, mu: ?*real_t, sigma: *real_t, alpha: *real_t, qf: bool) linksection(dr.code_section) bool {
    return dr.WP34S_CheckDistributionParameters(x, dr.REGISTER_M, mu, dr.REGISTER_S, sigma, dr.REGISTER_Q, alpha, @intFromBool(qf), checkDomain);
}

// The logarithm of the Pareto survival probability.
fn paretoLogSurvival(distance: *const real_t, sigma: *const real_t, alpha: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var relative_storage: dr.Real159 = undefined;
    const relative = relative_storage.ptr();

    dr.realDivide(distance, sigma, relative, real_context);
    dr.WP34S_Ln1P(relative, res, real_context);
    dr.realMultiply(res, alpha, res, real_context);
    dr.realChangeSign(res);
}

// A Pareto density from its nonnegative support distance.
fn paretoDensity(distance: *const real_t, sigma: *const real_t, alpha: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var denominator_storage: dr.Real159 = undefined;
    var log_survival_storage: dr.Real159 = undefined;
    const denominator = denominator_storage.ptr();
    const log_survival = log_survival_storage.ptr();

    if (dr.realIsInfinite(distance)) {
        dr.setZero(res);
        return;
    }
    paretoLogSurvival(distance, sigma, alpha, log_survival, real_context);
    dr.realExponential(log_survival, res, real_context);
    dr.realMultiply(res, alpha, res, real_context);
    dr.realAdd(distance, sigma, denominator, real_context);
    dr.realDivide(res, denominator, res, real_context);
    if (dr.realIsZero(res)) {
        dr.realNextToward(res, dr.const1(), res, real_context);
    }
}

// A Pareto lower probability from its support distance.
fn paretoLower(distance: *const real_t, sigma: *const real_t, alpha: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    paretoLogSurvival(distance, sigma, alpha, res, real_context);
    dr.WP34S_ExpM1(res, res, real_context);
    dr.realChangeSign(res);
    if (!dr.realIsZero(distance) and !dr.realIsInfinite(distance)) {
        dr.WP34S_MarkProbability(res, real_context);
    }
}

// A Pareto upper probability from its support distance.
fn paretoUpper(distance: *const real_t, sigma: *const real_t, alpha: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    paretoLogSurvival(distance, sigma, alpha, res, real_context);
    dr.realExponential(res, res, real_context);
    if (!dr.realIsZero(distance) and !dr.realIsInfinite(distance)) {
        dr.WP34S_MarkProbability(res, real_context);
    }
}

// log(1 - p) without a finite-width subtraction near p = 0: the atanh series of
// (1 - p) after repeated square roots have brought it next to 1.
fn paretoLogOneMinusExtended(probability: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var argument_storage: dr.Real159 = undefined;
    var denominator_storage: dr.Real159 = undefined;
    var factor_storage: dr.Real159 = undefined;
    var previous_storage: dr.Real159 = undefined;
    var square_storage: dr.Real159 = undefined;
    var sum_storage: dr.Real159 = undefined;
    var term_storage: dr.Real159 = undefined;
    var value_storage: dr.Real159 = undefined;
    const argument = argument_storage.ptr();
    const denominator = denominator_storage.ptr();
    const factor = factor_storage.ptr();
    const previous = previous_storage.ptr();
    const square = square_storage.ptr();
    const sum = sum_storage.ptr();
    const term = term_storage.ptr();
    const value = value_storage.ptr();

    if (dr.realCompareLessEqual(probability, dr.const1on2())) {
        dr.realSubtract(dr.const2(), probability, denominator, real_context);
        dr.realDivide(probability, denominator, argument, real_context);
        dr.realChangeSign(argument);
        dr.setOne(factor);
    } else {
        dr.realSubtract(dr.const1(), probability, value, real_context);
        dr.setOne(factor);
        while (dr.realCompareLessEqual(value, dr.const39Root2on2())) {
            dr.realSquareRoot(value, value, real_context);
            dr.realAdd(factor, factor, factor, real_context);
        }
        dr.realSubtract(value, dr.const1(), argument, real_context);
        dr.realAdd(value, dr.const1(), denominator, real_context);
        dr.realDivide(argument, denominator, argument, real_context);
    }

    dr.realMultiply(argument, argument, square, real_context);
    dr.realCopy(argument, term);
    dr.realCopy(argument, sum);
    var index: i32 = 3;
    while (index < 2001) : (index += 2) {
        dr.realMultiply(term, square, term, real_context);
        dr.int32ToReal(index, denominator);
        dr.realDivide(term, denominator, value, real_context);
        dr.realCopy(sum, previous);
        dr.realAdd(sum, value, sum, real_context);
        if (dr.realEqual(sum, previous)) {
            break;
        }
    }
    dr.realAdd(sum, sum, sum, real_context);
    dr.realMultiply(sum, factor, res, real_context);
}

// exp(x) - 1 for nonnegative x at extended precision.
fn paretoExpM1Extended(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var denominator_storage: dr.Real159 = undefined;
    var previous_storage: dr.Real159 = undefined;
    var term_storage: dr.Real159 = undefined;
    const denominator = denominator_storage.ptr();
    const previous = previous_storage.ptr();
    const term = term_storage.ptr();

    if (dr.realLessThan(x, dr.const1on10())) {
        dr.realCopy(x, term);
        dr.realCopy(x, res);
        var index: i32 = 2;
        while (index < 1001) : (index += 1) {
            dr.realMultiply(term, x, term, real_context);
            dr.int32ToReal(index, denominator);
            dr.realDivide(term, denominator, term, real_context);
            dr.realCopy(res, previous);
            dr.realAdd(res, term, res, real_context);
            if (dr.realEqual(res, previous)) {
                break;
            }
        }
    } else {
        dr.realExponential(x, res, real_context);
        dr.realSubtract(res, dr.const1(), res, real_context);
    }
}

// The type II quantile terms at one work precision.
fn paretoTypeTwoQuantileAtContext(probability: *const real_t, mu: *const real_t, sigma: *const real_t, alpha: *const real_t, scaled: *real_t, value: *real_t, real_context: *realContext_t, extended_log: bool) linksection(dr.code_section) void {
    var delta_storage: dr.Real159 = undefined;
    var log_survival_storage: dr.Real159 = undefined;
    const delta = delta_storage.ptr();
    const log_survival = log_survival_storage.ptr();

    if (extended_log) {
        paretoLogOneMinusExtended(probability, log_survival, real_context);
    } else {
        dr.realMinus(probability, log_survival, real_context);
        dr.WP34S_Ln1P(log_survival, log_survival, real_context);
    }
    dr.realDivide(log_survival, alpha, log_survival, real_context);
    dr.realChangeSign(log_survival);
    if (extended_log) {
        paretoExpM1Extended(log_survival, delta, real_context);
    } else {
        dr.WP34S_ExpM1(log_survival, delta, real_context);
    }
    dr.realMultiply(sigma, delta, scaled, real_context);
    dr.realFMA(sigma, delta, mu, value, real_context);
}

// A type II Pareto quantile with adaptive cancellation work.
fn paretoTypeTwoQuantile(probability: *const real_t, mu: *const real_t, sigma: *const real_t, alpha: *const real_t, res: *real_t) linksection(dr.code_section) void {
    var scaled: real_t = undefined;
    var value: real_t = undefined;

    paretoTypeTwoQuantileAtContext(probability, mu, sigma, alpha, &scaled, &value, &dr.ctxtReal51, false);
    if (dr.WP34S_HasCancellation(mu, &scaled, &value, 8)) {
        paretoTypeTwoQuantileAtContext(probability, mu, sigma, alpha, &scaled, &value, &dr.ctxtReal75, false);
        if (dr.WP34S_HasCancellation(mu, &scaled, &value, 30)) {
            var extended_scaled_storage: dr.Real159 = undefined;
            var extended_value_storage: dr.Real159 = undefined;
            const extended_scaled = extended_scaled_storage.ptr();
            const extended_value = extended_value_storage.ptr();
            var extended_context: realContext_t = dr.ctxtReal75;

            extended_context.digits = 159;
            extended_context.status = 0;
            paretoTypeTwoQuantileAtContext(probability, mu, sigma, alpha, extended_scaled, extended_value, &extended_context, true);
            dr.realPlus(extended_value, res, &dr.ctxtReal75);
            return;
        }
    }
    dr.realCopy(&value, res);
}

// Type I Pareto distribution.
pub fn paretoP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var distance: real_t = undefined;

    if (paretoParameters(&x, null, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &sigma, &distance, &dr.ctxtReal51);
        paretoDensity(&distance, &sigma, &alpha, &x, &dr.ctxtReal51);
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn paretoL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var distance: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;

    if (paretoParameters(&x, null, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &sigma, &distance, &dr.ctxtReal51);
        paretoLower(&distance, &sigma, &alpha, &x, &dr.ctxtReal51);
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn paretoU(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var distance: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;

    if (paretoParameters(&x, null, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &sigma, &distance, &dr.ctxtReal51);
        paretoUpper(&distance, &sigma, &alpha, &x, &dr.ctxtReal51);
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn paretoI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var delta: real_t = undefined;
    var log_survival: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;

    if (paretoParameters(&x, null, &sigma, &alpha, true)) {
        if (dr.realLessThan(&x, dr.const0()) or dr.realGreaterThan(&x, dr.const1())) {
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.setNaN(&x);
                dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
            } else {
                dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            }
            return;
        }
        if (dr.realIsZero(&x)) {
            dr.realCopy(&sigma, &x);
        } else if (dr.realEqual(&x, dr.const1())) {
            dr.setPlusInfinity(&x);
            dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
            return;
        } else {
            dr.realMinus(&x, &log_survival, &dr.ctxtReal51);
            dr.WP34S_Ln1P(&log_survival, &log_survival, &dr.ctxtReal51);
            dr.realDivide(&log_survival, &alpha, &log_survival, &dr.ctxtReal51);
            dr.realChangeSign(&log_survival);
            dr.WP34S_ExpM1(&log_survival, &delta, &dr.ctxtReal51);
            dr.realFMA(&sigma, &delta, &sigma, &x, &dr.ctxtReal51);
            if (dr.realEqual(&x, &sigma)) {
                dr.realNextToward(&x, dr.constPlusInfinity(), &x, &dr.ctxtReal51);
            } else if (dr.realIsInfinite(&x)) {
                dr.realNextToward(&x, dr.const0(), &x, &dr.ctxtReal51);
            }
        }
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

// Type II Pareto distribution.
pub fn pareto2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var distance: real_t = undefined;

    if (paretoParameters(&x, &mu, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &mu, &distance, &dr.ctxtReal51);
        paretoDensity(&distance, &sigma, &alpha, &x, &dr.ctxtReal51);
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn pareto2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var distance: real_t = undefined;

    if (paretoParameters(&x, &mu, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &mu, &distance, &dr.ctxtReal51);
        paretoLower(&distance, &sigma, &alpha, &x, &dr.ctxtReal51);
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn pareto2U(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var distance: real_t = undefined;

    if (paretoParameters(&x, &mu, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &mu, &distance, &dr.ctxtReal51);
        paretoUpper(&distance, &sigma, &alpha, &x, &dr.ctxtReal51);
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn pareto2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;

    if (paretoParameters(&x, &mu, &sigma, &alpha, true)) {
        if (dr.realLessThan(&x, dr.const0()) or dr.realGreaterThan(&x, dr.const1())) {
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.setNaN(&x);
                dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
            } else {
                dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            }
            return;
        }
        if (dr.realIsZero(&x)) {
            dr.realCopy(&mu, &x);
        } else if (dr.realEqual(&x, dr.const1())) {
            dr.setPlusInfinity(&x);
            dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
            return;
        } else {
            paretoTypeTwoQuantile(&x, &mu, &sigma, &alpha, &x);
            if (dr.realEqual(&x, &mu)) {
                dr.realNextToward(&x, dr.constPlusInfinity(), &x, &dr.ctxtReal75);
            } else if (dr.realIsInfinite(&x)) {
                dr.realNextToward(&x, dr.const0(), &x, &dr.ctxtReal75);
            }
        }
        dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}
