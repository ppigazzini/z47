const std = @import("std");

pub fn maskLeft(word_size: u8, mask: u64, number_of_bits: u16) u64 {
    if (number_of_bits == 0) return 0;

    const bits: u8 = @intCast(number_of_bits);
    if (bits >= 64) return mask;

    const low_mask = (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
    return (low_mask & mask) << @as(u6, @intCast(word_size - bits));
}

pub fn maskRight(number_of_bits: u16) u64 {
    if (number_of_bits == 0) return 0;

    const bits: u8 = @intCast(number_of_bits);
    if (bits >= 64) return std.math.maxInt(u64);

    return (@as(u64, 1) << @as(u6, @intCast(bits))) - 1;
}

pub fn countBits(word: u64) u64 {
    return @popCount(word);
}

pub fn clearBit(word: u64, bit: u16) u64 {
    return word & ~(@as(u64, 1) << @as(u6, @intCast(bit)));
}

pub fn setBit(word: u64, bit: u16) u64 {
    return word | (@as(u64, 1) << @as(u6, @intCast(bit)));
}

pub fn flipBit(word: u64, bit: u16) u64 {
    return word ^ (@as(u64, 1) << @as(u6, @intCast(bit)));
}

pub fn isBitClear(word: u64, bit: u16) bool {
    return (word & (@as(u64, 1) << @as(u6, @intCast(bit)))) == 0;
}

pub fn isBitSet(word: u64, bit: u16) bool {
    return !isBitClear(word, bit);
}

/// The result of a justify: how far the value was shifted and the shifted word.
pub const JustifyResult = struct { count: u32, word: u64 };

/// The word after a shift/rotate and the CARRY to publish. `carry == null` means
/// leave CARRY unchanged, which a zero-count shift must do (the C only calls
/// setCarry on the final iteration, so no iterations touch nothing).
pub const ShiftResult = struct { word: u64, carry: ?bool };

/// Arithmetic shift right by `count` (ASR): the sign bit, sampled once from the
/// input, is fed back into the top on every step; CARRY is the last bit shifted
/// out. Result is unmasked (the caller re-masks to the word size).
pub fn arithmeticShiftRight(word_in: u64, count: u16, sign_bit: u64) ShiftResult {
    var word = word_in;
    const sign = word & sign_bit;
    var carry: ?bool = null;
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        if (i + 1 == count) carry = (word & 1) != 0;
        word = (word >> 1) | sign;
    }
    return .{ .word = word, .carry = carry };
}

/// Logical shift left by `count` (SL); CARRY is the last bit shifted out the top.
pub fn shiftLeft(word_in: u64, count: u16, sign_bit: u64) ShiftResult {
    var word = word_in;
    var carry: ?bool = null;
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        if (i + 1 == count) carry = (word & sign_bit) != 0;
        word <<= 1;
    }
    return .{ .word = word, .carry = carry };
}

/// Logical shift right by `count` (SR); CARRY is the last bit shifted out the bottom.
pub fn shiftRight(word_in: u64, count: u16) ShiftResult {
    var word = word_in;
    var carry: ?bool = null;
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        if (i + 1 == count) carry = (word & 1) != 0;
        word >>= 1;
    }
    return .{ .word = word, .carry = carry };
}

/// Rotate left by `count` (RL): the sign bit wraps into bit 0; CARRY is the last
/// sign bit rotated out. Result is unmasked (the caller re-masks).
pub fn rotateLeft(word_in: u64, count: u16, sign_bit: u64) ShiftResult {
    var word = word_in;
    var carry: ?bool = null;
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        const sign = (word & sign_bit) != 0;
        if (i + 1 == count) carry = sign;
        word = (word << 1) | @as(u64, @intFromBool(sign));
    }
    return .{ .word = word, .carry = carry };
}

