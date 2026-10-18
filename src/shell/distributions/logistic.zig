// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/logistic.c: the logistic distribution
// commands and the WP34S kernels behind them. The commands hand their descriptor
// row to fnDistribution, which loads register X, the location in M and the scale
// in S. The forward routines widen to 51 digits when the standardised argument
// passes 100; the quantile forms its closing sum at 39, 51 and 75 digits as the
// location cancels the scaled logit, and at 159 past 37 cancelled digits. Tagged
// linksection(dr.code_section) so the code runs from QSPI on the flash-limited
// old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// logisticCheckDomain: a finite location and a positive finite scale.
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = x;
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;
    const j = second.?;

    if (dr.realIsSpecial(i) or dr.realIsSpecial(j) or dr.realIsZero(j) or dr.realIsNegative(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function logisticCheckDomain:", "parameters must be finite and \x83\xc3 > 0", null, null);
        return false;
    }
    return true;
}

pub fn logisticP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_LOGIT * 4 + dr.DIST_P);
}

pub fn logisticL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_LOGIT * 4 + dr.DIST_L);
}

pub fn logisticR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_LOGIT * 4 + dr.DIST_R);
}

pub fn logisticI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_LOGIT * 4 + dr.DIST_I);
}

// Whether the location and scale define a logistic distribution.
fn logisticParametersAreValid(mu: *const real_t, s: *const real_t) linksection(dr.code_section) bool {
    return !dr.realIsSpecial(mu) and !dr.realIsSpecial(s) and !dr.realIsZero(s) and !dr.realIsNegative(s);
}

// The forward calculation context, widened to 51 digits when the standardised
// argument makes the exponential sensitive; `standard` is (x - mu) / s at it.
fn logisticForwardContext(x: *const real_t, mu: *const real_t, s: *const real_t, standard: *real_t, result_context: *realContext_t) linksection(dr.code_section) *realContext_t {
    var calculation_context = result_context;

    dr.realSubtract(x, mu, standard, calculation_context);
    dr.realDivide(standard, s, standard, calculation_context);
    if (calculation_context.digits <= 39 and dr.realCompareAbsGreaterThan(standard, dr.const100())) {
        calculation_context = &dr.ctxtReal51;
        dr.realSubtract(x, mu, standard, calculation_context);
        dr.realDivide(standard, s, standard, calculation_context);
    }
    return calculation_context;
}

// log(p/(1-p)) with a central series at a standard working precision.
fn logisticLogit(probability: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var addend: real_t = undefined;
    var divisor: real_t = undefined;
    var previous: real_t = undefined;
    var square: real_t = undefined;
    var sum: real_t = undefined;
    var tail: real_t = undefined;
    var term: real_t = undefined;

    if (dr.realCompareLessEqual(probability, dr.const1on4()) or dr.realCompareGreaterEqual(probability, dr.const3on4())) {
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realCopy(probability, &tail);
        } else {
            dr.realSubtract(dr.const1(), probability, &tail, real_context);
        }
        dr.realMinus(&tail, &term, real_context);
        dr.WP34S_Ln1P(&term, &sum, real_context);
        dr.WP34S_Ln(&tail, &term, real_context);
        dr.realSubtract(&sum, &term, res, real_context);
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realChangeSign(res);
        }
        return;
    }

    dr.realAdd(probability, probability, &term, real_context);
    dr.realSubtract(&term, dr.const1(), &term, real_context);
    dr.realMultiply(&term, &term, &square, real_context);
    dr.realCopy(&term, &sum);
    dr.int32ToReal(3, &divisor);
    var n: i32 = 0;
    while (n < 1000) : (n += 1) {
        dr.realMultiply(&term, &square, &term, real_context);
        dr.realDivide(&term, &divisor, &addend, real_context);
        dr.realCopy(&sum, &previous);
        dr.realAdd(&sum, &addend, &sum, real_context);
        if (dr.realEqual(&sum, &previous)) {
            break;
        }
        dr.realAdd(&divisor, dr.const2(), &divisor, real_context);
    }
    dr.realMultiply(&sum, dr.const2(), res, real_context);
}

