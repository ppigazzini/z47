const core = @import("shortint_core.zig");
const runtime = @import("shortint_runtime.zig");

pub export fn fnCountBits(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!runtime.getRegisterAsRawShortInt(runtime.REGISTER_X, &word, &base) or !runtime.saveLastX()) {
        return;
    }

    runtime.convertUInt64ToShortIntegerRegister(0, core.countBits(word), base, runtime.REGISTER_X);
}