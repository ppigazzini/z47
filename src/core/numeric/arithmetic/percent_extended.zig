const runtime = @import("../command_wrappers/runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

fn setNaNOrDomainError(result: *runtime.real_t, comptime who: [*:0]const u8, comptime why: [*:0]const u8) bool {
    if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError(who, why, null, null);
        }
        return false;
    }

    runtime.realSetNaN(result);
    return true;
}

fn setSignedInfinity(result: *runtime.real_t, is_negative: bool, comptime who: [*:0]const u8, comptime why: [*:0]const u8) bool {
    if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            runtime.moreInfoOnError(who, why, null, null);
        }
        return false;
    }

    result.* = runtime.z47_math_wrappers_const_plus_infinity().*;
    if (is_negative) {
        result.bits |= 0x80;
    }
    return true;
}

fn longIntegerSetPositiveSign(value: *runtime.mpz_struct) void {
    value._mp_size = @intCast(@abs(value._mp_size));
}

// The exact ratio of two registers, where both have finite scaled coefficients.
fn exactRegisterRatio(numerator_register: runtime.calcRegister_t, denominator_register: runtime.calcRegister_t, result: *runtime.real_t, real_context: *runtime.realContext_t) bool {
    var numerator_exponent: i32 = 0;
    var denominator_exponent: i32 = 0;
    var numerator: runtime.longInteger_t = undefined;
    var denominator: runtime.longInteger_t = undefined;

    if (!runtime.convertRegisterToScaledLongInteger(numerator_register, &numerator[0], &numerator_exponent)) {
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(denominator_register, &denominator[0], &denominator_exponent)) {
        runtime.__gmpz_clear(&numerator[0]);
        return false;
    }
    const ok = runtime.divideScaledLongIntegersToReal(&numerator[0], numerator_exponent, false, &denominator[0], denominator_exponent, result, real_context);
    runtime.__gmpz_clear(&denominator[0]);
    runtime.__gmpz_clear(&numerator[0]);
    return ok;
}

// The exact (x - y) / y of X and Y, over their magnitudes when asked.
fn exactRegisterRatioDifference(magnitudes: bool, result: *runtime.real_t, real_context: *runtime.realContext_t) bool {
    var x_exponent: i32 = 0;
    var y_exponent: i32 = 0;
    var difference_exponent: i32 = 0;
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var difference: runtime.longInteger_t = undefined;

    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_X, &x[0], &x_exponent)) {
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_Y, &y[0], &y_exponent)) {
        runtime.__gmpz_clear(&x[0]);
        return false;
    }
    if (magnitudes) {
        longIntegerSetPositiveSign(&x[0]);
        longIntegerSetPositiveSign(&y[0]);
    }
    runtime.__gmpz_init(&difference[0]);
    runtime.addSubtractScaledLongIntegers(&x[0], x_exponent, &y[0], y_exponent, true, &difference[0], &difference_exponent);
    const ok = runtime.divideScaledLongIntegersToReal(&difference[0], difference_exponent, false, &y[0], y_exponent, result, real_context);
    runtime.__gmpz_clear(&difference[0]);
    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
    return ok;
}

