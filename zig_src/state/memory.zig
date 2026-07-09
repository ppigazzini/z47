const block_availability_owned = @import("memory_block_availability.zig");
const c47_alloc_owned = @import("memory_c47_alloc.zig");
const abi = @import("abi");
const block_math = abi.block_math;
const debug_owned = @import("memory_debug.zig");
const gmp_alloc_owned = @import("memory_gmp_alloc.zig");
const resize_program_owned = @import("memory_resize_program.zig");
const runtime = @import("memory_runtime.zig");

fn toBlocks(byte_count: usize) usize {
    return block_math.toBlocks(usize, byte_count);
}

fn toBytesSize(block_count: usize) usize {
    return block_math.toBytes(usize, block_count);
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
