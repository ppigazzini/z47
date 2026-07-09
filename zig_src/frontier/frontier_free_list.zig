// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/core/freeList.c: the C47 block allocator over the `ram`
// pool. freeListAlloc/Realloc/Reduce/Free are the calculator's allocator (used
// by GMP and the register/variable store), so they are exported with C linkage
// and force-included by frontier.zig. The testSuite exercises them on every
// allocation, which is the parity gate.
//
// Build-conditional layout (frontier_build_options):
//   * old_hw firmware stores freeMemoryRegions as a static array; host and DMCP5
//     store a pointer to it.
//   * Only the PC build tracks allocatedMemoryRegions (double-free diagnostics).
//   * The free-region cap is 50 on old_hw firmware, 200 elsewhere.

const std = @import("std");
const abi = @import("abi");
const build_options = @import("frontier_build_options");
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_config = @import("frontier_config.zig"); // M-callconv: Zig-to-Zig

const dmcp_build: bool = build_options.dmcp_build;
const old_hw: bool = build_options.old_hw;
const free_regions_is_array: bool = dmcp_build and old_hw;
const track_allocations: bool = !dmcp_build;

const BPB = 2; // 2^BPB bytes per block
const C47_NULL: u16 = 65535;
const NOPARAM: u16 = 9876;
const MAX_FREE_REGIONS: i32 = if (free_regions_is_array) 50 else 200;
const MAX_ALLOCATED_REGIONS: i32 = 5000;

const freeMemoryRegion_t = abi.FreeMemoryRegion;

extern var ram: [*c]u32;
extern var numberOfFreeMemoryRegions: i32;

inline fn freeRegions() [*c]freeMemoryRegion_t {
    if (comptime free_regions_is_array) {
        return @extern([*c]freeMemoryRegion_t, .{ .name = "freeMemoryRegions" });
    } else {
        return @extern(*[*c]freeMemoryRegion_t, .{ .name = "freeMemoryRegions" }).*;
    }
}

// PC-only allocation tracking.
const allocated = if (track_allocations) struct {
    extern var numberOfAllocatedMemoryRegions: i32;
    inline fn regions() [*c]freeMemoryRegion_t {
        return @extern([*c]freeMemoryRegion_t, .{ .name = "allocatedMemoryRegions" });
    }
} else struct {};

inline fn toBytes(blocks: u32) u32 {
    return abi.block_math.toBytes(u32, blocks);
}

inline fn toPcMemPtr(blockAddress: u16) ?*anyopaque {
    if (blockAddress == C47_NULL) return null;
    return @ptrCast(ram + blockAddress);
}

inline fn toC47MemPtr(pcMemPtr: ?*const anyopaque) u16 {
    const p = pcMemPtr orelse return C47_NULL;
    return @intCast((@intFromPtr(p) - @intFromPtr(ram)) >> BPB);
}

inline fn regionBytes(count: i32) u32 {
    return @intCast(@as(i64, count) * @sizeOf(freeMemoryRegion_t));
}