// log(p/(1-p)) at an extended precision, with the extended logarithm in the tails.
fn logisticLogitExtended(probability: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var addend_storage: dr.Real159 = undefined;
    var divisor_storage: dr.Real159 = undefined;
    var log_one_minus_tail_storage: dr.Real159 = undefined;
    var log_tail_storage: dr.Real159 = undefined;
    var one_minus_tail_storage: dr.Real159 = undefined;
    var previous_storage: dr.Real159 = undefined;
    var square_storage: dr.Real159 = undefined;
    var sum_storage: dr.Real159 = undefined;
    var tail_storage: dr.Real159 = undefined;
    var term_storage: dr.Real159 = undefined;
    const addend = addend_storage.ptr();
    const divisor = divisor_storage.ptr();
    const log_one_minus_tail = log_one_minus_tail_storage.ptr();
    const log_tail = log_tail_storage.ptr();
    const one_minus_tail = one_minus_tail_storage.ptr();
    const previous = previous_storage.ptr();
    const square = square_storage.ptr();
    const sum = sum_storage.ptr();
    const tail = tail_storage.ptr();
    const term = term_storage.ptr();
    if (dr.realCompareLessEqual(probability, dr.const1on4()) or dr.realCompareGreaterEqual(probability, dr.const3on4())) {
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realCopy(probability, tail);
        } else {
            dr.realSubtract(dr.const1(), probability, tail, real_context);
        }
        dr.realSubtract(dr.const1(), tail, one_minus_tail, real_context);
        dr.WP34S_LnExtended(one_minus_tail, log_one_minus_tail, real_context);
        dr.WP34S_LnExtended(tail, log_tail, real_context);
        dr.realSubtract(log_one_minus_tail, log_tail, res, real_context);
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realChangeSign(res);
        }
        return;
    }

    dr.realAdd(probability, probability, term, real_context);
    dr.realSubtract(term, dr.const1(), term, real_context);
    dr.realMultiply(term, term, square, real_context);
    dr.realCopy(term, sum);
    dr.int32ToReal(3, divisor);
    var n: i32 = 0;
    while (n < 1000) : (n += 1) {
        dr.realMultiply(term, square, term, real_context);
        dr.realDivide(term, divisor, addend, real_context);
        dr.realCopy(sum, previous);
        dr.realAdd(sum, addend, sum, real_context);
        if (dr.realEqual(sum, previous)) {
            break;
        }
        dr.realAdd(divisor, dr.const2(), divisor, real_context);
    }
    dr.realMultiply(sum, dr.const2(), res, real_context);
}

// The quantile and the terms of its closing sum, at one working context.
fn logisticQuantileAtContext(probability: *const real_t, mu: *const real_t, s: *const real_t, logit: *real_t, scaled: *real_t, value: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    logisticLogit(probability, logit, real_context);
    dr.realMultiply(logit, s, scaled, real_context);
    dr.realFMA(logit, s, mu, value, real_context);
}

// The quantile recomputed at 159 digits after deep location-scale cancellation.
fn logisticQuantileExtended(probability: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, result_context: *realContext_t) linksection(dr.code_section) void {
    var logit_storage: dr.Real159 = undefined;
    var value_storage: dr.Real159 = undefined;
    const logit = logit_storage.ptr();
    const value = value_storage.ptr();
    var real_context: realContext_t = dr.ctxtReal75;

    real_context.digits = 159;
    real_context.status = 0;
    logisticLogitExtended(probability, logit, &real_context);
    dr.realFMA(logit, s, mu, value, &real_context);
    dr.realPlus(value, res, result_context);
}

pub fn wp34sPdfLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var denominator: real_t = undefined;
    var exponential: real_t = undefined;
    var one_plus_exponential: real_t = undefined;
    var standard: real_t = undefined;
    var value: real_t = undefined;

    if (dr.realIsNaN(x) or !logisticParametersAreValid(mu, s)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    const calculation_context = logisticForwardContext(x, mu, s, &standard, real_context);
    dr.realSetPositiveSign(&standard);
    dr.realChangeSign(&standard);
    dr.realExponential(&standard, &exponential, calculation_context);
    if (dr.realIsZero(&exponential)) {
        dr.realNextToward(&exponential, dr.const1(), &exponential, calculation_context);
    }
    dr.realAdd(dr.const1(), &exponential, &one_plus_exponential, calculation_context);
    dr.realMultiply(&one_plus_exponential, &one_plus_exponential, &denominator, calculation_context);
    dr.realMultiply(&denominator, s, &denominator, calculation_context);
    dr.realDivide(&exponential, &denominator, &value, calculation_context);
    if (dr.realIsZero(&value)) {
        dr.realNextToward(&value, dr.const1(), &value, calculation_context);
    }
    dr.realPlus(&value, res, real_context);
    if (dr.realIsZero(res) and !dr.realIsZero(&value)) {
        dr.realNextToward(res, dr.const1(), res, real_context);
    }
}

