const runtime = @import("../math_command_wrappers_runtime.zig");
const transcendental_command_owned = @import("../math_transcendental_command.zig");

fn realPower10(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln10(), res, real_context);
    transcendental_command_owned.realExp(res, res, real_context);
}

fn realPower2(
    x: *const runtime.real_t,
    res: *runtime.real_t,
    real_context: *runtime.realContext_t,
) void {
    runtime.realMultiply(x, runtime.z47_math_wrappers_const_ln2(), res, real_context);
    transcendental_command_owned.realExp(res, res, real_context);
}

fn intPowReal(powf: *const fn (x: *const runtime.real_t, res: *runtime.real_t, real_context: *runtime.realContext_t) void) void {
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

fn intPowCplx(ln_base: *const runtime.real_t) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var factor: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.realMultiply(ln_base, &a, &a, &runtime.ctxtReal39);
    runtime.realMultiply(ln_base, &b, &b, &runtime.ctxtReal39);

    transcendental_command_owned.realExp(&a, &factor, &runtime.ctxtReal39);
    runtime.realPolarToRectangular(runtime.z47_math_wrappers_const_1(), &b, &a, &b, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &a, &a, &runtime.ctxtReal39);
    runtime.realMultiply(&factor, &b, &b, &runtime.ctxtReal39);

    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
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

    while (exponent[0]._mp_size != 0 and runtime.lastErrorCode == 0) {
        if ((exponent[0]._mp_d[0] & 1) != 0) {
            runtime.__gmpz_mul(&power[0], &power[0], &base[0]);
        }

        _ = runtime.__gmpz_fdiv_q_ui(&exponent[0], &exponent[0], 2);

        if (exponent[0]._mp_size != 0) {
            runtime.__gmpz_mul(&base[0], &base[0], &base[0]);
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
    intPowReal(realPower2);
}

fn twoPowCplx() callconv(.c) void {
    intPowCplx(runtime.z47_math_wrappers_const_ln2());
}

fn tenPowShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_int10pow(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn tenPowReal() callconv(.c) void {
    intPowReal(realPower10);
}

fn tenPowCplx() callconv(.c) void {
    intPowCplx(runtime.z47_math_wrappers_const_ln10());
}

pub fn fn2Pow(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&twoPowReal, &twoPowCplx, &twoPowShoI, &twoPowLonI);
}

pub fn fn10Pow(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&tenPowReal, &tenPowCplx, &tenPowShoI, &tenPowLonI);
}
