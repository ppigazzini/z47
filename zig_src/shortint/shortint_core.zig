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