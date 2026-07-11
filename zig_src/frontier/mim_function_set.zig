//! Matrix-input-mode function membership -- the pure core of frontier_bufferize's
//! isFunctionInMim.
//!
//! While the matrix editor is in input mode, only certain functions are allowed;
//! each allowed set (type 0/1/2) is a const table of item numbers. Deciding
//! membership is a pure linear scan of the selected table for a matching item;
//! the owner picks which table by type. Lifting the scan here gives it native
//! coverage -- the bufferize owner is only reachable through the C oracle. The
//! owner keeps isFunctionInMim to select the table and delegate.

const std = @import("std");
const abi = @import("abi");

/// Whether `com` appears as an item number in `table`.
pub fn contains(table: []const abi.FInMim, com: i16) bool {
    for (table) |entry| {
        if (com == @as(i16, @bitCast(entry.itemNr))) {
            return true;
        }
    }
    return false;
}

test "contains finds a member and rejects a non-member" {
    const table = [_]abi.FInMim{ .{ .itemNr = 100 }, .{ .itemNr = 250 }, .{ .itemNr = 4000 } };
    try std.testing.expect(contains(&table, 100));
    try std.testing.expect(contains(&table, 250));
    try std.testing.expect(contains(&table, 4000));
    try std.testing.expect(!contains(&table, 101));
    try std.testing.expect(!contains(&table, 0));
}

test "an empty table contains nothing" {
    const table = [_]abi.FInMim{};
    try std.testing.expect(!contains(&table, 100));
}

test "item numbers above 0x7fff compare through the i16 bitcast" {
    // itemNr 0x8001 bitcasts to a negative i16; the caller's com is bitcast the
    // same way, so the match still holds.
    const table = [_]abi.FInMim{.{ .itemNr = 0x8001 }};
    try std.testing.expect(contains(&table, @as(i16, @bitCast(@as(u16, 0x8001)))));
    try std.testing.expect(!contains(&table, 1));
}
