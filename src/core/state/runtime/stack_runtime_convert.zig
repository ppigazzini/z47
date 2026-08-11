// The differential harness's surface for fnToReal and adjustResult.
//
// This file is NOT a second implementation of either. The shipping bodies are
// stack_result.zig's toReal / adjustResult and the helpers beside them; the
// wrappers in stack_runtime.zig route to this file only from inside
// `if (use_fake_stack_state_harness_surface)`, which is comptime-false in every
// product build, so the calls below exist purely to hand each step to the
// counting stub the parity runner links.
//
// It did carry a full second copy of both functions, reached from nowhere and
// analysed by nothing. Being unanalysed, it had drifted: the complex-matrix
// element loop addressed `.re` and `.im`, fields complex34_t does not have, so
// the body could not have compiled if any configuration had asked it to. That is
// what a divergent twin costs -- it looks like the implementation, and it is not
// even valid code.

const calcRegister_t = i16;

extern fn z47_stack_runtime_try_fn_to_real_complex_zero() bool;
extern fn z47_stack_runtime_try_fn_to_real_real34() bool;
extern fn z47_stack_runtime_try_fn_to_real_long_integer() bool;
extern fn z47_stack_runtime_try_fn_to_real_short_integer() bool;
extern fn z47_stack_runtime_try_fn_to_real_time() bool;
extern fn z47_stack_runtime_try_fn_to_real_date() bool;
extern fn z47_stack_runtime_adjust_result_scalar_core(res: calcRegister_t) bool;
extern fn z47_stack_runtime_adjust_result_real_matrix_core(res: calcRegister_t) bool;
extern fn z47_stack_runtime_adjust_result_complex_matrix_core(res: calcRegister_t) bool;
extern fn z47_stack_runtime_adjust_result_set_cpxres() void;

pub fn tryFnToRealComplexZero() bool {
    return z47_stack_runtime_try_fn_to_real_complex_zero();
}

pub fn tryFnToRealReal34() bool {
    return z47_stack_runtime_try_fn_to_real_real34();
}

pub fn tryFnToRealLongInteger() bool {
    return z47_stack_runtime_try_fn_to_real_long_integer();
}

pub fn tryFnToRealShortInteger() bool {
    return z47_stack_runtime_try_fn_to_real_short_integer();
}

pub fn tryFnToRealTime() bool {
    return z47_stack_runtime_try_fn_to_real_time();
}

pub fn tryFnToRealDate() bool {
    return z47_stack_runtime_try_fn_to_real_date();
}

pub fn adjustResultScalarCore(res: calcRegister_t) bool {
    return z47_stack_runtime_adjust_result_scalar_core(res);
}

pub fn adjustResultRealMatrixCore(res: calcRegister_t) bool {
    return z47_stack_runtime_adjust_result_real_matrix_core(res);
}

pub fn adjustResultComplexMatrixCore(res: calcRegister_t) bool {
    return z47_stack_runtime_adjust_result_complex_matrix_core(res);
}

pub fn adjustResultSetCpxRes() void {
    z47_stack_runtime_adjust_result_set_cpxres();
}
