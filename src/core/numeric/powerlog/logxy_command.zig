const logxy_owned = @import("logxy.zig");
const powlog_power_owned = @import("powlog_power.zig");
const runtime = @import("../command_wrappers/runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const transcendental_command_owned = @import("../special/transcendental_command.zig");

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY

// EXTRA_INFO_MESSAGE (defines.h): the macro prints three console lines --
// the fixed "In function " prefix, the function name, then the message --
// and is compiled out on the firmware and under the testSuite.
fn extraInfoMessage(function_name: [*:0]const u8, message: [*:0]const u8) void {
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function ", function_name, message, null);
    }
}

fn copyReal(destination: *runtime.real_t, source: *const runtime.real_t) void {
    destination.* = source.*;
}

fn realRescale(operand: *const runtime.real_t, result: *runtime.real_t, accuracy: *const runtime.real_t, real_context: *runtime.realContext_t) void {
    _ = runtime.decNumberRescale(result, operand, accuracy, real_context);
}

/// The base whose logarithm denom is: 2 for the ln 2 the binary logarithm
/// divides by, 10 otherwise.
fn logBase(denom: *const runtime.real_t) u32 {
    return if (denom == runtime.z47_math_wrappers_const_ln2()) 2 else 10;
}

fn logXYComplex(x: *const runtime.cplx_t, y: *const runtime.cplx_t, r: *runtime.cplx_t) void {
    var ln_x: runtime.cplx_t = undefined;

    // lnComplexDirect handles the case where y = 0+i0.
    @import("../ln_complex.zig").lnComplexDirect(y, r); // r = Ln(y)
    @import("../ln_complex.zig").lnComplexDirect(x, &ln_x); // ln_x = Ln(x)
    runtime.divComplexComplex(r, &ln_x, r, &runtime.ctxtReal75);
}

fn logXYArgsHandled(x_real: *const runtime.real_t, x_imag: ?*const runtime.real_t, y_real: *const runtime.real_t, y_imag: ?*const runtime.real_t) bool {
    const x_zero = runtime.realIsZero(x_real) and (x_imag == null or runtime.realIsZero(x_imag.?));
    const y_zero = runtime.realIsZero(y_real) and (y_imag == null or runtime.realIsZero(y_imag.?));

    if (x_zero and y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_OVERFLOW_PLUS_INF, runtime.ERR_REGISTER_LINE);
            extraInfoMessage("checkArgs", "cannot calculate LogXY with x=0 and y=0");
        }
        return true;
    }

    if (!x_zero and y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_minus_infinity(), runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_OVERFLOW_MINUS_INF, runtime.ERR_REGISTER_LINE);
            extraInfoMessage("checkArgs", "cannot calculate LogXY with x=0 and y!=0");
        }
        return true;
    }

    if (x_zero and !y_zero) {
        if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
            runtime.convertRealToResultRegister(runtime.const_NaN, runtime.REGISTER_X, runtime.amNone);
        } else {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        }
        return true;
    }

    return false;
}

fn logxyRealCore(x_real: *const runtime.real_t, y_real: *const runtime.real_t, real_context: *runtime.realContext_t) void {
    var x: runtime.cplx_t = undefined;
    var r: runtime.cplx_t = undefined;

    if (logXYArgsHandled(x_real, null, y_real, null)) {
        return;
    }

    if (runtime.realIsNegative(x_real) or runtime.realIsNegative(y_real)) {
        copyReal(&x.Real, x_real);
        runtime.realSetZero(&x.Imag);
        copyReal(&r.Real, y_real);
        runtime.realSetZero(&r.Imag);
        logXYComplex(&x, &r, &r);

        if (!runtime.realIsZero(&r.Imag)) {
            if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
                runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
                return;
            }

            if (runtime.getFlag(@intCast(runtime.FLAG_SPCRES))) {
                runtime.realSetNaN(&r.Real);
            } else {
                runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
                extraInfoMessage("logxy", "cannot calculate LogXY with x<0 or y<0 when flag I is not set");
                return;
            }
        }
    } else {
        logxy_owned.logxyRealValue(y_real, x_real, &r.Real, real_context);
    }

    runtime.convertRealToResultRegister(&r.Real, runtime.REGISTER_X, runtime.amNone);
}

fn logXYLongInt() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34 and runtime.real34IsAnInteger(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        runtime.convertReal34ToLongIntegerRegister(runtime.registerReal34Ptr(runtime.REGISTER_X), runtime.REGISTER_X, runtime.DEC_ROUND_DOWN);
    }
}

