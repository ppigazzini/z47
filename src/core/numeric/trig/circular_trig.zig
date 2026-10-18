const std = @import("std");
const abi = @import("abi");
const is_dmcp_build = @import("builtin").target.os.tag == .freestanding;
const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("../command_wrappers/runtime.zig");

// The Taylor progress/abort surface comes from the runtime seam rather than from
// the wp34s owner that also uses it: that owner reaches command_wrappers.zig,
// which reaches this file.
const checkHalfSec = abi.host.checkHalfSec; // routed through the host-callback boundary
const exitKeyWaiting = abi.host.exitKeyWaiting;
const progressHalfSecUpdate_Integer = abi.host.progressHalfSecUpdate_Integer;
const ERROR_SOLVER_ABORT: u8 = 60;
const REGISTER_T: runtime.calcRegister_t = 103;
const NIM_REGISTER_LINE: runtime.calcRegister_t = 100; // REGISTER_X
const halfSec_timed: u8 = 0;
const halfSec_force: u8 = 1;
const halfSec_clearZ: bool = true;
const halfSec_clearT: bool = true;
const halfSec_disp: bool = true;
inline fn realGetExponent(source: *align(1) const runtime.real_t) i32 {
    return source.digits + source.exponent - 1;
}

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

fn roundToCallerPrecision(value: *runtime.real_t, real_context: *runtime.realContext_t) void {
    _ = runtime.decNumberPlus(value, value, real_context);
}

fn setNegativeSign(value: *runtime.real_t) void {
    value.bits |= 0x80;
}

// The radian range reduction runs at a width that covers the 1001-digit input
// cap: the DM42 reduces with the 2139-digit 2pi, since the 12321-digit one NaNs
// on the DM42 decNumber at that context; every other target takes the wider one.
const radian_reduction_digits: u32 = if (runtime.wp34s_mod_small_buffers) 2139 else 12321;

fn radianReduction2Pi() *const runtime.real_t {
    return if (comptime runtime.wp34s_mod_small_buffers) abi.constants.const2139_2pi() else abi.constants.const12321_2pi();
}

