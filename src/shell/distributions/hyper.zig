// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/hyper.c: the Hypergeometric distribution
// commands (fnHypergeometricP/L/R/I) and the WP34S math borrowings. Part of the
// SAVE_SPACE_DM42_17 cluster, gated by strip_17: present only on host and DMCP5,
// stubbed on every DM42 package.
//
// cdf_Hypergeometric2 and pdf_Hypergeometric are exported with C linkage because
// still-C cluster members reach them where the cluster is kept (the geometric
// qf_discrete_final dispatcher and the f-distribution Newton solver's
// HYPERGEOMETRIC case; the f distribution's PDF path). The quantile uses the
// shared C Newton solver (WP34S_Qf_Newton) and the poisson owner's
// WP34S_normal_moment_approx; the CDF uses logCyxReal, WP34S_Ln/ExpM1, and
// WP34S_RelativeError, all bound through distribution_runtime.zig. The
// testSuite drives every branch via tests/hypergeometric_{p,l,r,i}.txt.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

const QF_NEWTON_HYPERGEOMETRIC: u32 = 5;

// Parameters: x in X, K (k) in Q, n (j) in N, N (i) in M.
fn checkParamHyper(x: *real_t, k: *real_t, j: *real_t, i: *real_t) bool {
    var xmin: real_t = undefined;
    var xmax: real_t = undefined;

    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, i) or
        !dr.getRegisterAsReal(dr.REGISTER_N, j) or !dr.getRegisterAsReal(dr.REGISTER_Q, k))
    {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DATA_TYPE_FOR_OP, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamHyper:", "Values in register X, I, J and K must be of the real or long integer type", null, null);
        return false;
    }

    dr.realAdd(j, k, &xmin, &dr.ctxtReal39);
    dr.realSubtract(&xmin, i, &xmin, &dr.ctxtReal39);
    if (dr.realIsNegative(&xmin)) {
        dr.setZero(&xmin);
    }
    dr.realCopy(if (dr.realLessThan(k, j)) k else j, &xmax);

    if (!dr.checkRegisterNoFP(i) or !dr.checkRegisterNoFP(j) or !dr.checkRegisterNoFP(k)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamHyper:", "N, n and/or K is not an integer", null, null);
        return false;
    }
    if (dr.realIsNegative(x) or dr.realLessThan(x, &xmin) or dr.realGreaterThan(x, &xmax)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamHyper:", "cannot calculate for x < max(0, n + K - N) or x > min(n, K)", null, null);
        return false;
    }
    if (dr.realIsNegative(k) or dr.realGreaterThan(k, i) or dr.realIsNegative(j) or dr.realGreaterThan(j, i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamHyper:", "the parameters must be integer, and 0 \xa2\x64 K \xa2\x64 N, 0 \xa2\x64 n \xa2\x64 N, and N \xa2\x65 0", null, null);
        return false;
    }
    return true;
}

fn storeOrInvalid(ans: *const real_t, comptime where: [*:0]const u8) void {
    if (dr.realIsNaN(ans)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError(where, "a parameter is invalid", null, null);
    } else {
        dr.convertRealToResultRegister(ans, dr.REGISTER_X, dr.amNone);
    }
    dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
}

pub fn hypergeometricP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (checkParamHyper(&val, &spec, &samp, &batch)) {
        if (dr.isAnInteger(&val)) {
            pdfHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal39);
        } else {
            dr.setZero(&ans);
        }
        storeOrInvalid(&ans, "In function fnHypergeometricP:");
    }
}

pub fn hypergeometricL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (checkParamHyper(&val, &spec, &samp, &batch)) {
        cdfHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal75);
        storeOrInvalid(&ans, "In function fnHypergeometricL:");
    }
}

pub fn hypergeometricR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (checkParamHyper(&val, &spec, &samp, &batch)) {
        cdfuHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal75);
        storeOrInvalid(&ans, "In function fnHypergeometricR:");
    }
}

