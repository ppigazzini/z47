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

pub export fn getFreeRamMemory() u32 {
    var freeMem: u32 = 0;
    var index: i32 = 0;

    while (index < runtime.numberOfFreeMemoryRegions) : (index += 1) {
        freeMem += runtime.getFreeRegion(@intCast(index)).sizeInBlocks;
    }

    return freeMem << runtime.BPB;
}

pub export fn isMemoryBlockAvailable(sizeInBlocks: usize, numBlocks: u16, extraFraction: f32) bool {
    var index: i32 = 0;
    const extraSize = runtime.scaleExtraSize(sizeInBlocks, extraFraction);
    const blockCount: usize = numBlocks;
    const requiredSizeForBlockCount = sizeInBlocks * blockCount;
    var availableBlockCount: usize = 0;
    var hasExtraBlock = false;

    while (index < runtime.numberOfFreeMemoryRegions) : (index += 1) {
        const blockSize: usize = runtime.getFreeRegion(@intCast(index)).sizeInBlocks;

        if (blockSize >= requiredSizeForBlockCount + extraSize) {
            return true;
        }

        if (blockSize >= sizeInBlocks) {
            availableBlockCount += blockSize / sizeInBlocks;
            const residualSize = blockSize % sizeInBlocks;

            if (residualSize >= extraSize) {
                hasExtraBlock = true;
            }
            if (availableBlockCount > blockCount) {
                return true;
            }
            if (availableBlockCount == blockCount and hasExtraBlock) {
                return true;
            }
        } else if (blockSize >= extraSize) {
            hasExtraBlock = true;
            if (availableBlockCount >= blockCount) {
                return true;
            }
        }
    }

    return false;
}

pub export fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque {
    const allocated = runtime.freeListAlloc(sizeInBlocks);
    if (allocated != null) {
        runtime.c47MemInBlocks +%= sizeInBlocks;
        return allocated;
    }

    return null;
}

pub export fn reallocC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) ?*anyopaque {
    const allocated = runtime.freeListRealloc(pcMemPtr, oldSizeInBlocks, newSizeInBlocks);
    if (allocated != null) {
        runtime.c47MemInBlocks +%= newSizeInBlocks -% oldSizeInBlocks;
        return allocated;
    }

    return null;
}

pub export fn reduceC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) void {
    if (newSizeInBlocks == 0) {
        freeC47Blocks(pcMemPtr, oldSizeInBlocks);
        return;
    }

    runtime.freeListReduce(pcMemPtr, oldSizeInBlocks, newSizeInBlocks);
    runtime.c47MemInBlocks +%= newSizeInBlocks -% oldSizeInBlocks;
}

pub export fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void {
    if (pcMemPtr == null) {
        return;
    }

    runtime.c47MemInBlocks -%= sizeInBlocks;
    runtime.freeListFree(pcMemPtr, sizeInBlocks);
}

pub export fn allocGmp(sizeInBytes: usize) ?*anyopaque {
    const roundedSize = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes +%= roundedSize;
    return runtime.allocGmpBytes(roundedSize);
}

pub export fn reallocGmp(pcMemPtr: ?*anyopaque, oldSizeInBytes: usize, newSizeInBytes: usize) ?*anyopaque {
    const roundedNewSize = toBytesSize(toBlocks(newSizeInBytes));
    const roundedOldSize = toBytesSize(toBlocks(oldSizeInBytes));

    runtime.gmpMemInBytes +%= roundedNewSize -% roundedOldSize;
    return runtime.reallocGmpBytes(pcMemPtr, roundedNewSize);
}

pub export fn freeGmp(pcMemPtr: ?*anyopaque, sizeInBytes: usize) void {
    const roundedSize = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes -%= roundedSize;
    runtime.freeGmpBytes(pcMemPtr);
}

pub export fn resizeProgramMemory(newSizeInBlocks: u16) void {
    const currentSizeInBlocks: u16 = runtime.getRamSizeInBlocks() - runtime.toC47MemPtr(runtime.beginOfProgramMemory);
    var deltaBlocks: u16 = 0;
    var blocksToMove: u16 = 0;
    var newProgramMemoryPointer: [*c]u8 = null;

    if (newSizeInBlocks == currentSizeInBlocks) {
        return;
    }

    if (newSizeInBlocks > currentSizeInBlocks) {
        deltaBlocks = newSizeInBlocks - currentSizeInBlocks;
        const lastRegionIndex: u16 = @intCast(runtime.numberOfFreeMemoryRegions - 1);
        var lastRegion = runtime.getFreeRegion(lastRegionIndex);

        if (deltaBlocks > lastRegion.sizeInBlocks) {
            runtime.handleResizeProgramMemoryOutOfMemory(deltaBlocks);
        } else {
            const deltaBytes = toBytesSize(deltaBlocks);

            blocksToMove = currentSizeInBlocks;
            newProgramMemoryPointer = runtime.beginOfProgramMemory - deltaBytes;
            runtime.firstFreeProgramByte = runtime.firstFreeProgramByte - deltaBytes;
            lastRegion.sizeInBlocks -%= deltaBlocks;
            runtime.setFreeRegion(lastRegionIndex, lastRegion);
        }
    } else {
        const deltaBytes = toBytesSize(currentSizeInBlocks - newSizeInBlocks);
        const lastRegionIndex: u16 = @intCast(runtime.numberOfFreeMemoryRegions - 1);
        var lastRegion = runtime.getFreeRegion(lastRegionIndex);

        deltaBlocks = currentSizeInBlocks - newSizeInBlocks;
        blocksToMove = newSizeInBlocks;
        newProgramMemoryPointer = runtime.beginOfProgramMemory + deltaBytes;
        runtime.firstFreeProgramByte = runtime.firstFreeProgramByte + deltaBytes;
        lastRegion.sizeInBlocks +%= deltaBlocks;
        runtime.setFreeRegion(lastRegionIndex, lastRegion);
    }

    runtime.copyBytes(newProgramMemoryPointer, runtime.beginOfProgramMemory, toBytesU32(blocksToMove));
    runtime.beginOfProgramMemory = newProgramMemoryPointer;
}
