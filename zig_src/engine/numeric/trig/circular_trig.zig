const std = @import("std");
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("../math_command_wrappers_runtime.zig");

const taylor_iteration_max: usize = 1000;

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn copyAbs(destination: *runtime.real_t, source: *const runtime.real_t) void {
    copyReal(destination, source);
    runtime.realSetPositiveSign(destination);
}

fn isLessEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return runtime.realCompareLessThan(lhs, rhs) or runtime.realCompareEqual(lhs, rhs);
}

fn isGreaterEqual(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !runtime.realCompareLessThan(lhs, rhs);
}

fn isGreaterThan(lhs: *const runtime.real_t, rhs: *const runtime.real_t) bool {
    return !isLessEqual(lhs, rhs);
}

fn buildQuarter(result: *runtime.real_t, real_context: *runtime.realContext_t) void {
    var four: runtime.real_t = undefined;
    runtime.uInt32ToReal(4, &four);
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &four, result, real_context);
}

fn buildRoot2on2(result: *runtime.real_t) void {
    var two: runtime.real_t = undefined;
    var root_context = runtime.ctxtReal39;

    runtime.uInt32ToReal(2, &two);
    runtime.realSquareRoot(&two, &two, &root_context);
    runtime.realDivide(&two, runtime.z47_math_wrappers_const_2(), result, &root_context);
}

fn roundToCallerPrecision(value: *runtime.real_t, real_context: *runtime.realContext_t) void {
    _ = runtime.decNumberPlus(value, value, real_context);
}

fn setNegativeSign(value: *runtime.real_t) void {
    value.bits |= 0x80;
}

fn reduceAngleToRange(
    angle: *runtime.real_t,
    angle45: *runtime.real_t,
    angle90: *runtime.real_t,
    angle180: *runtime.real_t,
    angular_mode: *runtime.angularMode_t,
    real_context: *runtime.realContext_t,
) void {
    switch (angular_mode.*) {
        runtime.amRadian => {
            copyReal(angle45, runtime.z47_math_wrappers_const75_piOn4());
            copyReal(angle90, runtime.z47_math_wrappers_const75_piOn2());
            copyReal(angle180, runtime.z47_math_wrappers_const75_pi());
            runtime.mod2Pi(angle, angle, real_context);
        },
        runtime.amMultPi => {
            buildQuarter(angle45, real_context);
            copyReal(angle90, runtime.z47_math_wrappers_const_1on2());
            copyReal(angle180, runtime.z47_math_wrappers_const_1());
            runtime.WP34S_Mod(angle, runtime.z47_math_wrappers_const_2(), angle, real_context);
        },
        runtime.amGrad => {
            var four_hundred: runtime.real_t = undefined;

            runtime.uInt32ToReal(50, angle45);
            copyReal(angle90, runtime.z47_math_wrappers_const_100());
            runtime.realAdd(angle90, angle90, angle180, real_context);
            runtime.realAdd(angle180, angle180, &four_hundred, real_context);
            runtime.WP34S_Mod(angle, &four_hundred, angle, real_context);
        },
        runtime.amDegree, runtime.amDMS => {
            var three_sixty: runtime.real_t = undefined;

            runtime.uInt32ToReal(45, angle45);
            copyReal(angle90, runtime.z47_math_wrappers_const_90());
            copyReal(angle180, runtime.z47_math_wrappers_const_180());
            runtime.realAdd(angle180, angle180, &three_sixty, real_context);
            runtime.WP34S_Mod(angle, &three_sixty, angle, real_context);
            angular_mode.* = runtime.amDegree;
        },
        else => {},
    }
}

