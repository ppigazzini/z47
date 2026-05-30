const block_availability_owned = @import("memory_block_availability_owned.zig");
const c47_alloc_owned = @import("memory_c47_alloc_owned.zig");
const debug_owned = @import("memory_debug_owned.zig");
const gmp_alloc_owned = @import("memory_gmp_alloc_owned.zig");
const resize_program_owned = @import("memory_resize_program_owned.zig");
const runtime = @import("memory_runtime.zig");

fn toBlocks(byte_count: usize) usize {
    return (byte_count + (runtime.BYTES_PER_BLOCK - 1)) >> runtime.BPB;
}

fn toBytesSize(block_count: usize) usize {
    return block_count << runtime.BPB;
}

fn toBytesU32(block_count: u16) u32 {
    return @as(u32, block_count) << runtime.BPB;
}

pub export fn debugMemory(message: [*:0]const u8) callconv(.c) void {
    debug_owned.debugMemory(message);
}

pub export fn getFreeRamMemory() u32 {
    return debug_owned.getFreeRamMemory();
}

pub export fn isMemoryBlockAvailable(sizeInBlocks: usize, numBlocks: u16, extraFraction: f32) bool {
    return block_availability_owned.isMemoryBlockAvailable(sizeInBlocks, numBlocks, extraFraction);
}

pub export fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque {
    return c47_alloc_owned.allocC47Blocks(sizeInBlocks);
}

pub export fn reallocC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) ?*anyopaque {
    return c47_alloc_owned.reallocC47Blocks(pcMemPtr, oldSizeInBlocks, newSizeInBlocks);
}

pub export fn reduceC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) void {
    c47_alloc_owned.reduceC47Blocks(pcMemPtr, oldSizeInBlocks, newSizeInBlocks, freeC47Blocks);
}

pub export fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void {
    c47_alloc_owned.freeC47Blocks(pcMemPtr, sizeInBlocks);
}

pub export fn allocGmp(sizeInBytes: usize) ?*anyopaque {
    return gmp_alloc_owned.allocGmp(sizeInBytes);
}

pub export fn reallocGmp(pcMemPtr: ?*anyopaque, oldSizeInBytes: usize, newSizeInBytes: usize) ?*anyopaque {
    return gmp_alloc_owned.reallocGmp(pcMemPtr, oldSizeInBytes, newSizeInBytes);
}

pub export fn freeGmp(pcMemPtr: ?*anyopaque, sizeInBytes: usize) void {
    gmp_alloc_owned.freeGmp(pcMemPtr, sizeInBytes);
}

pub export fn resizeProgramMemory(newSizeInBlocks: u16) void {
    resize_program_owned.resizeProgramMemory(newSizeInBlocks);
}
