//! Numeric-type classifier -- the pure core of
//! frontier_register_value_conversions' typeIsNumber.
//!
//! Deciding whether a register data type is a number (and, via an out-flag,
//! whether it is complex) is a pure classification over the data-type codes. Lift
//! it here for native coverage -- the conversion owner is only reachable through
//! the C oracle.

const std = @import("std");

/// Whether data type `t` is numeric; sets `cmplx` (when given) to whether it is
/// complex.
pub fn typeIsNumber(t: u32, cmplx: ?*bool, dt_complex: u32, dt_long: u32, dt_short: u32, dt_real: u32) bool {
    if (t == dt_complex) {
        if (cmplx) |c| c.* = true;
        return true;
    }
    if (t == dt_long or t == dt_short or t == dt_real) {
        if (cmplx) |c| c.* = false;
        return true;
    }
    return false;
}

test "complex is numeric and sets the complex flag" {
    var c: bool = false;
    try std.testing.expect(typeIsNumber(2, &c, 2, 0, 8, 1));
    try std.testing.expect(c);
}

test "real/integer types are numeric and clear the complex flag" {
    var c: bool = true;
    try std.testing.expect(typeIsNumber(1, &c, 2, 0, 8, 1));
    try std.testing.expect(!c);
    try std.testing.expect(typeIsNumber(0, &c, 2, 0, 8, 1));
    try std.testing.expect(typeIsNumber(8, &c, 2, 0, 8, 1));
}

test "non-numeric types return false without touching the flag" {
    var c: bool = true;
    try std.testing.expect(!typeIsNumber(5, &c, 2, 0, 8, 1));
    try std.testing.expect(c); // unchanged
    try std.testing.expect(!typeIsNumber(6, null, 2, 0, 8, 1));
}
