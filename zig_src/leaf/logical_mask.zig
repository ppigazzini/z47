const core = @import("shortint_core.zig");
const runtime = @import("shortint_runtime.zig");

pub export fn fnMaskl(number_of_bits: u16) callconv(.c) void {
    if (number_of_bits > runtime.shortIntegerWordSize) {
        runtime.wordSizeError();
        return;
    }

    runtime.liftStack();
    const mask = core.maskLeft(runtime.shortIntegerWordSize, runtime.shortIntegerMask, number_of_bits);
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, 2, mask);
}

pub export fn fnMaskr(number_of_bits: u16) callconv(.c) void {
    if (number_of_bits > runtime.shortIntegerWordSize) {
        runtime.wordSizeError();
        return;
    }

    runtime.liftStack();
    const mask = core.maskRight(number_of_bits) & runtime.shortIntegerMask;
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, 2, mask);
}