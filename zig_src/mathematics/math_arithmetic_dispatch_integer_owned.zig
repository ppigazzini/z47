const runtime = @import("math_command_wrappers_runtime.zig");

const no_register = @as(runtime.calcRegister_t, -1);

const dyadic_integer_add: u8 = 0;
const dyadic_integer_subtract: u8 = 1;
const dyadic_integer_multiply: u8 = 2;

fn shortIntegerData(regist: runtime.calcRegister_t) *align(1) u64 {
    return @as(*align(1) u64, @ptrCast(runtime.getRegisterDataPointer(regist).?));
}

fn tryDyadicLongIntegerArithmetic(operation: u8) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_long = type_x == runtime.dtLongInteger;
    const y_is_long = type_y == runtime.dtLongInteger;
    const x_is_short = type_x == runtime.dtShortInteger;
    const y_is_short = type_y == runtime.dtShortInteger;

    if (!(x_is_long or x_is_short) or !(y_is_long or y_is_short)) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_short and y_is_short) {
        const x_value = shortIntegerData(runtime.REGISTER_X);
        const y_value = shortIntegerData(runtime.REGISTER_Y);

        runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterTag(runtime.REGISTER_Y));
        x_value.* = switch (operation) {
            dyadic_integer_add => runtime.WP34S_intAdd(y_value.*, x_value.*),
            dyadic_integer_subtract => runtime.WP34S_intSubtract(y_value.*, x_value.*),
            dyadic_integer_multiply => runtime.WP34S_intMultiply(y_value.*, x_value.*),
            else => unreachable,
        };

        runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        return true;
    }

    var x_value: runtime.longInteger_t = undefined;
    var y_value: runtime.longInteger_t = undefined;

    if (x_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    }

    if (y_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    }

    defer runtime.__gmpz_clear(&x_value[0]);
    defer runtime.__gmpz_clear(&y_value[0]);

    switch (operation) {
        dyadic_integer_add => runtime.__gmpz_add(&x_value[0], &y_value[0], &x_value[0]),
        dyadic_integer_subtract => runtime.__gmpz_sub(&x_value[0], &y_value[0], &x_value[0]),
        dyadic_integer_multiply => runtime.__gmpz_mul(&x_value[0], &y_value[0], &x_value[0]),
        else => unreachable,
    }

    runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    return true;
}

fn tryDyadicLongIntegerDivide(with_remainder: bool) bool {
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);
    const x_is_long = type_x == runtime.dtLongInteger;
    const y_is_long = type_y == runtime.dtLongInteger;
    const x_is_short = type_x == runtime.dtShortInteger;
    const y_is_short = type_y == runtime.dtShortInteger;

    if (!(x_is_long or x_is_short) or !(y_is_long or y_is_short)) {
        return false;
    }

    if (!runtime.saveLastX()) {
        return true;
    }

    if (x_is_short and y_is_short and !with_remainder) {
        var divisor_magnitude: u64 = 0;
        var divisor_sign: i16 = 0;
        runtime.convertShortIntegerRegisterToUInt64(runtime.REGISTER_X, &divisor_sign, &divisor_magnitude);

        if (divisor_magnitude == 0) {
            runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
            runtime.moreInfoOnError(
                if (with_remainder) "In function fnIDivR:" else "In function fnIDiv:",
                "cannot divide current integer pair by 0",
                null,
                null,
            );
        } else {
            const x_raw = shortIntegerData(runtime.REGISTER_X);
            const y_raw = shortIntegerData(runtime.REGISTER_Y);

            x_raw.* = runtime.WP34S_intDivide(y_raw.*, x_raw.*);
            runtime.setRegisterTag(runtime.REGISTER_X, runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y));
        }

        runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        return true;
    }

    var x_value: runtime.longInteger_t = undefined;
    var y_value: runtime.longInteger_t = undefined;

    if (x_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_X, &x_value[0]);
    }

    if (y_is_long) {
        runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    } else {
        runtime.convertShortIntegerRegisterToLongInteger(runtime.REGISTER_Y, &y_value[0]);
    }

    defer runtime.__gmpz_clear(&x_value[0]);
    defer runtime.__gmpz_clear(&y_value[0]);

    if (x_value[0]._mp_size == 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
        runtime.moreInfoOnError(
            if (with_remainder) "In function fnIDivR:" else "In function fnIDiv:",
            "cannot divide current integer pair by 0",
            null,
            null,
        );
    } else if (with_remainder) {
        var quotient: runtime.longInteger_t = undefined;
        var remainder: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&quotient[0]);
        runtime.__gmpz_init(&remainder[0]);
        defer runtime.__gmpz_clear(&quotient[0]);
        defer runtime.__gmpz_clear(&remainder[0]);

        runtime.__gmpz_tdiv_qr(&quotient[0], &remainder[0], &y_value[0], &x_value[0]);
        if (x_is_short and y_is_short) {
            const base_y = runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y);
            runtime.convertLongIntegerToShortIntegerRegister(&quotient[0], base_y, runtime.REGISTER_X);
            runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], base_y, runtime.REGISTER_Y);
        } else {
            runtime.convertLongIntegerToLongIntegerRegister(&quotient[0], runtime.REGISTER_X);
            if (y_is_short) {
                runtime.convertLongIntegerToShortIntegerRegister(&remainder[0], runtime.getRegisterShortIntegerBase(runtime.REGISTER_Y), runtime.REGISTER_Y);
            } else {
                runtime.convertLongIntegerToLongIntegerRegister(&remainder[0], runtime.REGISTER_Y);
            }
        }
    } else {
        var remainder: runtime.longInteger_t = undefined;

        runtime.__gmpz_init(&remainder[0]);
        defer runtime.__gmpz_clear(&remainder[0]);

        runtime.__gmpz_tdiv_qr(&x_value[0], &remainder[0], &y_value[0], &x_value[0]);
        runtime.convertLongIntegerToLongIntegerRegister(&x_value[0], runtime.REGISTER_X);
    }

    if (with_remainder) {
        runtime.adjustResult(runtime.REGISTER_X, false, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
        runtime.adjustResult(runtime.REGISTER_Y, false, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    } else {
        runtime.adjustResult(runtime.REGISTER_X, true, false, runtime.REGISTER_X, runtime.REGISTER_Y, no_register);
    }

    return true;
}

pub fn tryIntegerAdd() bool {
    return tryDyadicLongIntegerArithmetic(dyadic_integer_add);
}

pub fn tryIntegerSubtract() bool {
    return tryDyadicLongIntegerArithmetic(dyadic_integer_subtract);
}

pub fn tryIntegerMultiply() bool {
    return tryDyadicLongIntegerArithmetic(dyadic_integer_multiply);
}

pub fn tryIntegerIDiv() bool {
    return tryDyadicLongIntegerDivide(false);
}

pub fn tryIntegerIDivR() bool {
    return tryDyadicLongIntegerDivide(true);
}
