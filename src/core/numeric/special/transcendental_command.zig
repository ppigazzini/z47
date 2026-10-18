const abi = @import("abi");
const build_options = @import("math_command_wrappers_build_options");
const comparison_reals_owned = @import("../compare/comparison_reals.zig");
const ln_complex_owned = @import("../ln_complex.zig");
const real_predicates_owned = @import("../compare/real_predicates.zig");
const runtime = @import("../command_wrappers/runtime.zig");
const math_command_wrappers = @import("../command_wrappers.zig");
const math_wp34s = @import("wp34s.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

fn realCompareGreaterThan(lhs: *const real_t, rhs: *const real_t) bool {
    return runtime.realCompareLessThan(rhs, lhs);
}

fn realCompareLessEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn setExpLimitResult(x: *const real_t, result: *real_t, zeroOrNegativeOne: *const real_t) void {
    if (runtime.realIsNegative(x)) {
        copyReal(result, zeroOrNegativeOne);
    } else {
        copyReal(result, runtime.z47_math_wrappers_const_plus_infinity());
    }
}

pub fn realExpLimitCheck(
    x: *const real_t,
    result: *real_t,
    zeroOrNegativeOne: *const real_t,
) bool {
    if (runtime.realIsSpecial(x)) {
        if (runtime.realIsInfinite(x)) {
            setExpLimitResult(x, result, zeroOrNegativeOne);
        } else {
            runtime.realSetNaN(result);
        }
        return false;
    }

    if (runtime.realCompareAbsGreaterThan(x, runtime.z47_math_wrappers_const_2e6())) {
        setExpLimitResult(x, result, zeroOrNegativeOne);
        return false;
    }

    return true;
}

pub fn realExp(
    x: *const real_t,
    result: *real_t,
    real_context: *realContext_t,
) void {
    if (realExpLimitCheck(x, result, runtime.z47_math_wrappers_const_0())) {
        _ = runtime.decNumberExp(result, x, real_context);
    }
}

pub fn expComplex(
    z: *const cplx_t,
    res: *cplx_t,
    real_context: *realContext_t,
) void {
    if (runtime.realIsZero(&z.Imag)) {
        realExp(&z.Real, &res.Real, real_context);
        runtime.realSetZero(&res.Imag);
        return;
    }

    if (runtime.realIsNaN(&z.Real) or runtime.realIsSpecial(&z.Imag)) {
        runtime.realSetNaN(&res.Real);
        runtime.realSetNaN(&res.Imag);
        return;
    }

    // Three wide working reals, in a deep call chain under the solver, go on
    // the heap and not the DM42 frame.
    const expa_p = runtime.mallocReal();
    const sin_p = runtime.mallocReal();
    const cos_p = runtime.mallocReal();
    defer {
        runtime.freeReal(expa_p);
        runtime.freeReal(sin_p);
        runtime.freeReal(cos_p);
    }
    if (expa_p == null or sin_p == null or cos_p == null) {
        runtime.realSetNaN(&res.Real);
        runtime.realSetNaN(&res.Imag);
        return;
    }
    const expa = expa_p.?;
    const sin_value = sin_p.?;
    const cos_value = cos_p.?;

    realExp(&z.Real, expa, real_context);
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&z.Imag, runtime.amRadian, sin_value, cos_value, null, real_context);
    runtime.realMultiply(expa, cos_value, &res.Real, real_context);
    runtime.realMultiply(expa, sin_value, &res.Imag, real_context);
}

pub fn realExpM1(
    x: *const real_t,
    res: *real_t,
    real_context: *realContext_t,
) void {
    runtime.WP34S_ExpM1(x, res, real_context);
}

