const core = @import("shortint_core.zig");
const runtime = @import("shortint_runtime.zig");

pub export fn fnMaskl(numberOfBits: u16) callconv(.c) void {
    if (numberOfBits > runtime.shortIntegerWordSize) {
        runtime.wordSizeError();
        return;
    }

    runtime.liftStack();
    const mask = core.maskLeft(runtime.shortIntegerWordSize, runtime.shortIntegerMask, numberOfBits);
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, 2, mask);
}

pub export fn fnMaskr(numberOfBits: u16) callconv(.c) void {
    if (numberOfBits > runtime.shortIntegerWordSize) {
        runtime.wordSizeError();
        return;
    }

    runtime.liftStack();
    const mask = core.maskRight(numberOfBits) & runtime.shortIntegerMask;
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, 2, mask);
}