fn doTaylorIterations(
    a: *const runtime.real_t,
    angle: *runtime.real_t,
    a2: *runtime.real_t,
    t: *runtime.real_t,
    j: *runtime.real_t,
    z: *runtime.real_t,
    sin_value: *runtime.real_t,
    cos_value: *runtime.real_t,
    sin_out: ?*runtime.real_t,
    cos_out: ?*runtime.real_t,
    epsilon_or_compare: *runtime.real_t,
    do_epsilon: bool,
    epsilon_digits: i32,
    real_context: *runtime.realContext_t,
) void {
    var epsilon_buffer: [16]u8 = undefined;
    var end_sin = sin_out == null;
    var end_cos = cos_out == null;

    if (do_epsilon) {
        const epsilon_text = runtime.bufPrintZ(&epsilon_buffer, "1E-{d}", .{epsilon_digits}) catch unreachable;
        _ = runtime.decNumberFromString(epsilon_or_compare, epsilon_text, real_context);
    }

    copyReal(angle, a);
    runtime.realMultiply(angle, angle, a2, real_context);
    runtime.realSetOne(j);
    runtime.realSetOne(t);
    runtime.realSetOne(sin_value);
    runtime.realSetOne(cos_value);

    var iteration: usize = 1;
    while (!(end_sin and end_cos) and iteration < taylor_iteration_max) : (iteration += 1) {
        runtime.realAdd(j, runtime.z47_math_wrappers_const_1(), j, real_context);
        runtime.realDivide(a2, j, z, real_context);
        runtime.realMultiply(t, z, t, real_context);
        runtime.realChangeSign(t);

        if (!end_cos) {
            copyReal(z, cos_value);
            runtime.realAdd(cos_value, t, cos_value, real_context);
            if (do_epsilon) {
                copyAbs(z, t);
            } else {
                _ = runtime.decNumberCompare(epsilon_or_compare, cos_value, z, real_context);
            }
            end_cos = (!do_epsilon and runtime.realIsZero(epsilon_or_compare)) or (do_epsilon and runtime.realCompareLessThan(z, epsilon_or_compare));
        }

        runtime.realAdd(j, runtime.z47_math_wrappers_const_1(), j, real_context);
        runtime.realDivide(t, j, t, real_context);

        if (!end_sin) {
            copyReal(z, sin_value);
            runtime.realAdd(sin_value, t, sin_value, real_context);
            if (do_epsilon) {
                copyAbs(z, t);
            } else {
                _ = runtime.decNumberCompare(epsilon_or_compare, sin_value, z, real_context);
            }
            end_sin = (!do_epsilon and runtime.realIsZero(epsilon_or_compare)) or (do_epsilon and runtime.realCompareLessThan(z, epsilon_or_compare));
        }
    }

    if (runtime.realIsZero(cos_value)) {
        runtime.realSetPositiveSign(cos_value);
    }
    if (runtime.realIsZero(sin_value)) {
        runtime.realSetPositiveSign(sin_value);
    }
    runtime.realMultiply(sin_value, angle, sin_value, real_context);
}

fn sinCosTanTaylorTemp75(
    angle: *const runtime.real_t,
    swap: bool,
    sin_out: ?*runtime.real_t,
    cos_out: ?*runtime.real_t,
    tan_out: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var do_epsilon = false;
    var epsilon_digits: i32 = 39;
    var work_angle: runtime.real_t = undefined;
    var a2: runtime.real_t = undefined;
    var t: runtime.real_t = undefined;
    var j: runtime.real_t = undefined;
    var z: runtime.real_t = undefined;
    var sin_value: runtime.real_t = undefined;
    var cos_value: runtime.real_t = undefined;
    var epsilon_or_compare: runtime.real_t = undefined;
    const saved_context_digits = real_context.digits;

    if (real_context.digits > 51) {
        real_context.digits = 75;
        epsilon_digits = 72;
        do_epsilon = true;
    } else {
        real_context.digits = 51;
    }

    doTaylorIterations(
        angle,
        &work_angle,
        &a2,
        &t,
        &j,
        &z,
        &sin_value,
        &cos_value,
        sin_out,
        cos_out,
        &epsilon_or_compare,
        do_epsilon,
        epsilon_digits,
        real_context,
    );

    real_context.digits = saved_context_digits;

    if (sin_out) |output| {
        _ = runtime.decNumberPlus(output, &sin_value, real_context);
    }
    if (cos_out) |output| {
        _ = runtime.decNumberPlus(output, &cos_value, real_context);
    }
    if (tan_out) |output| {
        if (sin_out == null or cos_out == null) {
            runtime.realSetNaN(output);
        } else if (swap) {
            runtime.realDivide(&cos_value, &sin_value, output, real_context);
        } else {
            runtime.realDivide(&sin_value, &cos_value, output, real_context);
        }
    }
}

