const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const shortint_owned = @import("transform_shortint.zig");

fn squareLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    runtime.__gmpz_mul(&x[0], &x[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn squareShoI() callconv(.c) void {
    shortint_owned.shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        shortint_owned.shortIntegerData(runtime.REGISTER_X).*,
        shortint_owned.shortIntegerData(runtime.REGISTER_X).*,
    );
}

fn squareReal() callconv(.c) void {
    var x: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_square_real_domain_error();
        return;
    }

    runtime.realMultiply(&x, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn squareCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.mulComplexComplex(&a, &b, &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

fn cubeLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var cube_value: runtime.longInteger_t = undefined;

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }
    defer runtime.__gmpz_clear(&x[0]);

    runtime.__gmpz_init(&cube_value[0]);
    defer runtime.__gmpz_clear(&cube_value[0]);

    runtime.__gmpz_mul(&cube_value[0], &x[0], &x[0]);
    runtime.__gmpz_mul(&cube_value[0], &cube_value[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&cube_value[0], runtime.REGISTER_X);
}

fn cubeShoI() callconv(.c) void {
    const square_value = runtime.WP34S_intMultiply(
        shortint_owned.shortIntegerData(runtime.REGISTER_X).*,
        shortint_owned.shortIntegerData(runtime.REGISTER_X).*,
    );
    shortint_owned.shortIntegerData(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        square_value,
        shortint_owned.shortIntegerData(runtime.REGISTER_X).*,
    );
}

fn cubeReal() callconv(.c) void {
    var x: runtime.real_t = undefined;
    var x_squared: runtime.real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_cube_real_domain_error();
        return;
    }

    runtime.realMultiply(&x, &x, &x_squared, &runtime.ctxtReal39);
    runtime.realMultiply(&x_squared, &x, &x, &runtime.ctxtReal39);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

fn cubeCplx() callconv(.c) void {
    var a: runtime.real_t = undefined;
    var b: runtime.real_t = undefined;
    var real_square: runtime.real_t = undefined;
    var imag_square: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a, &b)) {
        return;
    }

    runtime.mulComplexComplex(&a, &b, &a, &b, &real_square, &imag_square, &runtime.ctxtReal39);
    runtime.mulComplexComplex(&real_square, &imag_square, &a, &b, &a, &b, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, &b, runtime.REGISTER_X);
}

pub fn square(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&squareReal, &squareCplx, &squareShoI, &squareLonI);
}

pub fn cube(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&cubeReal, &cubeCplx, &cubeShoI, &cubeLonI);
}
