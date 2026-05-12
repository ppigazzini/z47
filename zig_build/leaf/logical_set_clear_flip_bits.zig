const core = @import("shortint_core.zig");
const runtime = @import("shortint_runtime.zig");

fn getBitOperand(bit: u16, base: ?*u32, word: *u64, require_save_last_x: bool) bool {
    if (bit >= runtime.shortIntegerWordSize) {
        runtime.wordSizeError();
        return false;
    }

    if (!runtime.getRegisterAsRawShortInt(runtime.REGISTER_X, word, base)) {
        return false;
    }
    if (require_save_last_x and !runtime.saveLastX()) {
        return false;
    }
    return true;
}

pub export fn fnCb(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getBitOperand(bit, &base, &word, true)) return;

    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, base, core.clearBit(word, bit));
}

pub export fn fnSb(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getBitOperand(bit, &base, &word, true)) return;

    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, base, core.setBit(word, bit));
}

pub export fn fnFb(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getBitOperand(bit, &base, &word, true)) return;

    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, base, core.flipBit(word, bit));
}

pub export fn fnBc(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    if (!getBitOperand(bit, null, &word, false)) return;

    runtime.thereIsSomethingToUndo = false;
    runtime.setTemporaryInformation(core.isBitClear(word, bit));
}

pub export fn fnBs(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    if (!getBitOperand(bit, null, &word, false)) return;

    runtime.thereIsSomethingToUndo = false;
    runtime.setTemporaryInformation(core.isBitSet(word, bit));
}