pub fn lnRealValue(
    x_in: *const real_t,
    res: *real_t,
    real_context: *realContext_t,
) void {
    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_Ln(x_in, res, real_context);
        return;
    }

    var z: real_t = undefined;
    var t: real_t = undefined;
    var f: real_t = undefined;
    var n: real_t = undefined;
    var m: real_t = undefined;
    var i: real_t = undefined;
    var v: real_t = undefined;
    var w: real_t = undefined;
    var e: real_t = undefined;
    var exponent_adjust: i32 = 0;

    if (runtime.realIsSpecial(x_in)) {
        if (runtime.realIsNaN(x_in) or runtime.realIsNegative(x_in)) {
            runtime.realSetNaN(res);
        } else {
            copyReal(res, runtime.z47_math_wrappers_const_plus_infinity());
        }
        return;
    }

    if (realCompareLessEqual(x_in, runtime.z47_math_wrappers_const_0())) {
        if (runtime.realIsNegative(x_in)) {
            runtime.realSetNaN(res);
        } else {
            copyReal(res, runtime.z47_math_wrappers_const_minus_infinity());
        }
        return;
    }

    copyReal(&z, x_in);
    copyReal(&f, runtime.z47_math_wrappers_const_2());
    runtime.realSubtract(x_in, runtime.z47_math_wrappers_const_1(), &t, real_context);
    copyReal(&v, &t);
    runtime.realSetPositiveSign(&v);

    if (realCompareGreaterThan(&v, runtime.z47_math_wrappers_const_1on2())) {
        exponent_adjust = z.exponent + z.digits;
        z.exponent = -z.digits;
    }

    // The blob constant, not a runtime sqrt(1/2): computing it at the caller's
    // precision moves the threshold and lands an inexact status in the caller's
    // context on every ln.
    while (realCompareLessEqual(&z, abi.constants.const39_root2on2())) {
        runtime.realMultiply(&f, runtime.z47_math_wrappers_const_2(), &f, real_context);
        runtime.realSquareRoot(&z, &z, real_context);
    }

    runtime.realAdd(&z, runtime.z47_math_wrappers_const_1(), &t, real_context);
    runtime.realSubtract(&z, runtime.z47_math_wrappers_const_1(), &v, real_context);
    runtime.realDivide(&v, &t, &n, real_context);
    copyReal(&v, &n);
    runtime.realMultiply(&v, &v, &m, real_context);
    runtime.int32ToReal(3, &i);

    runtime.int32ToReal(1 - real_context.digits, &t);
    math_command_wrappers.realPower10(&t, &z, real_context);

    while (true) {
        runtime.realMultiply(&m, &n, &n, real_context);
        runtime.realDivide(&n, &i, &e, real_context);
        runtime.realAdd(&v, &e, &w, real_context);
        if (runtime.WP34S_RelativeError(&w, &v, &z, real_context)) {
            break;
        }
        copyReal(&v, &w);
        runtime.realAdd(&i, runtime.z47_math_wrappers_const_2(), &i, real_context);
    }

    runtime.realMultiply(&f, &w, res, real_context);
    if (exponent_adjust == 0) {
        return;
    }

    runtime.int32ToReal(exponent_adjust, &e);
    runtime.realMultiply(&e, runtime.z47_math_wrappers_const_ln10(), &w, real_context);
    runtime.realAdd(res, &w, res, real_context);
}

pub fn expM1Complex(
    z: *const cplx_t,
    res: *cplx_t,
    real_context: *realContext_t,
) void {
    var z2: cplx_t = undefined;
    var e: cplx_t = undefined;

    if (runtime.realIsZero(&z.Imag)) {
        if (runtime.realIsInfinite(&z.Real) and runtime.realIsNegative(&z.Real)) {
            runtime.realSetNegativeOne(&res.Real);
            runtime.realSetZero(&res.Imag);
            return;
        }
        realExpM1(&z.Real, &res.Real, real_context);
        runtime.realSetZero(&res.Imag);
        return;
    }

    if (runtime.realIsNaN(&z.Real) or runtime.realIsSpecial(&z.Imag)) {
        runtime.realSetNaN(&res.Real);
        runtime.realSetNaN(&res.Imag);
        return;
    }

    // The split identity below has factors that approach zero and infinity for
    // a large negative real part. Direct subtraction is well-conditioned for
    // real <= -0.1 and avoids multiplying those factors.
    if (runtime.realIsInfinite(&z.Real) or (runtime.realIsNegative(&z.Real) and !comparison_reals_owned.realCompareAbsLessThan(&z.Real, abi.constants.const_1on10()))) {
        expComplex(z, res, real_context);
        runtime.realSubtract(&res.Real, runtime.z47_math_wrappers_const_1(), &res.Real, real_context);
        return;
    }

    // Complex (e^z)-1.
    //
    // With a bit of algebra it can be shown that:
    //  e^z - 1 = -exp(z/2) * 2*i*sin(i*z/2)
    // which avoids direct subtraction near the zeros of e^z - 1.
    //
    // The negation and multiplication by i are simplified to negates and swaps.
    runtime.realMultiply(&z.Real, runtime.z47_math_wrappers_const_1on2(), &z2.Real, real_context);
    runtime.realMultiply(&z.Imag, runtime.z47_math_wrappers_const_1on2(), &z2.Imag, real_context);
    expComplex(&z2, &e, real_context);
    runtime.realChangeSign(&e.Real);
    runtime.realChangeSign(&e.Imag);
    runtime.mulComplexi(&e, &e);
    runtime.addComplex(&e, &e, &e, real_context);
    // sin(i * z/2)
    runtime.mulComplexi(&z2, &z2);
    runtime.sinComplex(&z2, &z2, real_context);
    runtime.mulComplexComplex(&z2, &e, res, real_context);
}

