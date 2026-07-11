//! Register-band index resolution -- the pure core shared by
//! register_descriptor_storage's named/local descriptor accessors.
//!
//! Translating a register id into a storage array index means checking it is at
//! or above the band base, that the band is non-empty, and that the offset is
//! within the live count. That bounds-checked bijection is pure integer
//! arithmetic; the accessors then read/write the descriptor array. Lift it here
//! for native coverage -- the storage owner is only reachable through the C
//! oracle.

const std = @import("std");

/// The array index for `reg` in a band starting at `first` with `count` live
/// entries, or null when out of range.
pub fn resolveIndex(reg: i16, first: i16, count: u16) ?u16 {
    if (reg < first or count == 0) {
        return null;
    }
    const index: u16 = @intCast(reg - first);
    if (index >= count) {
        return null;
    }
    return index;
}

test "resolveIndex maps in-range registers and rejects the rest" {
    // band base 256, 3 live entries.
    try std.testing.expectEqual(@as(?u16, 0), resolveIndex(256, 256, 3));
    try std.testing.expectEqual(@as(?u16, 2), resolveIndex(258, 256, 3));
    try std.testing.expectEqual(@as(?u16, null), resolveIndex(259, 256, 3)); // past the count
    try std.testing.expectEqual(@as(?u16, null), resolveIndex(255, 256, 3)); // below the base
    try std.testing.expectEqual(@as(?u16, null), resolveIndex(256, 256, 0)); // empty band
}
