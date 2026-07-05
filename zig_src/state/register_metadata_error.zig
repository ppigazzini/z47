const build_options = @import("register_metadata_build_options");
const stack_runtime = @import("stack_runtime.zig");

const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

pub const REGISTER_X = stack_runtime.REGISTER_X;
pub const REGISTER_Y = stack_runtime.REGISTER_Y;

extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: stack_runtime.calcRegister_t, err_register_line: stack_runtime.calcRegister_t) void;

fn reportError(error_code: u8) void {
    displayCalcErrorMessage(
        error_code,
        if (use_fake_register_metadata_harness_surface) REGISTER_X else stack_runtime.REGISTER_Z,
        if (use_fake_register_metadata_harness_surface) REGISTER_Y else REGISTER_X,
    );
}

pub fn reportRamFull() void {
    reportError(stack_runtime.ERROR_RAM_FULL);
}

pub fn reportInvalidName(error_invalid_name: u8) void {
    reportError(error_invalid_name);
}

pub fn reportUndefSourceVar(error_undef_source_var: u8) void {
    reportError(error_undef_source_var);
}

pub fn reportCannotDeletePredefItem(error_cannot_delete_predef_item: u8) void {
    reportError(error_cannot_delete_predef_item);
}

pub fn reportTooManyVariables(error_too_many_variables: u8) void {
    reportError(error_too_many_variables);
}