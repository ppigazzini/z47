const abi = @import("abi");
const atan_owned = @import("atan.zig");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("../command_wrappers/runtime.zig");

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn copyAbs(destination: *runtime.real_t, source: *const runtime.real_t) void {
    copyReal(destination, source);
    runtime.realSetPositiveSign(destination);
}

fn realGetExponent(source: *const runtime.real_t) i32 {
    return source.digits + source.exponent - 1;
}

fn isAbsLessThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareAbsGreaterThan(lhs, rhs) and !runtime.realCompareAbsEqual(lhs, rhs);
}

fn realExp(rhs: *const runtime.real_t, result: *runtime.real_t, real_context: *runtime.realContext_t) void {
    _ = runtime.decNumberExp(result, rhs, real_context);
}

pub fn arcsinReal(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var abs_x: runtime.real_t = undefined;
    var z: runtime.real_t = undefined;

    if (build_options.use_fake_wp34s_model) {
        runtime.C47_WP34S_Asin(x, angle, real_context);
        return;
    }

    if (runtime.realIsNaN(x)) {
        runtime.realSetNaN(angle);
        return;
    }

    copyAbs(&abs_x, x);
    if (runtime.realCompareAbsGreaterThan(x, runtime.z47_math_wrappers_const_1())) {
        runtime.realSetNaN(angle);
        return;
    }

    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &abs_x, &z, real_context); // 1-x*x as (1-|x|)(1+|x|): both factors are exact, where 1-x*x cancels near |x| = 1
    runtime.realAdd(runtime.z47_math_wrappers_const_1(), &abs_x, &abs_x, real_context);
    runtime.realMultiply(&z, &abs_x, &z, real_context);
    runtime.realSquareRoot(&z, &z, real_context);
    runtime.realAdd(&z, runtime.z47_math_wrappers_const_1(), &z, real_context);
    runtime.realDivide(x, &z, &z, real_context);
    atan_owned.arctanReal(&z, &abs_x, real_context);
    runtime.realAdd(&abs_x, &abs_x, angle, real_context);
}

pub fn arccosReal(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var abs_x: runtime.real_t = undefined;
    var z: runtime.real_t = undefined;

    if (build_options.use_fake_wp34s_model) {
        runtime.C47_WP34S_Acos(x, angle, real_context);
        return;
    }

    if (runtime.realIsNaN(x)) {
        runtime.realSetNaN(angle);
        return;
    }

    copyAbs(&abs_x, x);
    if (runtime.realCompareAbsGreaterThan(x, runtime.z47_math_wrappers_const_1())) {
        runtime.realSetNaN(angle);
        return;
    }

    if (runtime.realCompareEqual(x, runtime.z47_math_wrappers_const_1())) {
        runtime.realSetZero(angle);
        return;
    }

    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &abs_x, &z, real_context); // 1-x*x as (1-|x|)(1+|x|): both factors are exact, where 1-x*x cancels near |x| = 1
    runtime.realAdd(runtime.z47_math_wrappers_const_1(), &abs_x, &abs_x, real_context);
    runtime.realMultiply(&z, &abs_x, &z, real_context);
    runtime.realSquareRoot(&z, &z, real_context);
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), x, &abs_x, real_context);
    runtime.realDivide(&abs_x, &z, &z, real_context);
    atan_owned.arctanReal(&z, &abs_x, real_context);
    runtime.realAdd(&abs_x, &abs_x, angle, real_context);
}

pub fn sinhCoshReal(
    x: *const runtime.real_t,
    sinh_out: ?*runtime.real_t,
    cosh_out: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var t: runtime.real_t = undefined;
    var u: runtime.real_t = undefined;
    var v: runtime.real_t = undefined;

    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_SinhCosh(x, sinh_out, cosh_out, real_context);
        return;
    }

    if (runtime.realIsNaN(x)) {
        if (sinh_out) |output| {
            runtime.realSetNaN(output);
        }
        if (cosh_out) |output| {
            runtime.realSetNaN(output);
        }
        return;
    }

    if (sinh_out) |output| {
        if (isAbsLessThan(x, runtime.z47_math_wrappers_const_1on2())) {
            runtime.WP34S_ExpM1(x, &u, real_context);
            runtime.realMultiply(&u, runtime.z47_math_wrappers_const_1on2(), &t, real_context);

            runtime.realAdd(&u, runtime.z47_math_wrappers_const_1(), &u, real_context);
            runtime.realDivide(&t, &u, &v, real_context);

            runtime.realAdd(&u, runtime.z47_math_wrappers_const_1(), &u, real_context);
            runtime.realMultiply(&u, &v, output, real_context);
        } else {
            realExp(x, &u, real_context);
            runtime.realDivide(runtime.z47_math_wrappers_const_1(), &u, &v, real_context);
            runtime.realSubtract(&u, &v, output, real_context);
            runtime.realMultiply(output, runtime.z47_math_wrappers_const_1on2(), output, real_context);
        }
    }

    if (cosh_out) |output| {
        realExp(x, &u, real_context);
        runtime.realDivide(runtime.z47_math_wrappers_const_1(), &u, &v, real_context);
        runtime.realAdd(&u, &v, output, real_context);
        runtime.realMultiply(output, runtime.z47_math_wrappers_const_1on2(), output, real_context);
    }
}

