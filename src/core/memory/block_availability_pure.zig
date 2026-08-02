//! Free-memory bin-packing predicate -- the pure core of
//! memory_block_availability's isMemoryBlockAvailable.
//!
//! Deciding whether `num_blocks` allocations of `size_in_blocks` (plus one
//! `extra_size` slack block) fit in the free-region list is a running count over
//! the regions: a single region large enough for everything wins immediately,
//! otherwise whole blocks and a leftover slack block are accumulated across
//! regions. The arithmetic is pure over plain sizes; only the region iteration
//! and the extra-size scaling are edges the owner keeps.
//!
//! Lifting it here gives the bin-packing logic native coverage -- the memory
//! owner is only reachable through the C oracle. The owner drives the
//! accumulator over its free regions.

const std = @import("std");

/// A running availability check fed one free-region block size at a time.
pub const Availability = struct {
    required_for_n_blocks: usize,
    size_in_blocks: usize,
    num_blocks: usize,
    extra_size: usize,
    count_of_blocks_of_size: usize = 0,
    have_extra_block: bool = false,

    pub fn init(size_in_blocks: usize, num_blocks: usize, extra_size: usize) Availability {
        return .{
            .required_for_n_blocks = size_in_blocks * num_blocks,
            .size_in_blocks = size_in_blocks,
            .num_blocks = num_blocks,
            .extra_size = extra_size,
        };
    }

    /// Feed one free region's block size. Returns true when the request is now
    /// satisfiable, so the caller can stop iterating.
    pub fn accept(self: *Availability, this_block_size: usize) bool {
        if (this_block_size >= self.required_for_n_blocks + self.extra_size) {
            return true;
        }
        if (this_block_size >= self.size_in_blocks) {
            self.count_of_blocks_of_size += this_block_size / self.size_in_blocks;
            const residual_size = this_block_size % self.size_in_blocks;
            if (residual_size >= self.extra_size) {
                self.have_extra_block = true;
            }
            if (self.count_of_blocks_of_size > self.num_blocks) {
                return true;
            }
            if (self.count_of_blocks_of_size == self.num_blocks and self.have_extra_block) {
                return true;
            }
        } else if (this_block_size >= self.extra_size) {
            self.have_extra_block = true;
            if (self.count_of_blocks_of_size >= self.num_blocks) {
                return true;
            }
        }
        return false;
    }
};

/// Whether the request fits across `region_sizes` (a convenience over the
/// accumulator).
pub fn isAvailable(region_sizes: []const usize, size_in_blocks: usize, num_blocks: usize, extra_size: usize) bool {
    var acc = Availability.init(size_in_blocks, num_blocks, extra_size);
    for (region_sizes) |s| {
        if (acc.accept(s)) return true;
    }
    return false;
}

test "one region large enough for everything wins immediately" {
    try std.testing.expect(isAvailable(&.{100}, 10, 2, 5)); // needs 20 + 5 = 25
}

test "whole blocks accumulate across regions" {
    // Three regions of 10 give exactly three blocks of size 10, extra_size 0.
    try std.testing.expect(isAvailable(&.{ 10, 10, 10 }, 10, 3, 0));
    // Only two such regions falls short of three blocks.
    try std.testing.expect(!isAvailable(&.{ 10, 10 }, 10, 3, 0));
}

test "a residual slack block is required when extra_size is non-zero" {
    // 12 blocks = one block of 10 with residual 2, which is < the extra 3.
    try std.testing.expect(!isAvailable(&.{12}, 10, 1, 3));
    // 13 blocks covers the block plus the extra outright.
    try std.testing.expect(isAvailable(&.{13}, 10, 1, 3));
}

test "a small region can supply the slack block a big one lacked" {
    // First region gives the one block but no slack; the second (size 3) is the
    // slack block on its own.
    try std.testing.expect(isAvailable(&.{ 10, 3 }, 10, 1, 3));
}

test "an empty free list satisfies nothing" {
    try std.testing.expect(!isAvailable(&.{}, 10, 1, 0));
}