fn logXYShortInt() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    const base = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) or !runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);

    if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtReal34) {
        if (runtime.real34IsNaN(runtime.registerReal34Ptr(runtime.REGISTER_X)) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            extraInfoMessage("logxy", "cannot calculate LogXY with x=0");
            return;
        }

        if (runtime.real34IsAnInteger(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
            runtime.clearSystemFlag(runtime.FLAG_CARRY);
        } else {
            runtime.setSystemFlag(runtime.FLAG_CARRY);
        }

        runtime.fnChangeBase(@intCast(base));
    }
}

fn logXYReal() callconv(.c) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) or !runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value)) {
        return;
    }

    logxyRealCore(&x_value, &y_value, &runtime.ctxtReal39);
}

fn logXYCplx() callconv(.c) void {
    var x: runtime.cplx_t = undefined;
    var y: runtime.cplx_t = undefined;
    var r: runtime.cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y) or !runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (logXYArgsHandled(&x.Real, &x.Imag, &y.Real, &y.Imag)) {
        return;
    }

    logXYComplex(&x, &y, &r);
    runtime.convertComplexToResultRegister(&r, runtime.REGISTER_X);
}

pub fn fnLogXY(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexDyadicFunction(&logXYReal, &logXYCplx, &logXYShortInt, &logXYLongInt);
}

pub fn logxyReal(denom: *const runtime.real_t) callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &a)) {
        return;
    }

    if (runtime.realIsZero(&a)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function logxyReal:", "cannot calculate log2(0)", null, null);
            }
            return;
        }

        copyReal(&a, runtime.z47_math_wrappers_const_minus_infinity());
    } else if (runtime.realIsInfinite(&a)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function logxyReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of log2 when flag SPCRES is not set", null, null);
            }
            return;
        }

        if (math_real_predicates.realIsPositive(&a)) {
            copyReal(&a, runtime.z47_math_wrappers_const_plus_infinity());
        } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
            runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtComplex34, 0, runtime.amNone);
            runtime.realDivide(runtime.z47_math_wrappers_const_pi(), denom, &a, &runtime.ctxtReal39);
            runtime.convertComplexPartsToResultRegister(runtime.z47_math_wrappers_const_plus_infinity(), &a, runtime.REGISTER_X);
            return;
        } else {
            runtime.realSetNaN(&a);
        }
    } else if (math_real_predicates.realIsPositive(&a)) {
        var k: runtime.real_t = undefined;
        var p: runtime.real_t = undefined;
        copyReal(&b, &a);
        transcendental_command_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
        realRescale(&a, &k, runtime.z47_math_wrappers_const_0(), &runtime.ctxtReal39);
        const n = runtime.realToInt32C47(&k, null);
        if (logBase(denom) != 2 or (n >= -100 and n <= 112)) { // 10^k, and 2^k in that range, are exact at 75 digits; the range takes every power of 2 of 34 digits
            if (logBase(denom) == 2) {
                powlog_power_owned.realPower2(&k, &p, &runtime.ctxtReal75);
            } else {
                powlog_power_owned.realPower10(&k, &p, &runtime.ctxtReal75);
            }
            if (runtime.realCompareEqual(&p, &b)) { // X an exact power of the base gives the integer
                copyReal(&a, &k);
            }
        }
    } else if (runtime.getFlag(@intCast(runtime.FLAG_CPXRES))) {
        runtime.realSetPositiveSign(&a);
        transcendental_command_owned.lnRealValue(&a, &a, &runtime.ctxtReal39);
        runtime.realDivide(&a, denom, &a, &runtime.ctxtReal39);
        runtime.realDivide(runtime.z47_math_wrappers_const_pi(), denom, &b, &runtime.ctxtReal39);
        runtime.convertComplexPartsToResultRegister(&a, &b, runtime.REGISTER_X);
        return;
    } else if (runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.realSetNaN(&a);
    } else {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError("In function logxyReal:", "cannot calculate log2 of a negative number when CPXRES is not set!", null, null);
        }
        return;
    }

    runtime.convertRealToResultRegister(&a, runtime.REGISTER_X, runtime.amNone);
}

pub fn logxyCplx(denom: *const runtime.real_t) callconv(.c) void {
    var x: runtime.cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x.Real) and runtime.realIsZero(&x.Imag)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function logxyCplx:", "cannot calculate log2(0)", null, null);
            }
            return;
        }

        copyReal(&x.Real, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(&x.Imag);
    } else {
        runtime.realRectangularToPolar(&x, x.mag(), x.arg(), &runtime.ctxtReal39);
        transcendental_command_owned.lnRealValue(x.mag(), &x.Real, &runtime.ctxtReal39);
        runtime.realDivide(&x.Real, denom, &x.Real, &runtime.ctxtReal39);
        runtime.realDivide(&x.Imag, denom, &x.Imag, &runtime.ctxtReal39);
    }

    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