pub fn lnReal() callconv(.c) void {
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            copyReal(&x, runtime.z47_math_wrappers_const_minus_infinity());
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function lnReal:", "cannot calculate Ln(0)", null, null);
            }
            return;
        }
    } else if (runtime.realIsInfinite(&x)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function lnReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of ln when flag SPCRES is not set", null, null);
            }
            return;
        } else if (real_predicates_owned.realIsPositive(&x)) {
            copyReal(&x, runtime.z47_math_wrappers_const_plus_infinity());
        } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            runtime.convertComplexPartsToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), runtime.z47_math_wrappers_const_pi(), runtime.REGISTER_X);
            return;
        } else {
            runtime.realSetNaN(&x);
        }
    } else {
        if (real_predicates_owned.realIsPositive(&x)) {
            lnRealValue(&x, &x, &runtime.ctxtReal39);
        } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            runtime.realSetPositiveSign(&x);
            lnRealValue(&x, &x, &runtime.ctxtReal39);
            runtime.convertComplexPartsToResultRegister(&x, runtime.z47_math_wrappers_const_pi(), runtime.REGISTER_X);
            return;
        } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function lnReal:", "cannot calculate Ln of a negative number when CPXRES is not set!", null, null);
            }
            return;
        }
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn lnCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var result: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x.Real) and runtime.realIsZero(&x.Imag) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function lnCplx:", "cannot calculate Ln(0)", null, null);
        }
        return;
    }

    ln_complex_owned.lnComplexDirect(&x, &result);
    runtime.convertComplexToResultRegister(&result, runtime.REGISTER_X);
}

// For |z| small, the series expansion:
//
//  log(1+z) = z - z^2/2 + z^3/3 - z^4/4 + ...
//
// Thresholding |z| against 1e-6 means each term after the first produces
// approximately six more digits. For |z| larger, the complex Ln function
// applies directly without loss.
pub fn lnP1Complex(
    z: *const cplx_t,
    ln: *cplx_t,
    real_context: *realContext_t,
) void {
    var r: real_t = undefined;
    var t: real_t = undefined;
    var sum: cplx_t = undefined;
    var term: cplx_t = undefined;

    // |z| through complexMagnitude: three operations and no angle. A
    // rectangular-to-polar conversion would additionally run an arctangent
    // that is thrown away, leaving its status in the caller's context.
    runtime.complexMagnitude(z, &t, real_context);
    if (comparison_reals_owned.realCompareAbsLessThan(&t, abi.constants.const_1e_6())) {
        var series_context: realContext_t = real_context.*;
        if (series_context.digits > 51) {
            series_context.digits = 51;
        }
        copyReal(&term.Real, &z.Real); // Sequential terms
        copyReal(&term.Imag, &z.Imag);
        copyReal(&sum.Real, &z.Real); // Running summation
        copyReal(&sum.Imag, &z.Imag);

        // The number of iterations for the number of required digits: a worst
        // case of five digits per iteration, and always an odd number of
        // iterations.
        const n: i32 = @divTrunc(series_context.digits, 5) | 1;
        var i: i32 = 1;
        while (i <= n) : (i += 1) {
            runtime.mulComplexComplex(&term, z, &term, &series_context);
            runtime.realChangeSign(&term.Real);
            runtime.realChangeSign(&term.Imag);
            runtime.int32ToReal(i + 1, &r);
            runtime.realDivide(&term.Real, &r, &t, &series_context);
            runtime.realAdd(&sum.Real, &t, &sum.Real, &series_context);
            runtime.realDivide(&term.Imag, &r, &t, &series_context);
            runtime.realAdd(&sum.Imag, &t, &sum.Imag, &series_context);
        }
        copyReal(&ln.Real, &sum.Real);
        copyReal(&ln.Imag, &sum.Imag);
    } else {
        // No numeric problems, so just do this directly
        runtime.realAdd(&z.Real, runtime.z47_math_wrappers_const_1(), &term.Real, real_context); // term = 1 + z
        copyReal(&term.Imag, &z.Imag);
        if (runtime.realIsZero(&term.Real) and runtime.realIsZero(&term.Imag)) {
            copyReal(&ln.Real, runtime.z47_math_wrappers_const_minus_infinity());
            runtime.realSetZero(&ln.Imag);
        } else {
            copyReal(&sum.Imag, &z.Imag);
            runtime.realRectangularToPolar(&term, ln.mag(), ln.arg(), real_context);
            if (runtime.realCompareGreaterThan(ln.mag(), runtime.z47_math_wrappers_const_1on2()) and runtime.realCompareLessThan(ln.mag(), runtime.z47_math_wrappers_const_2())) {
                runtime.realSubtract(&term.Real, runtime.z47_math_wrappers_const_1(), &t, real_context);
                runtime.realAdd(&term.Real, runtime.z47_math_wrappers_const_1(), &sum.Real, real_context);
                runtime.realMultiply(&t, &sum.Real, &sum.Real, real_context);
                runtime.realFMA(&sum.Imag, &sum.Imag, &sum.Real, &sum.Real, real_context);
                runtime.WP34S_Ln1P(&sum.Real, &ln.Real, real_context);
                runtime.realMultiply(&ln.Real, runtime.z47_math_wrappers_const_1on2(), &ln.Real, real_context);
            } else {
                lnRealValue(ln.mag(), &ln.Real, real_context);
            }
        }
    }
    runtime.realAdd(&z.Real, runtime.z47_math_wrappers_const_1(), &r, real_context);
}