// A negative ratio close to -1 raised to an odd reciprocal integer power, via
// the logarithm of its magnitude: the plain power loses the digits.
fn stableNegativeRatio(ratio: *const runtime.real_t, periods: *const runtime.real_t, result: *runtime.real_t) bool {
    var exponent: runtime.real_t = undefined;
    var logarithm: runtime.real_t = undefined;
    var conversion_error = false;

    if (!runtime.realIsNegative(ratio) or !runtime.realCompareAbsGreaterThan(ratio, runtime.z47_math_wrappers_const_1on2()) or !runtime.realCompareAbsLessThan(ratio, runtime.z47_math_wrappers_const_2())) {
        return false;
    }
    runtime.realDivide(runtime.z47_math_wrappers_const_1(), periods, &exponent, &runtime.ctxtReal75);
    if (!runtime.realIsAnInteger(&exponent)) {
        return false;
    }
    const integer_exponent = runtime.realToInt32C47(&exponent, &conversion_error);
    if (conversion_error or integer_exponent < -999999999 or integer_exponent > 999999999) {
        return false;
    }
    if (!exactRegisterRatioDifference(true, &logarithm, &runtime.ctxtReal51)) {
        return false;
    }
    runtime.WP34S_Ln1P(&logarithm, &logarithm, &runtime.ctxtReal51);
    runtime.realDivide(&logarithm, periods, result, &runtime.ctxtReal51);
    runtime.WP34S_ExpM1(result, result, &runtime.ctxtReal51);
    if ((integer_exponent & 1) != 0) {
        runtime.realChangeSign(result);
        runtime.realSubtract(result, runtime.z47_math_wrappers_const_2(), result, &runtime.ctxtReal51);
    }
    return true;
}

pub fn percentMRR(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var z_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;

    _ = unused_but_mandatory_parameter;

    if (!runtime.saveLastX()) {
        return;
    }

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) and runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value) and runtime.getRegisterAsReal(runtime.REGISTER_Z, &z_value)) {
        if (runtime.realIsZero(&x_value) and runtime.realIsZero(&y_value)) {
            _ = setNaNOrDomainError(&result, "In function percentMRR:", "cannot divide x=0 by y=0");
        } else if (runtime.realIsZero(&y_value)) {
            _ = setSignedInfinity(&result, runtime.realIsNegative(&x_value) != runtime.realIsNegative(&y_value), "In function percentMRR:", "cannot divide a real by 0");
        } else if (runtime.realIsZero(&z_value)) {
            _ = setNaNOrDomainError(&result, "In function percentMRR:", "cannot calculate a mean rate over zero periods");
        } else {
            if (!exactRegisterRatio(runtime.REGISTER_X, runtime.REGISTER_Y, &result, &runtime.ctxtReal51)) {
                runtime.realDivide(&x_value, &y_value, &result, &runtime.ctxtReal51);
            }
            if (runtime.realCompareGreaterThan(&result, runtime.z47_math_wrappers_const_0())) {
                if (runtime.realCompareGreaterThan(&result, runtime.z47_math_wrappers_const_1on2()) and runtime.realCompareLessThan(&result, runtime.z47_math_wrappers_const_2())) {
                    if (!exactRegisterRatioDifference(false, &result, &runtime.ctxtReal51)) {
                        runtime.realSubtract(&x_value, &y_value, &result, &runtime.ctxtReal51); // q = x - y
                        runtime.realDivide(&result, &y_value, &result, &runtime.ctxtReal51); // q = x/y - 1
                    }
                    runtime.WP34S_Ln1P(&result, &result, &runtime.ctxtReal51); // q = ln(x/y)
                } else {
                    runtime.WP34S_Ln(&result, &result, &runtime.ctxtReal51);
                }
                runtime.realDivide(&result, &z_value, &result, &runtime.ctxtReal51); // q = ln(x/y) / z
                runtime.WP34S_ExpM1(&result, &result, &runtime.ctxtReal51); // q = exp(ln(x/y) / z) - 1
            } else {
                if (!stableNegativeRatio(&result, &z_value, &result)) {
                    if (!exactRegisterRatio(runtime.REGISTER_X, runtime.REGISTER_Y, &result, &runtime.ctxtReal75)) {
                        runtime.realDivide(&x_value, &y_value, &result, &runtime.ctxtReal75);
                    }
                    runtime.realDivide(runtime.z47_math_wrappers_const_1(), &z_value, &z_value, &runtime.ctxtReal75);
                    runtime.realPower(&result, &z_value, &result, &runtime.ctxtReal75);
                    runtime.realSubtract(&result, runtime.z47_math_wrappers_const_1(), &result, &runtime.ctxtReal75);
                }
            }
            result.exponent += 2; // q = 100 * (pow(x/y, 1/z) - 1)
        }

        if (runtime.lastErrorCode == 0) {
            runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
            runtime.temporaryInformation = runtime.TI_PERC;
        }
    }

    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, no_register, no_register);
    if (runtime.lastErrorCode == 0) {
        runtime.fnDropY(runtime.NOPARAM);
    }
}

