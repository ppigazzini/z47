const runtime = @import("../command_wrappers/runtime.zig");

// The four factorial cells of factorial.c live behind the
// z47_math_wrappers_fact_* symbols: the LINUX-vs-mpz_fac_ui split, the
// mpz_init2 size hint, the unsigned-wraparound fact_uint64 kernel and the
// diagnostics that render the offending register are all single-sourced there,
// so this owner only wires the dispatch table.
pub fn fnFactorial(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    runtime.processIntRealComplexMonadicFunction(
        &runtime.z47_math_wrappers_fact_real,
        &runtime.z47_math_wrappers_fact_cplx,
        &runtime.z47_math_wrappers_fact_short_integer,
        &runtime.z47_math_wrappers_fact_long_integer,
    );
}
