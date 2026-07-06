const runtime = @import("memory_runtime.zig");

fn toBlocks(byte_count: usize) usize {
    return (byte_count + (runtime.BYTES_PER_BLOCK - 1)) >> runtime.BPB;
}

fn toBytesSize(block_count: usize) usize {
    return block_count << runtime.BPB;
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
