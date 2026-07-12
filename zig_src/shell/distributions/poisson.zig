// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/poisson.c: the Poisson distribution
// commands (fnPoissonP/L/R/I) and the WP34S math borrowings. Like the other
// SAVE_SPACE_DM42_17 cluster members it is compiled only where that cluster is
// kept (host and DMCP5) and stubbed on every DM42 package via strip_17.
//
// Three helpers are exported with C linkage because still-C cluster members
// reach them where the cluster is present:
//   - WP34S_Cdf_Poisson2 : the geometric owner's qf_discrete_final dispatcher,
//   - WP34S_Pdf_Poisson  : the f distribution,
//   - WP34S_normal_moment_approx : the binomial/hyper/negBinom quantiles.
// The quantile uses the shared C Newton solver (WP34S_Qf_Newton) and the
// incomplete-gamma helpers (WP34S_GammaP/LnGamma), all bound through
// frontier_distribution_runtime.
//
// The testSuite drives every branch directly (tests/poisson_{p,l,r,i}.txt).

const dr = @import("../frontier_distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// WP34S_Qf_Newton distribution selector (defines.h).
const QF_NEWTON_POISSON: u32 = 1;

fn checkParamPoisson(x: *real_t, i: *real_t) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_R, i)) {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamPoisson:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsZero(i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamPoisson:", "the parameter must be \x83\xbb > 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn poissonP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamPoisson(&val, &prob)) {
        wp34sPdfPoisson(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn poissonL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamPoisson(&val, &prob)) {
        wp34sCdfPoisson(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn poissonR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamPoisson(&val, &prob)) {
        wp34sCdfuPoisson(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn poissonI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamPoisson(&val, &prob)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnPoissonI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfPoisson(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

// ---------------------------------------------------------------------------
// WP34S math borrowings (upstream comment: "borrowed from the WP34S project").
// ---------------------------------------------------------------------------

// Stack: probability in Z, variance in Y, mean in X; returns a normal
// approximation. Shared by the binomial/hyper/negBinom quantiles.
pub fn wp34sNormalMomentApprox(prob: *const real_t, variance: *const real_t, mean: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    dr.WP34S_qf_q_est(prob, &p, null, ctx);
    dr.realMultiply(&p, &p, &q, ctx);
    dr.realSubtract(&q, dr.const1(), &q, ctx);
    dr.realDivide(&q, dr.const6(), &q, ctx);
    dr.realDivide(&q, variance, &q, ctx);
    dr.realAdd(&p, &q, &p, ctx);
    dr.realMultiply(&p, variance, &p, ctx);
    dr.realAdd(&p, mean, res, ctx);
}

pub fn wp34sPdfPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    if (dr.realIsNegative(x) or !dr.isAnInteger(x)) {
        dr.setZero(res);
        return;
    }
    dr.WP34S_Ln(lambda, &p, ctx);
    dr.realMultiply(&p, x, &p, ctx);
    dr.realSubtract(&p, lambda, &p, ctx);
    dr.realAdd(x, dr.const1(), &q, ctx);
    dr.WP34S_LnGamma(&q, &r, ctx);
    dr.realSubtract(&p, &r, &q, ctx); // ln(PDF) = x*ln(lambda) - lambda - lngamma(x+1)
    dr.realExponential(&q, res, ctx);
}

fn wp34sCdfuPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    if (dr.realCompareLessEqual(lambda, dr.const0())) {
        dr.setZero(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, ctx);
    if (dr.realLessThan(&p, dr.const1())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(&p)) {
        dr.setZero(res);
        return;
    }
    dr.WP34S_GammaP(lambda, &p, res, ctx, false, true);
}

fn wp34sCdfPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    if (dr.realCompareLessEqual(lambda, dr.const0())) {
        dr.setZero(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, ctx);
    wp34sCdfPoisson2(&p, lambda, res, ctx);
}

pub fn wp34sCdfPoisson2(x: *const real_t, lambda: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    dr.realAdd(x, dr.const1(), &p, ctx);
    dr.WP34S_GammaP(lambda, &p, res, ctx, true, true);
}

fn wp34sQfPoisson(x: *const real_t, lambda: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realCompareLessEqual(lambda, dr.const0())) {
        dr.setZero(res);
        return;
    }
    dr.realSquareRoot(lambda, &p, ctx);
    wp34sNormalMomentApprox(x, &p, lambda, &q, ctx);
    dr.WP34S_Qf_Newton(QF_NEWTON_POISSON, x, &q, lambda, null, null, res, ctx);
}
