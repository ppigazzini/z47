const runtime = @import("memory_runtime.zig");
const pure = @import("block_availability_pure.zig"); // std-only bin-packing predicate

pub fn isMemoryBlockAvailable(sizeInBlocks: usize, numBlocks: u16, extraFraction: f32) bool {
    const extra_size = runtime.scaleExtraSize(sizeInBlocks, extraFraction);
    var acc = pure.Availability.init(sizeInBlocks, numBlocks, extra_size);

    var index: i32 = 0;
    while (index < runtime.numberOfFreeMemoryRegions) : (index += 1) {
        if (acc.accept(runtime.getFreeRegion(@intCast(index)).sizeInBlocks)) {
            return true;
        }
    }

    return false;
}
