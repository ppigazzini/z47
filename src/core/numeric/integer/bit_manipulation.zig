// SPDX-License-Identifier: GPL-3.0-only
//
// Short-integer bit-manipulation commands: the operations that read, count, mask
// or toggle individual bits and bit-fields of the X-register word. This is the
// sibling of logical_boolean_ops (whole-word boolean logic) and rotate_bits
// (shifts and rotations); it collects the per-bit and mask operations that were
// split across three single-purpose files (count-bits, mask, set/clear/flip).
// Every entry is a dispatch-table command, so the symbols are unchanged.

const core = @import("core.zig");
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

pub export fn fnMaskl(number_of_bits: u16) callconv(.c) void {
    if (number_of_bits > runtime.shortIntegerWordSize) {
        runtime.wordSizeError("In function fnMaskl:", "MASKL", number_of_bits);
        return;
    }

    runtime.liftStack();
    const mask = core.maskLeft(runtime.shortIntegerWordSize, runtime.shortIntegerMask, number_of_bits);
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, 2, mask);
}

pub export fn fnMaskr(number_of_bits: u16) callconv(.c) void {
    if (number_of_bits > runtime.shortIntegerWordSize) {
        runtime.wordSizeError("In function fnMaskr:", "MASKR", number_of_bits);
        return;
    }

    runtime.liftStack();
    const mask = core.maskRight(number_of_bits) & runtime.shortIntegerMask;
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, 2, mask);
}

fn getBitOperand(
    function_name: [*:0]const u8,
    operation_name: []const u8,
    bit: u16,
    base: ?*u32,
    word: *u64,
    require_save_last_x: bool,
) bool {
    if (bit >= runtime.shortIntegerWordSize) {
        runtime.wordSizeError(function_name, operation_name, bit);
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
    if (!getBitOperand("In function fnCb:", "CB", bit, &base, &word, true)) return;

    // Masked like the other logical ops: keeps the result inside the word and
    // cleanses out-of-range values inherited from older saved states.
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, base, core.clearBit(word, bit) & runtime.shortIntegerMask);
}

pub export fn fnSb(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getBitOperand("In function fnSb:", "SB", bit, &base, &word, true)) return;

    // Masked like the other logical ops: keeps the result inside the word and
    // cleanses out-of-range values inherited from older saved states.
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, base, core.setBit(word, bit) & runtime.shortIntegerMask);
}

pub export fn fnFb(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getBitOperand("In function fnFb:", "FB", bit, &base, &word, true)) return;

    // Masked like the other logical ops: keeps the result inside the word and
    // cleanses out-of-range values inherited from older saved states.
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, base, core.flipBit(word, bit) & runtime.shortIntegerMask);
}

pub export fn fnBc(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    if (!getBitOperand("In function fnBc:", "BC?", bit, null, &word, false)) return;

    runtime.thereIsSomethingToUndo = false;
    runtime.setTemporaryInformation(core.isBitClear(word, bit));
}

pub export fn fnBs(bit: u16) callconv(.c) void {
    var word: u64 = undefined;
    if (!getBitOperand("In function fnBs:", "BS?", bit, null, &word, false)) return;

    runtime.thereIsSomethingToUndo = false;
    runtime.setTemporaryInformation(core.isBitSet(word, bit));
}
