const build_options = @import("math_command_wrappers_build_options");
const runtime = @import("math_command_wrappers_runtime.zig");
const legacy = runtime.legacy;

fn setPositiveSign(value: *runtime.mpz_struct) void {
    if (value._mp_size < 0) {
        value._mp_size = -value._mp_size;
    }
}

fn setNegativeSign(value: *runtime.mpz_struct) void {
    if (value._mp_size > 0) {
        value._mp_size = -value._mp_size;
    }
}

fn setPowerOfTwo(result: *runtime.mpz_struct, exponent: u32) void {
    runtime.__gmpz_set_ui(result, 1);
    runtime.__gmpz_mul_2exp(result, result, @as(c_ulong, @intCast(exponent)));
}

fn initShortIntegerRegisterAsLongInteger(reg: runtime.calcRegister_t, value: *runtime.longInteger_t) void {
    var sign: i16 = 0;
    var raw_value: u64 = 0;

    runtime.convertShortIntegerRegisterToUInt64(reg, &sign, &raw_value);
    runtime.__gmpz_init(&value[0]);
    runtime.__gmpz_set_ui(&value[0], @as(c_ulong, @intCast(raw_value >> 32)));
    runtime.__gmpz_mul_2exp(&value[0], &value[0], 32);
    runtime.__gmpz_add_ui(&value[0], &value[0], @as(c_ulong, @intCast(@as(u32, @truncate(raw_value)))));

    if (sign != 0) {
        setNegativeSign(&value[0]);
    }
}

fn reportDblMultiplyTypeError(reg: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    _ = runtime.getRegisterDataType(reg);
    runtime.moreInfoOnError("In function fnDblMultiply:", "the input type is not allowed for DBLx!", null, null);
}

fn requireDblMultiplyShortInteger(reg: runtime.calcRegister_t) bool {
    if (runtime.getRegisterDataType(reg) == runtime.dtShortInteger) {
        return true;
    }

    reportDblMultiplyTypeError(reg);
    return false;
}

fn dblMultiplyOwned() void {
    if (!requireDblMultiplyShortInteger(runtime.REGISTER_X) or
        !requireDblMultiplyShortInteger(runtime.REGISTER_Y))
    {
        return;
    }

    if (!runtime.saveLastX()) {
        return;
    }

    const sim = runtime.shortIntegerMode;
    defer runtime.shortIntegerMode = sim;
    const word_size: u32 = runtime.shortIntegerWordSize;
    const base = runtime.getRegisterTag(runtime.REGISTER_Y);
    var signs_differ = false;

    if (sim == runtime.SIM_1COMPL or sim == runtime.SIM_SIGNMT) {
        const y_negative = (runtime.registerShortIntegerPtr(runtime.REGISTER_Y).* & runtime.shortIntegerSignBit) != 0;
        const x_negative = (runtime.registerShortIntegerPtr(runtime.REGISTER_X).* & runtime.shortIntegerSignBit) != 0;
        signs_differ = y_negative != x_negative;
    }

    var scale: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&scale[0]);
    defer runtime.__gmpz_clear(&scale[0]);
    setPowerOfTwo(&scale[0], word_size);

    var y_value: runtime.longInteger_t = undefined;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_Y, &y_value);
    defer runtime.__gmpz_clear(&y_value[0]);

    var x_value: runtime.longInteger_t = undefined;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_X, &x_value);
    defer runtime.__gmpz_clear(&x_value[0]);

    var product: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&product[0]);
    defer runtime.__gmpz_clear(&product[0]);
    runtime.__gmpz_mul(&product[0], &y_value[0], &x_value[0]);

    if (sim == runtime.SIM_1COMPL) {
        if (signs_differ) {
            runtime.__gmpz_sub_ui(&product[0], &product[0], 1);
        }
        runtime.shortIntegerMode = runtime.SIM_2COMPL;
    } else if (sim == runtime.SIM_SIGNMT) {
        setPositiveSign(&product[0]);
        runtime.shortIntegerMode = runtime.SIM_UNSIGN;
    }

    runtime.__gmpz_tdiv_qr(&x_value[0], &y_value[0], &product[0], &scale[0]);

    if (sim == runtime.SIM_SIGNMT) {
        runtime.shortIntegerMode = runtime.SIM_SIGNMT;
        if (signs_differ) {
            setNegativeSign(&x_value[0]);
        }
    }

    runtime.convertLongIntegerToShortIntegerRegister(&y_value[0], base, runtime.REGISTER_Y);
    runtime.convertLongIntegerToShortIntegerRegister(&x_value[0], base, runtime.REGISTER_X);
    runtime.clearSystemFlag(runtime.FLAG_OVERFLOW);
}

fn reportDblDivideTypeError(reg: runtime.calcRegister_t) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    _ = runtime.getRegisterDataType(reg);
    runtime.moreInfoOnError("In function dblDivide:", "the input type is not allowed for DBL divide!", null, null);
}

fn reportDblDivideZeroDivisor() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    runtime.moreInfoOnError("In function dblDivide:", "cannot divide a short integer by 0", null, null);
}

fn reportDblDivideOverflow() void {
    runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE, runtime.REGISTER_T);
    runtime.moreInfoOnError("In function dblDivide:", "quotient overflow", null, null);
}

