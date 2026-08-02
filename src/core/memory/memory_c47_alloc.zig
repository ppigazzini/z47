const runtime = @import("memory_runtime.zig");

pub fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque {
    const allocated = runtime.freeListAlloc(sizeInBlocks);
    if (allocated != null) {
        runtime.c47MemInBlocks +%= sizeInBlocks;
        return allocated;
    }

    return null;
}

pub fn reallocC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) ?*anyopaque {
    const allocated = runtime.freeListRealloc(pcMemPtr, oldSizeInBlocks, newSizeInBlocks);
    if (allocated != null) {
        runtime.c47MemInBlocks +%= newSizeInBlocks -% oldSizeInBlocks;
        return allocated;
    }

    return null;
}

pub fn reduceC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize, free_c47_blocks: *const fn (?*anyopaque, usize) callconv(.c) void) void {
    if (newSizeInBlocks == 0) {
        free_c47_blocks(pcMemPtr, oldSizeInBlocks);
        return;
    }

    runtime.freeListReduce(pcMemPtr, oldSizeInBlocks, newSizeInBlocks);
    runtime.c47MemInBlocks +%= newSizeInBlocks -% oldSizeInBlocks;
}

pub fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void {
    if (pcMemPtr == null) {
        return;
    }

    runtime.c47MemInBlocks -%= sizeInBlocks;
    runtime.freeListFree(pcMemPtr, sizeInBlocks);
}
