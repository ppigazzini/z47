// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Cauchy distribution commands, porting
// `src/c47/distributions/cauchy.c`. The four fn* entry points are dispatched
// from the items.c function table (exported via frontier.zig); the WP34S_*
// helpers are cauchy-internal and stay private. All decNumber/register access
// goes through frontier_distribution_runtime.

const dr = @import("frontier_distribution_runtime.zig");
const real_t = dr.real_t;
const realContext_t = dr.realContext_t;

fn checkParamCauchy(x: *real_t, x0: *real_t, gamma: *real_t) linksection(dr.code_section) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, x0) or !dr.getRegisterAsReal(dr.REGISTER_S, gamma)) {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsZero(gamma) or dr.realIsNegative(gamma)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamCauchy:", "cannot calculate for gamma <= 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn cauchyP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        wp34sPdfCauchy(&val, &x0, &gamma, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn cauchyL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        wp34sCdfCauchy(&val, &x0, &gamma, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn cauchyR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        wp34sCdfuCauchy(&val, &x0, &gamma, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn cauchyI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var x0: real_t = undefined;
    var gamma: real_t = undefined;

    if (checkParamCauchy(&val, &x0, &gamma)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnCauchyI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfCauchy(&val, &x0, &gamma, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_NO_ROOT_FOUND, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnCauchyI:", "WP34S_Qf_Chi2 did not converge", null, null);
            dr.specialResultNaN();
            return;
        }
        dr.storeResult(&ans);
    }
}

// These functions are borrowed from the WP34S project.

fn wp34sPdfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    wp34sCdfCauchyXform(x, x0, gamma, res, real_context);
    if (dr.realIsSpecial(res)) {
        dr.setZero(res); // Can only be infinite which has zero probability.
        return;
    }
    dr.realMultiply(res, res, res, real_context);
    dr.realAdd(res, dr.const1(), res, real_context);
    dr.realMultiply(res, gamma, res, real_context);
    dr.realMultiply(res, dr.const39Pi(), res, real_context);
    dr.realDivide(dr.const1(), res, res, real_context);
}

fn wp34sCdfuCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    wp34sCdfCauchyCommon(x, x0, gamma, true, res, real_context);
}

fn wp34sCdfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    wp34sCdfCauchyCommon(x, x0, gamma, false, res, real_context);
}

fn wp34sCdfCauchyCommon(x: *const real_t, x0: *const real_t, gamma: *const real_t, complementary: bool, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;

    wp34sCdfCauchyXform(x, x0, gamma, &p, real_context);
    if (dr.realIsSpecial(&p)) {
        dr.setPlusInfinity(res);
        return;
    }
    dr.C47_WP34S_Atan(&p, &p, real_context);
    dr.realDivide(&p, dr.const39Pi(), &p, real_context);
    if (complementary) {
        dr.realChangeSign(&p);
    }
    dr.realAdd(&p, dr.const1on2(), res, real_context);
}

fn wp34sCdfCauchyXform(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    dr.realSubtract(x, x0, res, real_context);
    dr.realDivide(res, gamma, res, real_context);
}

fn wp34sQfCauchy(x: *const real_t, x0: *const real_t, gamma: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var s: real_t = undefined;
    var c: real_t = undefined;

    dr.realSubtract(x, dr.const1on2(), &p, real_context);
    dr.realMultiply(&p, dr.const39Pi(), &p, real_context);
    dr.C47_WP34S_SinCosTanTaylor(&p, false, &s, &c, &p, real_context);
    dr.realMultiply(&p, gamma, &p, real_context);
    dr.realAdd(&p, x0, res, real_context);
}
