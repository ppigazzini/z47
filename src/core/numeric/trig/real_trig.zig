const abi = @import("abi");
const atan2_owned = @import("atan2.zig");
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

    // angle = atan2(x, sqrt((1-|x|)(1+|x|))): both factors are exact, where 1-x*x cancels near |x| = 1
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &abs_x, &z, real_context);
    runtime.realAdd(runtime.z47_math_wrappers_const_1(), &abs_x, &abs_x, real_context);
    runtime.realMultiply(&z, &abs_x, &z, real_context);
    runtime.realSquareRoot(&z, &z, real_context);
    atan2_owned.arctan2Real(x, &z, angle, real_context);
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

    // angle = atan2(sqrt((1-|x|)(1+|x|)), x): both factors are exact, where 1-x*x cancels near |x| = 1
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &abs_x, &z, real_context);
    runtime.realAdd(runtime.z47_math_wrappers_const_1(), &abs_x, &abs_x, real_context);
    runtime.realMultiply(&z, &abs_x, &z, real_context);
    runtime.realSquareRoot(&z, &z, real_context);
    atan2_owned.arctan2Real(&z, x, angle, real_context);
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
    const negative = runtime.realIsNegative(x);

    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_Tanh(x, res, real_context);
        return;
    }

    if (runtime.realIsNaN(x)) {
        runtime.realSetNaN(res);
        return;
    }

    // tanh x = (1 - exp(-2|x|)) / (1 + exp(-2|x|)) with the sign of x: the
    // exponential never overflows, and a large |x| gives exactly 1.
    copyAbs(&a, x);
    runtime.realAdd(&a, &a, &a, real_context);
    a.bits |= 0x80; // a = -2|x|
    runtime.WP34S_ExpM1(&a, &b, real_context); // b = exp(-2|x|) - 1
    runtime.realChangeSign(&b); // b = 1 - exp(-2|x|)
    runtime.realSubtract(runtime.z47_math_wrappers_const_2(), &b, &a, real_context); // a = 1 + exp(-2|x|)
    runtime.realDivide(&b, &a, res, real_context);
    if (negative) {
        res.bits |= 0x80;
    }
}

pub fn arcsinhReal(
    xin: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a: runtime.real_t = undefined;
    var s: runtime.real_t = undefined;
    const negative = runtime.realIsNegative(xin);

    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_ArcSinh(xin, res, real_context);
        return;
    }

    if (runtime.realIsSpecial(xin)) {
        copyReal(res, xin);
        return;
    }
    if (runtime.realIsZero(xin)) {
        if (negative) {
            runtime.realDivide(runtime.z47_math_wrappers_const_minus_1(), runtime.z47_math_wrappers_const_plus_infinity(), res, real_context);
        } else {
            runtime.realSetZero(res);
        }
        return;
    }

    copyAbs(&a, xin); // arsinh is odd: the formula below cancels for x < 0, so it runs on |x|
    if (realGetExponent(&a) < -18) { // arsinh x = x - x^3/6 to 72 digits, below |x| by less than half a unit at 34 digits
        runtime.WP34S_TinyOddSeries(&a, abi.constants.const_6(), false, res, real_context);
        if (negative) {
            res.bits |= 0x80;
        }
        return;
    }
    runtime.realFMA(&a, &a, runtime.z47_math_wrappers_const_1(), &s, real_context);
    runtime.realSquareRoot(&s, &s, real_context);
    runtime.realAdd(&s, runtime.z47_math_wrappers_const_1(), &s, real_context);
    runtime.realDivide(&a, &s, &s, real_context);
    runtime.realAdd(&s, runtime.z47_math_wrappers_const_1(), &s, real_context);
    runtime.realMultiply(&a, &s, &s, real_context);
    runtime.WP34S_Ln1P(&s, res, real_context);
    if (negative) {
        res.bits |= 0x80;
    }
}

pub fn arctanhReal(
    xin: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var y: runtime.real_t = undefined;
    var z: runtime.real_t = undefined;
    const negative = runtime.realIsNegative(xin);

    if (build_options.use_fake_wp34s_model) {
        runtime.WP34S_ArcTanh(xin, res, real_context);
        return;
    }

    if (runtime.realIsNaN(xin)) {
        runtime.realSetNaN(res);
        return;
    }
    if (runtime.realIsZero(xin)) {
        if (negative) {
            runtime.realDivide(runtime.z47_math_wrappers_const_minus_1(), runtime.z47_math_wrappers_const_plus_infinity(), res, real_context);
        } else {
            runtime.realSetZero(res);
        }
        return;
    }

    // artanh x = (ln1p(x) - ln1p(-x)) / 2
    runtime.WP34S_Ln1P(xin, &y, real_context);
    runtime.realMinus(xin, &z, real_context);
    runtime.WP34S_Ln1P(&z, &z, real_context);
    runtime.realSubtract(&y, &z, &y, real_context);
    runtime.realMultiply(&y, runtime.z47_math_wrappers_const_1on2(), res, real_context);
}
