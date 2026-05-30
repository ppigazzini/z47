pub const calcRegister_t = i16;

extern fn z47_stack_runtime_get_stack_top() calcRegister_t;
extern fn z47_stack_runtime_real34_size_in_blocks() u16;
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
extern fn z47_stack_runtime_statistical_sums_blocks() u16;
extern fn z47_stack_runtime_statistical_sums_bytes() u32;
extern fn z47_stack_runtime_request_clear_registers_confirmation() void;
extern fn z47_stack_runtime_do_partial_register_load(s: u16, n: u16, d: u16) void;

pub fn getStackTop() calcRegister_t {
    return z47_stack_runtime_get_stack_top();
}

pub fn real34SizeInBlocks() u16 {
    return z47_stack_runtime_real34_size_in_blocks();
}

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

pub fn adjustResultSetCpxRes() void {
    z47_stack_runtime_adjust_result_set_cpxres();
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

pub fn statisticalSumsBlocks() u16 {
    return z47_stack_runtime_statistical_sums_blocks();
}

pub fn statisticalSumsBytes() u32 {
    return z47_stack_runtime_statistical_sums_bytes();
}

pub fn requestClearRegistersConfirmationRetained() void {
    z47_stack_runtime_request_clear_registers_confirmation();
}

pub fn doPartialRegisterLoadRetained(s: u16, n: u16, d: u16) void {
    z47_stack_runtime_do_partial_register_load(s, n, d);
}