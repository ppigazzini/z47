const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const rectangular_to_polar_owned = @import("math_rectangular_to_polar_owned.zig");
const runtime = @import("math_command_wrappers_runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn int32ToRealLocal(source: i32, destination: *runtime.real_t) void {
    if (source >= 0) {
        runtime.uInt32ToReal(@intCast(source), destination);
        return;
    }

    runtime.uInt32ToReal(@intCast(-@as(i64, source)), destination);
    if (!runtime.realIsZero(destination)) {
        runtime.realChangeSign(destination);
    }
}

fn setExpLimitResult(x: *const runtime.real_t, result: *runtime.real_t, zero: *const runtime.real_t) void {
    if (runtime.realIsNegative(x)) {
        copyReal(result, zero);
    } else {
        copyReal(result, runtime.z47_math_wrappers_const_plus_infinity());
    }
}

fn realExpLimitCheck(
    x: *const runtime.real_t,
    result: *runtime.real_t,
    zero: *const runtime.real_t,
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
    x: *const runtime.real_t,
    result: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (realExpLimitCheck(x, result, runtime.z47_math_wrappers_const_0())) {
        _ = runtime.decNumberExp(result, x, real_context);
    }
}

fn realPower10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln10(), res, real_context);
    realExp(res, res, real_context);
}

fn realCompareLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(rhs, lhs);
}

fn realCompareGreaterThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return runtime.realCompareLessThan(rhs, lhs);
}

pub fn lnRealValue(
    x_in: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_Ln(x_in, res, real_context);
        return;
    }

    var z: runtime.real_t = undefined;
    var t: runtime.real_t = undefined;
    var f: runtime.real_t = undefined;
    var n: runtime.real_t = undefined;
    var m: runtime.real_t = undefined;
    var i: runtime.real_t = undefined;
    var v: runtime.real_t = undefined;
    var w: runtime.real_t = undefined;
    var e: runtime.real_t = undefined;
    var root2on2: runtime.real_t = undefined;
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

    copyReal(&root2on2, runtime.z47_math_wrappers_const_1on2());
    runtime.realSquareRoot(&root2on2, &root2on2, real_context);

    while (realCompareLessEqual(&z, &root2on2)) {
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

    int32ToRealLocal(exponent_adjust, &e);
    runtime.realMultiply(&e, runtime.z47_math_wrappers_const_ln10(), &w, real_context);
    runtime.realAdd(res, &w, res, real_context);
}

pub fn lnComplex(
    real: *const runtime.real_t,
    imag: *const runtime.real_t,
    ln_real: *runtime.real_t,
    ln_imag: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    if (runtime.realIsZero(real) and runtime.realIsZero(imag)) {
        copyReal(ln_real, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(ln_imag);
        return;
    }

    rectangular_to_polar_owned.rectangularToPolarReal(real, imag, ln_real, ln_imag, real_context);
    lnRealValue(ln_real, ln_real, real_context);
}