/// Rotate right by `count` (RR): bit 0 wraps to the top (`top_shift` = word_size-1);
/// CARRY is the last bit rotated out the bottom.
pub fn rotateRight(word_in: u64, count: u16, top_shift: u6) ShiftResult {
    var word = word_in;
    var carry: ?bool = null;
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        const lsb = word & 1;
        if (i + 1 == count) carry = lsb != 0;
        word = (word >> 1) | (lsb << top_shift);
    }
    return .{ .word = word, .carry = carry };
}

/// Rotate left through carry (RLC): the sign bit becomes the new carry and the
/// old carry enters at bit 0, `count` times. Unlike the plain rotates this always
/// publishes the final carry (so `carry` is never null, even for count 0).
pub fn rotateLeftThroughCarry(word_in: u64, count: u16, carry_in: bool, sign_bit: u64) ShiftResult {
    var word = word_in;
    var carry: u64 = @intFromBool(carry_in);
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        const sign = @as(u64, @intFromBool((word & sign_bit) != 0));
        word = (word << 1) | carry;
        carry = sign;
    }
    return .{ .word = word, .carry = carry != 0 };
}

/// Rotate right through carry (RRC): bit 0 becomes the new carry and the old carry
/// enters at `top_shift`, `count` times. Always publishes the final carry.
pub fn rotateRightThroughCarry(word_in: u64, count: u16, carry_in: bool, top_shift: u6) ShiftResult {
    var word = word_in;
    var carry: u64 = @intFromBool(carry_in);
    var i: u16 = 0;
    while (i < count) : (i += 1) {
        const lsb = word & 1;
        word = (word >> 1) | (carry << top_shift);
        carry = lsb;
    }
    return .{ .word = word, .carry = carry != 0 };
}

/// Left-justify (LJ): shift `word` up so its most significant set bit sits at the
/// top of the word size. Zero yields a full-word-size count and an unchanged 0.
pub fn leftJustify(word: u64, word_size: u8) JustifyResult {
    if (word == 0) return .{ .count = word_size, .word = 0 };
    const count: u32 = @as(u32, @clz(word)) - (64 - @as(u32, word_size));
    return .{ .count = count, .word = word << @as(u6, @intCast(count)) };
}

/// Right-justify (RJ): shift `word` down to drop its trailing zero bits. `mask` is
/// the active word mask (the trailing-zero search is confined to it); `word_size`
/// is the zero-input count. Zero yields a full-word-size count and an unchanged 0.
pub fn rightJustify(word: u64, word_size: u8, mask: u64) JustifyResult {
    if (word == 0) return .{ .count = word_size, .word = 0 };
    const count: u32 = @ctz(word | ~mask);
    return .{ .count = count, .word = word >> @as(u6, @intCast(count)) };
}

/// Reverse the byte order of `word` for the SWAP-endian command. `bit_width` is
/// the swap granularity (8 = reverse all bytes, 16 = swap bytes within each 16-bit
/// half) and `word_size` is the (already-resolved) active word size in bits. An
/// unsupported width/size combination returns the word unchanged, matching the C.
pub fn swapEndian(word: u64, word_size: u8, bit_width: u16) u64 {
    const b0 = (word >> 0) & 0xff;
    const b1 = (word >> 8) & 0xff;
    const b2 = (word >> 16) & 0xff;
    const b3 = (word >> 24) & 0xff;
    const b4 = (word >> 32) & 0xff;
    const b5 = (word >> 40) & 0xff;
    const b6 = (word >> 48) & 0xff;
    const b7 = (word >> 56) & 0xff;
    if (bit_width == 8) {
        return switch (word_size) {
            16 => (b0 << 8) | b1,
            24 => (b0 << 16) | (b1 << 8) | b2,
            32 => (b0 << 24) | (b1 << 16) | (b2 << 8) | b3,
            40 => (b0 << 32) | (b1 << 24) | (b2 << 16) | (b3 << 8) | b4,
            48 => (b0 << 40) | (b1 << 32) | (b2 << 24) | (b3 << 16) | (b4 << 8) | b5,
            56 => (b0 << 48) | (b1 << 40) | (b2 << 32) | (b3 << 24) | (b4 << 16) | (b5 << 8) | b6,
            64 => (b0 << 56) | (b1 << 48) | (b2 << 40) | (b3 << 32) | (b4 << 24) | (b5 << 16) | (b6 << 8) | b7,
            else => word,
        };
    } else if (bit_width == 16) {
        return switch (word_size) {
            32 => (b1 << 24) | (b0 << 16) | (b3 << 8) | b2,
            48 => (b1 << 40) | (b0 << 32) | (b3 << 24) | (b2 << 16) | (b5 << 8) | b4,
            64 => (b1 << 56) | (b0 << 48) | (b3 << 40) | (b2 << 32) | (b5 << 24) | (b4 << 16) | (b7 << 8) | b6,
            else => word,
        };
    }
    return word;
}

