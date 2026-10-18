// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/gev.c: the generalised extreme value
// distribution commands. The four entry points load register X, the location
// in M, the scale in S and the shape in Q through WP34S_CheckDistributionParameters
// and keep their own bodies, since the GEV has no row in the descriptor table.
// Tagged linksection(dr.code_section) so the code runs from QSPI on the
// flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;

const GevSupport = enum { err, inside, below, above };

// gevCheckDomain: the scale must be positive.
fn checkDomain(registers_valid: bool, x: *real_t, mu: ?*real_t, sigma: ?*real_t, xi: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = x;
    _ = mu;
    _ = xi;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const scale = sigma.?;
    if (dr.realIsZero(scale) or dr.realIsNegative(scale)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function gevCheckDomain:", "the parameter sigma must be positive", null, null);
        return false;
    }
    return true;
}

// The registers, and where x sits relative to the support boundary mu - sigma/xi.
fn gevParameters(x: *real_t, mu: *real_t, sigma: *real_t, xi: *real_t, qf: bool) linksection(dr.code_section) GevSupport {
    var t: real_t = undefined;

    if (!dr.WP34S_CheckDistributionParameters(x, dr.REGISTER_M, mu, dr.REGISTER_S, sigma, dr.REGISTER_Q, xi, @intFromBool(qf), checkDomain)) {
        return .err;
    }

    if (qf or dr.realIsZero(xi)) {
        return .inside;
    }
    dr.realDivide(sigma, xi, &t, &dr.ctxtReal39);
    dr.realSubtract(mu, &t, &t, &dr.ctxtReal39);
    if (dr.realIsNegative(xi)) {
        return if (dr.realGreaterThan(x, &t)) .above else .inside;
    }
    return if (dr.realLessThan(x, &t)) .below else .inside;
}

// t(x) = (1 + xi (x - mu) / sigma)^(-1/xi), or e^-((x - mu) / sigma) when xi is zero.
fn tGEV(x: *const real_t, mu: *const real_t, sigma: *const real_t, xi: *const real_t, t: *real_t) linksection(dr.code_section) void {
    var z: real_t = undefined;

    dr.realSubtract(x, mu, &z, &dr.ctxtReal39);
    dr.realDivide(&z, sigma, &z, &dr.ctxtReal39);

    if (!dr.realIsZero(xi)) {
        dr.realMultiply(&z, xi, &z, &dr.ctxtReal39);
        dr.WP34S_Ln1P(&z, &z, &dr.ctxtReal39);
        dr.realDivide(&z, xi, &z, &dr.ctxtReal39);
    }
    dr.realChangeSign(&z);
    dr.realExponential(&z, t, &dr.ctxtReal39);
}

pub fn gevP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;
    var t: real_t = undefined;
    var u: real_t = undefined;
    var v: real_t = undefined;
    const support = gevParameters(&x, &mu, &sigma, &xi, false);

    if (support == .err) {
        return;
    }
    if (support != .inside) {
        dr.setZero(&x);
    } else {
        tGEV(&x, &mu, &sigma, &xi, &t);
        if (dr.realIsInfinite(&t)) {
            dr.setZero(&x);
        } else {
            dr.realAdd(&xi, dr.const1(), &u, &dr.ctxtReal39);
            if (dr.realIsZero(&t) and dr.realIsZero(&u)) {
                dr.realCopy(dr.const1(), &v);
            } else {
                dr.powerReal(&t, &u, &v, &dr.ctxtReal39);
            }
            dr.realDivide(&v, &sigma, &u, &dr.ctxtReal39);
            dr.realChangeSign(&t);
            dr.realExponential(&t, &v, &dr.ctxtReal39);
            dr.realMultiply(&v, &u, &x, &dr.ctxtReal39);
        }
    }
    dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
    dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
}

fn lowerLnGEV(x: *const real_t, mu: *const real_t, sigma: *const real_t, xi: *const real_t, z: *real_t) linksection(dr.code_section) void {
    tGEV(x, mu, sigma, xi, z);
    dr.realChangeSign(z);
}

pub fn gevL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;
    const support = gevParameters(&x, &mu, &sigma, &xi, false);

    if (support == .err) {
        return;
    }
    if (support == .below) {
        dr.setZero(&x);
    } else if (support == .above) {
        dr.realCopy(dr.const1(), &x);
    } else {
        lowerLnGEV(&x, &mu, &sigma, &xi, &x);
        dr.realExponential(&x, &x, &dr.ctxtReal39);
    }
    dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
    dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
}

pub fn gevR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var x: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;
    const support = gevParameters(&x, &mu, &sigma, &xi, false);

    if (support == .err) {
        return;
    }
    if (support == .below) {
        dr.realCopy(dr.const1(), &x);
    } else if (support == .above) {
        dr.setZero(&x);
    } else {
        lowerLnGEV(&x, &mu, &sigma, &xi, &x);
        dr.realExpM1(&x, &x, &dr.ctxtReal39);
        dr.realChangeSign(&x);
    }
    dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
    dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
}

pub fn gevI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var p: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var xi: real_t = undefined;
    var x: real_t = undefined;
    var lnp: real_t = undefined;

    if (gevParameters(&p, &mu, &sigma, &xi, true) == .err) {
        return;
    }

    var domain_okay = dr.realGreaterThan(&p, dr.const0()) and dr.realLessThan(&p, dr.const1());
    if (!domain_okay and !dr.realIsZero(&xi)) {
        if (dr.realIsNegative(&xi)) {
            domain_okay = dr.realEqual(&p, dr.const1());
        } else {
            domain_okay = dr.realIsZero(&p);
        }
    }

    if (!domain_okay) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function fnGEVI:", "the argument out of range", null, null);
        if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.setNaN(&x);
            dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
        }
        return;
    }

    if (!dr.realIsZero(&xi) and (dr.realIsZero(&p) or dr.realEqual(&p, dr.const1()))) {
        dr.realDivide(&sigma, &xi, &lnp, &dr.ctxtReal39);
        dr.realSubtract(&mu, &lnp, &x, &dr.ctxtReal39);
    } else if (dr.realIsZero(&xi)) {
        dr.WP34S_Ln(&p, &lnp, &dr.ctxtReal39);
        dr.realChangeSign(&lnp);
        dr.WP34S_Ln(&lnp, &p, &dr.ctxtReal39);
        dr.realChangeSign(&p);
        dr.realFMA(&sigma, &p, &mu, &x, &dr.ctxtReal39);
    } else {
        dr.WP34S_Ln(&p, &lnp, &dr.ctxtReal39);
        dr.realChangeSign(&lnp);
        dr.realMinus(&xi, &p, &dr.ctxtReal39);
        dr.powerReal(&lnp, &p, &lnp, &dr.ctxtReal39);
        dr.realSubtract(&lnp, dr.const1(), &p, &dr.ctxtReal39);
        dr.realDivide(&p, &xi, &lnp, &dr.ctxtReal39);
        dr.realFMA(&lnp, &sigma, &mu, &x, &dr.ctxtReal39);
    }

    dr.convertRealToResultRegister(&x, dr.REGISTER_X, dr.amNone);
    dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
}
