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
