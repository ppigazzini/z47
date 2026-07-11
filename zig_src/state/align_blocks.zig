//! Long-integer block alignment -- the pure core of register_metadata_size's
//! alignLongIntegerBlocks.
//!
//! A long-integer payload block count is rounded up to a whole number of usize
//! limbs so the mpz limbs stay aligned. The rounding is pure integer arithmetic
//! over the block count, the bytes-per-block, and the limb size in blocks. Lift
//! it here for native coverage -- the size owner otherwise sits behind the
//! register-metadata runtime.

const std = @import("std");

/// Round `size_in_blocks` up to a whole number of usize limbs.
pub fn alignLongIntegerBlocks(size_in_blocks: u16, bytes_per_block: usize, limb_size_in_blocks: u16) u16 {
    const limb_size_in_bytes = @sizeOf(usize);
    if ((@as(usize, size_in_blocks) * bytes_per_block) % limb_size_in_bytes != 0) {
        return @intCast(((@as(usize, size_in_blocks) / limb_size_in_blocks) + 1) * limb_size_in_blocks);
    }
    return size_in_blocks;
}

test "block counts round up to a whole limb" {
    // Host: usize is 8 bytes; with 4-byte blocks a limb is 2 blocks.
    const bpb = 4;
    const limb_blocks = 2;
    try std.testing.expectEqual(@as(u16, 4), alignLongIntegerBlocks(3, bpb, limb_blocks)); // 3 -> 4
    try std.testing.expectEqual(@as(u16, 6), alignLongIntegerBlocks(5, bpb, limb_blocks)); // 5 -> 6
}

test "already-aligned counts are unchanged" {
    try std.testing.expectEqual(@as(u16, 4), alignLongIntegerBlocks(4, 4, 2));
    try std.testing.expectEqual(@as(u16, 2), alignLongIntegerBlocks(2, 4, 2));
}
