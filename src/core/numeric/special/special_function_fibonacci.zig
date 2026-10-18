const runtime = @import("../command_wrappers/runtime.zig");
const comparison_reals_owned = @import("../compare/comparison_reals.zig");
const transcendental_command_owned = @import("transcendental_command.zig");
const math_wp34s = @import("wp34s.zig");
const abi = @import("abi");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

// defines.h values.
const ERROR_MESSAGE_LENGTH: i32 = 512; // defines.h:2501
const TMP_STR_LENGTH: usize = 2560; // defines.h:2499
const SCREEN_WIDTH: i16 = 400; // defines.h:1504

fn copyReal(destination: *real_t, source: *const real_t) void {
    destination.* = source.*;
}

// fibLonI's over-the-limit refusal: render X into errorMessage, then wrap it in
// the sentence, exactly as the upstream sprintf pair does. Assembled by hand to
// keep std.fmt out of the firmware image.
fn reportFibonacciLimit() void {
    if (!runtime.extra_info_on_calc_error) {
        return;
    }

    runtime.longIntegerRegisterToDisplayString(runtime.REGISTER_X, runtime.errorMessage, ERROR_MESSAGE_LENGTH, SCREEN_WIDTH, 50, false);

    const prefix = "cannot calculate fib(";
    const suffix = "), the limit is 4791, it's to ensure that the 3328 bits limit is not exceeded";
    @memcpy(runtime.tmpString[0..prefix.len], prefix);
    var length: usize = prefix.len;
    var i: usize = 0;
    while (runtime.errorMessage[i] != 0 and length < TMP_STR_LENGTH - suffix.len - 1) : (i += 1) {
        runtime.tmpString[length] = runtime.errorMessage[i];
        length += 1;
    }
    @memcpy(runtime.tmpString[length..][0..suffix.len], suffix);
    runtime.tmpString[length + suffix.len] = 0;
    runtime.moreInfoOnError("In function fibLonI:", @ptrCast(runtime.tmpString), null, null);
}

fn fibLonI() callconv(.c) void {
    var value: runtime.longInteger_t = undefined;
    var result: runtime.longInteger_t = undefined;

    // The reader initialises its value on every path, refusals included, so the
    // clear has to cover the failure branch too.
    defer runtime.__gmpz_clear(&value[0]);

    if (!runtime.getRegisterAsLongInt(runtime.REGISTER_X, &value[0], null)) {
        return;
    }

    const neg = runtime.longIntegerIsNegative(&value[0]);
    if (neg) {
        value[0]._mp_size = -value[0]._mp_size;
    }

    if (runtime.__gmpz_cmp_ui(&value[0], 4791) > 0) {
        runtime.displayCalcErrorMessage(runtime.ERROR_OUT_OF_RANGE, runtime.ERR_REGISTER_LINE);
        reportFibonacciLimit();
        return;
    }

    runtime.__gmpz_init(&result[0]);
    defer runtime.__gmpz_clear(&result[0]);

    runtime.z47_math_wrappers_long_integer_fibonacci(@intCast(runtime.__gmpz_get_ui(&value[0])), &result[0]);
    if (neg and !runtime.longIntegerIsOdd(&value[0])) {
        result[0]._mp_size = -result[0]._mp_size;
    }

    runtime.convertLongIntegerToLongIntegerRegister(&result[0], runtime.REGISTER_X);
}

fn fibonacciConstants(lnPhi: *real_t, sqrt5: *real_t, real_context: *realContext_t) void {
    runtime.realSquareRoot(runtime.z47_math_wrappers_const_5(), sqrt5, real_context);
    runtime.realAdd(sqrt5, runtime.z47_math_wrappers_const_1(), lnPhi, real_context);
    runtime.realMultiply(lnPhi, runtime.z47_math_wrappers_const_1on2(), lnPhi, real_context);
    math_wp34s.WP34S_Ln(lnPhi, lnPhi, real_context);
}

