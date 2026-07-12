// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/t.c: the Student's t distribution commands
// (fnT_P/L/R/I) and the WP34S math borrowings. Part of the SAVE_SPACE_DM42_17B
// cluster (kept on DM42 packages 1 and 3 and on host/DMCP5), gated by strip_17b
// and tagged linksection(dr.code_section) so the code runs from QSPI on the
// flash-limited old_hw DM42. Self-contained (its own Halley-style quantile
// refinement); no helpers are exported. The testSuite drives every branch via
// tests/t_{p,l,r,i}.txt.

const dr = @import("../distribution_runtime.zig");
const real_t = dr.real_t;
const realContext_t = dr.realContext_t;

fn checkParamT(x: *real_t, i: *real_t) linksection(dr.code_section) bool {
    if (!dr.saveLastX()) {
        return false;
    }
    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, i)) {
        dr.specialResultNaN();
        return false;
    }
    if (dr.realIsZero(i) or dr.realIsNegative(i)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamT:", "cannot calculate for \x83\xbd \xa2\x64 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn tP(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;
    if (checkParamT(&val, &dof)) {
        wp34sPdfT(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn tL(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;
    if (checkParamT(&val, &dof)) {
        cdfT(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn tR(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;
    if (checkParamT(&val, &dof)) {
        wp34sCdfuT(&val, &dof, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn tI(unused_but_mandatory_parameter: u16) linksection(dr.code_section) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var dof: real_t = undefined;
    if (checkParamT(&val, &dof)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnT_I:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfT(&val, &dof, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_NO_ROOT_FOUND, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnT_I:", "WP34S_Qf_T did not converge", null, null);
        } else {
            dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        }
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

// ---------------------------------------------------------------------------
// WP34S math borrowings (upstream comment: "borrowed from the WP34S project").
// ---------------------------------------------------------------------------

fn wp34sPdfT(x: *const real_t, nu: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var i: real_t = undefined;

    dr.realMultiply(x, x, &p, ctx);
    dr.realMultiply(nu, dr.const1on2(), &q, ctx);
    dr.WP34S_LnGamma(&q, &r, ctx);
    dr.realAdd(dr.const1on2(), &q, &i, ctx);
    dr.WP34S_LnGamma(&i, &s, ctx);
    dr.realSubtract(&s, &r, &q, ctx);
    dr.realDivide(&p, nu, &p, ctx);
    dr.WP34S_Ln1P(&p, &p, ctx);
    dr.realMultiply(&p, &i, &p, ctx);
    dr.realSubtract(&q, &p, &p, ctx);
    dr.realExponential(&p, &p, ctx);
    dr.realMultiply(dr.const39Pi(), nu, &q, ctx);
    dr.realSquareRoot(&q, &q, ctx);
    dr.realDivide(&p, &q, res, ctx);
}

fn cdfT(x: *const real_t, nu: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var invert = false;

    dr.realCopy(x, &p);

    if (dr.realIsInfinite(&p)) {
        dr.realCopy(if (dr.realIsNegative(&p)) dr.const0() else dr.const1(), res);
        return;
    }
    if (dr.realIsZero(&p)) {
        dr.realCopy(dr.const1on2(), res);
        return;
    }
    if (dr.realIsPositive(&p)) {
        invert = true;
    }

    dr.realMultiply(&p, &p, &p, ctx);
    if (dr.realCompareGreaterEqual(&p, dr.const1())) {
        dr.realAdd(&p, nu, &p, ctx);
        dr.realDivide(nu, &p, &p, ctx);
        dr.realMultiply(nu, dr.const1on2(), &q, ctx);
        dr.WP34S_betai(dr.const1on2(), &q, &p, &r, ctx);
        dr.realMultiply(&r, dr.const1on2(), res, ctx);
    } else { // cdf_t_small
        dr.realAdd(&p, nu, &q, ctx);
        dr.realDivide(&p, &q, &p, ctx);
        dr.realMultiply(nu, dr.const1on2(), &q, ctx);
        dr.WP34S_betai(&q, dr.const1on2(), &p, &r, ctx);
        dr.realMultiply(&r, dr.const1on2(), &r, ctx);
        dr.realChangeSign(&r);
        dr.realAdd(&r, dr.const1on2(), res, ctx);
    }
    if (invert) {
        dr.realSubtract(dr.const1(), res, res, ctx);
    }
}

fn wp34sCdfuT(x: *const real_t, nu: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var xn: real_t = undefined;
    dr.realMinus(x, &xn, ctx);
    cdfT(&xn, nu, res, ctx);
}

fn wp34sQfT(x: *const real_t, nu: *const real_t, res: *real_t, ctx: *realContext_t) linksection(dr.code_section) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var a: real_t = undefined;
    var reg0: real_t = undefined;
    var neg = false;
    var loops: i32 = 7;

    dr.realSubtract(dr.const1(), x, &p, ctx);
    if (dr.realLessThan(x, &p)) {
        neg = true;
        dr.realCopy(x, &p);
    }
    dr.realCopy(&p, &reg0);
    dr.realSquareRoot(nu, &p, ctx);
    dr.realAdd(&p, dr.const7(), &p, ctx);
    dr.realMinus(nu, &q, ctx);
    dr.realPow(&p, &q, &p, ctx);
    dr.realMultiply(&p, dr.const1on4(), &a, ctx);
    if (dr.realCompareLessEqual(&reg0, &a)) {
        dr.realMultiply(nu, dr.const2(), &p, ctx);
        dr.realMultiply(&reg0, &p, &q, ctx);
        dr.realSubtract(dr.const1on4(), dr.const1(), &r, ctx);
        dr.realAdd(&p, &r, &p, ctx);
        dr.realDivide(dr.const39Pi(), &p, &p, ctx);
        dr.realSquareRoot(&p, &p, ctx);
        dr.realMultiply(&p, &q, &q, ctx);
        dr.realDivide(dr.const1(), nu, &r, ctx);
        dr.realPow(&q, &r, &q, ctx);
        dr.realSquareRoot(nu, &r, ctx);
        dr.realDivide(&r, &q, &p, ctx);
    } else { // qf_t_tail
        dr.WP34S_qf_q_est(&reg0, &p, null, ctx);
        dr.realMultiply(&p, &p, &p, ctx);
        dr.realMultiply(dr.constEE(), nu, &r, ctx);
        dr.realDivide(dr.const1(), &r, &r, ctx);
        dr.realAdd(&r, dr.const1(), &r, ctx);
        dr.realMultiply(&p, &r, &p, ctx);
        dr.realDivide(&p, nu, &p, ctx);
        dr.realExponential(&p, &p, ctx);
        dr.realSubtract(&p, dr.const1(), &p, ctx);
        dr.realMultiply(&p, nu, &p, ctx);
        dr.realSquareRoot(&p, &p, ctx);
    }

    var converged = false;
    while (true) { // qf_t_loop
        dr.realMultiply(&p, &p, &q, ctx);
        if (dr.realCompareGreaterEqual(&q, dr.const1())) {
            wp34sCdfuT(&p, nu, &q, ctx);
            dr.realSubtract(&q, &reg0, &q, ctx);
        } else { // qf_t_small
            dr.realAdd(&q, nu, &r, ctx);
            dr.realDivide(&q, &r, &q, ctx);
            dr.realMultiply(nu, dr.const1on2(), &r, ctx);
            dr.WP34S_betai(&r, dr.const1on2(), &q, &s, ctx);
            dr.realMultiply(&s, dr.const1on2(), &s, ctx);
            dr.realChangeSign(&s);
            dr.realSubtract(dr.const1on2(), &reg0, &q, ctx);
            dr.realAdd(&s, &q, &q, ctx);
        }
        // qf_t_step
        wp34sPdfT(&p, nu, &r, ctx);
        dr.realDivide(&q, &r, &q, ctx);
        dr.realMultiply(&q, &r, &r, ctx);
        dr.realAdd(nu, dr.const1(), &s, ctx);
        dr.realMultiply(&r, &s, &r, ctx);
        dr.realMultiply(&p, &p, &s, ctx);
        dr.realAdd(&s, nu, &s, ctx);
        dr.realMultiply(&s, dr.const2(), &s, ctx);
        dr.realDivide(&r, &s, &r, ctx);
        dr.realSubtract(&r, dr.const1(), &r, ctx);
        dr.realDivide(&q, &r, &q, ctx);
        dr.realChangeSign(&q);
        dr.realAdd(&p, &q, &q, ctx);
        dr.setOne(&r);
        r.exponent -= 32;
        if (dr.WP34S_RelativeError(&q, &p, &r, ctx)) {
            dr.realCopy(&q, res);
            converged = true;
            break;
        }
        dr.realCopy(&q, &p);
        loops -= 1;
        if (loops <= 0) break;
    }

    if (!converged) {
        dr.setNaN(res); // ERR 20
    }
    if (neg) {
        dr.realChangeSign(res);
    }
}
