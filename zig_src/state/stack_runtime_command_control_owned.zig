const build_options = @import("stack_state_build_options");
const conversion_owned = @import("stack_runtime_conversion_owned.zig");

const use_fake_stack_state_harness_surface =
    @hasDecl(build_options, "use_fake_stack_state_harness_surface") and
    build_options.use_fake_stack_state_harness_surface;

pub const calcRegister_t = i16;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Z: calcRegister_t = 102;
pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
pub const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
pub const LM_REGISTERS_PARTIAL: u16 = 6;
pub const manualLoad: u16 = 1;

extern fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void;
extern fn fnClearRegisters(confirmation: u16) callconv(.c) void;
extern fn setConfirmationMode(handler: *const fn (confirmation: u16) callconv(.c) void) void;
extern fn z47_registers_retained_sort_reg(range_start: u16, range_end: u16) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;

pub fn requestClearRegistersConfirmation() void {
    if (use_fake_stack_state_harness_surface) {
        conversion_owned.requestClearRegistersConfirmationRetained();
        return;
    }

    setConfirmationMode(&fnClearRegisters);
}

pub fn doPartialRegisterLoad(s: u16, n: u16, d: u16) void {
    if (use_fake_stack_state_harness_surface) {
        conversion_owned.doPartialRegisterLoadRetained(s, n, d);
        return;
    }

    doLoad(LM_REGISTERS_PARTIAL, s, n, d, manualLoad);
}

pub fn sortRegisterRange(range_start: u16, range_end: u16) void {
    z47_registers_retained_sort_reg(range_start, range_end);
}

pub fn reportRegisterCommandError(error_code: u8) void {
    if (use_fake_stack_state_harness_surface) {
        displayCalcErrorMessage(error_code, REGISTER_X, REGISTER_X);
        return;
    }

    displayCalcErrorMessage(error_code, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}