fn cosinePiComplex(z: *const cplx_t, res: *cplx_t, real_context: *realContext_t) void {
    var sinReal: real_t = undefined;
    var cosReal: real_t = undefined;
    var sinhImag: real_t = undefined;
    var coshImag: real_t = undefined;
    var piImag: real_t = undefined;
    const pi: *const real_t = if (real_context.digits > 51) runtime.z47_math_wrappers_const75_pi() else runtime.z47_math_wrappers_const_pi();

    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&z.Real, runtime.amMultPi, &sinReal, &cosReal, null, real_context);
    runtime.realMultiply(&z.Imag, pi, &piImag, real_context);
    math_wp34s.WP34S_SinhCosh(&piImag, &sinhImag, &coshImag, real_context);
    runtime.multiplyTrigByHyperbolic(&cosReal, &coshImag, &res.Real, real_context);
    runtime.multiplyTrigByHyperbolic(&sinReal, &sinhImag, &res.Imag, real_context);
    runtime.realChangeSign(&res.Imag);
}

fn sinePiHalfComplex(z: *const cplx_t, res: *cplx_t, real_context: *realContext_t) void {
    var halfReal: real_t = undefined;
    var sinReal: real_t = undefined;
    var cosReal: real_t = undefined;
    var sinhImag: real_t = undefined;
    var coshImag: real_t = undefined;
    var piImag: real_t = undefined;
    const piOn2: *const real_t = if (real_context.digits > 51) runtime.z47_math_wrappers_const75_piOn2() else runtime.z47_math_wrappers_const_piOn2();

    runtime.realMultiply(&z.Real, runtime.z47_math_wrappers_const_1on2(), &halfReal, real_context);
    math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&halfReal, runtime.amMultPi, &sinReal, &cosReal, null, real_context);
    runtime.realMultiply(&z.Imag, piOn2, &piImag, real_context);
    math_wp34s.WP34S_SinhCosh(&piImag, &sinhImag, &coshImag, real_context);
    runtime.multiplyTrigByHyperbolic(&sinReal, &coshImag, &res.Real, real_context);
    runtime.multiplyTrigByHyperbolic(&cosReal, &sinhImag, &res.Imag, real_context);
}

fn FibonacciReal(n: *const real_t, res: *real_t, real_context: *realContext_t) u8 {
    // FIB(x) = [ PHI^(x) - PHI^(-x)*COS(PI * x) ] / SQRT(5)
    var a: real_t = undefined;
    var b: real_t = undefined;
    var lnPhi: real_t = undefined;
    var sqrt5: real_t = undefined;

    fibonacciConstants(&lnPhi, &sqrt5, real_context);
    runtime.realMultiply(&lnPhi, n, &a, real_context);

    if (comparison_reals_owned.realCompareAbsLessThan(n, abi.constants.const_1on10())) {
        var oneMinusCos: real_t = undefined;
        var sinHalf: real_t = undefined;

        copyReal(&b, &a);
        runtime.realChangeSign(&b);
        transcendental_command_owned.realExp(&b, &b, real_context);
        runtime.realAdd(&a, &a, &a, real_context);
        math_wp34s.WP34S_ExpM1(&a, &a, real_context);
        runtime.realMultiply(n, runtime.z47_math_wrappers_const_1on2(), &sinHalf, real_context);
        math_wp34s.C47_WP34S_Cvt2RadSinCosTan(&sinHalf, runtime.amMultPi, &sinHalf, null, null, real_context);
        runtime.realMultiply(&sinHalf, &sinHalf, &oneMinusCos, real_context);
        runtime.realAdd(&oneMinusCos, &oneMinusCos, &oneMinusCos, real_context);
        runtime.realAdd(&a, &oneMinusCos, &a, real_context);
        runtime.realMultiply(&a, &b, &a, real_context);
    } else {
        copyReal(&b, &a);
        runtime.realChangeSign(&b);
        transcendental_command_owned.realExp(&a, &a, real_context);
        transcendental_command_owned.realExp(&b, &b, real_context);
        math_wp34s.C47_WP34S_Cvt2RadSinCosTan(n, runtime.amMultPi, null, res, null, real_context);
        runtime.multiplyTrigByHyperbolic(res, &b, &b, real_context);
        runtime.realSubtract(&a, &b, &a, real_context);
    }

    runtime.realDivide(&a, &sqrt5, res, real_context);

    return runtime.ERROR_NONE;
}

