// SPDX-License-Identifier: GPL-3.0-only
//! Byte <-> allocation-block arithmetic, the single tested source for the
//! conversion that a dozen state owners had each open-coded (memory.zig,
//! memory_gmp_alloc.zig, memory_debug.zig, memory_resize_program.zig,
//! memory_runtime.zig, program_serialization_pointer.zig,
//! keyboard_state_runtime.zig, register_metadata_tables.zig,
//! register_metadata_local_registers.zig). Every copy computed the same thing --
//! round bytes up to whole blocks, and multiply blocks back to bytes -- but with
//! different integer widths (u16 / u32 / usize / u64).
//!
//! The functions are width-parameterised so each owner keeps its exact return
//! type: memory_runtime needs the overflow-safe u64 on 32-bit firmware, while
//! the rest stay usize/u16. Imports only std, so it runs under
//! `zig build test:unit`; the block sizing is also behaviour-checked by the
//! memory_parity oracle.

const std = @import("std");

/// log2 of the block size: the calculator allocates in BYTES_PER_BLOCK blocks.
pub const BPB: u6 = 2;
/// Bytes per allocation block (4).
pub const BYTES_PER_BLOCK: usize = 1 << BPB;

/// Round `byte_count` up to whole blocks, returned as `R`. The result is
/// computed in usize and cast to the caller's chosen width; the cast traps an
/// over-wide value exactly as the owners' own @intCast did.
pub fn toBlocks(comptime R: type, byte_count: anytype) R {
    return @intCast((@as(usize, @intCast(byte_count)) + (BYTES_PER_BLOCK - 1)) >> BPB);
}

/// Convert `block_count` to bytes, returned as `R`. `R` is caller-chosen so
/// memory_runtime keeps its overflow-safe u64 while the rest stay usize.
pub fn toBytes(comptime R: type, block_count: anytype) R {
    return @as(R, @intCast(block_count)) << BPB;
}

const testing = std.testing;

test "toBlocks rounds bytes up to whole 4-byte blocks" {
    try testing.expectEqual(@as(usize, 0), toBlocks(usize, 0));
    try testing.expectEqual(@as(usize, 1), toBlocks(usize, 1));
    try testing.expectEqual(@as(usize, 1), toBlocks(usize, 4));
    try testing.expectEqual(@as(usize, 2), toBlocks(usize, 5));
    try testing.expectEqual(@as(usize, 2), toBlocks(usize, 8));
    try testing.expectEqual(@as(usize, 3), toBlocks(usize, 9));
}

test "toBytes multiplies blocks back to bytes" {
    try testing.expectEqual(@as(usize, 0), toBytes(usize, 0));
    try testing.expectEqual(@as(usize, 4), toBytes(usize, 1));
    try testing.expectEqual(@as(usize, 12), toBytes(usize, 3));
}

test "toBlocks honours the caller-chosen narrow return width" {
    try testing.expectEqual(@as(u16, 25), toBlocks(u16, @as(u32, 100)));
    try testing.expectEqual(@as(u16, 26), toBlocks(u16, @as(u32, 101)));
}

test "toBytes keeps a wide u64 result for large block counts" {
    // 2^31 blocks * 4 = 2^33 bytes -- overflows u32, must stay exact in u64.
    const blocks: u64 = 1 << 31;
    try testing.expectEqual(@as(u64, 1) << 33, toBytes(u64, blocks));
}

test "toBytes then toBlocks recovers the block count" {
    var b: usize = 0;
    while (b < 64) : (b += 1) {
        try testing.expectEqual(b, toBlocks(usize, toBytes(usize, b)));
    }
}