fn trackAllocation(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void {
    const ar = allocated.regions();
    const n: usize = @intCast(allocated.numberOfAllocatedMemoryRegions);
    ar[n].blockAddress = toC47MemPtr(pcMemPtr);
    ar[n].sizeInBlocks = @intCast(sizeInBlocks);
    allocated.numberOfAllocatedMemoryRegions += 1;
    if (allocated.numberOfAllocatedMemoryRegions >= MAX_ALLOCATED_REGIONS) {
        std.debug.print("error: numberOfAllocatedMemoryRegions is >= MAX_ALLOCATED_REGIONS, increase MAX_ALLOCATED_REGIONS in defines.h (this affects only the PC simulator not the HW firmware)\n", .{});
    }
}

// Drop the tracking entry for an allocation being freed/reduced. Returns the
// recorded size in blocks if found (for the diagnostic size check), else null.
fn untrackAllocation(c47RamPtr: u16) ?u16 {
    const ar = allocated.regions();
    var region: i32 = 0;
    while (region < allocated.numberOfAllocatedMemoryRegions) : (region += 1) {
        const idx: usize = @intCast(region);
        if (ar[idx].blockAddress == c47RamPtr) {
            const recorded = ar[idx].sizeInBlocks;
            if (allocated.numberOfAllocatedMemoryRegions - region - 1 != 0) {
                _ = frontier_char_string.xcopy(@ptrCast(ar + idx), @ptrCast(ar + idx + 1), regionBytes(allocated.numberOfAllocatedMemoryRegions - region - 1));
            }
            allocated.numberOfAllocatedMemoryRegions -= 1;
            return recorded;
        }
    }
    return null;
}

pub export fn freeListAlloc(sizeInBlocksArg: usize) callconv(.c) ?*anyopaque {
    var sizeInBlocks = sizeInBlocksArg;
    var minSizeInBlocks: u16 = 65535;
    var minBlock: u16 = C47_NULL;

    if (sizeInBlocks == 0) {
        sizeInBlocks = 1;
    }

    const fr = freeRegions();

    // Search the smallest hole where the claimed block fits.
    var i: i32 = 0;
    while (i < numberOfFreeMemoryRegions) : (i += 1) {
        const idx: usize = @intCast(i);
        if (fr[idx].sizeInBlocks == sizeInBlocks) {
            const pcMemPtr = toPcMemPtr(fr[idx].blockAddress);
            _ = frontier_char_string.xcopy(@ptrCast(fr + idx), @ptrCast(fr + idx + 1), regionBytes(numberOfFreeMemoryRegions - i - 1));
            numberOfFreeMemoryRegions -= 1;
            if (comptime track_allocations) trackAllocation(pcMemPtr, sizeInBlocks);
            return pcMemPtr;
        } else if (fr[idx].sizeInBlocks > sizeInBlocks and fr[idx].sizeInBlocks < minSizeInBlocks) {
            minSizeInBlocks = fr[idx].sizeInBlocks;
            minBlock = @intCast(i);
        }
    }

    if (minBlock == C47_NULL) {
        if (comptime !dmcp_build) {
            var total: u32 = 0;
            var j: i32 = 0;
            while (j < numberOfFreeMemoryRegions) : (j += 1) {
                total += fr[@as(usize, @intCast(j))].sizeInBlocks;
            }
            std.debug.print("\nOUT OF MEMORY\nMemory claimed: {d} bytes\nFragmented free memory: {d} bytes\n", .{ toBytes(@intCast(sizeInBlocks)), toBytes(total) });
        }
        return null;
    }

    const mb: usize = @intCast(minBlock);
    const pcMemPtr = toPcMemPtr(fr[mb].blockAddress);
    fr[mb].blockAddress += @as(u16, @intCast(sizeInBlocks));
    fr[mb].sizeInBlocks -= @as(u16, @intCast(sizeInBlocks));
    if (comptime track_allocations) trackAllocation(pcMemPtr, sizeInBlocks);
    return pcMemPtr;
}

pub export fn freeListRealloc(pcMemPtr: ?*anyopaque, oldSizeInBlocksArg: usize, newSizeInBlocksArg: usize) callconv(.c) ?*anyopaque {
    var oldSizeInBlocks = oldSizeInBlocksArg;
    var newSizeInBlocks = newSizeInBlocksArg;

    // GMP never calls realloc with pcMemPtr being NULL.
    if (oldSizeInBlocks == 0) oldSizeInBlocks = 1;
    if (newSizeInBlocks == 0) newSizeInBlocks = 1;

    const newMemPtr = freeListAlloc(newSizeInBlocks);
    if (newMemPtr != null) {
        _ = frontier_char_string.xcopy(newMemPtr, pcMemPtr, toBytes(@intCast(@min(newSizeInBlocks, oldSizeInBlocks))));
        freeListFree(pcMemPtr, oldSizeInBlocks);
        return newMemPtr;
    }
    return null; // not enough memory
}

pub export fn freeListReduce(pcMemPtr: ?*anyopaque, oldSizeInBlocksArg: usize, newSizeInBlocks: usize) callconv(.c) void {
    var oldSizeInBlocks = oldSizeInBlocksArg;
    if (oldSizeInBlocks == 0) oldSizeInBlocks = 1;

    var c47RamPtr = toC47MemPtr(pcMemPtr);
    const fr = freeRegions();

    if (comptime track_allocations) {
        const ar = allocated.regions();
        var region: i32 = 0;
        var found = false;
        while (region < allocated.numberOfAllocatedMemoryRegions) : (region += 1) {
            const idx: usize = @intCast(region);
            if (ar[idx].blockAddress == c47RamPtr) {
                if (ar[idx].sizeInBlocks != oldSizeInBlocks) {
                    std.debug.print("---->Memory reducing: {d} blocks at address {d}, but {d} were allocated\n", .{ oldSizeInBlocks, c47RamPtr, ar[idx].sizeInBlocks });
                }
                ar[idx].sizeInBlocks -= @as(u16, @intCast(oldSizeInBlocks - newSizeInBlocks));
                found = true;
                break;
            }
        }
        if (!found) {
            std.debug.print("---->Memory reducing: {d} blocks at address {d} never allocated at this address\n", .{ oldSizeInBlocks, c47RamPtr });
        }
    }

    // Is the freed tail just before another free block?
    var done = false;
    const addr: u16 = c47RamPtr + @as(u16, @intCast(oldSizeInBlocks)); // first block after the region
    c47RamPtr += @as(u16, @intCast(newSizeInBlocks)); // address of the block to free
    var i: i32 = 0;
    while (i < numberOfFreeMemoryRegions and fr[@as(usize, @intCast(i))].blockAddress <= addr) : (i += 1) {
        const idx: usize = @intCast(i);
        if (fr[idx].blockAddress == addr) {
            fr[idx].blockAddress = c47RamPtr;
            fr[idx].sizeInBlocks += @as(u16, @intCast(oldSizeInBlocks - newSizeInBlocks));
            done = true;
            break;
        }
    }

    if (!done) {
        insertFreeBlock(c47RamPtr, @intCast(oldSizeInBlocks - newSizeInBlocks));
    }
}

pub export fn freeListFree(pcMemPtr: ?*anyopaque, sizeInBlocksArg: usize) callconv(.c) void {
    // GMP never calls free with pcMemPtr being NULL.
    if (pcMemPtr == null) {
        return;
    }

    var sizeInBlocks = sizeInBlocksArg;
    if (sizeInBlocks == 0) sizeInBlocks = 1;

    const c47RamPtr = toC47MemPtr(pcMemPtr);
    const fr = freeRegions();

    if (comptime track_allocations) {
        const recorded = untrackAllocation(c47RamPtr);
        if (recorded) |sz| {
            if (sz != sizeInBlocks) {
                std.debug.print("---->Memory freeing A (regions): {d} blocks at address {d}, but {d} were allocated\n", .{ sizeInBlocks, c47RamPtr, sz });
            }
        } else {
            std.debug.print("---->Memory freeing B (number of regions): {d} blocks at address {d} never allocated at this address\n", .{ sizeInBlocks, c47RamPtr });
        }
    }

    var done = false;
    var j: i32 = 0;

    // Is the freed block just before another free block?
    const addr: u16 = c47RamPtr + @as(u16, @intCast(sizeInBlocks)); // first block after the freed region
    var i: i32 = 0;
    while (i < numberOfFreeMemoryRegions and fr[@as(usize, @intCast(i))].blockAddress <= addr) : (i += 1) {
        const idx: usize = @intCast(i);
        if (fr[idx].blockAddress == addr) {
            fr[idx].blockAddress = c47RamPtr;
            fr[idx].sizeInBlocks += @as(u16, @intCast(sizeInBlocks));
            sizeInBlocks = fr[idx].sizeInBlocks;
            j = i;
            done = true;
            break;
        }
    }

    // Is the freed block just after another free block?
    i = 0;
    while (i < numberOfFreeMemoryRegions and fr[@as(usize, @intCast(i))].blockAddress + fr[@as(usize, @intCast(i))].sizeInBlocks <= c47RamPtr) : (i += 1) {
        const idx: usize = @intCast(i);
        if (fr[idx].blockAddress + fr[idx].sizeInBlocks == c47RamPtr) {
            fr[idx].sizeInBlocks += @as(u16, @intCast(sizeInBlocks));
            if (done) {
                const jdx: usize = @intCast(j);
                _ = frontier_char_string.xcopy(@ptrCast(fr + jdx), @ptrCast(fr + jdx + 1), regionBytes(numberOfFreeMemoryRegions - j - 1));
                numberOfFreeMemoryRegions -= 1;
            } else {
                done = true;
            }
            break;
        }
    }

    if (!done) {
        insertFreeBlock(c47RamPtr, @intCast(sizeInBlocks));
    }
}

// Insert a new free region keeping freeMemoryRegions sorted by address. Shared
// by the no-coalesce tails of freeListReduce and freeListFree.
fn insertFreeBlock(c47RamPtr: u16, sizeInBlocks: u16) void {
    const fr = freeRegions();

    if (numberOfFreeMemoryRegions == MAX_FREE_REGIONS) {
        if (comptime dmcp_build) {
            frontier_config.backToSystem(NOPARAM);
        } else {
            std.debug.print("\n* The maximum number of free memory blocks has been exceeded! *\n", .{});
            std.process.exit(254); // exit(-2) truncated to a process exit code
        }
    }

    var i: i32 = 0;
    while (i < numberOfFreeMemoryRegions and fr[@as(usize, @intCast(i))].blockAddress < c47RamPtr) : (i += 1) {}

    if (i < numberOfFreeMemoryRegions) {
        const idx: usize = @intCast(i);
        _ = frontier_char_string.xcopy(@ptrCast(fr + idx + 1), @ptrCast(fr + idx), regionBytes(numberOfFreeMemoryRegions - i));
    }

    const idx: usize = @intCast(i);
    fr[idx].blockAddress = c47RamPtr;
    fr[idx].sizeInBlocks = sizeInBlocks;
    numberOfFreeMemoryRegions += 1;
}