fn FibonacciComplex(n: *const cplx_t, res: *cplx_t, real_context: *realContext_t) u8 {
    // FIB(x) = [ PHI^(x) - PHI^(-x)*COS(PI * x) ] / SQRT(5)
    var lnPhi: real_t = undefined;
    var sqrt5: real_t = undefined;
    var a: cplx_t = undefined;
    var b: cplx_t = undefined;

    fibonacciConstants(&lnPhi, &sqrt5, real_context);
    runtime.mulComplexReal(n, &lnPhi, &a, real_context);

    if (comparison_reals_owned.realCompareAbsLessThan(&n.Real, abi.constants.const_1on10()) and comparison_reals_owned.realCompareAbsLessThan(&n.Imag, abi.constants.const_1on10())) {
        var c: cplx_t = undefined;

        copyReal(&b.Real, &a.Real);
        copyReal(&b.Imag, &a.Imag);
        runtime.realChangeSign(&b.Real);
        runtime.realChangeSign(&b.Imag);
        transcendental_command_owned.expComplex(&b, &b, real_context);
        runtime.realAdd(&a.Real, &a.Real, &a.Real, real_context);
        runtime.realAdd(&a.Imag, &a.Imag, &a.Imag, real_context);
        transcendental_command_owned.expM1Complex(&a, &a, real_context);
        sinePiHalfComplex(n, &c, real_context);
        runtime.mulComplexComplex(&c, &c, &c, real_context);
        runtime.realAdd(&c.Real, &c.Real, &c.Real, real_context);
        runtime.realAdd(&c.Imag, &c.Imag, &c.Imag, real_context);
        runtime.realAdd(&a.Real, &c.Real, &a.Real, real_context);
        runtime.realAdd(&a.Imag, &c.Imag, &a.Imag, real_context);
        runtime.mulComplexComplex(&a, &b, &a, real_context);
    } else {
        copyReal(&b.Real, &a.Real);
        copyReal(&b.Imag, &a.Imag);
        runtime.realChangeSign(&b.Real);
        runtime.realChangeSign(&b.Imag);
        transcendental_command_owned.expComplex(&a, &a, real_context);
        transcendental_command_owned.expComplex(&b, &b, real_context);
        cosinePiComplex(n, res, real_context);
        runtime.mulComplexComplex(&b, res, &b, real_context);
        runtime.realSubtract(&a.Real, &b.Real, &a.Real, real_context);
        runtime.realSubtract(&a.Imag, &b.Imag, &a.Imag, real_context);
    }

    runtime.divComplexReal(&a, &sqrt5, res, real_context);

    return runtime.ERROR_NONE;
}

fn fibonacciRealContext(n: *const real_t) *realContext_t {
    if (comparison_reals_owned.realCompareAbsLessThan(n, abi.constants.const_1on10())) {
        return &runtime.ctxtReal39;
    }
    return if (runtime.realIsNegative(n)) &runtime.ctxtReal75 else &runtime.ctxtReal51;
}

fn fibReal() callconv(.c) void {
    // FIB(x) = [ PHI^(x) - PHI^(-x)*COS(PI * x) ] / SQRT(5)
    var x: real_t = undefined;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        _ = FibonacciReal(&x, &x, fibonacciRealContext(&x));
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    }
}

fn fibCplx() callconv(.c) void {
    var x: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x)) {
        return;
    }

    if (runtime.realIsZero(&x.Imag)) {
        _ = FibonacciReal(&x.Real, &x.Real, fibonacciRealContext(&x.Real));
    } else {
        _ = FibonacciComplex(&x, &x, &runtime.ctxtReal75);
    }

    runtime.convertComplexToResultRegister(&x, runtime.REGISTER_X);
}

pub fn fnFib(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(&fibReal, &fibCplx, null, &fibLonI);
}