// y / (1 - x/100) from the exact scaled coefficients of X and Y.
fn percentPlusMGExactRegisters(result: *runtime.real34_t) bool {
    var x_exponent: i32 = 0;
    var y_exponent: i32 = 0;
    var denominator_exponent: i32 = 0;
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var one_hundred: runtime.longInteger_t = undefined;
    var denominator: runtime.longInteger_t = undefined;

    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_X, &x[0], &x_exponent)) {
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_Y, &y[0], &y_exponent)) {
        runtime.__gmpz_clear(&x[0]);
        return false;
    }

    runtime.__gmpz_init(&one_hundred[0]);
    runtime.__gmpz_set_ui(&one_hundred[0], 1);
    runtime.addSubtractScaledLongIntegers(&one_hundred[0], 2, &x[0], x_exponent, true, &denominator[0], &denominator_exponent);
    var negative_zero = false;
    if (runtime.longIntegerIsZero(&y[0])) {
        const numerator_negative = runtime.getRegisterDataType(runtime.REGISTER_Y) == runtime.dtReal34 and runtime.real34IsNegative(runtime.registerReal34Ptr(runtime.REGISTER_Y));
        negative_zero = numerator_negative != runtime.longIntegerIsNegative(&denominator[0]);
    }
    const ok = runtime.divideScaledLongIntegersToReal34(&y[0], y_exponent + 2, negative_zero, &denominator[0], denominator_exponent, result);
    runtime.__gmpz_clear(&denominator[0]);
    runtime.__gmpz_clear(&one_hundred[0]);
    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
    return ok;
}

pub fn percentPlusMG(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var exact_result: runtime.real34_t = undefined;
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const exact_quotient = (type_x == runtime.dtLongInteger or type_y == runtime.dtLongInteger) and
        percentPlusMGExactRegisters(&exact_result);

    _ = unused_but_mandatory_parameter;

    if (!exact_quotient and (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value))) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (exact_quotient) {
        // the exact quotient stands
    } else if (runtime.realCompareEqual(&x_value, runtime.z47_math_wrappers_const_100()) and runtime.realIsZero(&y_value)) {
        if (!setNaNOrDomainError(&result, "In function percentPlusMGReal:", "cannot divide 0 by 0")) {
            return;
        }
    } else if (runtime.realCompareEqual(&x_value, runtime.z47_math_wrappers_const_100())) {
        if (!setSignedInfinity(&result, runtime.realIsNegative(&y_value), "In function percentPlusMGReal:", "cannot divide a real by 0")) {
            return;
        }
    } else {
        runtime.realDivide(&x_value, runtime.z47_math_wrappers_const_100(), &result, &runtime.ctxtReal39);
        runtime.realSubtract(runtime.z47_math_wrappers_const_1(), &result, &result, &runtime.ctxtReal39);
        runtime.realDivide(&y_value, &result, &result, &runtime.ctxtReal39);
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    if (exact_quotient) {
        runtime.registerReal34Ptr(runtime.REGISTER_X).* = exact_result;
    } else {
        runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    }
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
}

// The error of percentTReal: raised only while SPCRES is clear; with it set the
// division itself yields the NaN or the signed infinity.
fn percentTDomainError(comptime why: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError("In function percentTReal:", why, null, null);
    }
}

