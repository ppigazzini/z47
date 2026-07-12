const runtime = @import("shortint_runtime.zig");
const shortint_core = @import("core.zig");

fn getShiftInput(word: *u64, base: *u32) bool {
    if (!runtime.getRegisterAsRawShortInt(runtime.REGISTER_X, word, base)) {
        runtime.invalidShortIntegerError(runtime.REGISTER_X);
        return false;
    }
    if (!runtime.saveLastX()) {
        return false;
    }
    return true;
}

fn setShiftResult(word: u64, base: u32) void {
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, base, word & runtime.shortIntegerMask);
}

fn setCarry(enabled: bool) void {
    runtime.forceSystemFlag(runtime.FLAG_CARRY, @as(c_int, @intFromBool(enabled)));
}

fn justifyResultToRegisters(count: u32, base: u32, value: u64) void {
    setShiftResult(value, base);
    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();
    runtime.setRawShortIntegerRegister(runtime.REGISTER_X, 10, count);
    runtime.convertShortIntegerRegisterToLongIntegerRegister(runtime.REGISTER_X, runtime.REGISTER_X);
}

fn topShift() u6 {
    return @intCast(runtime.shortIntegerWordSize - 1);
}

pub export fn fnAsr(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const r = shortint_core.arithmeticShiftRight(word, number_of_shifts, runtime.shortIntegerSignBit);
    if (r.carry) |c| setCarry(c);
    setShiftResult(r.word, base);
}

pub export fn fnSl(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const r = shortint_core.shiftLeft(word, number_of_shifts, runtime.shortIntegerSignBit);
    if (r.carry) |c| setCarry(c);
    setShiftResult(r.word, base);
}

pub export fn fnSr(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const r = shortint_core.shiftRight(word, number_of_shifts);
    if (r.carry) |c| setCarry(c);
    setShiftResult(r.word, base);
}

pub export fn fnRl(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const r = shortint_core.rotateLeft(word, number_of_shifts, runtime.shortIntegerSignBit);
    if (r.carry) |c| setCarry(c);
    setShiftResult(r.word, base);
}

pub export fn fnRr(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const r = shortint_core.rotateRight(word, number_of_shifts, topShift());
    if (r.carry) |c| setCarry(c);
    setShiftResult(r.word, base);
}

pub export fn fnRlc(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const carry_in = runtime.getSystemFlag(@as(i32, @intCast(runtime.FLAG_CARRY)));
    const r = shortint_core.rotateLeftThroughCarry(word, number_of_shifts, carry_in, runtime.shortIntegerSignBit);
    if (r.carry) |c| setCarry(c);
    setShiftResult(r.word, base);
}

pub export fn fnRrc(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const carry_in = runtime.getSystemFlag(@as(i32, @intCast(runtime.FLAG_CARRY)));
    const r = shortint_core.rotateRightThroughCarry(word, number_of_shifts, carry_in, topShift());
    if (r.carry) |c| setCarry(c);
    setShiftResult(r.word, base);
}

pub export fn fnLj(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const r = shortint_core.leftJustify(word, runtime.shortIntegerWordSize);
    justifyResultToRegisters(r.count, base, r.word);
}

pub export fn fnRj(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const r = shortint_core.rightJustify(word, runtime.shortIntegerWordSize, runtime.shortIntegerMask);
    justifyResultToRegisters(r.count, base, r.word);
}

pub export fn fnMirror(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    setShiftResult(shortint_core.mirrorBits(word, runtime.shortIntegerWordSize), base);
}

pub export fn fnSwapEndian(bit_width: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    // The command first grows the word size to a multiple of the swap
    // granularity; that resize is a side effect kept here, then the pure byte
    // reversal runs against the resolved word size.
    if (bit_width == 8) {
        if (runtime.shortIntegerWordSize < 16) {
            runtime.fnSetWordSize(16);
        } else if ((runtime.shortIntegerWordSize & @as(u8, @intCast(bit_width - 1))) != 0) {
            runtime.fnSetWordSize((runtime.shortIntegerWordSize | @as(u8, @intCast(bit_width - 1))) + 1);
        }
    } else if (bit_width == 16) {
        if (runtime.shortIntegerWordSize < 32) {
            runtime.fnSetWordSize(32);
        } else if ((runtime.shortIntegerWordSize & @as(u8, @intCast(bit_width - 1))) != 0) {
            runtime.fnSetWordSize((runtime.shortIntegerWordSize | @as(u8, @intCast(bit_width - 1))) + 1);
        }
    }

    setShiftResult(shortint_core.swapEndian(word, runtime.shortIntegerWordSize, bit_width), base);
}

pub export fn fnZip(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var x: u64 = undefined;
    var y: u64 = undefined;
    var base: u32 = undefined;

    if (!runtime.getRegisterAsRawShortInt(runtime.REGISTER_Y, &y, &base)) {
        runtime.invalidShortIntegerError(runtime.REGISTER_Y);
        return;
    }
    if (!getShiftInput(&x, &base)) return;

    const result = shortint_core.zipBits(x, y, runtime.shortIntegerWordSize);

    setShiftResult(result, base);
    runtime.adjustResult(runtime.REGISTER_X, true, true, runtime.REGISTER_X, runtime.REGISTER_Y, @as(runtime.calcRegister_t, -1));
}

pub export fn fnUnzip(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var a: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&a, &base)) return;

    runtime.setSystemFlag(runtime.FLAG_ASLIFT);
    runtime.liftStack();

    const unzipped = shortint_core.unzipBits(a, runtime.shortIntegerWordSize);

    runtime.setRawShortIntegerRegister(runtime.REGISTER_Y, base, unzipped.y & runtime.shortIntegerMask);
    setShiftResult(unzipped.x, base);
}
