const runtime = @import("program_serialization_runtime.zig");

pub fn toBlocks(byte_count: usize) u16 {
    return @intCast((byte_count + (runtime.BYTES_PER_BLOCK - 1)) >> runtime.BPB);
}

pub fn toBytes(block_count: usize) usize {
    return block_count << runtime.BPB;
}

pub fn offsetPointer(ptr: [*c]u8, delta: isize) [*c]u8 {
    const base: isize = @intCast(@intFromPtr(ptr));
    return @ptrFromInt(@as(usize, @intCast(base + delta)));
}