pub fn percentT(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var exact_result: runtime.real34_t = undefined;
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const exact_quotient = (type_x == runtime.dtLongInteger or type_y == runtime.dtLongInteger) and
        runtime.divideRegisterValuesToReal34Scaled(runtime.REGISTER_X, runtime.REGISTER_Y, 2, &exact_result);

    _ = unused_but_mandatory_parameter;

    if (!exact_quotient and (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value))) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    if (exact_quotient) {
        runtime.convertReal34ToReal34Register(&exact_result, runtime.REGISTER_X);
    } else if (runtime.realIsZero(&x_value) and runtime.realIsZero(&y_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        percentTDomainError("cannot divide x=0 by y=0");
    } else if (runtime.realIsZero(&y_value) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        percentTDomainError("cannot divide a real by y=0");
    } else {
        x_value.exponent += 2; // xReal = xReal * 100.0
        runtime.realDivide(&x_value, &y_value, &result, &runtime.ctxtReal34); // rReal = xReal * 100.0 / yReal
        runtime.convertRealToResultRegister(&result, runtime.REGISTER_X, runtime.amNone);
    }

    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
    runtime.temporaryInformation = runtime.TI_PERC;
}

// 100 (x - y) / y from the exact scaled coefficients of X and Y.
fn deltaPercentExactRegisters(result: *runtime.real34_t) bool {
    var x_exponent: i32 = 0;
    var y_exponent: i32 = 0;
    var difference_exponent: i32 = 0;
    var x: runtime.longInteger_t = undefined;
    var y: runtime.longInteger_t = undefined;
    var difference: runtime.longInteger_t = undefined;

    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_X, &x[0], &x_exponent)) {
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_Y, &y[0], &y_exponent)) {
        runtime.__gmpz_clear(&x[0]);
        return false;
    }

    runtime.addSubtractScaledLongIntegers(&x[0], x_exponent, &y[0], y_exponent, true, &difference[0], &difference_exponent);
    const ok = runtime.divideScaledLongIntegersToReal34(&difference[0], difference_exponent + 2, false, &y[0], y_exponent, result);
    runtime.__gmpz_clear(&difference[0]);
    runtime.__gmpz_clear(&y[0]);
    runtime.__gmpz_clear(&x[0]);
    return ok;
}

pub fn deltaPercent(unused_but_mandatory_parameter: u16) void {
    var x_value: runtime.real_t = undefined;
    var y_value: runtime.real_t = undefined;
    var result: runtime.real_t = undefined;
    var exact_result: runtime.real34_t = undefined;
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const exact_quotient = (type_x == runtime.dtLongInteger or type_y == runtime.dtLongInteger) and
        deltaPercentExactRegisters(&exact_result);

    _ = unused_but_mandatory_parameter;

    if (!exact_quotient and (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value))) {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    if (exact_quotient) {
        runtime.registerReal34Ptr(runtime.REGISTER_X).* = exact_result;
    } else {
        // realSetZero, not a zero-filled decNumber: a decNumber with digits == 0 is
        // out of contract, and deltaPercentReal's refusal paths leave this seed as
        // the value the result register is written from.
        runtime.realSetZero(&result);

        if (runtime.realIsZero(&x_value) and runtime.realCompareEqual(&x_value, &y_value)) {
            _ = setNaNOrDomainError(&result, "In function deltaPercentReal:", "cannot divide 0 by 0");
        } else if (runtime.realIsZero(&y_value)) {
            if (runtime.realIsNaN(&x_value)) {
                if (!runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
                    _ = setNaNOrDomainError(&result, "In function deltaPercentReal:", "cannot divide a real by y=0");
                } else {
                    runtime.realSetNaN(&result);
                }
            } else {
                _ = setSignedInfinity(&result, runtime.realIsNegative(&x_value) != runtime.realIsNegative(&y_value), "In function deltaPercentReal:", "cannot divide a real by y=0");
            }
        } else {
            runtime.realSubtract(&x_value, &y_value, &result, &runtime.ctxtReal39);
            runtime.realDivide(&result, &y_value, &result, &runtime.ctxtReal39);
            result.exponent += 2;
        }

        runtime.convertRealToReal34ResultRegister(&result, runtime.REGISTER_X);
    }
    runtime.setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    runtime.adjustResult(runtime.REGISTER_X, false, true, runtime.REGISTER_X, no_register, no_register);
    runtime.temporaryInformation = runtime.TI_PERCD;
}
