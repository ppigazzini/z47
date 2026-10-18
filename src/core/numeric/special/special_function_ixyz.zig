const std = @import("std");
const runtime = @import("../command_wrappers/runtime.zig");
const math_wp34s = @import("wp34s.zig");

const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;

const no_register = @as(runtime.calcRegister_t, -1);

const std_less_equal = "\xa2\x64"; // STD_LESS_EQUAL

// ERROR_MESSAGE_LENGTH is 512 (defines.h); upstream formats the type-name hint
// into the shared errorMessage buffer of that size.
const ERROR_MESSAGE_LENGTH = 512;

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

// The regularised incomplete beta for Real34 inputs. With the F distribution
// in the build it is the distribution's beta pair at 51 digits, or 75 once both
// shape parameters reach 1e5; without it, the WP34S series at 75 digits.
fn ixyzEvaluate(x: *const real_t, a: *const real_t, b: *const real_t, res: *real_t) bool {
    if (comptime runtime.option_dist_f) {
        var complement: real_t = undefined;
        var logComplement: real_t = undefined;
        var logit: real_t = undefined;
        var lower: real_t = undefined;
        var upper: real_t = undefined;
        var real_context: *realContext_t = &runtime.ctxtReal51;
        var largeThreshold: real_t = undefined;

        runtime.realSetOne(&largeThreshold);
        largeThreshold.exponent = 5;
        if (runtime.realCompareGreaterEqual(a, &largeThreshold) and runtime.realCompareGreaterEqual(b, &largeThreshold)) {
            real_context = &runtime.ctxtReal75;
        }
        if (runtime.realIsZero(x)) {
            runtime.realSetZero(res);
            return true;
        }
        if (runtime.realCompareEqual(x, runtime.z47_math_wrappers_const_1())) {
            runtime.realSetOne(res);
            return true;
        }

        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), x, &complement, real_context);
        math_wp34s.WP34S_Ln(x, &logit, real_context);
        math_wp34s.WP34S_Ln(&complement, &logComplement, real_context);
        runtime.realSubtract(&logit, &logComplement, &logit, real_context);
        if (!runtime.distributionBetaPair(a, b, x, &complement, &logit, &lower, &upper, real_context)) {
            return false;
        }
        if (runtime.realIsZero(&lower)) {
            runtime.realNextToward(&lower, runtime.z47_math_wrappers_const_1(), &lower, real_context);
        } else if (runtime.realCompareEqual(&lower, runtime.z47_math_wrappers_const_1())) {
            runtime.realNextToward(&lower, runtime.z47_math_wrappers_const_0(), &lower, real_context);
        }
        copyReal(res, &lower);
        return true;
    } else {
        math_wp34s.WP34S_betai(b, a, x, res, &runtime.ctxtReal75);
        return !runtime.realIsNaN(res);
    }
}

fn ixyz() callconv(.c) void {
    var x: real_t = undefined;
    var a: real_t = undefined;
    var b: real_t = undefined;
    var val: real_t = undefined;

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &a) and runtime.getRegisterAsReal(runtime.REGISTER_Z, &b)) {
        if (!runtime.realIsSpecial(&x) and !runtime.realIsSpecial(&a) and !runtime.realIsSpecial(&b) and
            runtime.realCompareGreaterEqual(&x, runtime.z47_math_wrappers_const_0()) and runtime.realCompareLessEqual(&x, runtime.z47_math_wrappers_const_1()) and
            runtime.realCompareGreaterThan(&a, runtime.z47_math_wrappers_const_0()) and runtime.realCompareGreaterThan(&b, runtime.z47_math_wrappers_const_0()) and
            ixyzEvaluate(&x, &a, &b, &val))
        {
            runtime.convertRealToResultRegister(&val, runtime.REGISTER_X, runtime.amNone);
            runtime.fnDropY(runtime.NOPARAM);
            if (runtime.lastErrorCode == runtime.ERROR_NONE) {
                runtime.fnDropY(runtime.NOPARAM);
            }
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function fnIxyz:", "not in 0 " ++ std_less_equal ++ " x " ++ std_less_equal ++ " 1, a > 0, b > 0", null, null);
            }
        }
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            var buffer: [ERROR_MESSAGE_LENGTH]u8 = undefined;
            const x_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_X, true, false));
            const y_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Y, true, false));
            const z_name = std.mem.span(runtime.getRegisterDataTypeName(runtime.REGISTER_Z, true, false));
            const message = runtime.bufPrintZ(&buffer, "cannot calculate Ixyz for {s}, {s}, {s}", .{ x_name, y_name, z_name }) catch "";
            runtime.moreInfoOnError("In function fnIxyz:", message, null, null);
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, no_register, no_register);
}

pub fn fnIxyz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    ixyz();
}
