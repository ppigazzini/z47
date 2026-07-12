// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/chi2.c: the Chi-squared distribution
// commands (fnChi2P/L/R/I) and the WP34S math borrowings. Part of the
// SAVE_SPACE_DM42_17B cluster (cauchy/chi/expo/logis/t/weibull), which is kept on
// DM42 packages 1 and 3 and on host/DMCP5; gated by strip_17b and tagged
// linksection(dr.code_section) so the code runs from QSPI on the flash-limited
// old_hw DM42. Self-contained: the quantile is a Halley refinement (no shared
// Newton solver), so no helpers are exported. The testSuite drives every branch
// via tests/chi2_{p,l,r,i}.txt.

const dr = @import("../distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// checkRegisterNoFP lives in upstream chi2.c and is shared by the binomial/hyper/
// negBinom/f cluster members; export it (frontier.zig) so they link against it.
pub fn checkRegisterNoFP(reg: *const real_t) linksection(dr.code_section) bool {
    var floored: real_t = undefined;
    dr.toIntegralValue(reg, &floored, dr.DEC_ROUND_FLOOR, &dr.ctxtReal39);
    return dr.realEqual(reg, &floored);
}

fn checkParamChi2(x: *real_t, i: *real_t) linksection(dr.code_section) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, i)) {
        dr.specialResultNaN();
        return false;
    }

    if (!checkRegisterNoFP(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamChi2:", "k is not an integer", null, null);
        dr.specialResultNaN();
        return false;
    }
    if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamChi2:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    if (dr.realIsZero(i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamChi2:", "cannot calculate for k \xa2\x64 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn chi2P(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamChi2(&val, &dof)) {
        wp34sPdfChi2(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn chi2L(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamChi2(&val, &dof)) {
        wp34sCdfChi2(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn chi2R(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamChi2(&val, &dof)) {
        wp34sCdfuChi2(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn chi2I(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;

    if (checkParamChi2(&val, &dof)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnChi2I:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfChi2(&val, &dof, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_NO_ROOT_FOUND, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnChi2I:", "WP34S_Qf_Chi2 did not converge", null, null);
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

fn wp34sPdfChi2(x: *const real_t, k: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;

    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }

    dr.realMultiply(k, dr.const1on2(), &p, ctx);
    dr.WP34S_Ln(x, &q, ctx);
    dr.realMultiply(x, dr.const1on2(), &r, ctx);
    dr.realChangeSign(&r);
    dr.realSubtract(&p, dr.const1(), &s, ctx);
    dr.realMultiply(&q, &s, &q, ctx);
    dr.realAdd(&r, &q, &q, ctx);
    dr.WP34S_LnGamma(&p, &r, ctx);
    dr.realSubtract(&q, &r, &q, ctx);
    dr.realMultiply(&p, dr.constLn2(), &r, ctx);
    dr.realSubtract(&q, &r, &q, ctx);
    dr.realExponential(&q, res, ctx);
}

fn wp34sCdfuChi2(x: *const real_t, k: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    dr.realMultiply(x, dr.const1on2(), &p, ctx);
    dr.realMultiply(k, dr.const1on2(), &q, ctx);
    dr.WP34S_GammaP(&p, &q, res, ctx, true, true);
}

fn wp34sCdfChi2(x: *const real_t, k: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;

    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    dr.realMultiply(x, dr.const1on2(), &p, ctx);
    dr.realMultiply(k, dr.const1on2(), &q, ctx);
    dr.WP34S_GammaP(&p, &q, res, ctx, false, true);
}

fn wp34sQfChi2(x: *const real_t, k: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var t: real_t = undefined;
    var reg0: real_t = undefined;
    var loops: i32 = 6;

    if (dr.realEqual(x, dr.const0())) {
        dr.setZero(res);
    }

    dr.realCopy(x, &reg0);
    dr.int32ToReal(19, &p);
    p.exponent -= 1; // 1.9
    dr.realCopy(if (dr.realEqual(k, dr.const1())) dr.const0() else k, &q);
    dr.realChangeSign(&q);
    dr.realPow(&p, &q, &p, ctx);
    dr.realDivide(&p, dr.const39Pi(), &p, ctx);
    if (dr.realCompareGreaterEqual(&reg0, &p)) {
        dr.WP34S_qf_q_est(&reg0, &q, null, ctx);
        dr.int32ToReal(222, &s);
        s.exponent -= 3; // 0.222
        dr.realDivide(&s, k, &s, ctx);
        dr.realSquareRoot(&s, &r, ctx);
        dr.realMultiply(&q, &r, &q, ctx);
        dr.realAdd(&q, dr.const1(), &q, ctx);
        dr.realSubtract(&q, &s, &q, ctx);
        dr.realMultiply(&q, &q, &r, ctx);
        dr.realMultiply(&r, &q, &q, ctx);
        dr.realMultiply(&q, k, &q, ctx);
        dr.realMultiply(dr.constEE(), k, &r, ctx);
        dr.realAdd(&r, dr.const8(), &r, ctx);
        if (dr.realCompareGreaterEqual(&q, &r)) {
            dr.realMultiply(&q, dr.const1on2(), &q, ctx);
            dr.WP34S_Ln(&q, &q, ctx);
            dr.realMultiply(k, dr.const1on2(), &t, ctx);
            dr.realSubtract(&t, dr.const1(), &t, ctx);
            dr.realMultiply(&q, &t, &q, ctx);
            dr.realChangeSign(&q);
            dr.realMinus(&reg0, &t, ctx);
            dr.WP34S_Ln1P(&t, &t, ctx);
            dr.realAdd(&q, &t, &q, ctx);
            dr.realMultiply(k, dr.const1on2(), &t, ctx);
            dr.WP34S_LnGamma(&t, &t, ctx);
            dr.realAdd(&q, &t, &q, ctx);
            dr.realMultiply(&q, dr.const2(), &q, ctx);
            dr.realChangeSign(&q);
        }
    } else { // chi2_q_low
        dr.realDivide(&reg0, k, &q, ctx);
        dr.realMultiply(&q, dr.const1on2(), &q, ctx);
        dr.WP34S_Ln(&q, &q, ctx);
        dr.realMultiply(k, dr.const1on2(), &r, ctx);
        dr.WP34S_LnGamma(&r, &r, ctx);
        dr.realAdd(&q, &r, &q, ctx);
        dr.realMultiply(&q, dr.const2(), &q, ctx);
        dr.realDivide(&q, k, &q, ctx);
        dr.realExponential(&q, &q, ctx);
        dr.realMultiply(&q, dr.const2(), &q, ctx);
    }

    while (true) { // chi2_q_refine
        if (dr.realLessThan(&q, k)) {
            wp34sCdfChi2(&q, k, &p, ctx);
            dr.realDivide(&p, &reg0, &r, ctx);
            dr.WP34S_Ln(&r, &r, ctx);
        } else { // chi2_q_big
            dr.realSubtract(dr.const1(), &reg0, &r, ctx);
            wp34sCdfuChi2(&q, k, &s, ctx);
            dr.realSubtract(dr.const1(), &s, &p, ctx);
            dr.realSubtract(&r, &s, &r, ctx);
            dr.realDivide(&r, &reg0, &r, ctx);
            dr.WP34S_Ln1P(&r, &r, ctx);
        }
        // chi2_q_common
        wp34sPdfChi2(&q, k, &s, ctx);
        dr.realDivide(&s, &p, &p, ctx);
        dr.realDivide(&r, &p, &r, ctx);
        dr.realSubtract(k, dr.const2(), &s, ctx);
        dr.realSubtract(&s, &q, &s, ctx);
        dr.realDivide(&s, &q, &s, ctx);
        dr.realMultiply(&p, dr.const2(), &p, ctx);
        dr.realSubtract(&s, &p, &p, ctx);
        dr.realMultiply(&p, dr.const1on4(), &p, ctx);
        dr.realMultiply(&p, &r, &p, ctx);
        dr.realChangeSign(&p);
        dr.realAdd(&p, dr.const1(), &p, ctx);
        dr.realDivide(&r, &p, &r, ctx);
        dr.realChangeSign(&r);
        dr.realAdd(&q, &r, &p, ctx);
        // SHOW_CONVERGENCE
        dr.setOne(&r);
        r.exponent -= 32;
        if (dr.WP34S_RelativeError(&p, &q, &r, ctx)) {
            dr.realCopy(&p, res);
            return;
        }
        dr.realCopy(&p, &q);
        loops -= 1;
        if (loops <= 0) break;
    }

    dr.setNaN(res); // ERR 20
}
