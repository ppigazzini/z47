// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/geometric.c: the geometric distribution
// commands, the WP34S kernels behind them, and the discrete quantile finisher
// the binomial, Poisson, negative binomial and hypergeometric quantiles share.
// The commands hand their descriptor row to fnDistribution, which loads register
// X and the success probability in P. Tagged linksection(dr.code_section) so the
// code runs from QSPI on the flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

/// geometricCheckDomain: x may not be NaN and the probability must lie in (0, 1].
pub fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = second;
    _ = third;
    _ = parameter;
    if (!registers_valid) {
        return false;
    }
    const i = first.?;

    if (dr.realIsNaN(x)) {
        if (!dr.getSystemFlag(dr.FLAG_SPCRES)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
            dr.moreInfoOnError("In function geometricCheckDomain:", "x is NaN", null, null);
        }
        return false;
    } else if (dr.realIsSpecial(i) or dr.realCompareLessEqual(i, dr.const0()) or dr.realGreaterThan(i, dr.const1())) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function geometricCheckDomain:", "the parameter must be 0 < p \xa2\x64 1", null, null);
        return false;
    }
    return true;
}

pub fn geometricP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_GEOM * 4 + dr.DIST_P);
}

pub fn geometricL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_GEOM * 4 + dr.DIST_L);
}

pub fn geometricR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_GEOM * 4 + dr.DIST_R);
}

pub fn geometricI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    dr.fnDistribution(dr.DIST_GEOM * 4 + dr.DIST_I);
}

// Whether p is a geometric success probability.
fn geometricParameterIsValid(p: *const real_t) linksection(dr.code_section) bool {
    return !dr.realIsSpecial(p) and dr.realGreaterThan(p, dr.const0()) and dr.realCompareLessEqual(p, dr.const1());
}

// log(1 - p) without losing a small p or a small 1 - p.
fn geometricLogSurvival(p: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var argument: real_t = undefined;

    if (dr.realCompareLessEqual(p, dr.const1on2())) {
        dr.realMinus(p, &argument, real_context);
        dr.WP34S_Ln1P(&argument, res, real_context);
    } else {
        dr.realSubtract(dr.const1(), p, &argument, real_context);
        dr.WP34S_Ln(&argument, res, real_context);
    }
}

pub fn wp34sPdfGeom(x: *const real_t, p0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;

    if (dr.realIsNaN(x) or !geometricParameterIsValid(p0)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realLessThan(x, dr.const0()) or dr.realIsInfinite(x) or !dr.isAnInteger(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsZero(x)) {
        dr.realCopy(p0, res);
        return;
    }
    geometricLogSurvival(p0, &p, real_context);
    dr.realMultiply(x, &p, &p, real_context);
    dr.realExponential(&p, &p, real_context);
    dr.realMultiply(&p, p0, res, real_context);
    if (dr.realLessThan(p0, dr.const1())) {
        dr.WP34S_MarkProbability(res, real_context);
    }
}

pub fn wp34sCdfuGeom(x: *const real_t, p0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realIsNaN(x) or !geometricParameterIsValid(p0)) {
        dr.setNaN(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, real_context);
    if (dr.realLessThan(&p, dr.const1())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(&p)) {
        dr.setZero(res);
        return;
    }
    geometricLogSurvival(p0, &q, real_context);
    dr.realMultiply(&p, &q, &p, real_context);
    dr.realExponential(&p, res, real_context);
    if (dr.realLessThan(p0, dr.const1())) {
        dr.WP34S_MarkProbability(res, real_context);
    }
}

pub fn wp34sCdfGeom(x: *const real_t, p0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realIsNaN(x) or !geometricParameterIsValid(p0)) {
        dr.setNaN(res);
        return;
    }
    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, real_context);
    dr.realAdd(&p, dr.const1(), &p, real_context);
    geometricLogSurvival(p0, &q, real_context);
    dr.realMultiply(&p, &q, &p, real_context);
    dr.WP34S_ExpM1(&p, res, real_context);
    dr.realChangeSign(res);
    if (dr.realLessThan(p0, dr.const1())) {
        dr.WP34S_MarkProbability(res, real_context);
    }
}

