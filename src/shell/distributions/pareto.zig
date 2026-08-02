// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Pareto distribution commands (generalised Pareto / GPD,
// Type I and Type II), porting `src/c47/distributions/pareto.c`. The eight fn*
// entry points are dispatched from the items.c function table (exported via
// frontier.zig). All decNumber/register access goes through
// frontier_distribution_runtime. The testSuite has no Pareto dispatch entry, so
// these are verified by the dedicated distributions parity harness instead.

const dr = @import("distribution_runtime.zig");
const real_t = dr.real_t;

// Shared parameter check for both GPD types. `mu` is non-null for Type II only.
fn checkParamGPD(x: *real_t, mu: ?*real_t, sigma: *real_t, alpha: *real_t, qf: bool) linksection(dr.code_section) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or
        (mu != null and !dr.getRegisterAsReal(dr.REGISTER_M, mu.?)) or
        !dr.getRegisterAsReal(dr.REGISTER_S, sigma) or
        !dr.getRegisterAsReal(dr.REGISTER_Q, alpha))
    {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsZero(sigma) or dr.realIsNegative(sigma)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamGPD:", "the parameter sigma must be positive", null, null);
        dr.specialResultNaN();
        return false;
    }
    if (!qf and dr.realLessThan(x, if (mu == null) sigma else mu.?)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamGPD:", "cannot calculate for x < sigma/mu", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

// Type I Pareto distribution

pub fn paretoP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;

    if (checkParamGPD(&x, null, &sigma, &alpha, false)) {
        dr.realDivide(&sigma, &x, &t, ctx);
        dr.realPow(&t, &alpha, &u, ctx);
        dr.realDivide(&u, &x, &t, ctx);
        dr.realMultiply(&t, &alpha, &x, ctx);
        dr.storeResult(&x);
    }
}

pub fn paretoL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var t: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;

    if (checkParamGPD(&x, null, &sigma, &alpha, false)) {
        dr.realDivide(&sigma, &x, &t, ctx);
        dr.WP34S_Ln(&t, &sigma, ctx);
        dr.realMultiply(&alpha, &sigma, &t, ctx);
        dr.realExpM1(&t, &x, ctx);
        dr.realChangeSign(&x);
        dr.storeResult(&x);
    }
}

pub fn paretoU(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var t: real_t = undefined;

    if (checkParamGPD(&x, null, &sigma, &alpha, false)) {
        dr.realDivide(&sigma, &x, &t, ctx);
        dr.realPow(&t, &alpha, &x, ctx);
        dr.storeResult(&x);
    }
}

pub fn paretoI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var t: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;

    if (checkParamGPD(&x, null, &sigma, &alpha, true)) {
        if ((dr.realIsNegative(&x) and !dr.realIsZero(&x)) or dr.realGreaterThan(&x, dr.const1())) {
            dr.setNaN(&x);
        } else {
            dr.realChangeSign(&x);
            dr.WP34S_Ln1P(&x, &t, ctx);
            dr.realDivide(&t, &alpha, &x, ctx);
            dr.realChangeSign(&x);
            dr.realExponential(&x, &t, ctx);
            dr.realMultiply(&t, &sigma, &x, ctx);
        }
        dr.storeResult(&x);
    }
}

// Type II Pareto distribution

pub fn pareto2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var t: real_t = undefined;

    if (checkParamGPD(&x, &mu, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &mu, &t, ctx);
        dr.realAdd(&t, &sigma, &x, ctx); // x = x + sigma - mu
        dr.realDivide(&sigma, &x, &t, ctx);
        dr.realPow(&t, &alpha, &mu, ctx);
        dr.realDivide(&mu, &x, &t, ctx);
        dr.realMultiply(&t, &alpha, &x, ctx);
        dr.storeResult(&x);
    }
}

pub fn pareto2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var t: real_t = undefined;

    if (checkParamGPD(&x, &mu, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &mu, &t, ctx);
        dr.realDivide(&t, &sigma, &x, ctx);
        dr.WP34S_Ln1P(&x, &t, ctx);
        dr.realMultiply(&alpha, &t, &sigma, ctx);
        dr.realChangeSign(&sigma);
        dr.realExpM1(&sigma, &x, ctx);
        dr.realChangeSign(&x);
        dr.storeResult(&x);
    }
}

pub fn pareto2U(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var t: real_t = undefined;

    if (checkParamGPD(&x, &mu, &sigma, &alpha, false)) {
        dr.realSubtract(&x, &mu, &t, ctx);
        dr.realDivide(&t, &sigma, &x, ctx);
        dr.WP34S_Ln1P(&x, &t, ctx);
        dr.realMultiply(&alpha, &t, &sigma, ctx);
        dr.realChangeSign(&sigma);
        dr.realExponential(&sigma, &x, ctx);
        dr.storeResult(&x);
    }
}

pub fn pareto2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var alpha: real_t = undefined;
    var t: real_t = undefined;

    if (checkParamGPD(&x, &mu, &sigma, &alpha, true)) {
        if ((dr.realIsNegative(&x) and !dr.realIsZero(&x)) or dr.realGreaterThan(&x, dr.const1())) {
            dr.setNaN(&x);
        } else {
            dr.realChangeSign(&x);
            dr.WP34S_Ln1P(&x, &t, ctx);
            dr.realDivide(&t, &alpha, &x, ctx);
            dr.realExponential(&x, &t, ctx); // t = (1-x)^(1/alpha)
            dr.realSubtract(&mu, &sigma, &mu, ctx);
            dr.realMultiply(&mu, &t, &x, ctx);
            dr.realAdd(&x, &sigma, &mu, ctx);
            dr.realDivide(&mu, &t, &x, ctx);
        }
        dr.storeResult(&x);
    }
}