pub fn tanhReal(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_Tanh(x, res, real_context);
        return;
    }

    if (runtime.realIsNaN(x)) {
        runtime.realSetNaN(res);
        return;
    }

    // Above |x| = 47 the result equals 1 to 39 digits.
    if (runtime.realCompareAbsGreaterThan(x, abi.constants.const_47())) {
        copyReal(res, if (runtime.realIsNegative(x)) runtime.z47_math_wrappers_const_minus_1() else runtime.z47_math_wrappers_const_1());
        return;
    }

    runtime.realAdd(x, x, &a, real_context);
    runtime.WP34S_ExpM1(&a, &b, real_context);
    runtime.realAdd(&b, runtime.z47_math_wrappers_const_2(), &a, real_context);
    runtime.realDivide(&b, &a, res, real_context);
}

pub fn arcsinhReal(
    xin: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a: runtime.real_t = undefined;
    var xabs: runtime.real_t = undefined;
    const x = &xabs;

    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_ArcSinh(xin, res, real_context);
        return;
    }

    const negative = runtime.realIsNegative(xin);
    copyAbs(x, xin); // arsinh is odd: the formula below cancels for x < 0, so it runs on |x|
    if (!runtime.realIsZero(x) and realGetExponent(x) < -18) { // arsinh x = x - x^3/6 to 72 digits, below |x| by less than half a unit at 34 digits
        runtime.realMultiply(x, x, &a, real_context);
        runtime.realMultiply(&a, x, &a, real_context);
        runtime.realDivide(&a, abi.constants.const_6(), &a, real_context);
        runtime.realSubtract(x, &a, res, real_context);
        if (runtime.realCompareEqual(res, x)) { // x^3/6 is below the context's last digit: one step toward 0 keeps the result below |x|
            runtime.realNextToward(x, runtime.z47_math_wrappers_const_0(), res, real_context);
        }
        if (negative) {
            runtime.realChangeSign(res);
        }
        return;
    }
    runtime.realMultiply(x, x, &a, real_context);
    runtime.realAdd(&a, runtime.z47_math_wrappers_const_1(), &a, real_context);
    runtime.realSquareRoot(&a, &a, real_context);
    runtime.realAdd(&a, runtime.z47_math_wrappers_const_1(), &a, real_context);
    runtime.realDivide(x, &a, &a, real_context);
    runtime.realAdd(&a, runtime.z47_math_wrappers_const_1(), &a, real_context);
    runtime.realMultiply(x, &a, &a, real_context);
    runtime.WP34S_Ln1P(&a, res, real_context);
    if (negative) {
        runtime.realChangeSign(res);
    }
}

pub fn arctanhReal(
    xin: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var y: runtime.real_t = undefined;
    var z: runtime.real_t = undefined;
    var xabs: runtime.real_t = undefined;
    const x = &xabs;

    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_ArcTanh(xin, res, real_context);
        return;
    }

    if (runtime.realIsNaN(xin)) {
        runtime.realSetNaN(res);
        return;
    }

    const negative = runtime.realIsNegative(xin);
    copyAbs(x, xin); // artanh is odd: near -1 the formula takes 1 + z of a z near -1, so it runs on |x|, where 1-x is exact
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), x, &z, real_context);
    runtime.realDivide(x, &z, &y, real_context);
    runtime.realMultiply(&y, runtime.z47_math_wrappers_const_2(), &z, real_context);
    runtime.WP34S_Ln1P(&z, &y, real_context);
    runtime.realMultiply(&y, runtime.z47_math_wrappers_const_1on2(), res, real_context);
    if (negative) {
        runtime.realChangeSign(res);
    }
}
