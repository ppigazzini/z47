//! Power-of-ten text builder -- the pure core of frontier_addons' addzeroes.
//!
//! addzeroes writes the string "1" followed by `ix` "0" characters (the decimal
//! text of 10^ix). It is a pure byte fill. Lift it here for native coverage. This
//! module uses Zig many-item pointers rather than C pointers, so it stays out of
//! the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Write "1" then `ix` zeros (NUL-terminated) into `st`.
pub fn addzeroes(st: [*]u8, ix: u8) void {
    st[0] = '1';
    var iy: u8 = 0;
    while (iy < ix) : (iy += 1) {
        st[1 + @as(usize, iy)] = '0';
    }
    st[1 + @as(usize, ix)] = 0;
}

test "addzeroes builds a power of ten as text" {
    var buf: [16]u8 = undefined;
    addzeroes(&buf, 3);
    try std.testing.expectEqualStrings("1000", std.mem.sliceTo(&buf, 0));
    addzeroes(&buf, 0);
    try std.testing.expectEqualStrings("1", std.mem.sliceTo(&buf, 0));
}
