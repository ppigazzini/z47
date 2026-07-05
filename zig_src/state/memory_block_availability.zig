const runtime = @import("memory_runtime.zig");

pub fn isMemoryBlockAvailable(sizeInBlocks: usize, numBlocks: u16, extraFraction: f32) bool {
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