// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/normal.c: the Standard Normal, parametric
// Normal and Log-Normal distribution commands plus the WP34S math borrowings.
// The SAVE_SPACE_DM42_16 cluster is stripped on every DM42 package, so the owner
// is compiled only on host and DMCP5 (no QSPI linksection needed) and gated by
// strip_16. WP34S_qf_q_est (the signed Normal-quantile guess) and WP34S_Cdf_Q are
// exported with C linkage because the poisson/chi2/hyper/f and t members reach
// them where their clusters are kept; on DM42 they collapse to the upstream
// stubs. The testSuite drives every branch via tests/{normal,stdnormal,
// logNormal}_{p,l,r,i}.txt.

const dr = @import("frontier_distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

pub const NormalType = enum { std_normal, param_normal, log_normal };

fn checkParamNormal(t: NormalType, x: *real_t, i: *real_t, j: *real_t) bool {
    if (!dr.saveLastX()) {
        return false;
    }
    if (!dr.getRegisterAsReal(dr.REGISTER_X, x)) {
        dr.specialResultNaN();
        return false;
    }
    if (t == .std_normal) {
        return true;
    }
    if (!dr.getRegisterAsReal(dr.REGISTER_M, i) or !dr.getRegisterAsReal(dr.REGISTER_S, j)) {
        dr.specialResultNaN();
        return false;
    }
    if (dr.realIsZero(j) or dr.realIsNegative(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamNormal:", "cannot calculate for \x83\xc3 \xa2\x64 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

const ctx = &dr.ctxtReal39;

pub fn normalP(t: NormalType) void {
    var val: real_t = undefined;
    var alval: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var ans: real_t = undefined;
    const stdn = t == .std_normal;
    const logn = t == .log_normal;

    if (checkParamNormal(t, &val, &mu, &sigma)) {
        if (logn and dr.realIsZero(&val)) {
            dr.setZero(&ans);
        } else if (logn and dr.realIsNegative(&val)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function normalP:", "cannot calculate for x < 0", null, null);
        } else {
            if (!stdn) {
                if (logn) {
                    dr.realCopy(&val, &alval);
                    dr.WP34S_Ln(&alval, &val, ctx);
                }
                dr.realSubtract(&val, &mu, &val, ctx);
                dr.realDivide(&val, &sigma, &val, ctx);
            }
            wp34sPdfQ(&val, &ans, ctx);
            if (!stdn) {
                dr.realDivide(&ans, &sigma, &ans, ctx);
                if (logn) {
                    dr.realDivide(&ans, &alval, &ans, ctx);
                }
            }
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

fn normalCdf(t: NormalType, comptime where: [*:0]const u8, upper: bool) void {
    var val: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var ans: real_t = undefined;
    const stdn = t == .std_normal;
    const logn = t == .log_normal;

    if (checkParamNormal(t, &val, &mu, &sigma)) {
        if (logn and dr.realIsZero(&val)) {
            if (upper) dr.setOne(&ans) else dr.setZero(&ans);
        } else if (logn and dr.realIsNegative(&val)) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError(where, "cannot calculate for x < 0", null, null);
        } else {
            if (!stdn) {
                if (logn) {
                    dr.WP34S_Ln(&val, &val, ctx);
                }
                dr.realSubtract(&val, &mu, &val, ctx);
                dr.realDivide(&val, &sigma, &val, ctx);
            }
            if (upper) wp34sCdfuQ(&val, &ans, ctx) else wp34sCdfQ(&val, &ans, ctx);
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn normalL(t: NormalType) void {
    normalCdf(t, "In function normalL:", false);
}

pub fn normalR(t: NormalType) void {
    normalCdf(t, "In function normalR:", true);
}

pub fn normalI(t: NormalType) void {
    var val: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var ans: real_t = undefined;
    const stdn = t == .std_normal;
    const logn = t == .log_normal;

    if (checkParamNormal(t, &val, &mu, &sigma)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function normalI:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfQ(&val, &ans, ctx);
        if (!stdn) {
            dr.realMultiply(&ans, &sigma, &ans, ctx);
            dr.realAdd(&ans, &mu, &ans, ctx);
            if (logn) {
                dr.realExponential(&ans, &ans, ctx);
            }
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

// ---------------------------------------------------------------------------
// WP34S math borrowings (upstream comment: "borrowed from the WP34S project").
// ---------------------------------------------------------------------------

fn cdfQ(x: *const real_t, res: *real_t, real_context: *realContext_t, upper: bool) void {
    var p: real_t = undefined;
    // The upstream cross-jumps swap the tail for negative x: the "upper" block
    // runs when upper != (x < 0), otherwise the "lower" block runs.
    if (upper != dr.realIsNegative(x)) {
        dr.realMultiply(x, x, res, real_context);
        dr.realMultiply(res, dr.const1on2(), res, real_context);
        dr.WP34S_GammaP(res, dr.const1on2(), res, real_context, true, false);
        dr.realMultiply(res, dr.const1on2(), res, real_context);
        dr.realSquareRoot(dr.const39Pi(), &p, real_context);
        dr.realDivide(res, &p, res, real_context);
    } else {
        dr.realMultiply(x, x, res, real_context);
        dr.realMultiply(res, dr.const1on2(), res, real_context);
        dr.WP34S_GammaP(res, dr.const1on2(), res, real_context, false, false);
        dr.realSquareRoot(dr.const39Pi(), &p, real_context);
        dr.realDivide(res, &p, res, real_context);
        dr.realAdd(res, dr.const1(), res, real_context);
        dr.realMultiply(res, dr.const1on2(), res, real_context);
    }
}

fn wp34sPdfQ(x: *const real_t, res: *real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;
    dr.realMultiply(x, x, res, real_context);
    dr.realMultiply(res, dr.const1on2(), res, real_context);
    dr.realChangeSign(res);
    dr.realExponential(res, res, real_context);
    dr.realSquareRoot(dr.const39_2pi(), &p, real_context);
    dr.realDivide(res, &p, res, real_context);
}

fn wp34sCdfuQ(x: *const real_t, res: *real_t, real_context: *realContext_t) void {
    cdfQ(x, res, real_context, true);
}

pub fn wp34sCdfQ(x: *const real_t, res: *real_t, real_context: *realContext_t) void {
    cdfQ(x, res, real_context, false);
}

// Signed guess for the Normal quantile: any 0 < p < 1 -> signed estimate.
pub fn wp34sQfQEst(x: *const real_t, res: *real_t, res_y: ?*real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var is_small = false;

    dr.realMinus(x, &p, real_context);
    dr.realAdd(&p, dr.const1(), &p, real_context);
    if (dr.realLessThan(x, &p)) {
        is_small = true;
        dr.realCopy(x, &p);
    }

    dr.realMultiply(dr.const2(), dr.const1on10(), &q, real_context);

    if (dr.realLessThan(&p, &q)) {
        dr.WP34S_Ln(&p, &q, real_context);
        dr.realMultiply(&q, dr.const2(), &q, real_context);
        dr.realChangeSign(&q);
        dr.realSubtract(&q, dr.const1(), &r, real_context);
        dr.realMultiply(&r, dr.const39_2pi(), &r, real_context);
        dr.realSquareRoot(&r, &r, real_context);
        dr.realMultiply(&r, &p, &r, real_context);
        dr.WP34S_Ln(&r, &r, real_context);
        dr.realMultiply(&r, dr.const2(), &r, real_context);
        dr.realChangeSign(&r);
        dr.realSquareRoot(&r, &r, real_context);
        dr.int32ToReal(264, &s);
        s.exponent -= 3; // 0.264
        dr.realDivide(&s, &q, &q, real_context);
        dr.realAdd(&q, &r, &q, real_context);
    } else { // qf_q_mid
        dr.realMinus(&p, &q, real_context);
        dr.realAdd(&q, dr.const1on2(), &q, real_context);
        dr.realSquareRoot(dr.const39_2pi(), &r, real_context);
        dr.realMultiply(&q, &r, &q, real_context);
        dr.realMultiply(&q, &q, &r, real_context);
        dr.realMultiply(&r, &q, &r, real_context);
        dr.realDivide(&r, dr.const5(), &r, real_context);
        dr.realAdd(&q, &r, &q, real_context);
    }

    dr.realCopy(&q, res);
    if (res_y) |ry| {
        dr.realCopy(&p, ry);
    }
    if (is_small) {
        dr.realChangeSign(res);
    }
}

fn wp34sQfQ(x: *const real_t, res: *real_t, real_context: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var reg0: real_t = undefined;
    var half = false;
    var loops: i32 = 2;

    wp34sQfQEst(x, &p, &reg0, real_context);
    if (dr.realIsNegative(&p)) {
        half = true;
    }
    dr.realSetPositiveSign(&p);
    dr.realAdd(&p, dr.const1(), &q, real_context);
    dr.roundToSignificantDigits(&q, &q, 3, real_context);

    var do_refine = true;
    if (dr.realEqual(&q, dr.const1())) {
        loops -= 1;
        dr.realCopy(&p, &q);
        q.exponent += 16; // q * 1e16
        do_refine = dr.realGreaterThan(&q, dr.const1());
    }

    if (do_refine) {
        while (true) { // qf_q_refine
            if (dr.realCompareGreaterEqual(&p, dr.const1())) {
                wp34sCdfuQ(&p, &q, real_context);
                dr.realSubtract(&q, &reg0, &q, real_context);
            } else { // qf_q_small
                dr.realMultiply(&p, &p, &q, real_context);
                dr.realMultiply(&q, dr.const1on2(), &q, real_context);
                dr.WP34S_GammaP(&q, dr.const1on2(), &r, real_context, false, true);
                dr.realMultiply(&r, dr.const1on2(), &q, real_context);
                dr.realChangeSign(&q);
                dr.realSubtract(dr.const1on2(), &reg0, &r, real_context);
                dr.realAdd(&q, &r, &q, real_context);
            }
            // qf_q_common
            wp34sPdfQ(&p, &r, real_context);
            dr.realDivide(&q, &r, &q, real_context);
            dr.realMultiply(&q, &q, &r, real_context);
            dr.realMultiply(&r, &q, &r, real_context);
            dr.realMultiply(&p, &p, &s, real_context);
            dr.realMultiply(&s, dr.const2(), &s, real_context);
            dr.realAdd(&s, dr.const1(), &s, real_context);
            dr.realMultiply(&r, &s, &r, real_context);
            dr.realDivide(&r, dr.const6(), &r, real_context);
            dr.realMultiply(&p, dr.const1on2(), &s, real_context);
            dr.realMultiply(&s, &q, &s, real_context);
            dr.realMultiply(&s, &q, &s, real_context);
            dr.realAdd(&s, &r, &r, real_context);
            dr.realAdd(&r, &q, &q, real_context);
            dr.realAdd(&q, &p, &p, real_context);
            loops -= 1;
            if (loops <= 0) break;
        }
    }

    if (half) {
        dr.realChangeSign(&p);
    }
    dr.realCopy(&p, res);
}