pub fn hypergeometricI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var spec: real_t = undefined;
    var samp: real_t = undefined;
    var batch: real_t = undefined;

    if (checkParamHyper(&val, &spec, &samp, &batch)) {
        if (dr.realLessThan(&val, dr.const0()) or dr.realGreaterThan(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnHypergeometricI:", "the argument must be 0 \xa2\x64 x \xa2\x64 1", null, null);
            dr.specialResultNaN();
            return;
        }
        qfHypergeometric(&val, &spec, &samp, &batch, &ans, &dr.ctxtReal75);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnHypergeometricI:", "WP34S_Qf_Binomial did not converge", null, null);
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

// PDF(k; n, K, N) = (K C k) ((N-K) C (n-k)) / (N C n)
pub fn pdfHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var q: real_t = undefined;

    dr.realCopy(k0, &a);
    dr.realCopy(x, &b);
    dr.logCyxReal(&a, &b, &q, ctx); // K C k
    dr.realSubtract(n0, k0, &a, ctx);
    dr.realSubtract(n, x, &b, ctx);
    dr.logCyxReal(&a, &b, &c, ctx);
    dr.realAdd(&q, &c, &q, ctx); // (N-K) C (n-k)
    dr.realCopy(n0, &a);
    dr.realCopy(n, &b);
    dr.logCyxReal(&a, &b, &c, ctx);
    dr.realSubtract(&q, &c, &q, ctx); // N C n
    dr.realExponential(&q, res, ctx);
}

fn cdfHypergeometricCommon(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, complementary: bool, res: *real_t, ctx: *realContext_t) void {
    var a: real_t = undefined;
    var b: real_t = undefined;
    var c: real_t = undefined;
    var binom_part: real_t = undefined;
    var a1: real_t = undefined;
    var a2: real_t = undefined;
    var a3: real_t = undefined;
    var b1: real_t = undefined;
    var b2: real_t = undefined;
    var i: real_t = undefined;
    var hypergeom_part: real_t = undefined;
    var cvg_tol: real_t = undefined;

    dr.setOne(&cvg_tol);
    cvg_tol.exponent -= ctx.digits - 2;

    // (n C (k+1)) ((N-n) C (K-k-1)) / (N C K)
    dr.realCopy(n, &a);
    dr.realAdd(x, dr.const1(), &b, ctx);
    dr.logCyxReal(&a, &b, &binom_part, ctx); // n C (k+1)
    dr.realSubtract(n0, n, &a, ctx);
    dr.realSubtract(k0, x, &b, ctx);
    dr.realSubtract(&b, dr.const1(), &b, ctx);
    dr.logCyxReal(&a, &b, &c, ctx);
    dr.realAdd(&binom_part, &c, &binom_part, ctx); // (N-n) C (K-k-1)
    dr.realCopy(n0, &a);
    dr.realCopy(k0, &b);
    dr.logCyxReal(&a, &b, &c, ctx);
    dr.realSubtract(&binom_part, &c, &binom_part, ctx); // N C K

    // generalized hypergeometric function 3F2
    dr.setOne(&a1);
    dr.realAdd(x, dr.const1(), &a2, ctx);
    dr.realAdd(&a2, dr.const1(), &b1, ctx);
    dr.realSubtract(&a2, n, &a3, ctx);
    dr.realSubtract(&a2, k0, &a2, ctx);
    dr.realAdd(&b1, n0, &b2, ctx);
    dr.realSubtract(&b2, k0, &b2, ctx);
    dr.realSubtract(&b2, n, &b2, ctx);
    dr.setZero(&hypergeom_part);
    dr.setOne(&i);

    if (complementary) {
        dr.realExponential(&binom_part, &b, ctx);
    } else {
        dr.WP34S_ExpM1(&binom_part, &b, ctx);
        dr.realSetPositiveSign(&b);
    }

    while (true) {
        dr.realCopy(&b, &c);

        if (dr.realIsZero(&a2) or dr.realIsZero(&a3) or dr.realIsZero(&b1) or dr.realIsZero(&b2)) {
            break;
        }

        var sign_hgp = dr.realIsNegative(&a1);
        sign_hgp = sign_hgp != dr.realIsNegative(&a2);
        sign_hgp = sign_hgp != dr.realIsNegative(&a3);
        sign_hgp = sign_hgp != dr.realIsNegative(&b1);
        sign_hgp = sign_hgp != dr.realIsNegative(&b2);

        dr.realCopyAbs(&a1, &a);
        dr.WP34S_Ln(&a, &a, ctx);
        dr.realAdd(&hypergeom_part, &a, &hypergeom_part, ctx);
        dr.realCopyAbs(&a2, &a);
        dr.WP34S_Ln(&a, &a, ctx);
        dr.realAdd(&hypergeom_part, &a, &hypergeom_part, ctx);
        dr.realCopyAbs(&a3, &a);
        dr.WP34S_Ln(&a, &a, ctx);
        dr.realAdd(&hypergeom_part, &a, &hypergeom_part, ctx);
        dr.realCopyAbs(&b1, &a);
        dr.WP34S_Ln(&a, &a, ctx);
        dr.realSubtract(&hypergeom_part, &a, &hypergeom_part, ctx);
        dr.realCopyAbs(&b2, &a);
        dr.WP34S_Ln(&a, &a, ctx);
        dr.realSubtract(&hypergeom_part, &a, &hypergeom_part, ctx);
        dr.WP34S_Ln(&i, &a, ctx);
        dr.realSubtract(&hypergeom_part, &a, &hypergeom_part, ctx);

        dr.realAdd(&binom_part, &hypergeom_part, &a, ctx);
        dr.realExponential(&a, &a, ctx);
        if (sign_hgp) {
            dr.realSetNegativeSign(&a);
        }
        if (complementary) {
            dr.realAdd(&b, &a, &b, ctx);
        } else {
            dr.realSubtract(&b, &a, &b, ctx);
        }

        dr.realAdd(&a1, dr.const1(), &a1, ctx);
        dr.realAdd(&a2, dr.const1(), &a2, ctx);
        dr.realAdd(&a3, dr.const1(), &a3, ctx);
        dr.realAdd(&b1, dr.const1(), &b1, ctx);
        dr.realAdd(&b2, dr.const1(), &b2, ctx);
        dr.realAdd(&i, dr.const1(), &i, ctx);

        if (dr.WP34S_RelativeError(&b, &c, &cvg_tol, ctx) or dr.realIsSpecial(&b)) {
            break;
        }
    }

    dr.realCopy(&b, res);
    dr.realSetPositiveSign(res);
}

fn cdfuHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    dr.toIntegralValue(x, &p, dr.DEC_ROUND_CEILING, ctx);
    if (dr.realLessThan(&p, dr.const1())) {
        dr.setOne(res);
        return;
    }
    dr.realSubtract(&p, dr.const1(), &p, ctx);
    cdfHypergeometricCommon(&p, k0, n, n0, true, res, ctx);
}

