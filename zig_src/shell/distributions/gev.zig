// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for the Generalised Extreme Value distribution commands, porting
// `src/c47/distributions/gev.c`. The four fn* entry points are dispatched from
// the items.c function table (exported via frontier.zig). All decNumber/register
// access goes through frontier_distribution_runtime. The testSuite has no GEV
// dispatch entry, so these are verified by the distributions parity harness.
//
// The port reproduces upstream behaviour exactly, including the PDF's t^(t+1)
// exponent (upstream computes realPower(t, t+1); its comment says t^(xi+1)).

const dr = @import("distribution_runtime.zig");
const real_t = dr.real_t;

// noinline: called from all four entry points; a single shared copy keeps the
// flash-limited full package (pkg1) within budget.
noinline fn checkParamGEV(x: *real_t, mu: *real_t, sigma: *real_t, xi: *real_t, qf: bool) linksection(dr.code_section) bool {
    const ctx = &dr.ctxtReal39;
    var t: real_t = undefined;

    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, mu) or
        !dr.getRegisterAsReal(dr.REGISTER_S, sigma) or !dr.getRegisterAsReal(dr.REGISTER_Q, xi))
    {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamGEV:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsZero(sigma) or dr.realIsNegative(sigma)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamGEV:", "the parameter sigma must be positive", null, null);
        dr.specialResultNaN();
        return false;
    }

    // Check support range.
    if (qf or dr.realIsZero(xi)) {
        return true; // xi = 0, full line
    }
    dr.realSubtract(mu, sigma, &t, ctx);
    dr.realDivide(&t, xi, &t, ctx);
    if (dr.realIsNegative(xi)) {
        return dr.realCompareLessEqual(x, &t); // xi < 0, (-inf, (mu-sigma)/xi]
    }
    return dr.realCompareGreaterEqual(x, &t); // xi > 0, [(mu-sigma)/xi, +inf)
}

noinline fn tGEV(x: *const real_t, mu: *const real_t, sigma: *const real_t, xi: *const real_t, t: *real_t) linksection(dr.code_section) void {
    const ctx = &dr.ctxtReal39;
    var z: real_t = undefined;

    dr.realSubtract(x, mu, &z, ctx);
    dr.realDivide(&z, sigma, &z, ctx); // z = (x - mu) / sigma

    if (!dr.realIsZero(xi)) {
        dr.realMultiply(&z, xi, &z, ctx); // z = xi (x - mu) / sigma
        dr.WP34S_Ln1P(&z, &z, ctx);
        dr.realDivide(&z, xi, &z, ctx);
    }
    dr.realChangeSign(&z);
    dr.realExponential(&z, t, ctx);
}

fn lowerLnGEV(x: *const real_t, mu: *const real_t, sigma: *const real_t, xi: *const real_t, z: *real_t) linksection(dr.code_section) void {
    tGEV(x, mu, sigma, xi, z);
    dr.realChangeSign(z);
}

pub fn gevP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;

    if (!checkParamGEV(&x, &mu, &sigma, &xi, false)) {
        return;
    }
    tGEV(&x, &mu, &sigma, &xi, &t);
    dr.realAdd(&t, dr.const1(), &u, ctx);
    dr.realPow(&t, &u, &v, ctx); // upstream: v = t^(t+1)
    dr.realDivide(&v, &sigma, &u, ctx);
    dr.realChangeSign(&t);
    dr.realExponential(&t, &v, ctx); // v = e^-t
    dr.realMultiply(&v, &u, &x, ctx);
    dr.storeResult(&x);
}

pub fn gevL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;

    if (!checkParamGEV(&x, &mu, &sigma, &xi, false)) {
        return;
    }
    lowerLnGEV(&x, &mu, &sigma, &xi, &x);
    dr.realExponential(&x, &x, ctx);
    dr.storeResult(&x);
}

pub fn gevR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;

    if (!checkParamGEV(&x, &mu, &sigma, &xi, false)) {
        return;
    }
    lowerLnGEV(&x, &mu, &sigma, &xi, &x);
    dr.realExpM1(&x, &x, ctx);
    dr.realChangeSign(&x);
    dr.storeResult(&x);
}

pub fn gevI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    const ctx = &dr.ctxtReal39;
    var p: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;
    var x: real_t = undefined;
    var lnp: real_t = undefined;

    if (!checkParamGEV(&p, &mu, &sigma, &xi, true)) {
        return;
    }

    var domain_okay = dr.realGreaterThan(&p, dr.const0()) or dr.realLessThan(&p, dr.const1());
    if (!domain_okay and !dr.realIsZero(&xi)) {
        if (dr.realIsNegative(&xi)) {
            domain_okay = dr.realEqual(&p, dr.const1());
        } else {
            domain_okay = dr.realIsZero(&p);
        }
    }

    if (!domain_okay) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function fnGEVI:", "the argument out of range", null, null);
        dr.specialResultNaN();
        return;
    }

    dr.WP34S_Ln(&p, &lnp, ctx);
    dr.realChangeSign(&lnp);
    if (dr.realIsZero(&xi)) {
        dr.WP34S_Ln(&lnp, &p, ctx);
        dr.realChangeSign(&p);
        dr.realFMA(&sigma, &p, &mu, &x, ctx);
    } else {
        dr.realMinus(&xi, &p, ctx);
        dr.powerReal(&lnp, &p, &lnp, ctx); // lnp = (-ln p)^(-xi)
        dr.realSubtract(&lnp, dr.const1(), &p, ctx);
        dr.realDivide(&p, &xi, &lnp, ctx);
        dr.realFMA(&lnp, &sigma, &mu, &x, ctx);
    }
    dr.storeResult(&x);
}
