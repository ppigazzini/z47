const abi = @import("abi");
const runtime = @import("../command_wrappers/runtime.zig");

fn real34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return abi.registerReal34Aligned(regist);
}

fn imag34DataPointer(regist: runtime.calcRegister_t) *runtime.real34_t {
    return abi.registerImag34Aligned(regist);
}

pub fn readP(p: *runtime.real_t) bool {
    switch (runtime.getRegisterDataType(runtime.REGISTER_X)) {
        runtime.dtReal34 => {
            runtime.real34ToReal(real34DataPointer(runtime.REGISTER_X), p);
            return true;
        },
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(runtime.REGISTER_X, p, &runtime.ctxtReal75);
            return true;
        },
        else => return false,
    }
}

pub fn readCoeff(
    regist: runtime.calcRegister_t,
    data_type: u32,
    real_part: *runtime.real_t,
    imag_part: *runtime.real_t,
    real_coefs: *bool,
    data_tag: *runtime.angularMode_t,
) bool {
    switch (data_type) {
        runtime.dtLongInteger => {
            runtime.convertLongIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal75);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtShortInteger => {
            runtime.convertShortIntegerRegisterToReal(regist, real_part, &runtime.ctxtReal39);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtReal34 => {
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.getRegisterAngularMode(regist);
            return true;
        },
        runtime.dtTime => {
            runtime.convertTimeRegisterToReal34Register(regist, regist);
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtDate => {
            runtime.internalDateToJulianDay(real34DataPointer(regist), real34DataPointer(regist));
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            data_tag.* = runtime.amNone;
            return true;
        },
        runtime.dtComplex34 => {
            runtime.real34ToReal(real34DataPointer(regist), real_part);
            runtime.real34ToReal(imag34DataPointer(regist), imag_part);
            real_coefs.* = false;
            data_tag.* = runtime.amNone;
            return true;
        },
        else => return false,
    }
}

// --- exact interpolation ----------------------------------------------------
//
// With a long integer among X, Y and Z, and Y and Z integers or untagged
// reals, the interpolation a + p (b - a) is formed on scaled long integers and
// rounded once, to the display's significant digits (34 when unlimited).

// An endpoint as a real: a Real34 register as it is, any other register
// through its scaled long integer. False when the register has no exact form.
fn linpolExactEndpoint(regist: runtime.calcRegister_t, result: *runtime.real_t, real_context: *runtime.realContext_t) bool {
    var exponent: i32 = undefined;
    var coefficient: runtime.longInteger_t = undefined;

    if (runtime.getRegisterDataType(regist) == runtime.dtReal34) {
        runtime.real34ToReal(real34DataPointer(regist), result);
        return true;
    }
    if (!runtime.convertRegisterToScaledLongInteger(regist, &coefficient[0], &exponent)) {
        return false;
    }
    runtime.convertScaledLongIntegerToReal(&coefficient[0], exponent, result, real_context);
    runtime.__gmpz_clear(&coefficient[0]);
    return true;
}

// The exact interpolation of Z and Y by the amount p in X, or false when one
// of the registers has no scaled-long-integer form.
pub fn linpolExactRegisters(p_real: *const runtime.real_t, result: *runtime.real_t) bool {
    var a_exponent: i32 = undefined;
    var b_exponent: i32 = undefined;
    var p_exponent: i32 = undefined;
    var difference_exponent: i32 = undefined;
    var result_exponent: i32 = undefined;
    var a: runtime.longInteger_t = undefined;
    var b: runtime.longInteger_t = undefined;
    var p: runtime.longInteger_t = undefined;
    var difference: runtime.longInteger_t = undefined;
    var product: runtime.longInteger_t = undefined;
    var exact_result: runtime.longInteger_t = undefined;
    var result_context: runtime.realContext_t = runtime.ctxtReal34;

    if (runtime.significantDigits > 0 and runtime.significantDigits < 34) {
        result_context.digits = runtime.significantDigits;
    }
    if (runtime.realIsZero(p_real)) {
        return linpolExactEndpoint(runtime.REGISTER_Z, result, &result_context);
    }
    if (runtime.realCompareEqual(p_real, runtime.z47_math_wrappers_const_1())) {
        return linpolExactEndpoint(runtime.REGISTER_Y, result, &result_context);
    }

    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_Z, &a[0], &a_exponent)) {
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_Y, &b[0], &b_exponent)) {
        runtime.__gmpz_clear(&a[0]);
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_X, &p[0], &p_exponent)) {
        runtime.__gmpz_clear(&b[0]);
        runtime.__gmpz_clear(&a[0]);
        return false;
    }

    runtime.addSubtractScaledLongIntegers(&b[0], b_exponent, &a[0], a_exponent, true, &difference[0], &difference_exponent);
    runtime.__gmpz_init(&product[0]);
    runtime.__gmpz_mul(&product[0], &p[0], &difference[0]);
    const product_exponent = p_exponent + difference_exponent;
    runtime.addSubtractScaledLongIntegers(&a[0], a_exponent, &product[0], product_exponent, false, &exact_result[0], &result_exponent);
    runtime.convertScaledLongIntegerToReal(&exact_result[0], result_exponent, result, &result_context);
    runtime.__gmpz_clear(&exact_result[0]);
    runtime.__gmpz_clear(&product[0]);
    runtime.__gmpz_clear(&difference[0]);
    runtime.__gmpz_clear(&p[0]);
    runtime.__gmpz_clear(&b[0]);
    runtime.__gmpz_clear(&a[0]);
    return true;
}
