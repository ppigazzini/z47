// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/binomial.c: the Binomial distribution
// commands (fnBinomialP/L/R/I) and the WP34S math borrowings. Part of the
// SAVE_SPACE_DM42_17 cluster, so compiled only on host and DMCP5 and stubbed on
// every DM42 package via strip_17.
//
// WP34S_Cdf_Binomial2 and WP34S_Pdf_Binomial are exported with C linkage because
// still-C cluster members reach them where the cluster is kept (the geometric
// qf_discrete_final dispatcher / the f-distribution Newton solver, and the f
// distribution respectively). The quantile uses the shared C Newton solver
// (WP34S_Qf_Newton), the regularised incomplete beta (WP34S_betai), and the
// poisson owner's WP34S_normal_moment_approx, all bound through
// frontier_distribution_runtime. The testSuite drives every branch via
// tests/binomial_{p,l,r,i}.txt.

const dr = @import("frontier_distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// WP34S_Qf_Newton distribution selector (defines.h).
const QF_NEWTON_BINOMIAL: u32 = 2;

fn checkParamBinomial(x: *real_t, i: *real_t, j: *real_t) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_P, i) or !dr.getRegisterAsReal(dr.REGISTER_N, j)) {
        dr.specialResultNaN();
        return false;
    }

    if (!dr.checkRegisterNoFP(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamBinomial:", "n is not an integer", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamBinomial:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    } else if (dr.realIsNegative(i) or dr.realGreaterThan(i, dr.const1()) or dr.realIsNegative(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamBinomial:", "the parameters must be 0 \xa2\x64 p \xa2\x64 1 and n > 0", null, null);
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

pub fn binomialP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamBinomial(&val, &prob, &num)) {
        if (dr.isAnInteger(&val)) {
            wp34sPdfBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        } else {
            dr.setZero(&ans);
        }
        storeOrInvalid(&ans, "In function fnBinomialP:");
    }
}

pub fn binomialL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamBinomial(&val, &prob, &num)) {
        wp34sCdfBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        storeOrInvalid(&ans, "In function fnBinomialL:");
    }
}

pub fn binomialR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamBinomial(&val, &prob, &num)) {
        wp34sCdfuBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        storeOrInvalid(&ans, "In function fnBinomialR:");
    }
}

pub fn binomialI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var prob: real_t = undefined;
    var num: real_t = undefined;

    if (checkParamBinomial(&val, &prob, &num)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnBinomialI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfBinomial(&val, &prob, &num, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_NO_ROOT_FOUND, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnBinomialI:", "WP34S_Qf_Binomial did not converge", null, null);
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

fn binomialParam(n: *const real_t, res: *real_t) bool {
    if (dr.realIsSpecial(n)) {
        dr.setNaN(res);
        return false;
    }
    if (dr.realIsNegative(n) or !dr.isAnInteger(n)) {
        dr.setZero(res);
        return false;
    }
    return true;
}

pub fn wp34sPdfBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var nn: real_t = undefined;
    var xx: real_t = undefined;

    if (!binomialParam(n, res)) {
        return;
    }
    if (dr.realIsNegative(x) or dr.realGreaterThan(x, n)) {
        dr.setZero(res);
        return;
    }
    dr.realMinus(p0, &p, ctx);
    dr.WP34S_Ln1P(&p, &p, ctx);
    dr.realSubtract(n, x, &q, ctx);
    dr.realMultiply(&p, &q, &p, ctx);
    dr.realCopy(n, &nn);
    dr.realCopy(x, &xx);
    dr.logCyxReal(&nn, &xx, &q, ctx);
    dr.realAdd(&p, &q, &p, ctx);
    dr.WP34S_Ln(p0, &q, ctx);
    dr.realMultiply(&q, x, &q, ctx);
    dr.realAdd(&p, &q, &p, ctx);
    dr.realExponential(&p, res, ctx);
}

fn wp34sCdfuBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    if (!binomialParam(n, res)) {
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, ctx);
    if (dr.realLessThan(&p, dr.const1())) {
        dr.setOne(res);
        return;
    }
    dr.realSubtract(&p, dr.const1(), &p, ctx);
    if (dr.realGreaterThan(&p, n)) {
        dr.setZero(res);
        return;
    }
    dr.realSubtract(n, &p, &q, ctx);
    dr.realAdd(dr.const1(), &p, &r, ctx);
    dr.WP34S_betai(&q, &r, p0, res, ctx);
}

fn wp34sCdfBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    if (!binomialParam(n, res)) {
        return;
    }
    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, ctx);
    wp34sCdfBinomial2(&p, p0, n, res, ctx);
}

pub fn wp34sCdfBinomial2(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realGreaterThan(x, n)) {
        dr.setOne(res);
        return;
    }
    dr.realSubtract(n, x, &q, ctx);
    dr.realAdd(dr.const1(), x, &r, ctx);
    dr.realSubtract(dr.const1(), p0, &p, ctx);
    dr.WP34S_betai(&r, &q, &p, res, ctx);
}

fn wp34sQfBinomial(x: *const real_t, p0: *const real_t, n: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    if (!binomialParam(n, res)) {
        return;
    }
    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    dr.realMultiply(p0, n, &p, ctx); // mean = np
    dr.realSubtract(dr.const1(), p0, &q, ctx);
    dr.realMultiply(&q, &p, &p, ctx); // variance = np(1-p)
    dr.realSquareRoot(&q, &q, ctx);
    dr.WP34S_normal_moment_approx(x, &q, &p, &r, ctx);
    dr.WP34S_Qf_Newton(QF_NEWTON_BINOMIAL, x, &r, p0, n, null, &p, ctx);
    dr.realCopy(if (dr.realCompareLessEqual(&p, n)) &p else n, res);
}
