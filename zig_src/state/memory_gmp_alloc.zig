const runtime = @import("memory_runtime.zig");
const abi = @import("abi");
const block_math = abi.block_math;

fn toBlocks(byte_count: usize) usize {
    return block_math.toBlocks(usize, byte_count);
}

fn toBytesSize(block_count: usize) usize {
    return block_math.toBytes(usize, block_count);
}

pub fn allocGmp(sizeInBytes: usize) ?*anyopaque {
    const rounded_size = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes +%= rounded_size;
    return runtime.allocGmpBytes(rounded_size);
}

pub fn reallocGmp(pcMemPtr: ?*anyopaque, oldSizeInBytes: usize, newSizeInBytes: usize) ?*anyopaque {
    const rounded_new_size = toBytesSize(toBlocks(newSizeInBytes));
    const rounded_old_size = toBytesSize(toBlocks(oldSizeInBytes));

    runtime.gmpMemInBytes +%= rounded_new_size -% rounded_old_size;
    return runtime.reallocGmpBytes(pcMemPtr, rounded_new_size);
}

pub fn freeGmp(pcMemPtr: ?*anyopaque, sizeInBytes: usize) void {
    const rounded_size = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes -%= rounded_size;
    runtime.freeGmpBytes(pcMemPtr);
}