/// Reverse the low `word_size` bits of `word` (the MIRROR command). Bits at or
/// above word_size are dropped; the result occupies the same low field.
pub fn mirrorBits(word: u64, word_size: u8) u64 {
    var result: u64 = 0;
    var index: u8 = 0;
    while (index < word_size) : (index += 1) {
        const src_shift: u6 = @intCast(index);
        if ((word & (@as(u64, 1) << src_shift)) != 0) {
            const dst_shift: u6 = @intCast(word_size - index - 1);
            result |= @as(u64, 1) << dst_shift;
        }
    }
    return result;
}

// Native unit tests (REPORT-27 M-IDIOM-3). Pure bit logic; expected values are
// hand-computed. No C oracle, no global state.
const testing = std.testing;

test "maskRight" {
    try testing.expectEqual(@as(u64, 0), maskRight(0));
    try testing.expectEqual(@as(u64, 0x1), maskRight(1));
    try testing.expectEqual(@as(u64, 0xF), maskRight(4));
    try testing.expectEqual(@as(u64, 0xFF), maskRight(8));
    try testing.expectEqual(std.math.maxInt(u64), maskRight(64));
}

test "maskLeft" {
    try testing.expectEqual(@as(u64, 0), maskLeft(8, 0xFF, 0));
    try testing.expectEqual(@as(u64, 0xF0), maskLeft(8, 0xFF, 4));
    try testing.expectEqual(@as(u64, 0xFF00), maskLeft(16, 0xFFFF, 8));
}

test "countBits" {
    try testing.expectEqual(@as(u64, 0), countBits(0));
    try testing.expectEqual(@as(u64, 2), countBits(0x5));
    try testing.expectEqual(@as(u64, 8), countBits(0xFF));
    try testing.expectEqual(@as(u64, 64), countBits(std.math.maxInt(u64)));
}

test "set/clear/flip/isBit" {
    try testing.expectEqual(@as(u64, 0x8), setBit(0, 3));
    try testing.expectEqual(@as(u64, 0xFE), clearBit(0xFF, 0));
    try testing.expectEqual(@as(u64, 0x20), flipBit(0, 5));
    try testing.expectEqual(@as(u64, 0), flipBit(0x20, 5));
    try testing.expect(isBitSet(0x8, 3));
    try testing.expect(isBitClear(0x8, 2));
    try testing.expect(!isBitSet(0x8, 2));
}

