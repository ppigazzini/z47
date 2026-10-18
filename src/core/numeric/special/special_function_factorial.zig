const runtime = @import("../command_wrappers/runtime.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const realContext_t = runtime.realContext_t;

// The integer factorial cells of factorial.c live behind the
// z47_math_wrappers_fact_* symbols: the LINUX-vs-mpz_fac_ui split, the
// mpz_init2 size hint, the unsigned-wraparound fact_uint64 kernel and the
// diagnostics that render the offending register are all single-sourced there.
// The real and complex cells are here.

// x! for a real X. An integer from 0 to 36 has an exact factorial in 34 digits,
// so that range runs at 34 digits and the result lands without a rounding step.
fn factReal() callconv(.c) void {
    var x: real_t = undefined;
    var firstInexact: real_t = undefined;
    var real_context: *realContext_t = &runtime.ctxtReal39;

    if (runtime.getRegisterAsReal(runtime.REGISTER_X, &x)) {
        runtime.uInt32ToReal(37, &firstInexact);
        if (!runtime.realIsSpecial(&x) and runtime.realIsAnInteger(&x) and
            runtime.realCompareGreaterEqual(&x, runtime.z47_math_wrappers_const_0()) and runtime.realCompareLessThan(&x, &firstInexact))
        {
            real_context = &runtime.ctxtReal34;
        }
        runtime.WP34S_Factorial(&x, &x, real_context);
        runtime.convertRealToResultRegister(&x, runtime.REGISTER_X, runtime.amNone);
    }
}

fn factCplx() callconv(.c) void {
    var z: cplx_t = undefined;

    if (runtime.getRegisterAsComplex(runtime.REGISTER_X, &z)) {
        runtime.realAdd(&z.Real, runtime.z47_math_wrappers_const_1(), &z.Real, &runtime.ctxtReal39);
        runtime.WP34S_ComplexGamma(&z, &z, &runtime.ctxtReal39);
        runtime.convertComplexToResultRegister(&z, runtime.REGISTER_X);
    }
}

pub fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(
        &factReal,
        &factCplx,
        &runtime.z47_math_wrappers_fact_short_integer,
        &runtime.z47_math_wrappers_fact_long_integer,
    );
}
