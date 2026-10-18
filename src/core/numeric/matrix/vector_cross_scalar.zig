const runtime = @import("../command_wrappers/runtime.zig");

fn crossReal() callconv(.c) void {
    runtime.convertRealToResultRegister(runtime.z47_math_wrappers_const_0(), runtime.REGISTER_X, runtime.amNone);
}

// Re(y) Im(x) - Re(x) Im(y) at 39 digits, with the residual of the rounded
// first product added back when every operand is finite.
pub export fn crossCplx() callconv(.c) void {
    var x: runtime.cplx_t = undefined;
    var y: runtime.cplx_t = undefined;
    var result_real: runtime.real_t = undefined;
    var p: runtime.real_t = undefined;
    var t: runtime.real_t = undefined;

    if (!runtime.getRegisterAsComplex(runtime.REGISTER_X, &x) or !runtime.getRegisterAsComplex(runtime.REGISTER_Y, &y)) {
        return;
    }

    runtime.realMultiply(&x.Real, &y.Imag, &p, &runtime.ctxtReal39); // p = RN(xReal * yImag)
    t = p;
    runtime.realChangeSign(&t);
    runtime.realFMA(&y.Real, &x.Imag, &t, &result_real, &runtime.ctxtReal39); // r = RN(yReal * xImag - p)
    if (!runtime.realIsSpecial(&x.Real) and !runtime.realIsSpecial(&x.Imag) and !runtime.realIsSpecial(&y.Real) and !runtime.realIsSpecial(&y.Imag)) {
        runtime.realFMA(&x.Real, &y.Imag, &t, &p, &runtime.ctxtReal39); // p = xReal * yImag - RN(xReal * yImag)
        runtime.realChangeSign(&p);
        runtime.realAdd(&result_real, &p, &result_real, &runtime.ctxtReal39); // add the product residual
    }
    runtime.convertRealToResultRegister(&result_real, runtime.REGISTER_X, runtime.amNone);
}

pub fn runScalarCross() void {
    runtime.processRealComplexDyadicFunction(&crossReal, &crossCplx);
}
