//! Reserved-register predicates -- the pure core of
//! register_metadata_reallocate's reserved-register helpers.
//!
//! reallocateRegister classifies whether a register id is in the reserved band
//! and normalizes a lettered reserved register into the X.. register band. Both
//! are pure integer arithmetic over the band constants. Lift them here for native
//! coverage -- the reallocate owner is only reachable through the C oracle.

const std = @import("std");

/// Whether `reg` is in the reserved-variable band.
pub fn isReservedRegister(reg: i16, last_named: i16, last_reserved: i16) bool {
    return reg > last_named and reg <= last_reserved;
}

/// Map a lettered reserved register into the X.. register band; other registers
/// pass through unchanged.
pub fn normalizeLetteredReserved(reg: i16, first_reserved: i16, first_named_reserved: i16, register_x: i16) i16 {
    if (reg >= first_reserved and reg < first_named_reserved) {
        return reg - first_reserved + register_x;
    }
    return reg;
}

test "isReservedRegister spans (last_named, last_reserved]" {
    // last_named = 1999, last_reserved = 2047.
    try std.testing.expect(isReservedRegister(2000, 1999, 2047));
    try std.testing.expect(isReservedRegister(2047, 1999, 2047));
    try std.testing.expect(!isReservedRegister(1999, 1999, 2047));
    try std.testing.expect(!isReservedRegister(2048, 1999, 2047));
}

test "normalizeLetteredReserved maps into the X band" {
    // first_reserved = 2000, first_named_reserved = 2016, register_x = 100.
    try std.testing.expectEqual(@as(i16, 100), normalizeLetteredReserved(2000, 2000, 2016, 100));
    try std.testing.expectEqual(@as(i16, 105), normalizeLetteredReserved(2005, 2000, 2016, 100));
    // Outside the lettered range: unchanged.
    try std.testing.expectEqual(@as(i16, 2016), normalizeLetteredReserved(2016, 2000, 2016, 100));
    try std.testing.expectEqual(@as(i16, 50), normalizeLetteredReserved(50, 2000, 2016, 100));
}
