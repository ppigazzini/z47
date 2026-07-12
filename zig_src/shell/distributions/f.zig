// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/f.c: the F (Fisher-Snedecor) distribution
// commands (fnF_P/L/R/I) plus the WP34S math borrowings, including the shared
// Newton-step solver WP34S_Qf_Newton used by the poisson/binomial/negBinom/hyper
// quantiles. Part of the SAVE_SPACE_DM42_17 cluster (stripped on every DM42
// package), so compiled only on host and DMCP5 and gated by strip_17.
//
// WP34S_Qf_Newton is exported with C linkage (frontier.zig) so the other cluster
// members link against it where the cluster is kept; on DM42 it collapses to an
// empty stub. The solver dispatches to each distribution's CDF/PDF (the Zig
// owners' exports, bound through frontier_distribution_runtime) and finishes
// discrete searches via WP34S_qf_discrete_final. The testSuite drives every
// branch via tests/f_{p,l,r,i}.txt.

const dr = @import("../distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

// WP34S_Qf_Newton distribution selectors (defines.h).
const QF_NEWTON_F: u32 = 0;
const QF_NEWTON_POISSON: u32 = 1;
const QF_NEWTON_BINOMIAL: u32 = 2;
const QF_NEWTON_NEGBINOM: u32 = 4;
const QF_NEWTON_HYPERGEOMETRIC: u32 = 5;

fn checkParamF(x: *real_t, i: *real_t, j: *real_t) bool {
    if (!dr.saveLastX()) {
        return false;
    }

    if (!dr.getRegisterAsReal(dr.REGISTER_X, x) or !dr.getRegisterAsReal(dr.REGISTER_M, i) or !dr.getRegisterAsReal(dr.REGISTER_N, j)) {
        dr.specialResultNaN();
        return false;
    }

    if (!(dr.checkRegisterNoFP(i) or dr.checkRegisterNoFP(j))) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamF:", "d1 or d2 is not an integer", null, null);
        dr.specialResultNaN();
        return false;
    }
    if (dr.realIsNegative(x)) {
        dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamF:", "cannot calculate for x < 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    if (dr.realIsZero(i) or dr.realIsNegative(i) or dr.realIsZero(j) or dr.realIsNegative(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
        dr.moreInfoOnError("In function checkParamF:", "cannot calculate for d1 \xa2\x64 0 or d2 \xa2\x64 0", null, null);
        dr.specialResultNaN();
        return false;
    }
    return true;
}

pub fn fP(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var d1: real_t = undefined;
    var d2: real_t = undefined;
    if (checkParamF(&val, &d1, &d2)) {
        wp34sPdfF(&val, &d1, &d2, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn fL(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var d1: real_t = undefined;
    var d2: real_t = undefined;
    if (checkParamF(&val, &d1, &d2)) {
        wp34sCdfF(&val, &d1, &d2, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn fR(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var d1: real_t = undefined;
    var d2: real_t = undefined;
    if (checkParamF(&val, &d1, &d2)) {
        wp34sCdfuF(&val, &d1, &d2, &ans, &dr.ctxtReal39);
        dr.storeResult(&ans);
    }
}

pub fn fI(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    var val: real_t = undefined;
    var ans: real_t = undefined;
    var d1: real_t = undefined;
    var d2: real_t = undefined;
    if (checkParamF(&val, &d1, &d2)) {
        if (dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnF_I:", "the argument must be 0 < x < 1", null, null);
            dr.specialResultNaN();
            return;
        }
        wp34sQfF(&val, &d1, &d2, &ans, &dr.ctxtReal39);
        if (dr.realIsNaN(&ans)) {
            dr.displayDomainErrorMessage(dr.ERROR_NO_ROOT_FOUND, dr.ERR_REGISTER_LINE, dr.REGISTER_X);
            dr.moreInfoOnError("In function fnF_I:", "WP34S_Qf_F did not converge", null, null);
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

pub fn wp34sPdfF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    dr.WP34S_Ln(d2, &p, ctx);
    dr.realMultiply(&p, d2, &p, ctx);
    dr.realMultiply(d1, x, &q, ctx);
    dr.WP34S_Ln(&q, &r, ctx);
    dr.realMultiply(&r, d1, &r, ctx);
    dr.realAdd(&p, &r, &p, ctx);
    dr.realAdd(&q, d2, &q, ctx);
    dr.WP34S_Ln(&q, &q, ctx);
    dr.realAdd(d1, d2, &r, ctx);
    dr.realMultiply(&q, &r, &q, ctx);
    dr.realSubtract(&p, &q, &p, ctx);
    dr.realMultiply(&p, dr.const1on2(), &p, ctx);
    dr.realMultiply(d1, dr.const1on2(), &q, ctx);
    dr.realMultiply(d2, dr.const1on2(), &r, ctx);
    dr.LnBeta(&r, &q, &q, ctx);
    dr.realSubtract(&p, &q, &p, ctx);
    dr.realExponential(&p, &p, ctx);
    dr.realDivide(&p, x, res, ctx);
}

pub fn wp34sCdfuF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setOne(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setZero(res);
        return;
    }
    dr.realMultiply(x, d1, &p, ctx);
    dr.realAdd(&p, d2, &p, ctx);
    dr.realDivide(d2, &p, &p, ctx);
    dr.realMultiply(d2, dr.const1on2(), &q, ctx);
    dr.realMultiply(d1, dr.const1on2(), &r, ctx);
    dr.WP34S_betai(&r, &q, &p, res, ctx);
}

pub fn wp34sCdfF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;

    if (dr.realCompareLessEqual(x, dr.const0())) {
        dr.setZero(res);
        return;
    }
    if (dr.realIsInfinite(x)) {
        dr.setOne(res);
        return;
    }
    dr.realMultiply(x, d1, &p, ctx);
    dr.realAdd(&p, d2, &q, ctx);
    dr.realDivide(&p, &q, &p, ctx);
    dr.realMultiply(d2, dr.const1on2(), &q, ctx);
    dr.realMultiply(d1, dr.const1on2(), &r, ctx);
    dr.WP34S_betai(&q, &r, &p, res, ctx);
}

fn wp34sQfF(x: *const real_t, d1: *const real_t, d2: *const real_t, res: *real_t, ctx: *realContext_t) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var reg0: real_t = undefined;
    var reg1: real_t = undefined;
    var reg2: real_t = undefined;

    dr.realCopy(x, &reg0);
    dr.WP34S_qf_q_est(x, &p, null, ctx);
    dr.realCopy(d1, &r);
    if (dr.realGreaterThan(&r, dr.const1())) {
        dr.realSubtract(&r, dr.const1(), &r, ctx);
    }
    dr.realDivide(dr.const1(), &r, &r, ctx);
    dr.realCopy(d2, &s);
    if (dr.realGreaterThan(&s, dr.const1())) {
        dr.realSubtract(&s, dr.const1(), &s, ctx);
    }
    dr.realDivide(dr.const1(), &s, &s, ctx);
    dr.realCopy(&s, &reg1);
    dr.realCopy(&r, &reg2);
    dr.realAdd(&r, &s, &r, ctx);
    dr.realDivide(dr.const2(), &r, &r, ctx);
    dr.realMultiply(&p, &p, &s, ctx);
    dr.realSubtract(&s, dr.const3(), &s, ctx);
    dr.realDivide(&s, dr.const6(), &s, ctx);
    dr.realAdd(&s, &r, &q, ctx);
    dr.realSquareRoot(&q, &q, ctx);
    dr.realMultiply(&q, &p, &q, ctx);
    dr.realDivide(&q, &r, &q, ctx);
    dr.realDivide(dr.const2(), &r, &p, ctx);
    dr.realMultiply(&p, dr.const1on3(), &p, ctx);
    dr.realChangeSign(&p);
    dr.realAdd(&p, &s, &p, ctx);
    dr.realDivide(dr.const5(), dr.const60(), &r, ctx);
    r.exponent += 1;
    dr.realAdd(&p, &r, &p, ctx);
    dr.realSubtract(&reg2, &reg1, &r, ctx);
    dr.realMultiply(&p, &r, &p, ctx);
    dr.realSubtract(&q, &p, &q, ctx);
    dr.realMultiply(&q, dr.const2(), &q, ctx);
    dr.realExponential(&q, &q, ctx);

    wp34sQfNewton(QF_NEWTON_F, &reg0, &q, d1, d2, null, res, ctx);
}

// The Newton-step solver: target in r_p, estimate refined in r_r, bisecting
// between r_low/r_high. Restructured from the upstream goto control flow.
pub fn wp34sQfNewton(
    r_dist: u32,
    target: *const real_t,
    estimate: *const real_t,
    p1: [*c]const real_t,
    p2: [*c]const real_t,
    p3: [*c]const real_t,
    res: *real_t,
    ctx: *realContext_t,
) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r_p: real_t = undefined;
    var r_low: real_t = undefined;
    var r_high: real_t = undefined;
    var r_maxstep: real_t = undefined;
    var r_r: real_t = undefined;
    var r_z: real_t = undefined;
    var r_w: real_t = undefined;
    var r_iterations: u32 = 100;
    var f_discrete = false;
    var f_nobisect = false;
    const f_nonnegative = true;
    const f_limitjump = true;

    dr.realCopy(target, &r_p);
    dr.realCopy(estimate, &r_r);

    if (r_dist != QF_NEWTON_F) {
        f_discrete = true;
    }

    dr.realMultiply(dr.const3on2(), dr.const1on2(), &p, ctx);
    dr.realMultiply(&p, &r_r, &p, ctx);
    dr.realCopy(&p, &r_maxstep);

    dr.setPlusInfinity(&r_high);
    dr.realCopy(dr.const0(), &r_low); // f_nonnegative is always true here

    var converged: real_t = undefined;
    var done = false;

    while (true) {
        // out-of-bounds: expand or bisect
        if (dr.realCompareGreaterEqual(&r_r, &r_high) or dr.realCompareLessEqual(&r_r, &r_low)) {
            if (dr.realIsInfinite(&r_high)) {
                dr.realMultiply(&r_low, dr.const2(), &r_r, ctx);
            } else if (dr.realIsInfinite(&r_low)) {
                dr.realMultiply(&r_high, dr.const2(), &r_r, ctx);
            } else {
                dr.realAdd(&r_low, &r_high, &r_r, ctx);
                dr.realMultiply(&r_r, dr.const2(), &r_r, ctx);
                f_nobisect = true;
            }
        }

        // CDF evaluation, re-bisecting until the estimate is within bounds
        while (true) {
            switch (r_dist) {
                QF_NEWTON_F => wp34sCdfF(&r_r, p1, p2, &r_w, ctx),
                QF_NEWTON_POISSON => dr.WP34S_Cdf_Poisson2(&r_r, p1, &r_w, ctx),
                QF_NEWTON_BINOMIAL => dr.WP34S_Cdf_Binomial2(&r_r, p1, p2, &r_w, ctx),
                QF_NEWTON_NEGBINOM => dr.cdf_NegBinomial2(&r_r, p1, p2, &r_w, ctx),
                QF_NEWTON_HYPERGEOMETRIC => dr.cdf_Hypergeometric2(&r_r, p1, p2, p3, &r_w, &dr.ctxtReal75),
                else => {},
            }
            dr.realSubtract(&r_w, &r_p, &r_z, ctx);
            if (dr.realCompareGreaterEqual(&r_z, dr.const0())) {
                if (f_nobisect or dr.realLessThan(&r_r, &r_high) or dr.realIsInfinite(&r_low)) {
                    f_nobisect = false;
                    if (dr.realLessThan(&r_r, &r_high)) dr.realCopy(&r_r, &r_high);
                    break;
                }
            } else {
                if (f_nobisect or dr.realGreaterThan(&r_r, &r_low) or dr.realIsInfinite(&r_high)) {
                    f_nobisect = false;
                    if (dr.realGreaterThan(&r_r, &r_low)) dr.realCopy(&r_r, &r_low);
                    break;
                }
            }
            // do_bisect
            dr.realAdd(&r_low, &r_high, &r_r, ctx);
            dr.realMultiply(&r_r, dr.const2(), &r_r, ctx);
            f_nobisect = true;
        }

        // PDF for the Newton step
        switch (r_dist) {
            QF_NEWTON_F => wp34sPdfF(&r_r, p1, p2, &q, ctx),
            QF_NEWTON_POISSON => dr.WP34S_Pdf_Poisson(&r_r, p1, &q, ctx),
            QF_NEWTON_BINOMIAL => dr.WP34S_Pdf_Binomial(&r_r, p1, p2, &q, ctx),
            QF_NEWTON_NEGBINOM => dr.pdf_NegBinomial(&r_r, p1, p2, &q, ctx),
            QF_NEWTON_HYPERGEOMETRIC => dr.pdf_Hypergeometric(&r_r, p1, p2, p3, &q, ctx),
            else => {},
        }
        if (dr.realIsZero(&q)) { // function is flat -- can't estimate
            dr.realCopy(&r_r, &converged);
            done = true;
            break;
        }
        dr.realDivide(&r_z, &q, &r_w, ctx);
        dr.realCopyAbs(&r_w, &q);
        if (f_limitjump and dr.realCompareGreaterEqual(&q, &r_maxstep)) {
            if (dr.realLessThan(&r_w, dr.const0())) {
                dr.realMinus(&r_maxstep, &r_w, ctx);
            } else {
                dr.realCopy(&r_maxstep, &r_w);
            }
        }
        dr.realCopy(&r_r, &r_z);
        dr.realSubtract(&r_r, &r_w, &r_r, ctx);
        if (f_nonnegative and dr.realLessThan(&r_r, dr.const0())) {
            dr.realCopy(&r_z, &r_r);
            r_r.exponent -= 5;
        }

        if (!dr.realIsSpecial(&r_high) and !dr.realIsSpecial(&r_low) and dr.WP34S_RelativeError(&r_low, &r_high, dr.const1e_37(), ctx)) {
            dr.realAdd(&r_high, &r_low, &p, ctx);
            dr.realMultiply(&p, dr.const1on2(), &p, ctx);
            dr.realCopy(&p, &converged);
            done = true;
            break;
        } else if (f_discrete) {
            dr.realSubtract(&r_z, &r_r, &p, ctx);
            dr.realSetPositiveSign(&p);
            if (dr.realGreaterThan(dr.const1on10(), &p)) {
                dr.realCopy(&r_r, &converged);
                done = true;
                break;
            }
        } else if (dr.WP34S_RelativeError(&r_r, &r_z, dr.const1e_37(), ctx)) {
            dr.realCopy(&r_r, &converged);
            done = true;
            break;
        }

        r_iterations -= 1;
        if (r_iterations == 0) {
            dr.setNaN(res);
            return;
        }
    }

    if (done) {
        if (f_discrete) {
            dr.toIntegralValue(&converged, &q, dr.DEC_ROUND_FLOOR, ctx);
            dr.WP34S_qf_discrete_final(@intCast(r_dist - 1), &q, &r_p, p1, p2, p3, &converged, ctx);
        }
        dr.realCopy(&converged, res);
    }
}
