const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const mpz_struct = runtime.mpz_struct;

// The context an exact result rounds to: Real34, narrowed to the selected
// significant digits when SDIGS is set.
fn parallelResultContext(real_context: *runtime.realContext_t) void {
    real_context.* = runtime.ctxtReal34;
    if (runtime.significantDigits > 0 and runtime.significantDigits < 34) {
        real_context.digits = runtime.significantDigits;
    }
}

// The value of an integer or Real34 register, read exactly and rounded once at
// the result context.
fn parallelExactRegister(regist: runtime.calcRegister_t, result: *real_t) bool {
    var exponent: i32 = undefined;
    var coefficient: mpz_struct = undefined;
    var real_context: runtime.realContext_t = undefined;

    if (!runtime.convertRegisterToScaledLongInteger(regist, &coefficient, &exponent)) {
        return false;
    }
    parallelResultContext(&real_context);
    runtime.convertScaledLongIntegerToReal(&coefficient, exponent, result, &real_context);
    runtime.__gmpz_clear(&coefficient);
    return true;
}

// y || x = xy / (x + y) on two integer or Real34 registers, formed exactly on
// scaled integers and divided once at the result context.
fn parallelExactRegisters(result: *real_t) bool {
    var x_exponent: i32 = undefined;
    var y_exponent: i32 = undefined;
    var sum_exponent: i32 = undefined;
    var x: mpz_struct = undefined;
    var y: mpz_struct = undefined;
    var product: mpz_struct = undefined;
    var sum: mpz_struct = undefined;
    var real_context: runtime.realContext_t = undefined;

    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_X, &x, &x_exponent)) {
        return false;
    }
    if (!runtime.convertRegisterToScaledLongInteger(runtime.REGISTER_Y, &y, &y_exponent)) {
        runtime.__gmpz_clear(&x);
        return false;
    }
    if (runtime.longIntegerIsZero(&x) or runtime.longIntegerIsZero(&y)) {
        runtime.__gmpz_clear(&y);
        runtime.__gmpz_clear(&x);
        return false;
    }

    runtime.__gmpz_init(&product);
    runtime.__gmpz_mul(&product, &x, &y);
    runtime.addSubtractScaledLongIntegers(&x, x_exponent, &y, y_exponent, false, &sum, &sum_exponent);
    parallelResultContext(&real_context);
    const ok = runtime.divideScaledLongIntegersToReal(&product, x_exponent + y_exponent, false, &sum, sum_exponent, result, &real_context);
    runtime.__gmpz_clear(&sum);
    runtime.__gmpz_clear(&product);
    runtime.__gmpz_clear(&y);
    runtime.__gmpz_clear(&x);
    return ok;
}

