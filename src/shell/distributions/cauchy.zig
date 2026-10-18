// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/cauchy.c: the Cauchy distribution commands
// and the WP34S kernels behind them. The commands hand their descriptor row to
// fnDistribution, which loads register X, the location in M and the scale in S.
// The quantile forms its closing sum at 51 digits, again at 75 when the location
// cancels the scaled term by more than 8 digits, and at 159 past 34 cancelled
// digits. Tagged linksection(dr.code_section) so the code runs from QSPI on the
// flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// cauchyCheckDomain: a finite location and a positive finite scale.
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
        dr.moreInfoOnError("In function cauchyCheckDomain:", "cannot calculate for \x83\xb3 \xa2\x64 0", null, null);
        return false;
    }
    return true;
}

pub fn cauchyP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CAUCHY * 4 + dr.DIST_P);
}

pub fn cauchyL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CAUCHY * 4 + dr.DIST_L);
}

pub fn cauchyR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CAUCHY * 4 + dr.DIST_R);
}

pub fn cauchyI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_CAUCHY * 4 + dr.DIST_I);
}

// Whether the location and scale define a Cauchy distribution.
fn cauchyParametersAreValid(x0: *const real_t, gamma: *const real_t) linksection(dr.code_section) bool {
    return !dr.realIsSpecial(x0) and !dr.realIsSpecial(gamma) and !dr.realIsZero(gamma) and !dr.realIsNegative(gamma);
}

// Sine and cosine of an angle no greater than pi/4 in magnitude, by their
// Taylor series at the context's width.
fn cauchySinCosExtended(angle: *const real_t, sine: *real_t, cosine: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var cosine_term_storage: dr.Real159 = undefined;
    var previous_storage: dr.Real159 = undefined;
    var sine_term_storage: dr.Real159 = undefined;
    var square_storage: dr.Real159 = undefined;
    const cosine_term = cosine_term_storage.ptr();
    const previous = previous_storage.ptr();
    const sine_term = sine_term_storage.ptr();
    const square = square_storage.ptr();
    var denominator: real_t = undefined;

    dr.realMultiply(angle, angle, square, real_context);
    dr.realChangeSign(square);
    dr.realCopy(angle, sine_term);
    dr.realCopy(angle, sine);
    dr.setOne(cosine_term);
    dr.setOne(cosine);
    var index: i32 = 1;
    while (index < 1000) : (index += 1) {
        dr.int32ToReal((2 * index - 1) * (2 * index), &denominator);
        dr.realMultiply(cosine_term, square, cosine_term, real_context);
        dr.realDivide(cosine_term, &denominator, cosine_term, real_context);
        dr.realCopy(cosine, previous);
        dr.realAdd(cosine, cosine_term, cosine, real_context);
        const cosine_unchanged = dr.realEqual(cosine, previous);

        dr.int32ToReal((2 * index) * (2 * index + 1), &denominator);
        dr.realMultiply(sine_term, square, sine_term, real_context);
        dr.realDivide(sine_term, &denominator, sine_term, real_context);
        dr.realCopy(sine, previous);
        dr.realAdd(sine, sine_term, sine, real_context);
        const sine_unchanged = dr.realEqual(sine, previous);

        if (sine_unchanged and cosine_unchanged) {
            break;
        }
    }
}

// The quantile recomputed at 159 digits after severe location-scale cancellation.
fn cauchyQuantileExtended(probability: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, result_context: *realContext_t) linksection(dr.code_section) void {
    var angle_storage: dr.Real159 = undefined;
    var cosine_storage: dr.Real159 = undefined;
    var value_storage: dr.Real159 = undefined;
    const angle = angle_storage.ptr();
    const cosine = cosine_storage.ptr();
    const value = value_storage.ptr();
    var p: real_t = undefined;
    var real_context: realContext_t = dr.ctxtReal75;

    real_context.digits = 159;
    real_context.status = 0;
    if (dr.realLessThan(probability, dr.const1on4()) or dr.realGreaterThan(probability, dr.const3on4())) {
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realCopy(probability, &p);
        } else {
            dr.realSubtract(dr.const1(), probability, &p, &real_context);
        }
        dr.realMultiply(&p, dr.const1071Pi(), angle, &real_context);
        cauchySinCosExtended(angle, angle, cosine, &real_context);
        dr.realDivide(cosine, angle, angle, &real_context);
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realChangeSign(angle);
        }
    } else {
        dr.realSubtract(probability, dr.const1on2(), &p, &real_context);
        dr.realMultiply(&p, dr.const1071Pi(), angle, &real_context);
        cauchySinCosExtended(angle, angle, cosine, &real_context);
        dr.realDivide(angle, cosine, angle, &real_context);
    }
    dr.realFMA(angle, gamma, x0, value, &real_context);
    dr.realPlus(value, res, result_context);
}