fn cdfHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;

    dr.toIntegralValue(x, &p, dr.DEC_ROUND_FLOOR, ctx);
    cdfHypergeometric2(&p, k0, n, n0, res, ctx);
}

fn modeHypergeometric(k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var a: real_t = undefined;
    var q: real_t = undefined;

    dr.realAdd(n, dr.const1(), &a, ctx);
    dr.WP34S_Ln(&a, &q, ctx);
    dr.realAdd(k0, dr.const1(), &a, ctx);
    dr.WP34S_Ln(&a, &a, ctx);
    dr.realAdd(&q, &a, &q, ctx);
    dr.realAdd(n0, dr.const2(), &a, ctx);
    dr.WP34S_Ln(&a, &a, ctx);
    dr.realSubtract(&q, &a, &q, ctx);
    dr.realExponential(&q, &q, ctx);
    dr.toIntegralValue(&q, res, dr.DEC_ROUND_FLOOR, ctx);
}

pub fn cdfHypergeometric2(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var mode: real_t = undefined;
    var pdf: real_t = undefined;
    var i: real_t = undefined;
    var cdf: real_t = undefined;
    var cdf0: real_t = undefined;

    if (dr.realLessThan(x, dr.const0())) {
        dr.setZero(res);
        return;
    }

    modeHypergeometric(k0, n, n0, &mode, ctx);

    if (dr.realLessThan(x, &mode)) {
        dr.realCopy(x, &i);
        dr.setZero(&cdf);
        while (true) {
            dr.realCopy(&cdf, &cdf0);
            pdfHypergeometric(&i, k0, n, n0, &pdf, ctx);
            dr.realAdd(&cdf, &pdf, &cdf, ctx);
            dr.realSubtract(&i, dr.const1(), &i, ctx);
            if (dr.WP34S_RelativeError(&cdf, &cdf0, dr.const1e_37(), ctx) or dr.realIsNegative(&i)) {
                break;
            }
        }
        dr.realCopy(&cdf, res);
    } else {
        cdfHypergeometricCommon(x, k0, n, n0, false, res, ctx);
    }
}

fn qfHypergeometric(x: *const real_t, k0: *const real_t, n: *const real_t, n0: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var mean: real_t = undefined;
    var variance: real_t = undefined;
    var s: real_t = undefined;

    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }

    dr.WP34S_Ln(n, &variance, ctx);
    dr.WP34S_Ln(k0, &s, ctx);
    dr.realAdd(&variance, &s, &variance, ctx);
    dr.WP34S_Ln(n0, &s, ctx);
    dr.realSubtract(&variance, &s, &variance, ctx);
    dr.realExponential(&variance, &mean, ctx); // mean = nK/N

    dr.realSubtract(n0, k0, &s, ctx);
    dr.WP34S_Ln(&s, &s, ctx);
    dr.realAdd(&variance, &s, &variance, ctx);
    dr.WP34S_Ln(n0, &s, ctx);
    dr.realSubtract(&variance, &s, &variance, ctx);
    dr.realSubtract(n0, n, &s, ctx);
    dr.WP34S_Ln(&s, &s, ctx);
    dr.realAdd(&variance, &s, &variance, ctx);
    dr.realSubtract(n0, dr.const1(), &s, ctx);
    dr.WP34S_Ln(&s, &s, ctx);
    dr.realSubtract(&variance, &s, &variance, ctx);
    dr.realExponential(&variance, &variance, ctx); // variance = (nK/N)((N-K)/N)((N-n)/(N-1))
    dr.realSquareRoot(&variance, &variance, ctx);

    dr.WP34S_normal_moment_approx(x, &variance, &mean, &s, ctx);
    dr.WP34S_Qf_Newton(QF_NEWTON_HYPERGEOMETRIC, x, &s, k0, n, n0, res, ctx);
}