fn doParallelReal() callconv(.c) void {
    var y_value: real_t = undefined;
    var x_value: real_t = undefined;
    var product: real_t = undefined;
    var exact_result: real_t = undefined;
    const type_x = runtime.getRegisterDataType(runtime.REGISTER_X);
    const type_y = runtime.getRegisterDataType(runtime.REGISTER_Y);

    // An infinite resistor in parallel with an integer leaves the integer, read exactly.
    if (type_x == runtime.dtLongInteger and type_y == runtime.dtReal34 and runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_Y))) {
        _ = parallelExactRegister(runtime.REGISTER_X, &exact_result);
        runtime.convertRealToResultRegister(&exact_result, runtime.REGISTER_X, runtime.amNone);
        return;
    }
    if (type_y == runtime.dtLongInteger and type_x == runtime.dtReal34 and runtime.real34IsInfinite(runtime.registerReal34Ptr(runtime.REGISTER_X))) {
        _ = parallelExactRegister(runtime.REGISTER_Y, &exact_result);
        runtime.convertRealToResultRegister(&exact_result, runtime.REGISTER_X, runtime.amNone);
        return;
    }
    if ((type_x == runtime.dtLongInteger or type_y == runtime.dtLongInteger) and parallelExactRegisters(&exact_result)) {
        runtime.convertRealToResultRegister(&exact_result, runtime.REGISTER_X, runtime.amNone);
        return;
    }

    if (!runtime.getRegisterAsReal(runtime.REGISTER_X, &x_value) or !runtime.getRegisterAsReal(runtime.REGISTER_Y, &y_value)) {
        return;
    }

    if (runtime.realIsNaN(&x_value) or runtime.realIsNaN(&y_value)) {
        runtime.realSetNaN(&x_value);
    } else if (!runtime.realIsZero(&x_value)) {
        if (runtime.realIsZero(&y_value)) {
            x_value = y_value;
        } else if (runtime.realIsInfinite(&x_value)) {
            if (runtime.realIsInfinite(&y_value)) {
                runtime.realSetNaN(&x_value);
            } else {
                x_value = y_value;
            }
        } else if (!runtime.realIsInfinite(&y_value)) {
            // y || x = xy / (x+y)
            runtime.realMultiply(&y_value, &x_value, &product, &runtime.ctxtReal39);
            runtime.realAdd(&y_value, &x_value, &y_value, &runtime.ctxtReal39);
            runtime.realDivide(&product, &y_value, &x_value, &runtime.ctxtReal39);
        }
    }
    runtime.convertRealToResultRegister(&x_value, runtime.REGISTER_X, runtime.amNone);
}

fn doParallelComplex() callconv(.c) void {
    var denominator: real_t = undefined;
    var y: cplx_t = undefined;
    var x: cplx_t = undefined;
    var product: cplx_t = undefined;
    var sum: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x) or !runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y)) {
        return;
    }

    const x_is_zero = runtime.realIsZero(&x.Real) and runtime.realIsZero(&x.Imag);
    const y_is_zero = runtime.realIsZero(&y.Real) and runtime.realIsZero(&y.Imag);
    const x_is_infinite = runtime.realIsInfinite(&x.Real) or runtime.realIsInfinite(&x.Imag);
    const y_is_infinite = runtime.realIsInfinite(&y.Real) or runtime.realIsInfinite(&y.Imag);

    if (runtime.realIsNaN(&x.Real) or runtime.realIsNaN(&x.Imag) or runtime.realIsNaN(&y.Real) or runtime.realIsNaN(&y.Imag)) {
        runtime.realSetNaN(&x.Real);
        runtime.realSetNaN(&x.Imag);
    } else if (!x_is_zero) {
        if (y_is_zero) {
            x = y;
        } else if (x_is_infinite) {
            if (y_is_infinite) {
                runtime.realSetNaN(&x.Real);
                runtime.realSetNaN(&x.Imag);
            } else {
                x = y;
            }
        } else if (!y_is_infinite) {
            // y || x = xy / (x + y), the quotient formed as xy times the conjugate of the sum over |sum|^2
            runtime.mulComplexComplex(&y, &x, &product, &runtime.ctxtReal75);
            runtime.realAdd(&y.Real, &x.Real, &sum.Real, &runtime.ctxtReal75);
            runtime.realAdd(&y.Imag, &x.Imag, &sum.Imag, &runtime.ctxtReal75);

            runtime.realChangeSign(&sum.Imag);
            runtime.mulComplexComplex(&product, &sum, &x, &runtime.ctxtReal75);
            runtime.realMultiply(&sum.Real, &sum.Real, &denominator, &runtime.ctxtReal39);
            runtime.realFMA(&sum.Imag, &sum.Imag, &denominator, &denominator, &runtime.ctxtReal39);
            runtime.realDivide(&x.Real, &denominator, &x.Real, &runtime.ctxtReal39);
            runtime.realDivide(&x.Imag, &denominator, &x.Imag, &runtime.ctxtReal39);
        }
    }
    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

pub fn parallel(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    runtime.processRealComplexDyadicFunction(&doParallelReal, &doParallelComplex);
}