// The quantile and the two terms of its closing sum, at one working context.
fn cauchyQuantileAtContext(probability: *const real_t, x0: *const real_t, gamma: *const real_t, tangent: *real_t, scaled: *real_t, value: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var angle: real_t = undefined;
    var cosine: real_t = undefined;
    var p: real_t = undefined;
    var sine: real_t = undefined;
    const pi = dr.piForContext(real_context);

    if (dr.realLessThan(probability, dr.const1on4()) or dr.realGreaterThan(probability, dr.const3on4())) {
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realCopy(probability, &p);
        } else {
            dr.realSubtract(dr.const1(), probability, &p, real_context);
        }
        dr.realMultiply(&p, pi, &angle, real_context);
        cauchySinCosExtended(&angle, &sine, &cosine, real_context);
        dr.realDivide(&cosine, &sine, tangent, real_context);
        if (dr.realLessThan(probability, dr.const1on2())) {
            dr.realChangeSign(tangent);
        }
    } else {
        dr.realSubtract(probability, dr.const1on2(), &p, real_context);
        dr.realMultiply(&p, pi, &angle, real_context);
        cauchySinCosExtended(&angle, &sine, &cosine, real_context);
        dr.realDivide(&sine, &cosine, tangent, real_context);
    }
    dr.realMultiply(tangent, gamma, scaled, real_context);
    dr.realFMA(tangent, gamma, x0, value, real_context);
}

pub fn wp34sPdfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var difference: real_t = undefined;
    var factor: real_t = undefined;
    var ratio: real_t = undefined;
    const pi = dr.piForContext(real_context);

    if (dr.realIsNaN(x) or !cauchyParametersAreValid(x0, gamma)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    dr.realSubtract(x, x0, &difference, real_context);
    dr.realSetPositiveSign(&difference);
    if (dr.realCompareLessEqual(&difference, gamma)) {
        dr.realDivide(&difference, gamma, &ratio, real_context);
        dr.realFMA(&ratio, &ratio, dr.const1(), &factor, real_context);
        dr.realMultiply(&factor, gamma, &factor, real_context);
        dr.realMultiply(&factor, pi, &factor, real_context);
        dr.realDivide(dr.const1(), &factor, res, real_context);
    } else {
        dr.realDivide(gamma, &difference, &ratio, real_context);
        dr.realFMA(&ratio, &ratio, dr.const1(), &factor, real_context);
        dr.realMultiply(&factor, &difference, &factor, real_context);
        dr.realMultiply(&factor, pi, &factor, real_context);
        dr.realDivide(&ratio, &factor, res, real_context);
    }
}

pub fn wp34sCdfuCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    wp34sCdfCauchyCommon(x, x0, gamma, true, res, real_context);
}

pub fn wp34sCdfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    wp34sCdfCauchyCommon(x, x0, gamma, false, res, real_context);
}

pub fn wp34sCdfCauchyCommon(x: *const real_t, x0: *const real_t, gamma: *const real_t, complementary: bool, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var argument: real_t = undefined;
    var p: real_t = undefined;
    const pi = dr.piForContext(real_context);

    if (dr.realIsNaN(x) or !cauchyParametersAreValid(x0, gamma)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.realCopy(if (dr.realIsNegative(x) != complementary) dr.const0() else dr.const1(), res);
        return;
    }
    wp34sCdfCauchyXform(x, x0, gamma, &p, real_context);
    const small_result = dr.realIsNegative(&p) != complementary;
    dr.realSetPositiveSign(&p);
    if (dr.realGreaterThan(&p, dr.const1())) {
        dr.realDivide(dr.const1(), &p, &argument, real_context);
        dr.C47_WP34S_Atan(&argument, &argument, real_context);
        dr.realDivide(&argument, pi, &argument, real_context);
        if (small_result) {
            dr.realCopy(&argument, res);
        } else {
            dr.realSubtract(dr.const1(), &argument, res, real_context);
            if (dr.realEqual(res, dr.const1()) and !dr.realIsZero(&argument)) {
                dr.realNextToward(res, dr.const0(), res, real_context);
            }
        }
    } else {
        dr.C47_WP34S_Atan(&p, &argument, real_context);
        dr.realDivide(&argument, pi, &argument, real_context);
        if (small_result) {
            dr.realSubtract(dr.const1on2(), &argument, res, real_context);
        } else {
            dr.realAdd(dr.const1on2(), &argument, res, real_context);
        }
        if (dr.realEqual(res, dr.const1on2()) and !dr.realIsZero(&argument)) {
            dr.realNextToward(res, if (small_result) dr.const0() else dr.const1(), res, real_context);
        }
    }
}

pub fn wp34sCdfCauchyXform(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    dr.realSubtract(x, x0, res, real_context);
    dr.realDivide(res, gamma, res, real_context);
}

pub fn wp34sQfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var scaled: real_t = undefined;
    var tangent: real_t = undefined;
    var value: real_t = undefined;

    if (dr.realIsNaN(x) or !cauchyParametersAreValid(x0, gamma) or dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, dr.const1())) {
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
        dr.realCopy(x0, res);
        return;
    }
    if (dr.realEqual(x, dr.const1on4())) {
        dr.realSubtract(x0, gamma, &value, &dr.ctxtReal75);
        dr.realPlus(&value, res, real_context);
        return;
    }
    if (dr.realEqual(x, dr.const3on4())) {
        dr.realAdd(x0, gamma, &value, &dr.ctxtReal75);
        dr.realPlus(&value, res, real_context);
        return;
    }

    cauchyQuantileAtContext(x, x0, gamma, &tangent, &scaled, &value, &dr.ctxtReal51);
    if (dr.WP34S_HasCancellation(x0, &scaled, &value, 8)) {
        cauchyQuantileAtContext(x, x0, gamma, &tangent, &scaled, &value, &dr.ctxtReal75);
        if (dr.WP34S_HasCancellation(x0, &scaled, &value, 34)) {
            cauchyQuantileExtended(x, x0, gamma, res, real_context);
        } else {
            dr.realPlus(&value, res, real_context);
        }
    } else {
        dr.realPlus(&value, res, real_context);
    }
}
