// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/negBinom.c: the Negative Binomial
// distribution commands (fnNegBinomialP/L/R/I) and the WP34S math borrowings.
// Part of the SAVE_SPACE_DM42_17 cluster, so compiled only on host and DMCP5 and
// stubbed on every DM42 package via strip_17.
//
// cdf_NegBinomial2 and pdf_NegBinomial are exported with C linkage because
// still-C cluster members reach them where the cluster is kept (the geometric
// qf_discrete_final dispatcher and the f-distribution Newton solver's NEGBINOM
// case; the f distribution's PDF path). The quantile uses the shared C Newton
// solver (WP34S_Qf_Newton), the regularised incomplete beta (WP34S_betai),
// logCyxReal, and the poisson owner's WP34S_normal_moment_approx, all bound
// through frontier_distribution_runtime. The testSuite drives every branch via
// tests/negBinomial_{p,l,r,i}.txt.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// WP34S_Qf_Newton distribution selector (defines.h).
const QF_NEWTON_NEGBINOM: u32 = 4;

fn checkParamNegBinom(x: *real_t, i: *real_t, j: *real_t) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_P, i) or !dr.getRegisterAsReal(dr.REGISTER_N, j)) {
        dr.specialResultNaN();
        return false;
    }

    if (!dr.checkRegisterNoFP(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamNegBinom:", "r is not an integer", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamNegBinom:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsZero(i) or dr.realIsNegative(i) or dr.realCompareGreaterEqual(i, dr.const1()) or dr.realIsZero(j) or dr.realIsNegative(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamNegBinom:", "the parameters must be 0 < p < 1 and r > 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

// Tail shared by P/L/R: store the answer, or report an invalid parameter on NaN.
fn storeOrInvalid(ans: *const real_t, comptime where: [*:0]const u8) void {
    if (dr.realIsNaN(ans)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError(where, "a parameter is invalid", null, null);
    } else {
        dr.convertRealToResultRegister(ans, dr.REGISTER_X, dr.amNone);
    }
    dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
}

pub fn negBinomialP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamNegBinom(&val, &prob, &num)) {
        if (dr.isAnInteger(&val)) {
            pdfNegBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        } else {
            dr.setZero(&ans);
        }
        storeOrInvalid(&ans, "In function fnNegBinomialP:");
    }
}

pub fn negBinomialL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamNegBinom(&val, &prob, &num)) {
        cdfNegBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        storeOrInvalid(&ans, "In function fnNegBinomialL:");
    }
}

pub fn negBinomialR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamNegBinom(&val, &prob, &num)) {
        cdfuNegBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        storeOrInvalid(&ans, "In function fnNegBinomialR:");
    }
}

pub fn negBinomialI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamNegBinom(&val, &prob, &num)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnNegBinomialI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        qfNegBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_NO_ROOT_FOUND, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnNegBinomialI:", "WP34S_Qf_Binomial did not converge", null, null);
            dr.specialResultNaN();
            return;
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

// ---------------------------------------------------------------------------
// WP34S math borrowings (upstream comment: "borrowed from the WP34S project").
// ---------------------------------------------------------------------------

fn negBinomParam(r: *const real_t, res: *real_t) bool {
    if (dr.realIsSpecial(r)) {
        dr.setNaN(res);
        return false;
    }
    if (!dr.realIsPositive(r) or !dr.isAnInteger(r)) {
        dr.setZero(res);
        return false;
    }
    return true;
}

// PDF[NB(r, p)](k) = [(k + r - 1) C k] p^k (1 - p)^r
pub fn pdfNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var xx: real_t = undefined;
    var c: real_t = undefined;

    if (!negBinomParam(r, res)) {
        return;
    }
    if (dr.realIsNegative(x)) {
        dr.setZero(res);
        return;
    }

    dr.realMinus(p0, &p, ctx);
    dr.WP34S_Ln1P(&p, &p, ctx); // ln(1 - p0)
    dr.realMultiply(&p, r, &p, ctx); // ln((1 - p0) ^ r)

    dr.WP34S_Ln(p0, &q, ctx);
    dr.realMultiply(&q, x, &q, ctx); // ln(p0 ^ x)
    dr.realAdd(&p, &q, &p, ctx);

    dr.realAdd(x, r, &q, ctx);
    dr.realSubtract(&q, dr.const1(), &q, ctx);
    dr.realCopy(x, &xx);
    dr.logCyxReal(&q, &xx, &c, ctx);

    dr.realAdd(&p, &c, &p, ctx);
    dr.realExponential(&p, res, ctx);
}

// I[p](k, r)
fn cdfuNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    if (!negBinomParam(r, res)) {
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, ctx);
    if (dr.realLessThan(&p, dr.const1())) {
        dr.setOne(res);
        return;
    }
    dr.WP34S_betai(r, &p, p0, res, ctx);
}

// 1 - I[p](k + 1, r)
fn cdfNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    if (!negBinomParam(r, res)) {
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, ctx);
    cdfNegBinomial2(&p, p0, r, res, ctx);
}

pub fn cdfNegBinomial2(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }

    dr.realSubtract(dr.const1(), p0, &p, ctx);
    dr.realAdd(x, dr.const1(), &q, ctx);
    dr.WP34S_betai(&q, r, &p, res, ctx);
}

fn qfNegBinomial(x: *const real_t, p0: *const real_t, r: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p0c: real_t = undefined;
    var pr: real_t = undefined;
    var mean: real_t = undefined;
    var variance: real_t = undefined;
    var s: real_t = undefined;

    if (!negBinomParam(r, res)) {
        return;
    }
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }

    dr.realSubtract(dr.const1(), p0, &p0c, ctx); // 1 - p
    dr.realMultiply(p0, r, &pr, ctx);
    dr.realDivide(&pr, &p0c, &mean, ctx); // mean = pr/(1-p)

    dr.realDivide(&mean, &p0c, &variance, ctx); // variance = pr/((1-p)^2)
    dr.realSquareRoot(&variance, &variance, ctx);

    dr.WP34S_normal_moment_approx(x, &variance, &mean, &s, ctx);
    dr.WP34S_Qf_Newton(QF_NEWTON_NEGBINOM, x, &s, p0, r, null, res, ctx);
}
