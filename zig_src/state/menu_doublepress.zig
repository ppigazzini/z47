//! Double-press-blocked menu predicate -- the pure core of
//! keyboard_state_runtime's blockDoublepressMenu.
//!
//! Certain menus ignore a double-press on the two rightmost keys of the top row
//! (x in {4,5}, y == 0). The check is pure over the menu id and key position
//! plus the set of blocked menus. Lift it here for native coverage -- the
//! keyboard owner is only reachable through the C oracle.

const std = @import("std");

/// Whether a double-press on key (`x`, `y`) in menu `menu_id` is blocked. The
/// blocked menus are given as their positive ids (matched against -menu_id).
pub fn blockDoublepressMenu(menu_id: i16, x: i16, y: i16, blocked_menus: []const i16) bool {
    if (y != 0 or (x != 4 and x != 5)) {
        return false;
    }
    for (blocked_menus) |m| {
        if (menu_id == -m) return true;
    }
    return false;
}

const test_blocked = [_]i16{ 10, 20, 30, 40 };

test "only the two top-right keys of a blocked menu are blocked" {
    try std.testing.expect(blockDoublepressMenu(-10, 4, 0, &test_blocked));
    try std.testing.expect(blockDoublepressMenu(-20, 5, 0, &test_blocked));
    // Wrong key column.
    try std.testing.expect(!blockDoublepressMenu(-10, 3, 0, &test_blocked));
    // Wrong row.
    try std.testing.expect(!blockDoublepressMenu(-10, 4, 1, &test_blocked));
    // Not a blocked menu.
    try std.testing.expect(!blockDoublepressMenu(-99, 4, 0, &test_blocked));
}
