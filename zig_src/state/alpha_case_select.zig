//! Alpha lowercase-selected predicate -- the pure core of keyboard_state_runtime's
//! lowercaseSelected.
//!
//! Whether the alpha keyboard is showing lowercase depends on the alpha-case
//! setting XORed with the f-shift state: lowercase when lower-and-not-shifted or
//! upper-and-shifted. It is a pure boolean predicate. Lift it here for native
//! coverage -- the keyboard owner is only reachable through the C oracle.

const std = @import("std");

/// Whether lowercase is currently selected.
pub fn lowercaseSelected(alpha_case: u8, shift_f: bool, ac_lower: u8, ac_upper: u8) bool {
    return (alpha_case == ac_lower and !shift_f) or (alpha_case == ac_upper and shift_f);
}

test "lowercase when lower-unshifted or upper-shifted" {
    // ac_lower = 0, ac_upper = 1.
    try std.testing.expect(lowercaseSelected(0, false, 0, 1));
    try std.testing.expect(lowercaseSelected(1, true, 0, 1));
    try std.testing.expect(!lowercaseSelected(0, true, 0, 1));
    try std.testing.expect(!lowercaseSelected(1, false, 0, 1));
}
