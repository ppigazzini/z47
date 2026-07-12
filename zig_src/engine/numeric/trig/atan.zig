const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("../command_wrappers_runtime.zig");

const taylor_iteration_max: usize = 1000;

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn isLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return runtime.realCompareLessThan(lhs, rhs) or runtime.realCompareEqual(lhs, rhs);
}

fn isGreaterThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !isLessEqual(lhs, rhs);
}

pub fn arctanReal(
    x: *const runtime.real_t,
    angle: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var a2: runtime.real_t = undefined;
    var t: runtime.real_t = undefined;
    var j: runtime.real_t = undefined;
    var z: runtime.real_t = undefined;
    var last: runtime.real_t = undefined;
    var ten: runtime.real_t = undefined;
    var one_tenth: runtime.real_t = undefined;
    var doubles: usize = 0;
    var invert = false;
    const neg = runtime.realIsNegative(x);

    if (build_options.use_fake_wp34s_model or real_context.digits != runtime.ctxtReal39.digits) {
        runtime.C47_WP34S_Atan(x, angle, real_context);
        return;
    }

    if (runtime.realIsNaN(x)) {
        runtime.realSetNaN(angle);
        return;
    }

    copyReal(&a, x);
    if (neg) {
        runtime.realChangeSign(&a);
    }

    if (isGreaterThan(&a, runtime.z47_math_wrappers_const_1())) {
        invert = true;
        runtime.realDivide(runtime.z47_math_wrappers_const_1(), &a, &a, real_context);
    }

    runtime.uInt32ToReal(10, &ten);
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &ten, &one_tenth, real_context);

    var reduce_iteration: usize = 0;
    while (reduce_iteration < taylor_iteration_max and !isLessEqual(&a, &one_tenth)) : (reduce_iteration += 1) {
        doubles += 1;
        runtime.realMultiply(&a, &a, &b, real_context);
        runtime.realAdd(&b, runtime.z47_math_wrappers_const_1(), &b, real_context);
        runtime.realSquareRoot(&b, &b, real_context);
        runtime.realAdd(&b, runtime.z47_math_wrappers_const_1(), &b, real_context);
        runtime.realDivide(&a, &b, &a, real_context);
    }

    runtime.uInt32ToReal(3, angle);
    runtime.uInt32ToReal(5, &j);
    runtime.realMultiply(&a, &a, &a2, real_context);
    copyReal(&t, &a2);
    runtime.realDivide(&t, angle, angle, real_context);
    runtime.realSubtract(runtime.z47_math_wrappers_const_1(), angle, angle, real_context);

    var series_iteration: usize = 0;
    while (series_iteration < taylor_iteration_max) : (series_iteration += 1) {
        copyReal(&last, angle);

        runtime.realMultiply(&t, &a2, &t, real_context);
        runtime.realDivide(&t, &j, &z, real_context);
        runtime.realAdd(angle, &z, angle, real_context);

        runtime.realAdd(&j, runtime.z47_math_wrappers_const_2(), &j, real_context);

        runtime.realMultiply(&t, &a2, &t, real_context);
        runtime.realDivide(&t, &j, &z, real_context);
        runtime.realSubtract(angle, &z, angle, real_context);

        runtime.realAdd(&j, runtime.z47_math_wrappers_const_2(), &j, real_context);
        runtime.realSubtract(angle, &last, &b, real_context);
        if (runtime.realIsZero(&b)) {
            break;
        }
    }

    runtime.realMultiply(angle, &a, angle, real_context);

    while (doubles > 0) : (doubles -= 1) {
        runtime.realAdd(angle, angle, angle, real_context);
    }

    if (invert) {
        runtime.realSubtract(runtime.z47_math_wrappers_const_piOn2(), angle, angle, real_context);
    }

    if (neg) {
        runtime.realChangeSign(angle);
    }
}