test "arithmetic/logical shifts report the last out-bit as carry" {
    const s8: u64 = 0x80;
    // ASR preserves sign; last out-bit is CARRY.
    try testing.expectEqual(ShiftResult{ .word = 0x02, .carry = false }, arithmeticShiftRight(0x08, 2, s8));
    try testing.expectEqual(ShiftResult{ .word = 0xC0, .carry = false }, arithmeticShiftRight(0x80, 1, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x01, .carry = true }, arithmeticShiftRight(0x03, 1, s8));
    // SL: carry is the sign bit shifted out.
    try testing.expectEqual(ShiftResult{ .word = 0x02, .carry = false }, shiftLeft(0x01, 1, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x100, .carry = true }, shiftLeft(0x80, 1, s8));
    // SR: carry is the low bit shifted out.
    try testing.expectEqual(ShiftResult{ .word = 0x01, .carry = false }, shiftRight(0x02, 1));
    try testing.expectEqual(ShiftResult{ .word = 0x00, .carry = true }, shiftRight(0x01, 1));
    // Zero-count leaves CARRY untouched (null) and the word unchanged.
    try testing.expectEqual(ShiftResult{ .word = 0x08, .carry = null }, arithmeticShiftRight(0x08, 0, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x08, .carry = null }, shiftLeft(0x08, 0, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x08, .carry = null }, shiftRight(0x08, 0));
}

test "rotateLeft and rotateRight wrap the end bit around" {
    const s8: u64 = 0x80;
    // No wrap: plain shift, carry from the sign / low bit.
    try testing.expectEqual(ShiftResult{ .word = 0x02, .carry = false }, rotateLeft(0x01, 1, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x80, .carry = false }, rotateLeft(0x40, 1, s8));
    // Wrap: the sign bit rotates into bit 0 (result is pre-mask, so the extra
    // high bit is present and CARRY records the rotated-out sign).
    try testing.expectEqual(ShiftResult{ .word = 0x101, .carry = true }, rotateLeft(0x80, 1, s8));

    // RR wraps bit 0 up to top_shift (word_size-1 == 7 for an 8-bit word).
    try testing.expectEqual(ShiftResult{ .word = 0x80, .carry = true }, rotateRight(0x01, 1, 7));
    try testing.expectEqual(ShiftResult{ .word = 0x40, .carry = false }, rotateRight(0x80, 1, 7));

    // Zero-count leaves both the word and CARRY untouched.
    try testing.expectEqual(ShiftResult{ .word = 0x12, .carry = null }, rotateLeft(0x12, 0, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x12, .carry = null }, rotateRight(0x12, 0, 7));
}

test "rotate through carry threads the CARRY bit" {
    const s8: u64 = 0x80;
    // RLC: old carry enters bit 0, sign becomes the new carry.
    try testing.expectEqual(ShiftResult{ .word = 0x02, .carry = false }, rotateLeftThroughCarry(0x01, 1, false, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x100, .carry = true }, rotateLeftThroughCarry(0x80, 1, false, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x01, .carry = false }, rotateLeftThroughCarry(0x00, 1, true, s8));
    // RRC: old carry enters the top, bit 0 becomes the new carry.
    try testing.expectEqual(ShiftResult{ .word = 0x01, .carry = false }, rotateRightThroughCarry(0x02, 1, false, 7));
    try testing.expectEqual(ShiftResult{ .word = 0x00, .carry = true }, rotateRightThroughCarry(0x01, 1, false, 7));
    try testing.expectEqual(ShiftResult{ .word = 0x80, .carry = false }, rotateRightThroughCarry(0x00, 1, true, 7));
    // Zero count still republishes the incoming carry (never null).
    try testing.expectEqual(ShiftResult{ .word = 0x12, .carry = true }, rotateLeftThroughCarry(0x12, 0, true, s8));
    try testing.expectEqual(ShiftResult{ .word = 0x12, .carry = false }, rotateRightThroughCarry(0x12, 0, false, 7));
}

