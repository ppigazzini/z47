//! TAM shuffle register decode -- the pure core lifted from frontier_tam's
//! _tamUpdateBuffer.
//!
//! In shuffle mode the TAM value packs up to four register selections: a presence
//! bit at position i*2+8 and, when present, a 2-bit register number at i*2 (0..3
//! mapping to x/y/z/t). Decoding it into a four-character name string (absent
//! slots shown as '_') is a pure bijection over the value word. Lift it here for
//! native coverage -- the TAM owner is only reachable through the C oracle. The
//! owner keeps the buffer-write shim.

const std = @import("std");

/// Decode the shuffle `value` into a NUL-terminated 4-character register-name
/// buffer: each slot is 'x'/'y'/'z'/'t' when present, else '_'.
pub fn decodeShuffle(value: i16) [5]u8 {
    var regists: [5]u8 = undefined;
    regists[4] = 0;
    var i: u4 = 0;
    while (i < 4) : (i += 1) {
        if ((value >> @intCast(i * 2 + 8)) & 1 != 0) {
            const regNum: u8 = @intCast((value >> @intCast(i * 2)) & 3);
            regists[i] = if (regNum == 3) 't' else 'x' + regNum;
        } else {
            regists[i] = '_';
        }
    }
    return regists;
}

test "an empty shuffle value is all underscores" {
    try std.testing.expectEqualStrings("____", std.mem.sliceTo(&decodeShuffle(0), 0));
}

test "a present slot decodes its register number to x/y/z/t" {
    // slot 0 present (bit 8), regnum 0 -> 'x'.
    try std.testing.expectEqualStrings("x___", std.mem.sliceTo(&decodeShuffle(1 << 8), 0));
    // slot 0 present, regnum 1 (bits 0..1 = 01) -> 'y'.
    try std.testing.expectEqualStrings("y___", std.mem.sliceTo(&decodeShuffle((1 << 8) | 1), 0));
    // slot 0 present, regnum 3 -> 't'.
    try std.testing.expectEqualStrings("t___", std.mem.sliceTo(&decodeShuffle((1 << 8) | 3), 0));
}

test "multiple slots decode independently" {
    // slot 0 present regnum 2 ('z'); slot 2 present (bit 12) regnum 0 ('x').
    const v: i16 = (1 << 8) | 2 | (1 << 12);
    try std.testing.expectEqualStrings("z_x_", std.mem.sliceTo(&decodeShuffle(v), 0));
}
