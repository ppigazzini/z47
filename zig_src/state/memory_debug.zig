const std = @import("std");
const builtin = @import("builtin");
const runtime = @import("memory_runtime.zig");

fn toBytesSize(block_count: usize) usize {
    return block_count << runtime.BPB;
}

pub fn getFreeRamMemory() u32 {
    var free_mem: u32 = 0;
    var index: i32 = 0;

    while (index < runtime.numberOfFreeMemoryRegions) : (index += 1) {
        free_mem += runtime.getFreeRegion(@intCast(index)).sizeInBlocks;
    }

    return free_mem << runtime.BPB;
}

pub fn debugMemory(message: [*:0]const u8) void {
    if (comptime builtin.os.tag == .freestanding) {
        return;
    }

    std.debug.print(
        "\n{s}\nC47 owns {d: >6} bytes and GMP owns {d: >6} bytes ({d} bytes free)\n",
        .{ std.mem.span(message), toBytesSize(runtime.c47MemInBlocks), runtime.gmpMemInBytes, getFreeRamMemory() },
    );
    std.debug.print("    Addr   Size\n", .{});

    var index: i32 = 0;
    while (index < runtime.numberOfFreeMemoryRegions) : (index += 1) {
        const region = runtime.getFreeRegion(@intCast(index));
        std.debug.print("{d: >2}{d: >6}{d: >7}\n", .{ index, region.blockAddress, region.sizeInBlocks });
    }

    std.debug.print("\n", .{});
}