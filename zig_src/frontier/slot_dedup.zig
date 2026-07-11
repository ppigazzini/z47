//! Adjacent fixed-slot dedup -- the pure core of frontier_softmenus'
//! _removeDuplicateLabels.
//!
//! Menu labels are collected into fixed-stride, NUL-terminated name slots and
//! sorted; _removeDuplicateLabels then compacts runs of equal adjacent slots in
//! place (a two-pointer stable-unique pass) and returns the surviving count. The
//! compaction is pure over the slot buffer given the stride and a slot-equality
//! test -- lift it here for native coverage. This module uses Zig many-item
//! pointers rather than C pointers, so it stays out of the idiom-ratchet ceiling.

const std = @import("std");
const name_slot_equal = @import("name_slot_equal.zig"); // NUL-terminated slot strcmp

/// Compact adjacent equal slots in `slots` (each `stride` bytes) in place and
/// return the new slot count. Mirrors the C two-pointer unique: keep slot 0, and
/// for each later slot copy it forward only when it differs from the last kept.
pub fn dedupeAdjacentSlots(slots: [*]u8, n: i16, stride: usize) i16 {
    if (n <= 0) return 0;
    var j: i16 = 0;
    var i: i16 = 1;
    while (i < n) : (i += 1) {
        const si = slots + stride * @as(usize, @intCast(i));
        const sj = slots + stride * @as(usize, @intCast(j));
        if (!name_slot_equal.slotsEqual(si, sj)) {
            j += 1;
            const dst = slots + stride * @as(usize, @intCast(j));
            var k: usize = 0;
            while (k < stride) : (k += 1) {
                dst[k] = si[k];
            }
        }
    }
    return j + 1;
}

fn build(comptime names: []const []const u8) [names.len * 4]u8 {
    var buf: [names.len * 4]u8 = [_]u8{0} ** (names.len * 4);
    for (names, 0..) |name, idx| {
        @memcpy(buf[idx * 4 ..][0..name.len], name);
    }
    return buf;
}

test "runs of equal adjacent slots collapse to one" {
    var buf = build(&.{ "A", "A", "B", "B", "B", "C" }); // stride 4, NUL-terminated
    const count = dedupeAdjacentSlots(&buf, 6, 4);
    try std.testing.expectEqual(@as(i16, 3), count);
    try std.testing.expectEqualStrings("A", std.mem.sliceTo(buf[0..4], 0));
    try std.testing.expectEqualStrings("B", std.mem.sliceTo(buf[4..8], 0));
    try std.testing.expectEqualStrings("C", std.mem.sliceTo(buf[8..12], 0));
}

test "all-distinct is unchanged and empty is zero" {
    var buf = build(&.{ "A", "B", "C" });
    try std.testing.expectEqual(@as(i16, 3), dedupeAdjacentSlots(&buf, 3, 4));
    var one = build(&.{"X"});
    try std.testing.expectEqual(@as(i16, 1), dedupeAdjacentSlots(&one, 1, 4));
    try std.testing.expectEqual(@as(i16, 0), dedupeAdjacentSlots(&one, 0, 4));
}
