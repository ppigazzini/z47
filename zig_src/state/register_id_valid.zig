//! Register-ID band validity -- the pure core of register_metadata's
//! reallocateRegister guard.
//!
//! A register id is valid only inside one of the allocated bands: the global
//! range, the named-variable range, the reserved-variable range, or the local
//! range. Malformed ids (negative, in a gap between bands, or past the last
//! local register) are rejected. The check is pure interval arithmetic over the
//! band constants. Lift it here for native coverage -- the register owner is only
//! reachable through the C oracle.

const std = @import("std");

/// Whether `reg` falls inside a valid register band. `reg` and the bounds are
/// widened to i32 so a negative id compares correctly.
pub fn isValidRegisterId(reg: i32, last_global: i32, first_named: i32, last_reserved: i32, first_local: i32, last_local: i32) bool {
    if (reg < 0) return false;
    if (reg > last_global and reg < first_named) return false;
    if (reg > last_reserved and reg < first_local) return false;
    if (reg > last_local) return false;
    return true;
}

// The real z47 register-band layout, used so the tests pin the documented bounds.
fn valid(reg: i32) bool {
    return isValidRegisterId(reg, 111, 256, 2047, 7000, 7098);
}

test "ids inside each band are valid" {
    try std.testing.expect(valid(0));
    try std.testing.expect(valid(111)); // last global
    try std.testing.expect(valid(256)); // first named
    try std.testing.expect(valid(2047)); // last reserved
    try std.testing.expect(valid(7000)); // first local
    try std.testing.expect(valid(7098)); // last local
}

test "negative, gap, and past-the-end ids are rejected" {
    try std.testing.expect(!valid(-1));
    try std.testing.expect(!valid(200)); // between global and named
    try std.testing.expect(!valid(5000)); // between reserved and local
    try std.testing.expect(!valid(7099)); // past last local
}
