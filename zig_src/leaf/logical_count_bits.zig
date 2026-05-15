const core = @import("shortint_core.zig");
const runtime = @import("shortint_runtime.zig");

pub export fn fnCountBits(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!runtime.getRegisterAsRawShortInt(runtime.REGISTER_X, &word, &base) or !runtime.saveLastX()) {
        return;
    }

    runtime.convertUInt64ToShortIntegerRegister(0, core.countBits(word), base, runtime.REGISTER_X);
}