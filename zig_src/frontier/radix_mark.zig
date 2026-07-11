//! Radix-mark buffer fill -- the pure core of frontier_display's radixTT.
//!
//! The radix mark is copied into a 4-byte buffer for later concatenation: a full
//! copy when it is a real two-byte glyph, or a single character plus a
//! terminator when the second byte is the 0x01 single-character marker. It is
//! pure over the radix bytes and the buffer; the owner resolves the radix mark
//! from the grouping globals. Lift it here for native coverage -- the display
//! owner is only reachable through the C oracle. This module uses Zig many-item
//! pointers rather than C pointers, so it stays out of the idiom-ratchet cptr
//! ceiling.

const std = @import("std");

/// Fill `tt` with the radix mark: a full NUL-terminated copy of `radix`, unless
/// its second byte is the 0x01 single-character marker, in which case just the
/// first character plus a terminator.
pub fn radixTT(tt: *[4]u8, radix: [*]const u8) void {
    if (radix[1] != 1) {
        var i: usize = 0;
        while (radix[i] != 0) : (i += 1) {
            tt[i] = radix[i];
        }
        tt[i] = 0;
    } else {
        tt[0] = radix[0];
        tt[1] = 0;
    }
}

test "a single-character radix mark takes just the first byte" {
    var tt: [4]u8 = undefined;
    radixTT(&tt, ".\x01");
    try std.testing.expectEqualStrings(".", std.mem.sliceTo(&tt, 0));
}

test "a two-byte radix glyph is copied whole" {
    var tt: [4]u8 = undefined;
    radixTT(&tt, "\xa1\x2c");
    try std.testing.expectEqualSlices(u8, &[_]u8{ 0xa1, 0x2c }, std.mem.sliceTo(&tt, 0));
}
