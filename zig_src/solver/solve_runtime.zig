pub const bool_t = bool;
pub const calcRegister_t = i16;

pub extern var currentSolverProgram: u16;

pub extern fn letteredRegisterName(regist: calcRegister_t) u8;
pub extern fn findNamedLabel(label_name: [*:0]const u8) calcRegister_t;
pub extern fn z47_solver_retained_fnIntegrate(label_or_variable: u16) void;
pub extern fn z47_solver_retained_fnIntegrateYX(label_or_variable: u16) void;
pub extern fn z47_solver_retained_fnProgrammableSum(label: u16) void;
pub extern fn z47_solver_retained_fnProgrammableProduct(label: u16) void;
pub extern fn z47_solver_retained_fnProgrammableiSum(label: u16) void;
pub extern fn z47_solver_retained_fnProgrammableiProduct(label: u16) void;
pub extern fn z47_solver_retained_fn1stDeriv(label: u16) void;

extern fn z47_solver_is_label(label: u16) bool_t;
extern fn z47_solver_is_stack_register(label: u16) bool_t;
extern fn z47_solver_is_invalid_variable(variable: u16) bool_t;
extern fn z47_solver_label_to_program(label: u16) u16;
extern fn z47_solver_report_label_not_found(buf: [*:0]const u8) void;
extern fn z47_solver_report_out_of_range(label: u16) void;
extern fn z47_solver_report_label_not_found_pgm_int(buf: [*:0]const u8) void;
extern fn z47_solver_report_out_of_range_pgm_int(label: u16) void;
extern fn z47_solver_clear_uses_formula_status() void;
extern fn z47_solver_tvm_begin_mode() void;
extern fn z47_solver_tvm_end_mode() void;

pub inline fn isLabel(label: u16) bool {
    return z47_solver_is_label(label);
}

pub inline fn isStackRegister(label: u16) bool {
    return z47_solver_is_stack_register(label);
}

pub inline fn isInvalidVariable(variable: u16) bool {
    return z47_solver_is_invalid_variable(variable);
}

pub inline fn labelToProgram(label: u16) u16 {
    return z47_solver_label_to_program(label);
}

pub inline fn reportLabelNotFound(buf: [*:0]const u8) void {
    z47_solver_report_label_not_found(buf);
}

pub inline fn reportOutOfRange(label: u16) void {
    z47_solver_report_out_of_range(label);
}

pub inline fn reportLabelNotFoundPgmInt(buf: [*:0]const u8) void {
    z47_solver_report_label_not_found_pgm_int(buf);
}

pub inline fn reportOutOfRangePgmInt(label: u16) void {
    z47_solver_report_out_of_range_pgm_int(label);
}

pub inline fn clearUsesFormulaStatus() void {
    z47_solver_clear_uses_formula_status();
}

pub inline fn tvmBeginMode() void {
    z47_solver_tvm_begin_mode();
}

pub inline fn tvmEndMode() void {
    z47_solver_tvm_end_mode();
}