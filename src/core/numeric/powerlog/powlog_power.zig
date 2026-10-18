const runtime = @import("../command_wrappers/runtime.zig");
const transcendental_command_owned = @import("../special/transcendental_command.zig");

// The exported intPowReal / intPowCplx take this pointer across the C boundary,
// so the two base powers carry the C calling convention.
pub const PowRealFn = *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) callconv(.c) void;

// decQuad limits (decQuad.h): the exponent range an integer power of ten can
// take without leaving the Real34 range once the fractional part is applied.
const DECQUAD_Emax: i32 = 6144;
const DECQUAD_Emin: i32 = -6143;
const DECQUAD_Pmax: i32 = 34;

/// 10^x. An integer part of x within the Real34 exponent range moves the
/// decimal exponent of 10^fraction directly, so a power of ten is exact.
pub fn realPower10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var conversion_error: bool = undefined;

    if (!runtime.realIsSpecial(x)) {
        const exponent = runtime.realToInt32C47(x, &conversion_error);
        if (!conversion_error and exponent <= DECQUAD_Emax and exponent >= DECQUAD_Emin - DECQUAD_Pmax + 1 and exponent < real_context.emax and exponent > real_context.emin) {
            var integer_part: runtime.real_t = undefined;

            runtime.int32ToReal(exponent, &integer_part);
            runtime.realSubtract(x, &integer_part, res, real_context);
            if (runtime.realIsZero(res)) {
                runtime.realSetOne(res);
            } else {
                runtime.realMultiply(res, runtime.z47_math_wrappers_const_ln10(), res, real_context);
                transcendental_command_owned.realExp(res, res, real_context);
            }
            res.exponent += exponent;
            return;
        }
    }

    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln10(), res, real_context);
    transcendental_command_owned.realExp(res, res, real_context);
}

/// 2^x. The integer part of x is raised exactly by realPower and the
/// fraction's factor multiplies it, so a power of two is exact.
pub fn realPower2(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) callconv(.c) void {
    var conversion_error: bool = undefined;

    if (!runtime.realIsSpecial(x)) {
        const exponent = runtime.realToInt32C47(x, &conversion_error);
        if (!conversion_error) {
            var integer_part: runtime.real_t = undefined;

            runtime.int32ToReal(exponent, &integer_part);
            runtime.realSubtract(x, &integer_part, res, real_context);
            if (runtime.realIsZero(res)) {
                runtime.realPower(runtime.z47_math_wrappers_const_2(), &integer_part, res, real_context);
            } else {
                var factor: runtime.real_t = undefined;

                runtime.realMultiply(res, runtime.z47_math_wrappers_const_ln2(), res, real_context);
                transcendental_command_owned.realExp(res, res, real_context);
                runtime.realPower(runtime.z47_math_wrappers_const_2(), &integer_part, &factor, real_context);
                runtime.realMultiply(&factor, res, res, real_context);
            }
            return;
        }
    }

    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln2(), res, real_context);
    transcendental_command_owned.realExp(res, res, real_context);
}

