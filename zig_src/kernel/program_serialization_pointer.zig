const abi = @import("abi");
const block_math = abi.block_math;

pub fn toBlocks(byte_count: usize) u16 {
    return block_math.toBlocks(u16, byte_count);
}

pub fn toBytes(block_count: usize) usize {
    return block_math.toBytes(usize, block_count);
}

pub fn offsetPointer(ptr: [*c]u8, delta: isize) [*c]u8 {
    const base: isize = @intCast(@intFromPtr(ptr));
    return @ptrFromInt(@as(usize, @intCast(base + delta)));
}