fn requireDblDivideShortInteger(reg: runtime.calcRegister_t) bool {
    if (runtime.getRegisterDataType(reg) == runtime.dtShortInteger) {
        return true;
    }

    reportDblDivideTypeError(reg);
    return false;
}

fn dblDivideOwned(remainder_mode: bool) void {
    if (!requireDblDivideShortInteger(runtime.REGISTER_X) or
        !requireDblDivideShortInteger(runtime.REGISTER_Y) or
        !requireDblDivideShortInteger(runtime.REGISTER_Z))
    {
        return;
    }

    const sim = runtime.shortIntegerMode;
    const word_size: u32 = runtime.shortIntegerWordSize;

    var divisor: runtime.longInteger_t = undefined;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_X, &divisor);
    defer runtime.__gmpz_clear(&divisor[0]);

    if (divisor[0]._mp_size == 0) {
        reportDblDivideZeroDivisor();
        return;
    }

    var scale: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&scale[0]);
    defer runtime.__gmpz_clear(&scale[0]);
    setPowerOfTwo(&scale[0], word_size);

    var dividend_hi: runtime.longInteger_t = undefined;
    var dividend_lo: runtime.longInteger_t = undefined;
    runtime.shortIntegerMode = runtime.SIM_UNSIGN;
    defer runtime.shortIntegerMode = sim;
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_Z, &dividend_lo);
    defer runtime.__gmpz_clear(&dividend_lo[0]);
    initShortIntegerRegisterAsLongInteger(runtime.REGISTER_Y, &dividend_hi);
    defer runtime.__gmpz_clear(&dividend_hi[0]);

    const base = runtime.getRegisterTag(runtime.REGISTER_Y);

    var dividend: runtime.longInteger_t = undefined;
    runtime.__gmpz_init(&dividend[0]);
    defer runtime.__gmpz_clear(&dividend[0]);
    runtime.__gmpz_mul(&dividend[0], &dividend_hi[0], &scale[0]);
    runtime.__gmpz_add(&dividend[0], &dividend[0], &dividend_lo[0]);

    if (sim != runtime.SIM_UNSIGN) {
        setPowerOfTwo(&scale[0], word_size * 2 - 1);
        if (runtime.__gmpz_cmp(&dividend[0], &scale[0]) >= 0) {
            if (sim == runtime.SIM_SIGNMT) {
                runtime.__gmpz_sub(&dividend[0], &dividend[0], &scale[0]);
                setNegativeSign(&dividend[0]);
            } else {
                setPowerOfTwo(&scale[0], word_size * 2);
                if (sim == runtime.SIM_1COMPL) {
                    runtime.__gmpz_sub_ui(&scale[0], &scale[0], 1);
                }
                runtime.__gmpz_sub(&dividend[0], &scale[0], &dividend[0]);
                setNegativeSign(&dividend[0]);
            }
        }
        setPowerOfTwo(&scale[0], word_size - 1);
    }

    runtime.__gmpz_tdiv_qr(&dividend_lo[0], &dividend_hi[0], &dividend[0], &divisor[0]);

    if (remainder_mode) {
        if (!runtime.saveLastX()) {
            return;
        }
        runtime.convertLongIntegerToShortIntegerRegister(&dividend_hi[0], base, runtime.REGISTER_X);
    } else {
        setPositiveSign(&scale[0]);
        if (runtime.__gmpz_cmp(&dividend_lo[0], &scale[0]) >= 0) {
            reportDblDivideOverflow();
            return;
        }

        if (sim != runtime.SIM_UNSIGN) {
            setNegativeSign(&scale[0]);
            const quotient_cmp = runtime.__gmpz_cmp(&dividend_lo[0], &scale[0]);
            if (quotient_cmp < 0 or (sim != runtime.SIM_2COMPL and quotient_cmp == 0)) {
                reportDblDivideOverflow();
                return;
            }
        }

        if (!runtime.saveLastX()) {
            return;
        }

        runtime.convertLongIntegerToShortIntegerRegister(&dividend_lo[0], base, runtime.REGISTER_X);

        if (dividend_hi[0]._mp_size == 0) {
            runtime.clearSystemFlag(runtime.FLAG_CARRY);
        } else {
            runtime.setSystemFlag(runtime.FLAG_CARRY);
        }

        runtime.clearSystemFlag(runtime.FLAG_OVERFLOW);
    }

    runtime.fnDropY(0);
    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        runtime.fnDropY(0);
    }
}

pub fn dblMultiply(unused_but_mandatory_parameter: u16) void {
    if (build_options.use_fake_wp34s_model) {
        dblMultiplyOwned();
        return;
    }

    legacy.fnDblMultiply(unused_but_mandatory_parameter);
}

pub fn dblDivide(unused_but_mandatory_parameter: u16) void {
    if (build_options.use_fake_wp34s_model) {
        dblDivideOwned(false);
        return;
    }

    legacy.fnDblDivide(unused_but_mandatory_parameter);
}

pub fn dblDivideRemainder(unused_but_mandatory_parameter: u16) void {
    if (build_options.use_fake_wp34s_model) {
        dblDivideOwned(true);
        return;
    }

    legacy.fnDblDivideRemainder(unused_but_mandatory_parameter);
}