pub fn intPowReal(powf: PowRealFn) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsSpecial(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_int_pow_real_domain_error();
        return;
    }

    powf(&x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

/// base^x for a complex x: base^Re(x) scales the unit vector at the angle
/// Im(x).ln(base), the angle formed at 75 digits.
pub fn intPowCplx(powf: PowRealFn, ln_base: *const runtime.real_t) void {
    var x: runtime.cplx_t = undefined;
    var factor: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x.Imag)) {
        powf(&x.Real, &x.Real, &runtime.ctxtReal39);
        runtime.realSetZero(&x.Imag);
        runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
        return;
    }

    powf(&x.Real, &factor, &runtime.ctxtReal39);
    runtime.realMultiply(ln_base, &x.Imag, &x.Imag, &runtime.ctxtReal75);
    runtime.realPolarToRectangular(runtime.z47_math_wrappers_const_1(), &x.Imag, &x, &runtime.ctxtReal75);
    runtime.realMultiply(&factor, &x.Real, &x.Real, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &x.Imag, &x.Imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

fn longIntegerSetPositiveSign(value: *runtime.mpz_struct) void {
    if (value._mp_size < 0) {
        value._mp_size = -value._mp_size;
    }
}

fn smallBasePowerLonI(base_value: c_ulong, negative_exponent_callback: *const fn () callconv(.c) void) void {
    var exponent: runtime.longInteger_t = undefined;
    var base: runtime.longInteger_t = undefined;
    var power: runtime.longInteger_t = undefined;
    var exponent_sign: i32 = 0;

    runtime.__gmpz_init(&base[0]);
    runtime.__gmpz_set_ui(&base[0], base_value);
    runtime.convertLongIntegerRegisterToLongInteger(runtime.REGISTER_X, &exponent[0]);
    if (exponent[0]._mp_size < 0) {
        exponent_sign = -1;
    } else if (exponent[0]._mp_size > 0) {
        exponent_sign = 1;
    }
    defer runtime.__gmpz_clear(&base[0]);
    defer runtime.__gmpz_clear(&exponent[0]);

    longIntegerSetPositiveSign(&exponent[0]);

    if (exponent[0]._mp_size == 0) {
        runtime.__gmpz_set_ui(&base[0], 1);
        runtime.convertLongIntegerToLongIntegerRegister(&base[0], runtime.REGISTER_X);
        return;
    }

    if (exponent_sign < 0) {
        negative_exponent_callback();
        return;
    }

    runtime.__gmpz_init(&power[0]);
    defer runtime.__gmpz_clear(&power[0]);
    runtime.__gmpz_set_ui(&power[0], 1);

    // The width-checked operators are what ends this loop: the exponent is any
    // long integer the user can key in, and each pass squares the base, so the
    // refusal that sets lastErrorCode is the only bound on the operand.
    while (exponent[0]._mp_size != 0 and runtime.lastErrorCode == 0) {
        if ((exponent[0]._mp_d[0] & 1) != 0) {
            runtime.longIntegerMultiply(&power[0], &base[0], &power[0]);
        }

        _ = runtime.__gmpz_tdiv_q_ui(&exponent[0], &exponent[0], 2);

        if (exponent[0]._mp_size != 0) {
            runtime.longIntegerSquare(&base[0], &base[0]);
        }
    }

    runtime.convertLongIntegerToLongIntegerRegister(&power[0], runtime.REGISTER_X);
}

fn tenPowLonI() callconv(.c) void {
    smallBasePowerLonI(10, &tenPowReal);
}

fn twoPowLonI() callconv(.c) void {
    smallBasePowerLonI(2, &twoPowReal);
}

fn twoPowShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_int2pow(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn twoPowReal() callconv(.c) void {
    intPowReal(&realPower2);
}

fn twoPowCplx() callconv(.c) void {
    intPowCplx(&realPower2, runtime.z47_math_wrappers_const75_ln2());
}

fn tenPowShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_int10pow(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn tenPowReal() callconv(.c) void {
    intPowReal(&realPower10);
}

// The same shape as intPowCplx, with the 75-digit ln 10.
fn tenPowCplx() callconv(.c) void {
    var x: runtime.cplx_t = undefined;
    var factor: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x.Imag)) {
        realPower10(&x.Real, &x.Real, &runtime.ctxtReal39);
        runtime.realSetZero(&x.Imag);
        runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
        return;
    }

    realPower10(&x.Real, &factor, &runtime.ctxtReal39);
    runtime.realMultiply(runtime.z47_math_wrappers_const75_ln10(), &x.Imag, &x.Imag, &runtime.ctxtReal75);
    runtime.realPolarToRectangular(runtime.z47_math_wrappers_const_1(), &x.Imag, &x, &runtime.ctxtReal75);
    runtime.realMultiply(&factor, &x.Real, &x.Real, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &x.Imag, &x.Imag, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

pub fn fn2Pow(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&twoPowReal, &twoPowCplx, &twoPowShoI, &twoPowLonI);
}

pub fn fn10Pow(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&tenPowReal, &tenPowCplx, &tenPowShoI, &tenPowLonI);
}
