const build_options = @import("register_metadata_build_options");
const stack_runtime = @import("stack_runtime.zig");

const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

pub const CONFIRMED: u16 = 9877;
pub const INVALID_VARIABLE: stack_runtime.calcRegister_t = @intCast(stack_runtime.INVALID_VARIABLE);

extern fn fnClSigma(confirmation: u16) callconv(.c) void;
extern fn fnDeleteVariable(regist: u16) callconv(.c) void;
extern fn findNamedVariable(variable_name: [*c]const u8) stack_runtime.calcRegister_t;

pub fn clearSigma() void {
    if (!use_fake_register_metadata_harness_surface) {
        fnClSigma(CONFIRMED);
        return;
    }

    var register = findNamedVariable("HISTO");
    if (register != INVALID_VARIABLE) {
        fnDeleteVariable(@intCast(register));
    }

    register = findNamedVariable("STATS");
    if (register != INVALID_VARIABLE) {
        fnDeleteVariable(@intCast(register));
    }

    stack_runtime.lrChosen = 0;
    stack_runtime.freeC47Blocks(stack_runtime.statisticalSumsPointer, stack_runtime.statisticalSumsBlocks());
    stack_runtime.statisticalSumsPointer = null;
}