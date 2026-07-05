const build_options = @import("register_metadata_build_options");

const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

extern fn z47_register_metadata_request_delete_all_variables_confirmation() void;
extern fn z47_register_metadata_request_clear_all_variables_confirmation() void;
extern fn fnDeleteAllVariables(confirmation: u16) callconv(.c) void;
extern fn fnClearAllVariables(confirmation: u16) callconv(.c) void;
extern fn setConfirmationMode(handler: *const fn (confirmation: u16) callconv(.c) void) void;

pub fn requestDeleteAllVariablesConfirmation() void {
    if (use_fake_register_metadata_harness_surface) {
        z47_register_metadata_request_delete_all_variables_confirmation();
        return;
    }

    setConfirmationMode(&fnDeleteAllVariables);
}

pub fn requestClearAllVariablesConfirmation() void {
    if (use_fake_register_metadata_harness_surface) {
        z47_register_metadata_request_clear_all_variables_confirmation();
        return;
    }

    setConfirmationMode(&fnClearAllVariables);
}