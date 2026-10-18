const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;

fn squareLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;

    // getRegisterAsLongInt initialises its output on every path, refusals
    // included, so the clear has to be registered before the refusal check.
    defer runtime.__gmpz_clear(&x[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }

    runtime.longIntegerMultiply(&x[0], &x[0], &x[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&x[0], runtime.REGISTER_X);
}

fn squareShoI() callconv(.c) void {
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn squareReal() callconv(.c) void {
    var x: real_t = undefined;

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsInfinite(&x) and !runtime.getSystemFlag(runtime.FLAG_SPCRES)) {
        runtime.z47_math_wrappers_report_square_real_domain_error();
        return;
    }

    runtime.realMultiply(&x, &x, &x, &runtime.ctxtReal34);
    runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
}

// Squares a complex number with a compensated real component.
fn squareComplex(z: *const cplx_t, squared: *cplx_t, real_context: *runtime.realContext_t) void {
    var product: real_t = undefined;
    var tmp: real_t = undefined;
    var term: real_t = undefined;
    var result: cplx_t = undefined;

    if (runtime.realIsSpecial(&z.Real) or runtime.realIsSpecial(&z.Imag)) {
        runtime.mulComplexComplex(z, z, squared, real_context);
        return;
    }

    // Real part: compensated a^2 - b^2
    runtime.realMultiply(&z.Real, &z.Real, &product, real_context);
    tmp = z.Imag;
    runtime.realChangeSign(&tmp);
    runtime.realFMA(&tmp, &z.Imag, &product, &term, real_context);
    runtime.realChangeSign(&product);
    runtime.realFMA(&z.Real, &z.Real, &product, &result.Real, real_context);
    runtime.realAdd(&result.Real, &term, &result.Real, real_context);

    // Imaginary part: 2ab
    runtime.realAdd(&z.Real, &z.Real, &tmp, real_context);
    runtime.realMultiply(&tmp, &z.Imag, &result.Imag, real_context);

    if (runtime.realIsZero(&result.Real)) {
        runtime.realSetZero(&result.Real);
    }
    if (runtime.realIsZero(&result.Imag)) {
        runtime.realSetZero(&result.Imag);
    }
    squared.Real = result.Real;
    squared.Imag = result.Imag;
}

fn squareCplx() callconv(.c) void {
    var a: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a)) {
        return;
    }

    squareComplex(&a, &a, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, runtime.REGISTER_X);
}

fn cubeLonI() callconv(.c) void {
    var x: runtime.longInteger_t = undefined;
    var cube_value: runtime.longInteger_t = undefined;

    // getRegisterAsLongInt initialises its output on every path, refusals
    // included, so the clear has to be registered before the refusal check.
    defer runtime.__gmpz_clear(&x[0]);
    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &x[0], null)) {
        return;
    }

    runtime.__gmpz_init(&cube_value[0]);
    defer runtime.__gmpz_clear(&cube_value[0]);

    runtime.longIntegerMultiply(&x[0], &x[0], &cube_value[0]);
    runtime.longIntegerMultiply(&cube_value[0], &x[0], &cube_value[0]);
    runtime.convertLongIntegerToLongIntegerRegister(&cube_value[0], runtime.REGISTER_X);
}

fn cubeShoI() callconv(.c) void {
    const square_value = runtime.WP34S_intMultiply(
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
    runtime.registerShortIntegerPtr(runtime.REGISTER_X).* = runtime.WP34S_intMultiply(
        square_value,
        runtime.registerShortIntegerPtr(runtime.REGISTER_X).*,
    );
}

fn cubeReal() callconv(.c) void {
    var x: real_t = undefined;
    var x_squared: real_t = undefined;

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

// Cubes a complex number with compensated component factors. An infinite part
// takes the cube's direction from three times the angle of the infinite octant.
fn cubeComplex(z: *const cplx_t, cubed: *cplx_t, real_context: *runtime.realContext_t) void {
    var factor: real_t = undefined;
    var product: real_t = undefined;
    var term: real_t = undefined;
    var correction: real_t = undefined;
    var result: cplx_t = undefined;

    if (runtime.realIsNaN(&z.Real) or runtime.realIsNaN(&z.Imag)) {
        runtime.realSetNaN(&cubed.Real);
        runtime.realSetNaN(&cubed.Imag);
        return;
    }

    if (runtime.realIsInfinite(&z.Real) or runtime.realIsInfinite(&z.Imag)) {
        runtime.setInfiniteComplexAngle((3 * runtime.getInfiniteComplexAngle(z)) % 8, cubed);
        return;
    }

    // Real part: a(a^2 - 3b^2)
    runtime.realMultiply(runtime.z47_math_wrappers_const_3(), &z.Imag, &factor, real_context);
    runtime.realMultiply(&z.Real, &z.Real, &product, real_context);
    runtime.realChangeSign(&factor);
    runtime.realFMA(&factor, &z.Imag, &product, &term, real_context);
    runtime.realChangeSign(&product);
    runtime.realFMA(&z.Real, &z.Real, &product, &correction, real_context);
    runtime.realAdd(&correction, &term, &correction, real_context);
    runtime.realMultiply(&z.Real, &correction, &result.Real, real_context);

    // Imaginary part: b(3a^2 - b^2)
    runtime.realMultiply(runtime.z47_math_wrappers_const_3(), &z.Real, &factor, real_context);
    runtime.realMultiply(&factor, &z.Real, &product, real_context);
    correction = z.Imag;
    runtime.realChangeSign(&correction);
    runtime.realFMA(&correction, &z.Imag, &product, &term, real_context);
    runtime.realChangeSign(&product);
    runtime.realFMA(&factor, &z.Real, &product, &correction, real_context);
    runtime.realAdd(&correction, &term, &correction, real_context);
    runtime.realMultiply(&z.Imag, &correction, &result.Imag, real_context);

    if (runtime.realIsZero(&result.Real)) {
        runtime.realSetZero(&result.Real);
    }
    if (runtime.realIsZero(&result.Imag)) {
        runtime.realSetZero(&result.Imag);
    }
    cubed.Real = result.Real;
    cubed.Imag = result.Imag;
}

fn cubeCplx() callconv(.c) void {
    var a: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &a)) {
        return;
    }

    cubeComplex(&a, &a, &runtime.ctxtReal39);
    runtime.convertComplexToResultRegister(&a, runtime.REGISTER_X);
}

pub fn square(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&squareReal, &squareCplx, &squareShoI, &squareLonI);
}

pub fn cube(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processIntRealComplexMonadicFunction(&cubeReal, &cubeCplx, &cubeShoI, &cubeLonI);
}
