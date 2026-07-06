const runtime = @import("memory_runtime.zig");

fn toBytesSize(block_count: usize) usize {
    return block_count << runtime.BPB;
}

fn toBytesU32(block_count: u16) u32 {
    return @as(u32, block_count) << runtime.BPB;
}

pub fn resizeProgramMemory(newSizeInBlocks: u16) void {
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
