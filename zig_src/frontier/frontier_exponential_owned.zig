// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Exponential distribution commands, porting
// `src/c47/distributions/exponential.c`. The four fn* entry points are
// dispatched from the items.c function table (exported via frontier.zig); the
// WP34S_*_Expon helpers are exponential-internal and stay private. All
// decNumber/register access goes through frontier_distribution_runtime.

const dr = @import("frontier_distribution_runtime.zig");
const real_t = dr.real_t;
const realContext_t = dr.realContext_t;

fn checkParamExponential(x: *real_t, lambda: *real_t) linksection(dr.code_section) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_R, lambda)) {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamExponential:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsZero(lambda) or dr.realIsNegative(lambda)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamExponential:", "cannot calculate for lambda <= 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn exponentialP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamExponential(&val, &dof)) {
        wp34sPdfExpon(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn exponentialL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamExponential(&val, &dof)) {
        wp34sCdfExpon(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn exponentialR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamExponential(&val, &dof)) {
        wp34sCdfuExpon(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn exponentialI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamExponential(&val, &dof)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnExponentialI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfExpon(&val, &dof, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_NO_ROOT_FOUND, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnExponentialI:", "WP34S_Qf_Expon did not converge", null, null);
            dr.specialResultNaN();
            return;
        }
        dr.storeResult(&ans);
    }
}

// These functions are borrowed from the WP34S project.

fn wp34sPdfExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsSpecial(lambda)) {
        dr.setZero(res); // Can only be infinite which has zero probability.
        return;
    }
    dr.realMultiply(x, lambda, res, real_context);
    dr.realChangeSign(res);
    dr.realExponential(res, res, real_context);
    dr.realMultiply(res, lambda, res, real_context);
}

fn wp34sCdfuExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsSpecial(lambda)) {
        dr.setPlusInfinity(res);
        return;
    }
    dr.realMultiply(x, lambda, res, real_context);
    if (dr.realLessThan(res, dr.const0())) {
        dr.setOne(res);
        return;
    }
    dr.realChangeSign(res);
    dr.realExponential(res, res, real_context);
}

fn wp34sCdfExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsSpecial(lambda)) {
        dr.setPlusInfinity(res);
        return;
    }
    dr.realMultiply(x, lambda, res, real_context);
    if (dr.realLessThan(res, dr.const0())) {
        dr.setOne(res);
        return;
    }
    dr.realChangeSign(res);
    dr.WP34S_ExpM1(res, res, real_context);
    dr.realChangeSign(res);
}

fn wp34sQfExpon(x: *const real_t, lambda: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;

    dr.realSubtract(dr.const0(), x, &p, real_context);
    dr.WP34S_Ln1P(&p, res, real_context);
    dr.realDivide(res, lambda, res, real_context);
    dr.realChangeSign(res);
}
