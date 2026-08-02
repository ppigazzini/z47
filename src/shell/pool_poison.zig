//! Extent arithmetic for the free-pool poison detector (REPORT-30 finding 5).
//!
//! WHY THIS EXISTS. Registers, variables, programs, formulae, menus and the GMP
//! heap all live in `ram`, one ~256 KiB allocation carved into 4-byte blocks. To
//! AddressSanitizer that is a SINGLE allocation, so a block overrunning its
//! neighbour is a write inside a live region and ASan says nothing -- and Zig's
//! own checks miss it too, because blocks are reached by `[*c]` arithmetic off
//! `ram`. Three of the defects REPORT-30 closed (findings 1, 16, 18) were exactly
//! that shape, and one of them was caught only because it happened to run past the
//! end of the pool entirely and hit unmapped memory.
//!
//! M-SAFE-6 proposed poisoning the pool with `__asan_poison_memory_region` and was
//! WITHDRAWN: Zig ships no AddressSanitizer runtime, so there is nothing to poison
//! with. That verdict is still correct about ASan and was wrong to treat as the end
//! of the matter -- a poison pattern needs no runtime at all.
//!
//! THE SCHEME. Fill every free region with a known byte, then later check those
//! bytes are unchanged. Anything that wrote into free space in between is caught.
//!
//! WHY THE INTERSECTION MATTERS, and it is the whole reason this module is
//! separate. The free set is not stable across the window: `resizeProgramMemory`
//! adjusts the last free region's size DIRECTLY (memory_runtime.zig), without going
//! through the allocator, so a region can GROW to cover bytes that were program
//! memory and were never poisoned. Auditing a region as it stands at the end would
//! report those as disturbed -- a false positive on completely correct behaviour.
//! So the audit checks only the bytes that were free at poison time AND are still
//! free now: the intersection. That is pure arithmetic on block extents, testable
//! without a pool, which is what lives here.
//!
//! WHAT THIS CANNOT SEE, stated here so no caller assumes otherwise: an overrun
//! from one LIVE allocation into another live allocation. Only free space carries
//! the pattern. Bounding that class needs per-allocation redzones, which would
//! change the pool layout and therefore the firmware.

const std = @import("std");

/// 0xA5 rather than 0 or 0xFF: both of those occur naturally as data, and a
/// pattern that a correct write could plausibly leave behind is a pattern whose
/// survival proves nothing. 0xA5 alternates bits, so a partial word overwrite
/// shows up as well as a full one.
pub const POISON: u8 = 0xA5;

/// A half-open run of pool blocks, `[start, start + blocks)`.
pub const Extent = struct {
    start: u32,
    blocks: u32,

    pub fn end(self: Extent) u32 {
        return self.start + self.blocks;
    }

    pub fn isEmpty(self: Extent) bool {
        return self.blocks == 0;
    }
};

/// The part of `a` that is also in `b`, or null when they do not overlap.
pub fn intersect(a: Extent, b: Extent) ?Extent {
    const start = @max(a.start, b.start);
    const stop = @min(a.end(), b.end());
    if (stop <= start) return null;
    return .{ .start = start, .blocks = stop - start };
}

/// Offset of the first byte that is no longer the poison pattern, or null if the
/// whole run is intact.
pub fn firstDisturbed(bytes: []const u8) ?usize {
    for (bytes, 0..) |b, i| {
        if (b != POISON) return i;
    }
    return null;
}

test "an extent knows its own end" {
    try std.testing.expectEqual(@as(u32, 12), (Extent{ .start = 4, .blocks = 8 }).end());
    try std.testing.expect((Extent{ .start = 4, .blocks = 0 }).isEmpty());
}

test "disjoint extents do not intersect" {
    try std.testing.expect(intersect(.{ .start = 0, .blocks = 4 }, .{ .start = 4, .blocks = 4 }) == null);
    try std.testing.expect(intersect(.{ .start = 8, .blocks = 4 }, .{ .start = 0, .blocks = 4 }) == null);
}

test "a partial overlap yields only the shared blocks" {
    const got = intersect(.{ .start = 0, .blocks = 10 }, .{ .start = 6, .blocks = 10 }).?;
    try std.testing.expectEqual(@as(u32, 6), got.start);
    try std.testing.expectEqual(@as(u32, 4), got.blocks);
}

test "a region that GREW past its poisoned extent contributes only the poisoned part" {
    // The resizeProgramMemory case: the free region was 4 blocks at poison time and
    // is 40 blocks now. Only the original 4 were ever poisoned, and auditing the
    // other 36 would report correct behaviour as corruption.
    const poisoned = Extent{ .start = 100, .blocks = 4 };
    const now = Extent{ .start = 100, .blocks = 40 };
    const got = intersect(now, poisoned).?;
    try std.testing.expectEqual(@as(u32, 100), got.start);
    try std.testing.expectEqual(@as(u32, 4), got.blocks);
}

test "a region that SHRANK contributes only what is still free" {
    const poisoned = Extent{ .start = 100, .blocks = 40 };
    const now = Extent{ .start = 120, .blocks = 20 };
    const got = intersect(now, poisoned).?;
    try std.testing.expectEqual(@as(u32, 120), got.start);
    try std.testing.expectEqual(@as(u32, 20), got.blocks);
}

test "intact poison reports nothing and one changed byte reports its offset" {
    // `@splat`, not `[_]u8{POISON} ** 16`: Zig master (0.17.0-dev) rejects the
    // repetition form here with "binary operator '*' has whitespace on one side,
    // but not the other", which 0.16.0 accepts. The zig-master compatibility
    // monitor is a CI lane, so a construct only one toolchain takes breaks the
    // build; @splat is accepted by both and says the same thing more directly.
    var buf: [16]u8 = @splat(POISON);
    try std.testing.expect(firstDisturbed(&buf) == null);
    buf[7] = 0;
    try std.testing.expectEqual(@as(usize, 7), firstDisturbed(&buf).?);
}

test "an empty run is trivially intact" {
    try std.testing.expect(firstDisturbed(&[_]u8{}) == null);
}
