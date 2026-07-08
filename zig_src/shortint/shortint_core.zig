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
