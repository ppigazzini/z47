// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Logistic distribution commands, porting
// `src/c47/distributions/logistic.c`. The four fn* entry points are dispatched
// from the items.c function table (exported via shell.zig); the WP34S_*_Logit
// helpers are logistic-internal and stay private. All decNumber/register access
// goes through distribution_runtime.zig.

const dr = @import("distribution_runtime.zig");
const real_t = dr.real_t;
const realContext_t = dr.realContext_t;

fn checkParamLogistic(x: *real_t, mu: *real_t, s: *real_t) linksection(dr.code_section) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, mu) or !dr.getRegisterAsReal(dr.REGISTER_S, s)) {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsZero(s) or dr.realIsNegative(s)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamLogistic:", "cannot calculate for sigma <= 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn logisticP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var mu: real_t = undefined;
    var s: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamLogistic(&val, &mu, &s)) {
        wp34sPdfLogit(&val, &mu, &s, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn logisticL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var mu: real_t = undefined;
    var s: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamLogistic(&val, &mu, &s)) {
        wp34sCdfLogit(&val, &mu, &s, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn logisticR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var mu: real_t = undefined;
    var s: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamLogistic(&val, &mu, &s)) {
        wp34sCdfuLogit(&val, &mu, &s, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn logisticI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var mu: real_t = undefined;
    var s: real_t = undefined;
    var ans: real_t = undefined;

    if (checkParamLogistic(&val, &mu, &s)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnLogisticI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfLogit(&val, &mu, &s, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

// These functions are borrowed from the WP34S project.

fn cdfLogitCommon(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;

    dr.WP34S_Tanh(x, &p, real_context);
    dr.realAdd(&p, dr.const1(), &p, real_context);
    dr.realMultiply(&p, dr.const1on2(), res, real_context);
}

// Extract the logistic rescaled parameter (x-J) / 2K.
fn logisticParam(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;

    dr.realSubtract(x, mu, res, real_context);
    dr.realAdd(s, s, &p, real_context);
    dr.realDivide(res, &p, res, real_context);
}

fn wp34sPdfLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var xx: real_t = undefined;
    var p: real_t = undefined;
    logisticParam(x, mu, s, &xx, real_context);
    if (dr.realIsSpecial(&xx)) {
        dr.setZero(res);
        return;
    }
    dr.WP34S_SinhCosh(&xx, null, &p, real_context);
    dr.realMultiply(&p, &p, &p, real_context);
    dr.realMultiply(&p, s, &p, real_context);
    dr.realMultiply(&p, dr.const4(), &p, real_context);
    dr.realDivide(dr.const1(), &p, res, real_context);
}

fn wp34sCdfuLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var xx: real_t = undefined;
    logisticParam(x, mu, s, &xx, real_context);
    if (dr.realIsSpecial(&xx)) {
        dr.realCopy(if (dr.realIsNegative(&xx)) dr.const0() else dr.const1(), res);
        return;
    }
    dr.realChangeSign(&xx);
    cdfLogitCommon(&xx, res, real_context);
}

fn wp34sCdfLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    // (1 + tanh( (x-J) / 2K)) / 2
    var xx: real_t = undefined;
    logisticParam(x, mu, s, &xx, real_context);
    if (dr.realIsSpecial(&xx)) {
        dr.realCopy(if (dr.realIsNegative(&xx)) dr.const0() else dr.const1(), res);
        return;
    }
    cdfLogitCommon(&xx, res, real_context);
}

fn wp34sQfLogit(x: *const real_t, mu: *const real_t, s: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    // archtanh(2p - 1) * 2K + J
    var p: real_t = undefined;
    var q: real_t = undefined;

    dr.realAdd(x, x, &p, real_context);
    dr.realSubtract(&p, dr.const1(), &p, real_context);
    dr.WP34S_ArcTanh(&p, &q, real_context);
    dr.realAdd(&q, &q, &p, real_context);
    dr.realMultiply(&p, s, &p, real_context);
    dr.realAdd(&p, mu, res, real_context);
}