pub fn expM1Real() callconv(.c) void {
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_exp_m1_real_domain_error();
        return;
    }

    realExpM1(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn expM1Cplx() callconv(.c) void {
    var z: cplx_t = undefined;
    var real_context: *realContext_t = &runtime.ctxtReal75;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        return;
    }

    if (runtime.realIsInfinite(&z.Real) or (runtime.realIsNegative(&z.Real) and !comparison_reals_owned.realCompareAbsLessThan(&z.Real, abi.constants.const_1on10()))) {
        real_context = &runtime.ctxtReal39;
    }
    expM1Complex(&z, &z, real_context);
    runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
}

pub fn lnP1Real() callconv(.c) void {
    var arg: real_t = undefined;
    var r: real_t = undefined;
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &arg)) {
        return;
    }

    runtime.realAdd(&arg, runtime.z47_math_wrappers_const_1(), &r, &runtime.ctxtReal39);
    if (runtime.realIsZero(&r)) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            copyReal(&x, runtime.z47_math_wrappers_const_minus_infinity());
        } else {
            runtime.z47_math_wrappers_report_ln_p1_real_zero_domain_error();
            return;
        }
    } else if (runtime.realIsInfinite(&r)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.z47_math_wrappers_report_ln_p1_real_infinite_domain_error();
            return;
        } else if (real_predicates_owned.realIsPositive(&r)) {
            copyReal(&x, runtime.z47_math_wrappers_const_plus_infinity());
        } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            runtime.convertComplexPartsToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), runtime.z47_math_wrappers_const_pi(), runtime.REGISTER_X);
            return;
        } else {
            runtime.realSetNaN(&x);
        }
    } else {
        if (real_predicates_owned.realIsPositive(&r)) {
            runtime.WP34S_Ln1P(&arg, &x, &runtime.ctxtReal39);
        } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            var z: cplx_t = undefined;

            copyReal(&z.Real, &arg);
            runtime.realSetZero(&z.Imag);
            lnP1Complex(&z, &z, &runtime.ctxtReal75);
            runtime.convertComplexPartsToResultRegister(&z.Real, runtime.z47_math_wrappers_const_pi(), runtime.REGISTER_X);
            return;
        } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.realSetNaN(&x);
        } else {
            runtime.z47_math_wrappers_report_ln_p1_real_negative_domain_error();
            return;
        }
    }

    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn lnP1Cplx() callconv(.c) void {
    var x: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x.Imag) and runtime.realCompareEqual(&x.Real, runtime.z47_math_wrappers_const_minus_1())) {
        if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            copyReal(&x.Real, runtime.z47_math_wrappers_const_minus_infinity());
            runtime.realSetZero(&x.Imag);
        } else {
            runtime.z47_math_wrappers_report_ln_p1_cplx_zero_domain_error();
            return;
        }
    } else {
        lnP1Complex(&x, &x, &runtime.ctxtReal75);
    }

    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

pub fn expReal() callconv(.c) void {
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_exp_real_domain_error();
        return;
    }

    realExp(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

pub fn expCplx() callconv(.c) void {
    var z: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        return;
    }

    expComplex(&z, &z, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
}

pub fn exp(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&expReal, &expCplx);
}

pub fn expM1(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&expM1Real, &expM1Cplx);
}

pub fn ln(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&lnReal, &lnCplx);
}

pub fn lnP1(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexMonadicFunction(&lnP1Real, &lnP1Cplx);
}