test "leftJustify and rightJustify shift to the word edges" {
    // 8-bit word, single bit at position 0.
    try testing.expectEqual(JustifyResult{ .count = 7, .word = 0x80 }, leftJustify(0x01, 8));
    try testing.expectEqual(JustifyResult{ .count = 0, .word = 0x01 }, rightJustify(0x01, 8, 0xFF));
    // single bit already at the top of the 8-bit word.
    try testing.expectEqual(JustifyResult{ .count = 0, .word = 0x80 }, leftJustify(0x80, 8));
    try testing.expectEqual(JustifyResult{ .count = 7, .word = 0x01 }, rightJustify(0x80, 8, 0xFF));
    // a multi-bit value: 0b0011_0000 -> left 0b1100_0000 (count 2), right 0b0000_0011 (count 4).
    try testing.expectEqual(JustifyResult{ .count = 2, .word = 0xC0 }, leftJustify(0x30, 8));
    try testing.expectEqual(JustifyResult{ .count = 4, .word = 0x03 }, rightJustify(0x30, 8, 0xFF));
    // zero: full-word-size count, unchanged word.
    try testing.expectEqual(JustifyResult{ .count = 8, .word = 0 }, leftJustify(0, 8));
    try testing.expectEqual(JustifyResult{ .count = 8, .word = 0 }, rightJustify(0, 8, 0xFF));
    // 32-bit word.
    try testing.expectEqual(JustifyResult{ .count = 24, .word = 0x8000_0000 }, leftJustify(0x80, 32));

    // Left- then right-justify returns the original trailing-zero-stripped value.
    try testing.expectEqual(@as(u64, 0x03), rightJustify(leftJustify(0x30, 8).word, 8, 0xFF).word);
}

test "swapEndian reverses byte order per word size" {
    // 8-bit granularity: full byte reversal across the word size.
    try testing.expectEqual(@as(u64, 0x3412), swapEndian(0x1234, 16, 8));
    try testing.expectEqual(@as(u64, 0x563412), swapEndian(0x123456, 24, 8));
    try testing.expectEqual(@as(u64, 0x78563412), swapEndian(0x12345678, 32, 8));
    try testing.expectEqual(@as(u64, 0xEFCDAB8967452301), swapEndian(0x0123456789ABCDEF, 64, 8));

    // 16-bit granularity: swap the two bytes within each 16-bit half.
    try testing.expectEqual(@as(u64, 0x56781234), swapEndian(0x12345678, 32, 16));

    // Unsupported width/size leaves the word unchanged.
    try testing.expectEqual(@as(u64, 0x1234), swapEndian(0x1234, 8, 8));
    try testing.expectEqual(@as(u64, 0x1234), swapEndian(0x1234, 16, 16));

    // 8-bit full reversal is an involution over each supported word size.
    for ([_]u8{ 16, 24, 32, 40, 48, 56, 64 }) |ws| {
        const mask = if (ws >= 64) std.math.maxInt(u64) else (@as(u64, 1) << @as(u6, @intCast(ws))) - 1;
        const m = @as(u64, 0x0123456789ABCDEF) & mask;
        try testing.expectEqual(m, swapEndian(swapEndian(m, ws, 8), ws, 8));
    }
}

test "mirrorBits reverses the low word_size bits" {
    try testing.expectEqual(@as(u64, 0x80), mirrorBits(0x01, 8)); // lsb -> msb
    try testing.expectEqual(@as(u64, 0x01), mirrorBits(0x80, 8));
    try testing.expectEqual(@as(u64, 0x81), mirrorBits(0x81, 8)); // palindrome
    try testing.expectEqual(@as(u64, 0x55), mirrorBits(0xAA, 8)); // 10101010 -> 01010101
    try testing.expectEqual(@as(u64, 0x4), mirrorBits(0x2, 4)); // 0010 -> 0100
    try testing.expectEqual(@as(u64, 0x80), mirrorBits(0xFF01, 8)); // bits >= word_size dropped

    // Involution: mirroring twice within a word size restores the masked value.
    for ([_]u8{ 4, 8, 16, 32, 63 }) |ws| {
        const mask = (@as(u64, 1) << @as(u6, @intCast(ws))) - 1;
        var x: u64 = 0;
        while (x < 400) : (x += 1) {
            const m = x & mask;
            try testing.expectEqual(m, mirrorBits(mirrorBits(m, ws), ws));
        }
    }
}
