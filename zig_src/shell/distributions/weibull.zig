// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Weibull distribution commands, porting
// `src/c47/distributions/weibull.c`. The four fn* entry points are dispatched
// from the items.c function table (exported via frontier.zig); the WP34S_*_Weib
// helpers are weibull-internal and stay private. All decNumber/register access
// goes through frontier_distribution_runtime.

const dr = @import("distribution_runtime.zig");
const real_t = dr.real_t;
const realContext_t = dr.realContext_t;

fn checkParamWeibull(x: *real_t, shape: *real_t, scale: *real_t) linksection(dr.code_section) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_Q, shape) or !dr.getRegisterAsReal(dr.REGISTER_S, scale)) {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamWeibull:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsZero(shape) or dr.realIsNegative(shape) or dr.realIsZero(scale) or dr.realIsNegative(scale)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamWeibull:", "cannot calculate for b <= 0 or t <= 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn weibullP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        wp34sPdfWeib(&val, &lifetime, &shape, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn weibullL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        wp34sCdfWeib(&val, &lifetime, &shape, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn weibullR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        wp34sCdfuWeib(&val, &lifetime, &shape, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn weibullI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var shape: real_t = undefined;
    var lifetime: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamWeibull(&val, &shape, &lifetime)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnWeibullI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfWeib(&val, &lifetime, &shape, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

// These functions are borrowed from the WP34S project.

fn wp34sPdfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    dr.realDivide(x, b, &p, real_context);
    if (dr.realIsSpecial(&p) or dr.realIsNegative(&p) or dr.realIsZero(&p)) {
        dr.setZero(res);
        return;
    }
    dr.realPow(&p, t, &q, real_context);
    dr.realMinus(&q, &r, real_context);
    dr.realExponential(&r, &r, real_context);
    dr.realMultiply(&r, &q, &r, real_context);
    dr.realDivide(&r, &p, &r, real_context);
    dr.realMultiply(&r, t, &r, real_context);
    dr.realDivide(&r, b, res, real_context);
}

fn wp34sCdfuWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;

    dr.realDivide(x, b, &p, real_context);
    if (dr.realIsNegative(&p) or dr.realIsZero(&p)) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsSpecial(&p)) {
        dr.setZero(res);
        return;
    }
    dr.realPow(&p, t, &p, real_context);
    dr.realChangeSign(&p);
    dr.realExponential(&p, res, real_context);
}

fn wp34sCdfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;

    dr.realDivide(x, b, &p, real_context);
    if (dr.realIsNegative(&p) or dr.realIsZero(&p)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsSpecial(&p)) {
        dr.setOne(res);
        return;
    }
    dr.realPow(&p, t, &p, real_context);
    dr.realChangeSign(&p);
    dr.WP34S_ExpM1(&p, res, real_context);
    dr.realChangeSign(res);
}

fn wp34sQfWeib(x: *const real_t, b: *const real_t, t: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    // (-ln(1-p) ^ (1/k)) * J
    var p: real_t = undefined;
    var q: real_t = undefined;

    dr.realMinus(x, &p, real_context);
    dr.WP34S_Ln1P(&p, &p, real_context);
    dr.realChangeSign(&p);
    dr.realDivide(dr.const1(), t, &q, real_context);
    dr.realPow(&p, &q, &p, real_context);
    dr.realMultiply(&p, b, res, real_context);
}
