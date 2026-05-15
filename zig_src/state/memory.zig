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
    var free_mem: u32 = 0;
    var index: i32 = 0;

    while (index < runtime.numberOfFreeMemoryRegions) : (index += 1) {
        free_mem += runtime.getFreeRegion(@intCast(index)).sizeInBlocks;
    }

    return free_mem << runtime.BPB;
}

pub export fn isMemoryBlockAvailable(sizeInBlocks: usize, numBlocks: u16, extraFraction: f32) bool {
    var index: i32 = 0;
    const extra_size = runtime.scaleExtraSize(sizeInBlocks, extraFraction);
    const num_blocks: usize = numBlocks;
    const required_for_n_blocks = sizeInBlocks * num_blocks;
    var count_of_blocks_of_size: usize = 0;
    var have_extra_block = false;

    while (index < runtime.numberOfFreeMemoryRegions) : (index += 1) {
        const this_block_size: usize = runtime.getFreeRegion(@intCast(index)).sizeInBlocks;

        if (this_block_size >= required_for_n_blocks + extra_size) {
            return true;
        }

        if (this_block_size >= sizeInBlocks) {
            count_of_blocks_of_size += this_block_size / sizeInBlocks;
            const residual_size = this_block_size % sizeInBlocks;

            if (residual_size >= extra_size) {
                have_extra_block = true;
            }
            if (count_of_blocks_of_size > num_blocks) {
                return true;
            }
            if (count_of_blocks_of_size == num_blocks and have_extra_block) {
                return true;
            }
        } else if (this_block_size >= extra_size) {
            have_extra_block = true;
            if (count_of_blocks_of_size >= num_blocks) {
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
    const rounded_size = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes +%= rounded_size;
    return runtime.allocGmpBytes(rounded_size);
}

pub export fn reallocGmp(pcMemPtr: ?*anyopaque, oldSizeInBytes: usize, newSizeInBytes: usize) ?*anyopaque {
    const rounded_new_size = toBytesSize(toBlocks(newSizeInBytes));
    const rounded_old_size = toBytesSize(toBlocks(oldSizeInBytes));

    runtime.gmpMemInBytes +%= rounded_new_size -% rounded_old_size;
    return runtime.reallocGmpBytes(pcMemPtr, rounded_new_size);
}

pub export fn freeGmp(pcMemPtr: ?*anyopaque, sizeInBytes: usize) void {
    const rounded_size = toBytesSize(toBlocks(sizeInBytes));
    runtime.gmpMemInBytes -%= rounded_size;
    runtime.freeGmpBytes(pcMemPtr);
}

pub export fn resizeProgramMemory(newSizeInBlocks: u16) void {
    const current_size_in_blocks: u16 = runtime.getRamSizeInBlocks() - runtime.toC47MemPtr(runtime.beginOfProgramMemory);
    var delta_blocks: u16 = 0;
    var blocks_to_move: u16 = 0;
    var new_program_memory_pointer: [*c]u8 = null;

    if (newSizeInBlocks == current_size_in_blocks) {
        return;
    }

    if (newSizeInBlocks > current_size_in_blocks) {
        delta_blocks = newSizeInBlocks - current_size_in_blocks;
        const last_region_index: u16 = @intCast(runtime.numberOfFreeMemoryRegions - 1);
        var last_region = runtime.getFreeRegion(last_region_index);

        if (delta_blocks > last_region.sizeInBlocks) {
            runtime.handleResizeProgramMemoryOutOfMemory(delta_blocks);
        } else {
            const delta_bytes = toBytesSize(delta_blocks);

            blocks_to_move = current_size_in_blocks;
            new_program_memory_pointer = runtime.beginOfProgramMemory - delta_bytes;
            runtime.firstFreeProgramByte = runtime.firstFreeProgramByte - delta_bytes;
            last_region.sizeInBlocks -%= delta_blocks;
            runtime.setFreeRegion(last_region_index, last_region);
        }
    } else {
        const delta_bytes = toBytesSize(current_size_in_blocks - newSizeInBlocks);
        const last_region_index: u16 = @intCast(runtime.numberOfFreeMemoryRegions - 1);
        var last_region = runtime.getFreeRegion(last_region_index);

        delta_blocks = current_size_in_blocks - newSizeInBlocks;
        blocks_to_move = newSizeInBlocks;
        new_program_memory_pointer = runtime.beginOfProgramMemory + delta_bytes;
        runtime.firstFreeProgramByte = runtime.firstFreeProgramByte + delta_bytes;
        last_region.sizeInBlocks +%= delta_blocks;
        runtime.setFreeRegion(last_region_index, last_region);
    }

    runtime.copyBytes(new_program_memory_pointer, runtime.beginOfProgramMemory, toBytesU32(blocks_to_move));
    runtime.beginOfProgramMemory = new_program_memory_pointer;
}