pub fn convertAngleToSinCosTan(
    angle_in: *const runtime.real_t,
    angular_mode_in: runtime.angularMode_t,
    sin_out: ?*runtime.real_t,
    cos_out: ?*runtime.real_t,
    tan_out: ?*runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    var angle: runtime.real_t = undefined;
    var angle45: runtime.real_t = undefined;
    var angle90: runtime.real_t = undefined;
    var angle180: runtime.real_t = undefined;
    var root2on2: runtime.real_t = undefined;
    var sin_neg = false;
    var cos_neg = false;
    var swap = false;
    var angular_mode = angular_mode_in;
    const saved_context_digits = real_context.digits;

    if (build_options.use_fake_wp34s_model or real_context.digits > runtime.ctxtReal75.digits) {
        runtime.C47_WP34S_Cvt2RadSinCosTan(angle_in, angular_mode_in, sin_out, cos_out, tan_out, real_context);
        return;
    }

    if (runtime.realIsNaN(angle_in)) {
        if (sin_out) |output| runtime.realSetNaN(output);
        if (cos_out) |output| runtime.realSetNaN(output);
        if (tan_out) |output| runtime.realSetNaN(output);
        return;
    }

    copyReal(&angle, angle_in);
    real_context.digits = if (saved_context_digits > 51) 75 else 51;

    if (runtime.realIsNegative(&angle)) {
        sin_neg = true;
        runtime.realSetPositiveSign(&angle);
    }

    reduceAngleToRange(&angle, &angle45, &angle90, &angle180, &angular_mode, real_context);

    if (isGreaterEqual(&angle, &angle180)) {
        runtime.realSubtract(&angle, &angle180, &angle, real_context);
        sin_neg = !sin_neg;
        cos_neg = !cos_neg;
    }

    if (isGreaterEqual(&angle, &angle90)) {
        runtime.realSubtract(&angle, &angle90, &angle, real_context);
        swap = true;
        cos_neg = !cos_neg;
    }

    if (runtime.realCompareEqual(&angle, &angle45)) {
        buildRoot2on2(&root2on2);
        if (sin_out) |output| copyReal(output, &root2on2);
        if (cos_out) |output| copyReal(output, &root2on2);
        if (tan_out) |output| {
            runtime.realSetOne(output);
        }
    } else {
        if (isGreaterThan(&angle, &angle45)) {
            runtime.realSubtract(&angle90, &angle, &angle, real_context);
            swap = !swap;
        }

        runtime.convertAngleFromTo(&angle, angular_mode, runtime.amRadian, real_context);
        sinCosTanTaylorTemp75(
            &angle,
            swap,
            if (swap) cos_out else sin_out,
            if (swap) sin_out else cos_out,
            tan_out,
            real_context,
        );
    }

    real_context.digits = saved_context_digits;

    if (sin_out) |output| {
        if (sin_neg) {
            setNegativeSign(output);
            if (tan_out) |tan_value| {
                setNegativeSign(tan_value);
            }
        }
        if (runtime.realIsZero(output)) {
            runtime.realSetPositiveSign(output);
            if (tan_out) |tan_value| {
                runtime.realSetPositiveSign(tan_value);
            }
        }
        roundToCallerPrecision(output, real_context);
    }

    if (cos_out) |output| {
        if (cos_neg) {
            setNegativeSign(output);
            if (tan_out) |tan_value| {
                runtime.realChangeSign(tan_value);
            }
        }
        if (runtime.realIsZero(output)) {
            runtime.realSetPositiveSign(output);
        }
        roundToCallerPrecision(output, real_context);
    }

    if (tan_out) |output| {
        if (cos_out) |cos_value_out| {
            if (runtime.realIsZero(cos_value_out)) {
                runtime.realSetPositiveSign(output);
                roundToCallerPrecision(output, real_context);
            }
        }
    }
}
