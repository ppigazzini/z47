//! Data-file byte transforms -- the pure cores of calc_state_register_codec's
//! hexVal and dataFileCommaToPeriod.
//!
//! Restoring a saved state parses uppercase hex nibbles and normalizes a
//! localized decimal comma to a period. Both are pure byte operations. Lift them
//! here for native coverage -- the restore owner is only reachable through the C
//! oracle. This module uses Zig many-item pointers rather than C pointers, so it
//! stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// The nibble value of an uppercase hex character ('0'..'9', 'A'..'F').
pub fn hexVal(c: u8) u32 {
    return if (c >= 'A') @as(u32, c - 'A' + 10) else @as(u32, c - '0');
}

/// Replace every ',' with '.' in the NUL-terminated string, in place.
pub fn commaToPeriod(str: [*]u8) void {
    var p = str;
    while (p[0] != 0) : (p += 1) {
        if (p[0] == ',') p[0] = '.';
    }
}

test "hexVal decodes digits and uppercase hex letters" {
    try std.testing.expectEqual(@as(u32, 0), hexVal('0'));
    try std.testing.expectEqual(@as(u32, 9), hexVal('9'));
    try std.testing.expectEqual(@as(u32, 10), hexVal('A'));
    try std.testing.expectEqual(@as(u32, 15), hexVal('F'));
}

test "commaToPeriod normalizes decimal separators in place" {
    var buf = "1,5".*;
    commaToPeriod(&buf);
    try std.testing.expectEqualStrings("1.5", std.mem.sliceTo(&buf, 0));

    var multi = "a,b,c".*;
    commaToPeriod(&multi);
    try std.testing.expectEqualStrings("a.b.c", std.mem.sliceTo(&multi, 0));

    var none = "xyz".*;
    commaToPeriod(&none);
    try std.testing.expectEqualStrings("xyz", std.mem.sliceTo(&none, 0));
}
