// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/geometric.c: the Geometric distribution
// commands (fnGeometricP/L/R/I) plus the WP34S math borrowings, including the
// shared discrete-quantile dispatcher WP34S_qf_discrete_final used by the f
// distribution. Exported from shell.zig under the strip_17 guard.
//
// Upstream strips the SAVE_SPACE_DM42_17 cluster (poisson/hyper/binomial/
// geometric/f) on every DM42 package, so this owner is compiled only where that
// cluster is present: the host (PC) build and DMCP5. There it links against the
// still-C discrete CDFs (WP34S_Cdf_Poisson2/Binomial2, cdf_Hypergeometric2,
// cdf_NegBinomial2) which the shared dispatcher reaches; on DM42 strip_17 is set,
// so the four entry points become empty stubs and the math is eliminated. No QSPI
// linksection is needed (the owner is absent on the flash-constrained targets).
//
// The testSuite exercises every branch directly (tests/geometric_{p,l,r,i}.txt),
// so this owner is parity-gated by `zig build test`.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// qf_discrete_final dispatch selectors (defines.h).
const QF_DISCRETE_CDF_POISSON: u16 = 0;
const QF_DISCRETE_CDF_BINOMIAL: u16 = 1;
const QF_DISCRETE_CDF_GEOMETRIC: u16 = 2;
const QF_DISCRETE_CDF_NEGBINOM: u16 = 3;
const QF_DISCRETE_CDF_HYPERGEOMETRIC: u16 = 4;

fn checkParamGeometric(x: *real_t, i: *real_t) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_P, i)) {
        dr.specialResultNaN();
        return false;
    }

    if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamGeometric:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsZero(i) or dr.realIsNegative(i) or dr.realGreaterThan(i, dr.const1())) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamGeometric:", "the parameter must be 0 < p \xa2\x64 1", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn geometricP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamGeometric(&val, &prob)) {
        wp34sPdfGeom(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn geometricL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamGeometric(&val, &prob)) {
        wp34sCdfGeom(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn geometricR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamGeometric(&val, &prob)) {
        wp34sCdfuGeom(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn geometricI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;

    if (checkParamGeometric(&val, &prob)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnGeometricI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfGeom(&val, &prob, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

// ---------------------------------------------------------------------------
// WP34S math borrowings (upstream comment: "borrowed from the WP34S project").
// ---------------------------------------------------------------------------

fn wp34sPdfGeom(x: *const real_t, p0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    if (dr.realIsNegative(x) or !dr.isAnInteger(x)) {
        dr.setZero(res);
        return;
    }
    dr.realMinus(p0, &p, ctx);
    dr.WP34S_Ln1P(&p, &p, ctx);
    dr.realMultiply(x, &p, &p, ctx);
    dr.realExponential(&p, &p, ctx);
    dr.realMultiply(&p, p0, res, ctx);
}

fn wp34sCdfuGeom(x: *const real_t, p0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, ctx);
    if (dr.realLessThan(&p, dr.const1())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(&p)) {
        dr.setZero(res);
        return;
    }
    dr.realSubtract(dr.const1(), p0, &q, ctx);
    dr.realPow(&q, &p, res, ctx);
}

fn wp34sCdfGeom(x: *const real_t, p0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, ctx);
    dr.realAdd(&p, dr.const1(), &p, ctx);
    dr.realMinus(p0, &q, ctx);
    dr.WP34S_Ln1P(&q, &q, ctx);
    dr.realMultiply(&p, &q, &p, ctx);
    dr.WP34S_ExpM1(&p, res, ctx);
    dr.realChangeSign(res);
}

fn wp34sQfGeom(x: *const real_t, p0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    dr.realMinus(x, &p, ctx);
    dr.WP34S_Ln1P(&p, &p, ctx);
    dr.realMinus(p0, &q, ctx);
    dr.WP34S_Ln1P(&q, &q, ctx);
    dr.realDivide(&p, &q, &p, ctx);
    dr.realSubtract(&p, dr.const1(), &p, ctx);
    dr.toIntegralValue(&p, &p, dr.DEC_ROUND_FLOOR, ctx);
    wp34sQfDiscreteFinal(QF_DISCRETE_CDF_GEOMETRIC, &p, x, p0, null, null, res, ctx);
}

// Shared discrete-quantile final step. Exported (C linkage) from shell.zig so
// the f distribution can reach it; i/j/k are nullable to match the C prototype.
pub fn wp34sQfDiscreteFinal(
    dist: u16,
    r: *const real_t,
    p: *const real_t,
    i: [*c]const real_t,
    j: [*c]const real_t,
    k: [*c]const real_t,
    res: *real_t,
    ctx: *realContext_t,
) void {
    var q: real_t = undefined;

    switch (dist) {
        QF_DISCRETE_CDF_POISSON => dr.WP34S_Cdf_Poisson2(r, i, &q, &dr.ctxtReal51),
        QF_DISCRETE_CDF_BINOMIAL => dr.WP34S_Cdf_Binomial2(r, i, j, &q, &dr.ctxtReal51),
        QF_DISCRETE_CDF_GEOMETRIC => wp34sCdfGeom(r, i, &q, &dr.ctxtReal51),
        QF_DISCRETE_CDF_NEGBINOM => dr.cdf_NegBinomial2(r, i, j, &q, &dr.ctxtReal51),
        QF_DISCRETE_CDF_HYPERGEOMETRIC => dr.cdf_Hypergeometric2(r, i, j, k, &q, &dr.ctxtReal75),
        else => dr.setZero(&q),
    }
    dr.realAdd(&q, dr.const0(), &q, ctx);
    if (dr.realLessThan(&q, p)) {
        dr.realAdd(r, dr.const1(), res, ctx);
    } else {
        dr.realCopy(r, res);
    }
}
