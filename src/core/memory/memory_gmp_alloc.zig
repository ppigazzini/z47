const runtime = @import("memory_runtime.zig");
const abi = @import("abi");
const block_math = abi.block_math;

fn toBlocks(byte_count: usize) usize {
    return block_math.toBlocks(usize, byte_count);
}

fn toBytesSize(block_count: usize) usize {
    return block_math.toBytes(usize, block_count);
}

// GMP never checks what its allocator returns, so a NULL here becomes limb writes
// through a null pointer. TMP_ALLOC blocks over the 1 KB split of the gmp-impl.h
// overlay reach these functions too, through __gmp_tmp_reentrant_alloc, so heap
// exhaustion stops here with a message instead of corrupting memory
// mid-arithmetic.
fn gmpAllocFailed() ?*anyopaque {
    abi.host.showBugScreen("In function allocGmp: GMP is out of memory");
    runtime.stopOnGmpExhaustion();
    return null;
}

pub fn allocGmp(sizeInBytes: usize) ?*anyopaque {
    const rounded_size = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes +%= rounded_size;
    const pcMemPtr = runtime.allocGmpBytes(rounded_size);
    if (pcMemPtr == null and rounded_size != 0) {
        return gmpAllocFailed();
    }
    return pcMemPtr;
}

pub fn reallocGmp(pcMemPtr: ?*anyopaque, oldSizeInBytes: usize, newSizeInBytes: usize) ?*anyopaque {
    const rounded_new_size = toBytesSize(toBlocks(newSizeInBytes));
    const rounded_old_size = toBytesSize(toBlocks(oldSizeInBytes));

    runtime.gmpMemInBytes +%= rounded_new_size -% rounded_old_size;
    const pcNewPtr = runtime.reallocGmpBytes(pcMemPtr, rounded_new_size);
    if (pcNewPtr == null and rounded_new_size != 0) {
        return gmpAllocFailed();
    }
    return pcNewPtr;
}

pub fn freeGmp(pcMemPtr: ?*anyopaque, sizeInBytes: usize) void {
    const rounded_size = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes -%= rounded_size;
    runtime.freeGmpBytes(pcMemPtr);
}