/// log10 and log2 of a complex differ only in the constant they divide by.
/// logxyCplx above has no near-unit branch, so it is a different routine and
/// is left alone.
pub fn logBaseCplx(denom: *const runtime.real_t) callconv(.c) void {
    var x: runtime.cplx_t = undefined;
    var result: runtime.cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x.Real) and runtime.realIsZero(&x.Imag)) {
        if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                runtime.moreInfoOnError("In function logBaseCplx:", "cannot calculate the log of 0", null, null);
            }
            return;
        }

        copyReal(&result.Real, runtime.z47_math_wrappers_const_minus_infinity());
        runtime.realSetZero(&result.Imag);
    } else {
        runtime.realRectangularToPolar(&x, result.mag(), result.arg(), &runtime.ctxtReal39);
        if (runtime.realCompareGreaterThan(&result.Real, runtime.z47_math_wrappers_const_1on2()) and runtime.realCompareLessThan(&result.Real, runtime.z47_math_wrappers_const_2())) {
            var near_unit_context: runtime.realContext_t = runtime.ctxtReal75;
            // Factoring the component with greater magnitude keeps its offset from one in working precision, while the other component contributes its square directly.
            if (math_comparison_reals.realCompareAbsLessThan(&x.Real, &x.Imag)) {
                runtime.realSubtract(&x.Imag, runtime.z47_math_wrappers_const_1(), &result.Real, &near_unit_context);
                runtime.realAdd(&x.Imag, runtime.z47_math_wrappers_const_1(), &x.Imag, &near_unit_context);
                runtime.realMultiply(&result.Real, &x.Imag, &result.Real, &near_unit_context);
                runtime.realFMA(&x.Real, &x.Real, &result.Real, &result.Real, &near_unit_context);
            } else {
                runtime.realSubtract(&x.Real, runtime.z47_math_wrappers_const_1(), &result.Real, &near_unit_context);
                runtime.realAdd(&x.Real, runtime.z47_math_wrappers_const_1(), &x.Real, &near_unit_context);
                runtime.realMultiply(&result.Real, &x.Real, &result.Real, &near_unit_context);
                runtime.realFMA(&x.Imag, &x.Imag, &result.Real, &result.Real, &near_unit_context);
            }
            runtime.WP34S_Ln1P(&result.Real, &result.Real, &near_unit_context);
            runtime.realMultiply(&result.Real, runtime.z47_math_wrappers_const_1on2(), &result.Real, &near_unit_context);
            runtime.realDivide(&result.Real, denom, &result.Real, &near_unit_context);
        } else {
            transcendental_command_owned.lnRealValue(&result.Real, &result.Real, &runtime.ctxtReal39);
            runtime.realDivide(&result.Real, denom, &result.Real, &runtime.ctxtReal39);
        }
        runtime.realDivide(&result.Imag, denom, &result.Imag, &runtime.ctxtReal39);
    }
    runtime.convertComplexToResultRegister(&result, runtime.REGISTER_X);
}

pub fn logxyLonI(denom: *const runtime.real_t) callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsNegative(&x) or runtime.realIsZero(&x)) {
        logxyReal(denom);
        return;
    }

    var x34: runtime.real_t = undefined;
    var c: runtime.realContext_t = runtime.ctxtReal34;
    c.round = runtime.DEC_ROUND_HALF_EVEN; // the test for an exact integer takes no mode from RM
    transcendental_command_owned.lnRealValue(&x, &x, &runtime.ctxtReal39);
    runtime.realDivide(&x, denom, &x, &runtime.ctxtReal39);
    _ = runtime.decNumberPlus(&x34, &x, &c); // Round using the 34 digit context
    if (!runtime.realIsAnInteger(&x34)) {
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    } else {
        var lgInt: runtime.longInteger_t = undefined;
        var power: runtime.longInteger_t = undefined;
        const k = runtime.realToInt32C47(&x34, null);

        _ = runtime.getRegisterAsLongInt(runtime.REGISTER_X, &lgInt[0], null);
        defer runtime.__gmpz_clear(&lgInt[0]);
        runtime.__gmpz_init(&power[0]);
        defer runtime.__gmpz_clear(&power[0]);
        runtime.__gmpz_ui_pow_ui(&power[0], logBase(denom), @intCast(k));
        if (runtime.__gmpz_cmp(&power[0], &lgInt[0]) == 0) { // an integer result only where X is the base to that power
            runtime.convertRealToLongIntegerRegister(&x34, runtime.REGISTER_X, runtime.DEC_ROUND_HALF_EVEN);
        } else {
            runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
        }
    }
}