// Reduces a nonnegative radian angle to the first octant without shortening it
// before the quadrant subtraction: the remainder modulo 2pi is taken at the full
// reduction width, four times it names the quadrant, its upper half is folded,
// and only the final division by eight rounds to the caller's context. The
// working real comes off the heap; without one the angle becomes NaN.
fn reduceRadianToFirstOctant(
    angle: *runtime.real_t,
    sin_neg: *bool,
    cos_neg: *bool,
    swap: *bool,
    real_context: *runtime.realContext_t,
) void {
    const work_p = runtime.mallocRealDigits(radian_reduction_digits);
    defer runtime.freeReal(work_p);
    var c: runtime.realContext_t = real_context.*;
    var quadrant: u32 = 0;

    if (work_p == null) {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
        runtime.realSetNaN(angle);
        return;
    }
    const work = work_p.?;
    const two_pi = radianReduction2Pi();

    c.digits = @intCast(radian_reduction_digits);
    _ = runtime.decNumberRemainder(work, angle, two_pi, &c);
    if (runtime.realIsNaN(work)) {
        copyReal(angle, work);
        return;
    }

    // Four times the remainder identifies its quadrant without shortening a value close to a multiple of pi/2.
    runtime.realMultiply(work, abi.constants.const_4(), work, &c);
    while (runtime.realCompareGreaterEqual(work, two_pi)) {
        runtime.realSubtract(work, two_pi, work, &c);
        quadrant += 1;
    }

    switch (quadrant) {
        1 => {
            swap.* = !swap.*;
            cos_neg.* = !cos_neg.*;
        },
        2 => {
            sin_neg.* = !sin_neg.*;
            cos_neg.* = !cos_neg.*;
        },
        3 => {
            swap.* = !swap.*;
            sin_neg.* = !sin_neg.*;
        },
        else => {},
    }

    // The value is now four times an angle in [0, pi/2). Fold its upper half before shortening it.
    runtime.realMultiply(work, runtime.z47_math_wrappers_const_2(), work, &c);
    if (runtime.realCompareGreaterThan(work, two_pi)) {
        runtime.realSubtract(work, two_pi, work, &c);
        runtime.realSubtract(two_pi, work, work, &c);
        swap.* = !swap.*;
    }
    runtime.realDivide(work, abi.constants.const_8(), angle, real_context);
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
            copyReal(angle45, abi.constants.const_1on4());
            copyReal(angle90, runtime.z47_math_wrappers_const_1on2());
            copyReal(angle180, runtime.z47_math_wrappers_const_1());
            runtime.WP34S_Mod(angle, runtime.z47_math_wrappers_const_2(), angle, real_context);
        },
        runtime.amGrad => {
            copyReal(angle45, abi.constants.const_50());
            copyReal(angle90, runtime.z47_math_wrappers_const_100());
            copyReal(angle180, abi.constants.const_200());
            runtime.WP34S_Mod(angle, abi.constants.const_400(), angle, real_context);
        },
        runtime.amDegree, runtime.amDMS => {
            copyReal(angle45, abi.constants.const_45());
            copyReal(angle90, runtime.z47_math_wrappers_const_90());
            copyReal(angle180, runtime.z47_math_wrappers_const_180());
            runtime.WP34S_Mod(angle, abi.constants.const_360(), angle, real_context);
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
        var t_exp: i32 = realGetExponent(t);

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
        t_exp = @max(t_exp, realGetExponent(t));

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

        if (runtime.explicitTaylorIterVisibilitySelection and checkHalfSec()) {
            var ss: [100]u8 = undefined;
            abi.fmtBufZ(&ss, "Taylor Iter: {d}/{d}; Dig: {d}/", .{ iteration, taylor_iteration_max, -@as(i16, @truncate(t_exp)) });
            ss[40] = 0; // hard limit to what the screen shows
            _ = progressHalfSecUpdate_Integer(halfSec_timed, @ptrCast(&ss[0]), epsilon_digits, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        }
        // Firmware only: the host build runs the Taylor loop to completion.
        if (comptime is_dmcp_build) {
            if (exitKeyWaiting()) {
                _ = progressHalfSecUpdate_Integer(halfSec_force + 1, "Interrupted Iter:", @intCast(iteration), halfSec_clearZ, halfSec_clearT, halfSec_disp);
                runtime.displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T);
                break;
            }
        }
    }

    if (runtime.realIsZero(cos_value)) {
        runtime.realSetPositiveSign(cos_value);
    }
    if (runtime.realIsZero(sin_value)) {
        runtime.realSetPositiveSign(sin_value);
    }
    runtime.realMultiply(sin_value, angle, sin_value, real_context);
    // One Taylor run consumes the request: whoever wants the iteration counter
    // shown next time has to ask again.
    runtime.explicitTaylorIterVisibilitySelection = false;
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

    // The eight working reals come from the heap, not the frame: eight
    // decNumbers at 60 bytes is 480 of this function's 672 byte frame, and it
    // sits on the integrand path of a plotted integral. The 1071 digit twin is
    // untouched. Mirrors upstream's REAL_T_ALLOC(name, 75) block --
    // REAL_SIZE_IN_BYTES(75) is @sizeOf(real_t).
    const work_angle_p = runtime.mallocReal();
    const a2_p = runtime.mallocReal();
    const t_p = runtime.mallocReal();
    const j_p = runtime.mallocReal();
    const z_p = runtime.mallocReal();
    const sin_value_p = runtime.mallocReal();
    const cos_value_p = runtime.mallocReal();
    const epsilon_or_compare_p = runtime.mallocReal();
    defer {
        runtime.freeReal(work_angle_p);
        runtime.freeReal(a2_p);
        runtime.freeReal(t_p);
        runtime.freeReal(j_p);
        runtime.freeReal(z_p);
        runtime.freeReal(sin_value_p);
        runtime.freeReal(cos_value_p);
        runtime.freeReal(epsilon_or_compare_p);
    }
    if (work_angle_p == null or a2_p == null or t_p == null or j_p == null or
        z_p == null or sin_value_p == null or cos_value_p == null or epsilon_or_compare_p == null)
    {
        runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE);
        return;
    }
    const work_angle = work_angle_p.?;
    const sin_value = sin_value_p.?;
    const cos_value = cos_value_p.?;

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
        work_angle,
        a2_p.?,
        t_p.?,
        j_p.?,
        z_p.?,
        sin_value,
        cos_value,
        sin_out,
        cos_out,
        epsilon_or_compare_p.?,
        do_epsilon,
        epsilon_digits,
        real_context,
    );

    real_context.digits = saved_context_digits;

    if (sin_out) |output| {
        _ = runtime.decNumberPlus(output, sin_value, real_context);
    }
    if (cos_out) |output| {
        _ = runtime.decNumberPlus(output, cos_value, real_context);
    }
    if (tan_out) |output| {
        if (sin_out == null or cos_out == null) {
            runtime.realSetNaN(output);
        } else if (swap) {
            runtime.realDivide(cos_value, sin_value, output, real_context);
        } else {
            runtime.realDivide(sin_value, cos_value, output, real_context);
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
    // Zero, not undefined: the reduction leaves all three alone for an angular
    // mode it does not know, and the comparisons below still read them.
    var angle45: runtime.real_t = undefined;
    var angle90: runtime.real_t = undefined;
    var angle180: runtime.real_t = undefined;
    runtime.realSetZero(&angle45);
    runtime.realSetZero(&angle90);
    runtime.realSetZero(&angle180);
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
    // The work runs on a copy of the caller's context at 75 digits: the
    // reduction at full width, the Taylor series at 51 where the caller asked
    // for 51 or fewer, and the result rounded to the caller's digits.
    var c: runtime.realContext_t = real_context.*;
    c.digits = 75;

    if (runtime.realIsNegative(&angle)) {
        sin_neg = true;
        runtime.realSetPositiveSign(&angle);
    }

    if (angular_mode == runtime.amRadian) {
        reduceRadianToFirstOctant(&angle, &sin_neg, &cos_neg, &swap, &c);
    } else {
        reduceAngleToRange(&angle, &angle45, &angle90, &angle180, &angular_mode, &c);
    }

    // sin(180+x) = -sin(x), cos(180+x) = -cos(x)
    if (angular_mode != runtime.amRadian and isGreaterEqual(&angle, &angle180)) {
        runtime.realSubtract(&angle, &angle180, &angle, &c);
        sin_neg = !sin_neg;
        cos_neg = !cos_neg;
    }

    // sin(90+x) = cos(x), cos(90+x) = -sin(x)
    if (angular_mode != runtime.amRadian and isGreaterEqual(&angle, &angle90)) {
        runtime.realSubtract(&angle, &angle90, &angle, &c);
        swap = true;
        cos_neg = !cos_neg;
    }

    // sin(90-x) = cos(x), cos(90-x) = sin(x)
    if (angular_mode != runtime.amRadian and runtime.realCompareEqual(&angle, &angle45)) {
        if (sin_out) |output| copyReal(output, abi.constants.const39_root2on2());
        if (cos_out) |output| copyReal(output, abi.constants.const39_root2on2());
        if (tan_out) |output| {
            runtime.realSetOne(output);
        }
    } else {
        if (angular_mode != runtime.amRadian and isGreaterThan(&angle, &angle45)) {
            runtime.realSubtract(&angle90, &angle, &angle, &c);
            swap = !swap;
        }

        const angle30 = (angular_mode == runtime.amDegree and runtime.realCompareEqual(&angle, abi.constants.const_30())); // exactly 30 degrees: its sine is 1/2
        if (angular_mode != runtime.amRadian) {
            runtime.convertAngleFromTo(&angle, angular_mode, runtime.amRadian, &c);
        }
        if (saved_context_digits <= 51) {
            c.digits = 51;
        }
        sinCosTanTaylorTemp75(
            &angle,
            swap,
            if (swap) cos_out else sin_out,
            if (swap) sin_out else cos_out,
            tan_out,
            &c,
        );
        if (angle30) {
            if (if (swap) cos_out else sin_out) |sin_of_angle| {
                copyReal(sin_of_angle, runtime.z47_math_wrappers_const_1on2());
            }
        }
    }

    c.digits = saved_context_digits;

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
        roundToCallerPrecision(output, &c);
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
        roundToCallerPrecision(output, &c);
    }

    if (tan_out) |output| {
        if (cos_out) |cos_value_out| {
            if (runtime.realIsZero(cos_value_out)) {
                runtime.realSetPositiveSign(output);
                roundToCallerPrecision(output, &c);
            }
        }
    }
}