// Either logistic probability, formed from the smaller tail.
fn logisticCdfCommon(x: *const real_t, mu: *const real_t, s: *const real_t, upper: bool, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var exponential: real_t = undefined;
    var small: real_t = undefined;
    var standard: real_t = undefined;
    var value: real_t = undefined;

    if (dr.realIsNaN(x) or !logisticParametersAreValid(mu, s)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.realCopy(if (dr.realIsNegative(x) != upper) dr.const0() else dr.const1(), res);
        return;
    }
    const calculation_context = logisticForwardContext(x, mu, s, &standard, real_context);
    const small_result = dr.realIsNegative(&standard) != upper;
    dr.realCopy(&standard, &exponential);
    dr.realSetPositiveSign(&exponential);
    dr.realChangeSign(&exponential);
    dr.realExponential(&exponential, &exponential, calculation_context);
    if (dr.realIsZero(&exponential)) {
        dr.realNextToward(&exponential, dr.const1(), &exponential, calculation_context);
    }
    dr.realAdd(dr.const1(), &exponential, &standard, calculation_context);
    dr.realDivide(&exponential, &standard, &small, calculation_context);
    if (small_result) {
        dr.realCopy(&small, &value);
    } else {
        dr.realSubtract(dr.const1(), &small, &value, calculation_context);
        if (dr.realEqual(&value, dr.const1()) and !dr.realIsZero(&small)) {
            dr.realNextToward(&value, dr.const0(), &value, calculation_context);
        }
    }
    dr.realPlus(&value, res, real_context);
    if (small_result and dr.realIsZero(res) and !dr.realIsZero(&value)) {
        dr.realNextToward(res, dr.const1(), res, real_context);
    } else if (!small_result and dr.realEqual(res, dr.const1()) and !dr.realEqual(&value, dr.const1())) {
        dr.realNextToward(res, dr.const0(), res, real_context);
    }
}

pub fn wp34sCdfuLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    logisticCdfCommon(x, mu, s, true, res, real_context);
}

pub fn wp34sCdfLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    logisticCdfCommon(x, mu, s, false, res, real_context);
}

pub fn wp34sQfLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var logit: real_t = undefined;
    var scaled: real_t = undefined;
    var value: real_t = undefined;

    if (dr.realIsNaN(x) or !logisticParametersAreValid(mu, s) or dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, dr.const1())) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x) or dr.realEqual(x, dr.const1())) {
        dr.setPlusInfinity(res);
        if (dr.realIsZero(x)) {
            dr.realSetNegativeSign(res);
        }
        return;
    }
    if (dr.realEqual(x, dr.const1on2())) {
        dr.realCopy(mu, res);
        return;
    }

    logisticQuantileAtContext(x, mu, s, &logit, &scaled, &value, &dr.ctxtReal39);
    if (dr.WP34S_HasCancellation(mu, &scaled, &value, 1)) {
        logisticQuantileAtContext(x, mu, s, &logit, &scaled, &value, &dr.ctxtReal51);
        if (dr.WP34S_HasCancellation(mu, &scaled, &value, 13)) {
            logisticQuantileAtContext(x, mu, s, &logit, &scaled, &value, &dr.ctxtReal75);
            if (dr.WP34S_HasCancellation(mu, &scaled, &value, 37)) {
                logisticQuantileExtended(x, mu, s, res, real_context);
            } else {
                dr.realPlus(&value, res, real_context);
            }
        } else {
            dr.realPlus(&value, res, real_context);
        }
    } else {
        dr.realPlus(&value, res, real_context);
    }
}
