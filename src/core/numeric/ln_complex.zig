const abi = @import("abi");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

fn int32ToRealLocal(source: i32, destination: *real_t) void {
    if (source >= 0) {
        runtime.uInt32ToReal(@intCast(source), destination);
        return;
    }

    runtime.uInt32ToReal(@intCast(-@as(i64, source)), destination);
    if (!runtime.realIsZero(destination)) {
        runtime.realChangeSign(destination);
    }
}

fn setExpLimitResult(x: *const real_t, result: *real_t, zero: *const real_t) void {
    if (runtime.realIsNegative(x)) {
        copyReal(result, zero);
    } else {
        copyReal(result, runtime.z47_math_wrappers_const_plus_infinity());
    }
}

fn realExpLimitCheck(
    x: *const real_t,
    result: *real_t,
    zero: *const real_t,
) bool {
    if (runtime.realIsSpecial(x)) {
        if (runtime.realIsInfinite(x)) {
            setExpLimitResult(x, result, zero);
        } else {
            runtime.realSetNaN(result);
        }
        return false;
    }

    if (runtime.realCompareAbsGreaterThan(x, runtime.z47_math_wrappers_const_2e6())) {
        setExpLimitResult(x, result, zero);
        return false;
    }

    return true;
}

fn realExp(
    x: *const real_t,
    result: *real_t,
    real_context: *realContext_t,
) void {
    if (realExpLimitCheck(x, result, runtime.z47_math_wrappers_const_0())) {
        _ = runtime.decNumberExp(result, x, real_context);
    }
}

fn realPower10(
    x: *const real_t,
    res: *real_t,
    real_context: *realContext_t,
) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln10(), res, real_context);
    realExp(res, res, real_context);
}

fn realCompareLessEqual(lhs: *const real_t, rhs: *const real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn realCompareGreaterThan(lhs: *const real_t, rhs: *const real_t) bool {
    return runtime.realCompareLessThan(rhs, lhs);
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
    int32ToRealLocal(3, &i);

    int32ToRealLocal(1 - real_context.digits, &t);
    realPower10(&t, &z, real_context);

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

    // The decimal exponent's share, at the 75-digit ln(10) when the context is
    // wider than 39 digits, as WP34S_Ln takes it.
    int32ToRealLocal(exponent_adjust, &e);
    const ln10: *const real_t = if (real_context.digits > 39) runtime.z47_math_wrappers_const75_ln10() else runtime.z47_math_wrappers_const_ln10();
    runtime.realMultiply(&e, ln10, &w, real_context);
    runtime.realAdd(res, &w, res, real_context);
}

/// ln z in the caller's context: the polar magnitude and angle land in ln, and
/// the magnitude is replaced by its logarithm in place.
pub fn lnComplex(
    z: *const cplx_t,
    ln: *cplx_t,
    real_context: *realContext_t,
) void {
    if (runtime.realIsZero(&z.Real) and runtime.realIsZero(&z.Imag)) {
        copyReal(&ln.Real, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(&ln.Imag);
        return;
    }

    runtime.realRectangularToPolar(z, ln.mag(), ln.arg(), real_context);
    lnRealValue(ln.mag(), &ln.Real, real_context);
}

/// ln z for a result register: 39 digits, except that a modulus between 1/2
/// and 2 takes ln(1 + (|z|^2 - 1)) / 2 at 75 digits, where the direct logarithm
/// of a modulus near one loses the digits the subtraction cancels.
pub fn lnComplexDirect(z: *const cplx_t, ln: *cplx_t) void {
    var w: cplx_t = undefined;

    copyReal(&w.Real, &z.Real);
    copyReal(&w.Imag, &z.Imag);
    runtime.realRectangularToPolar(&w, ln.mag(), ln.arg(), &runtime.ctxtReal39);
    if (runtime.realCompareGreaterThan(ln.mag(), runtime.z47_math_wrappers_const_1on2()) and runtime.realCompareLessThan(ln.mag(), runtime.z47_math_wrappers_const_2())) {
        var near_unit_context: realContext_t = runtime.ctxtReal75;
        if (runtime.realCompareAbsLessThan(&w.Real, &w.Imag)) {
            runtime.realSubtract(&w.Imag, runtime.z47_math_wrappers_const_1(), &ln.Real, &near_unit_context);
            runtime.realAdd(&w.Imag, runtime.z47_math_wrappers_const_1(), &w.Imag, &near_unit_context);
            runtime.realMultiply(&ln.Real, &w.Imag, &ln.Real, &near_unit_context);
            runtime.realFMA(&w.Real, &w.Real, &ln.Real, &ln.Real, &near_unit_context);
        } else {
            runtime.realSubtract(&w.Real, runtime.z47_math_wrappers_const_1(), &ln.Real, &near_unit_context);
            runtime.realAdd(&w.Real, runtime.z47_math_wrappers_const_1(), &w.Real, &near_unit_context);
            runtime.realMultiply(&ln.Real, &w.Real, &ln.Real, &near_unit_context);
            runtime.realFMA(&w.Imag, &w.Imag, &ln.Real, &ln.Real, &near_unit_context);
        }
        runtime.WP34S_Ln1P(&ln.Real, &ln.Real, &near_unit_context);
        runtime.realMultiply(&ln.Real, runtime.z47_math_wrappers_const_1on2(), &ln.Real, &near_unit_context);
    } else {
        lnRealValue(ln.mag(), &ln.Real, &runtime.ctxtReal39);
    }
}
