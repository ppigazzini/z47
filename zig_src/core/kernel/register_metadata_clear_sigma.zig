const build_options = @import("register_metadata_build_options");
const stack_runtime = @import("stack_runtime.zig");
const register_metadata = @import("register_metadata.zig");
const register_metadata_variables = @import("register_metadata_variables.zig");
const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

pub const CONFIRMED: u16 = 9877;
pub const INVALID_VARIABLE: stack_runtime.calcRegister_t = @intCast(stack_runtime.INVALID_VARIABLE);

extern fn fnClSigma(confirmation: u16) callconv(.c) void;

pub fn clearSigma() void {
    if (!use_fake_register_metadata_harness_surface) {
        fnClSigma(CONFIRMED);
        return;
    }

    var register = register_metadata_variables.findNamedVariable("HISTO");
    if (register != INVALID_VARIABLE) {
        register_metadata.fnDeleteVariable(@intCast(register));
    }

    register = register_metadata_variables.findNamedVariable("STATS");
    if (register != INVALID_VARIABLE) {
        register_metadata.fnDeleteVariable(@intCast(register));
    }

    stack_runtime.lrChosen = 0;
    stack_runtime.freeC47Blocks(stack_runtime.statisticalSumsPointer, stack_runtime.statisticalSumsBlocks());
    stack_runtime.statisticalSumsPointer = null;
}