pub fn wp34sQfGeom(x: *const real_t, p0: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realIsNaN(x) or !geometricParameterIsValid(p0) or dr.realLessThan(x, dr.const0()) or dr.realGreaterThan(x, dr.const1())) {
        dr.setNaN(res);
        return;
    }
    if (dr.realIsZero(x)) {
        dr.setZero(res);
        return;
    }
    if (dr.realEqual(x, dr.const1())) {
        dr.setPlusInfinity(res);
        return;
    }
    dr.realMinus(x, &p, real_context);
    dr.WP34S_Ln1P(&p, &p, real_context);
    geometricLogSurvival(p0, &q, real_context);
    dr.realDivide(&p, &q, &p, real_context);
    dr.realSubtract(&p, dr.const1(), &p, real_context);
    dr.toIntegralValue(&p, &p, dr.DEC_ROUND_FLOOR, real_context);
    // The closed form is accurate to the context, so the quantile is its floor or the next integer.
    if (qfDiscreteBelow(dr.QF_DISCRETE_CDF_GEOMETRIC, &p, x, p0, null, null)) {
        dr.realAdd(&p, dr.const1(), &p, real_context);
    }
    dr.realCopy(&p, res);
}

// Whether the CDF of a discrete distribution at r is below p. At an exact tie,
// such as L(0) = u = 1E-34 for NB(1, 1 - 1E-34), the CDF comes out up to about
// 1E-45 of u either side. Rounded to 43 digits a tie meets u, and the documented
// near-ties, 4E-40 below u, stay below.
fn qfDiscreteBelow(dist: u16, r: *const real_t, p: *const real_t, i: *const real_t, j: ?*const real_t, k: ?*const real_t) linksection(dr.code_section) bool {
    var tie_context: realContext_t = dr.ctxtReal51;
    var q: real_t = undefined;

    switch (dist) {
        dr.QF_DISCRETE_CDF_POISSON => dr.WP34S_Cdf_Poisson2(r, i, &q, &dr.ctxtReal51),
        dr.QF_DISCRETE_CDF_BINOMIAL => dr.WP34S_Cdf_Binomial2(r, i, j.?, &q, &dr.ctxtReal51),
        dr.QF_DISCRETE_CDF_GEOMETRIC => wp34sCdfGeom(r, i, &q, &dr.ctxtReal51),
        dr.QF_DISCRETE_CDF_NEGBINOM => dr.cdf_NegBinomial2(r, i, j.?, &q, &dr.ctxtReal51),
        dr.QF_DISCRETE_CDF_HYPERGEOMETRIC => dr.cdf_Hypergeometric2(r, i, j.?, k.?, &q, &dr.ctxtReal75),
        else => dr.setZero(&q),
    }
    tie_context.digits = 43;
    dr.realPlus(&q, &q, &tie_context);
    return dr.realLessThan(&q, p);
}

/// WP34S_qf_discrete_final: the smallest integer whose CDF reaches p. farEnd moves
/// from r, up when the CDF at r is below p and down otherwise, by a step that
/// doubles until the CDF at farEnd crosses p, and nearEnd follows one position
/// behind. The bracket from low to high is then halved, so a start d away costs
/// about 2 log2(d) CDF evaluations. Where the integers are further apart than
/// the step, as beyond 1E39 at 39 digits, a step that leaves the value unchanged
/// ends the doubling and a midpoint outside the bracket ends the halving.
pub fn wp34sQfDiscreteFinal(dist: u16, r: *const real_t, p: *const real_t, i: *const real_t, j: ?*const real_t, k: ?*const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var low: real_t = undefined;
    var high: real_t = undefined;
    var step: real_t = undefined;

    const below = qfDiscreteBelow(dist, r, p, i, j, k);
    const near_end: *real_t = if (below) &low else &high;
    const far_end: *real_t = if (below) &high else &low;
    dr.int32ToReal(if (below) 1 else -1, &step);
    dr.realCopy(r, far_end);
    while (true) {
        dr.realCopy(far_end, near_end);
        dr.realAdd(near_end, &step, far_end, real_context);
        dr.realAdd(&step, &step, &step, real_context);
        if (dr.realEqual(&high, &low) or qfDiscreteBelow(dist, far_end, p, i, j, k) != below) {
            break;
        }
    }
    while (true) {
        dr.realAdd(&low, &high, &step, real_context);
        dr.realMultiply(&step, dr.const1on2(), &step, real_context);
        dr.toIntegralValue(&step, &step, dr.DEC_ROUND_FLOOR, real_context);
        if (!dr.realGreaterThan(&step, &low) or !dr.realLessThan(&step, &high)) {
            break;
        }
        if (qfDiscreteBelow(dist, &step, p, i, j, k)) {
            dr.realCopy(&step, &low);
        } else {
            dr.realCopy(&step, &high);
        }
    }
    dr.realCopy(&high, res);
}
