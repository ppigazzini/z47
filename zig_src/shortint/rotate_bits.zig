const runtime = @import("shortint_runtime.zig");

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

    const sign = word & runtime.shortIntegerSignBit;
    var i: u16 = 0;
    while (i < number_of_shifts) : (i += 1) {
        if (i + 1 == number_of_shifts) {
            setCarry((word & 1) != 0);
        }
        word = (word >> 1) | sign;
    }
    setShiftResult(word, base);
}

pub export fn fnSl(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    var i: u16 = 0;
    while (i < number_of_shifts) : (i += 1) {
        if (i + 1 == number_of_shifts) {
            setCarry((word & runtime.shortIntegerSignBit) != 0);
        }
        word <<= 1;
    }
    setShiftResult(word, base);
}

pub export fn fnSr(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    var i: u16 = 0;
    while (i < number_of_shifts) : (i += 1) {
        if (i + 1 == number_of_shifts) {
            setCarry((word & 1) != 0);
        }
        word >>= 1;
    }
    setShiftResult(word, base);
}

pub export fn fnRl(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    var i: u16 = 0;
    while (i < number_of_shifts) : (i += 1) {
        const sign = (word & runtime.shortIntegerSignBit) != 0;
        if (i + 1 == number_of_shifts) {
            setCarry(sign);
        }
        word = (word << 1) | @as(u64, @intFromBool(sign));
    }
    setShiftResult(word, base);
}

pub export fn fnRr(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const shift = topShift();
    var i: u16 = 0;
    while (i < number_of_shifts) : (i += 1) {
        const lsb = word & 1;
        if (i + 1 == number_of_shifts) {
            setCarry(lsb != 0);
        }
        word = (word >> 1) | (lsb << shift);
    }
    setShiftResult(word, base);
}

pub export fn fnRlc(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    var carry: u64 = @intFromBool(runtime.getSystemFlag(@as(i32, @intCast(runtime.FLAG_CARRY))));
    var i: u16 = 0;
    while (i < number_of_shifts) : (i += 1) {
        const sign = @as(u64, @intFromBool((word & runtime.shortIntegerSignBit) != 0));
        word = (word << 1) | carry;
        carry = sign;
    }

    setCarry(carry != 0);
    setShiftResult(word, base);
}

pub export fn fnRrc(number_of_shifts: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const shift = topShift();
    var carry: u64 = @intFromBool(runtime.getSystemFlag(@as(i32, @intCast(runtime.FLAG_CARRY))));
    var i: u16 = 0;
    while (i < number_of_shifts) : (i += 1) {
        const lsb = word & 1;
        word = (word >> 1) | (carry << shift);
        carry = lsb;
    }

    setCarry(carry != 0);
    setShiftResult(word, base);
}

pub export fn fnLj(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    var count: u32 = runtime.shortIntegerWordSize;
    if (word != 0) {
        count = @intCast(@clz(word));
        count -= @as(u32, 64 - runtime.shortIntegerWordSize);
        word <<= @as(u6, @intCast(count));
    }

    justifyResultToRegisters(count, base, word);
}

pub export fn fnRj(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    var count: u32 = runtime.shortIntegerWordSize;
    if (word != 0) {
        count = @intCast(@ctz(word | ~runtime.shortIntegerMask));
        word >>= @as(u6, @intCast(count));
    }

    justifyResultToRegisters(count, base, word);
}

pub export fn fnMirror(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    var result: u64 = 0;
    var index: u8 = 0;
    while (index < runtime.shortIntegerWordSize) : (index += 1) {
        const src_shift: u6 = @intCast(index);
        if ((word & (@as(u64, 1) << src_shift)) != 0) {
            const dst_shift: u6 = @intCast(runtime.shortIntegerWordSize - index - 1);
            result |= @as(u64, 1) << dst_shift;
        }
    }

    setShiftResult(result, base);
}

fn byte(word: u64, shift: u6) u64 {
    return (word >> shift) & 0xff;
}

pub export fn fnSwapEndian(bit_width: u16) callconv(.c) void {
    var word: u64 = undefined;
    var base: u32 = undefined;
    if (!getShiftInput(&word, &base)) return;

    const b7 = byte(word, 56);
    const b6 = byte(word, 48);
    const b5 = byte(word, 40);
    const b4 = byte(word, 32);
    const b3 = byte(word, 24);
    const b2 = byte(word, 16);
    const b1 = byte(word, 8);
    const b0 = byte(word, 0);

    if (bit_width == 8) {
        if (runtime.shortIntegerWordSize < 16) {
            runtime.fnSetWordSize(16);
        } else if ((runtime.shortIntegerWordSize & @as(u8, @intCast(bit_width - 1))) != 0) {
            runtime.fnSetWordSize((runtime.shortIntegerWordSize | @as(u8, @intCast(bit_width - 1))) + 1);
        }

        switch (runtime.shortIntegerWordSize) {
            16 => word = (b0 << 8) | b1,
            24 => word = (b0 << 16) | (b1 << 8) | b2,
            32 => word = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3,
            40 => word = (b0 << 32) | (b1 << 24) | (b2 << 16) | (b3 << 8) | b4,
            48 => word = (b0 << 40) | (b1 << 32) | (b2 << 24) | (b3 << 16) | (b4 << 8) | b5,
            56 => word = (b0 << 48) | (b1 << 40) | (b2 << 32) | (b3 << 24) | (b4 << 16) | (b5 << 8) | b6,
            64 => word = (b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) | (b4 << 24) | (b5 << 16) | (b6 << 8) | b7,
            else => {},
        }
    } else if (bit_width == 16) {
        if (runtime.shortIntegerWordSize < 32) {
            runtime.fnSetWordSize(32);
        } else if ((runtime.shortIntegerWordSize & @as(u8, @intCast(bit_width - 1))) != 0) {
            runtime.fnSetWordSize((runtime.shortIntegerWordSize | @as(u8, @intCast(bit_width - 1))) + 1);
        }

        switch (runtime.shortIntegerWordSize) {
            32 => word = (b1 << 24) | (b0 << 16) | (b3 << 8) | b2,
            48 => word = (b1 << 40) | (b0 << 32) | (b3 << 24) | (b2 << 16) | (b5 << 8) | b4,
            64 => word = (b1 << 56) | (b0 << 48) | (b3 << 40) | (b2 << 32) | (b5 << 24) | (b4 << 16) | (b7 << 8) | b6,
            else => {},
        }
    }

    setShiftResult(word, base);
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

    var result: u64 = 0;
    var mask: u64 = 1;
    var shift: u8 = 0;
    var index: u8 = 0;
    const half_word = @divFloor(runtime.shortIntegerWordSize, 2);

    while (index < half_word) : (index += 1) {
        result |= (x & mask) << @as(u6, @intCast(shift));
        shift += 1;
        result |= (y & mask) << @as(u6, @intCast(shift));
        mask <<= 1;
    }

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

    var x: u64 = 0;
    var y: u64 = 0;
    var mask: u64 = 1;
    var shift: u8 = 0;
    var index: u8 = 0;
    const half_word = @divFloor(runtime.shortIntegerWordSize, 2);

    while (index < half_word) : (index += 1) {
        x |= (a & mask) >> @as(u6, @intCast(shift));
        shift += 1;
        mask <<= 1;
        y |= (a & mask) >> @as(u6, @intCast(shift));
        mask <<= 1;
    }

    runtime.setRawShortIntegerRegister(runtime.REGISTER_Y, base, y & runtime.shortIntegerMask);
    setShiftResult(x, base);
}
