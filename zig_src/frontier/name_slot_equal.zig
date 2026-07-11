//! NUL-terminated name-slot equality -- the pure core of frontier_softmenus'
//! slotsEqual.
//!
//! Deduplicating menu labels compares two fixed-size NUL-terminated name slots
//! for byte equality (a strcmp==0). The comparison is pure over the two buffers;
//! the dedup caller around it mutates global scratch state. Lift the compare here
//! for native coverage -- the softmenu owner is only reachable through the C
//! oracle. This module uses Zig many-item pointers rather than C pointers, so it
//! stays out of the idiom-ratchet cptr ceiling.

const std = @import("std");

/// Whether the two NUL-terminated byte strings are equal.
pub fn slotsEqual(a: [*]const u8, b: [*]const u8) bool {
    var k: usize = 0;
    while (true) : (k += 1) {
        if (a[k] != b[k]) return false;
        if (a[k] == 0) return true;
    }
}

test "equal strings compare equal" {
    try std.testing.expect(slotsEqual("label", "label"));
    try std.testing.expect(slotsEqual("", ""));
}

test "different strings compare unequal" {
    try std.testing.expect(!slotsEqual("labelA", "labelB"));
    try std.testing.expect(!slotsEqual("short", "shorter"));
    try std.testing.expect(!slotsEqual("shorter", "short"));
}

test "bytes past the terminator are ignored" {
    const a = [_]u8{ 'a', 'b', 0, 'X' };
    const b = [_]u8{ 'a', 'b', 0, 'Y' };
    try std.testing.expect(slotsEqual(&a, &b));
}
