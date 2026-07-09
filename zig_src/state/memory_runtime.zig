const std = @import("std");
const abi = @import("abi");
const builtin = @import("builtin");
const build_options = @import("memory_build_options");
const block_math = abi.block_math;

pub const freeMemoryRegion_t = abi.FreeMemoryRegion;

pub const BPB: u5 = 2;
pub const BYTES_PER_BLOCK: u32 = 1 << BPB;

const use_fake_harness_surface = @hasDecl(build_options, "use_fake_harness_surface") and build_options.use_fake_harness_surface;
const free_regions_are_inline_array = @hasDecl(build_options, "free_regions_are_inline_array") and build_options.free_regions_are_inline_array;
const max_free_regions: usize = if (@hasDecl(build_options, "max_free_regions")) build_options.max_free_regions else 200;
const ram_size_in_blocks: u16 = if (@hasDecl(build_options, "ram_size_in_blocks")) build_options.ram_size_in_blocks else 65534;

const C47_NULL: u16 = 65535;
const NOPARAM: u16 = 9876;

const FreeRegionsStorage = if (free_regions_are_inline_array) [max_free_regions]freeMemoryRegion_t else [*]freeMemoryRegion_t;

pub extern var numberOfFreeMemoryRegions: i32;
pub extern var beginOfProgramMemory: [*c]u8;
pub extern var firstFreeProgramByte: [*c]u8;
pub extern var gmpMemInBytes: usize;
pub extern var c47MemInBlocks: usize;
pub extern var freeMemoryRegions: FreeRegionsStorage;
pub extern var ram: [*]u32;

pub extern fn freeListAlloc(sizeInBlocks: usize) ?*anyopaque;
pub extern fn freeListRealloc(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) ?*anyopaque;
pub extern fn freeListReduce(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) void;
pub extern fn freeListFree(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;
pub extern fn xcopy(dest: [*c]u8, source: [*c]const u8, n: u32) ?*anyopaque;
pub extern fn backToSystem(confirmation: u16) void;
pub extern fn malloc(sizeInBytes: usize) ?*anyopaque;
pub extern fn realloc(pcMemPtr: ?*anyopaque, newSizeInBytes: usize) ?*anyopaque;
pub extern fn free(pcMemPtr: ?*anyopaque) void;
pub extern fn exit(code: c_int) noreturn;

pub extern fn z47_memory_runtime_get_ram_size_in_blocks() u16;
pub extern fn z47_memory_runtime_get_free_region(index: u16) freeMemoryRegion_t;
pub extern fn z47_memory_runtime_set_free_region(index: u16, region: freeMemoryRegion_t) void;
pub extern fn z47_memory_runtime_to_c47_mem_ptr(mem_ptr: [*c]u8) u16;
pub extern fn z47_memory_runtime_scale_extra_size(sizeInBlocks: usize, extraFraction: f32) usize;
pub extern fn z47_memory_runtime_copy_bytes(dest: [*c]u8, source: [*c]const u8, n: u32) ?*anyopaque;
pub extern fn z47_memory_runtime_handle_resize_program_memory_out_of_memory(deltaBlocks: u16) void;
pub extern fn z47_memory_runtime_alloc_gmp_bytes(sizeInBytes: usize) ?*anyopaque;
pub extern fn z47_memory_runtime_realloc_gmp_bytes(pcMemPtr: ?*anyopaque, newSizeInBytes: usize) ?*anyopaque;
pub extern fn z47_memory_runtime_free_gmp_bytes(pcMemPtr: ?*anyopaque) void;

fn toBytes(blocks: anytype) u64 {
    return block_math.toBytes(u64, blocks);
}

pub inline fn getRamSizeInBlocks() u16 {
    if (use_fake_harness_surface) {
        return z47_memory_runtime_get_ram_size_in_blocks();
    }

    return ram_size_in_blocks;
}

pub inline fn getFreeRegion(index: u16) freeMemoryRegion_t {
    if (use_fake_harness_surface) {
        return z47_memory_runtime_get_free_region(index);
    }

    return freeMemoryRegions[index];
}

pub inline fn setFreeRegion(index: u16, region: freeMemoryRegion_t) void {
    if (use_fake_harness_surface) {
        z47_memory_runtime_set_free_region(index, region);
        return;
    }

    freeMemoryRegions[index] = region;
}

pub inline fn toC47MemPtr(mem_ptr: [*c]u8) u16 {
    if (use_fake_harness_surface) {
        return z47_memory_runtime_to_c47_mem_ptr(mem_ptr);
    }

    if (mem_ptr == null) {
        return C47_NULL;
    }

    const mem_addr = @intFromPtr(mem_ptr);
    const ram_addr = @intFromPtr(ram);
    return @intCast(@divExact(mem_addr - ram_addr, @as(usize, BYTES_PER_BLOCK)));
}

pub inline fn scaleExtraSize(sizeInBlocks: usize, extraFraction: f32) usize {
    if (use_fake_harness_surface) {
        return z47_memory_runtime_scale_extra_size(sizeInBlocks, extraFraction);
    }

    return @intFromFloat(@as(f64, @floatFromInt(sizeInBlocks)) * @as(f64, extraFraction));
}

pub inline fn copyBytes(dest: [*c]u8, source: [*c]const u8, n: u32) void {
    if (use_fake_harness_surface) {
        _ = z47_memory_runtime_copy_bytes(dest, source, n);
        return;
    }

    if (n == 0) {
        return;
    }

    _ = xcopy(dest, source, n);
}

pub inline fn handleResizeProgramMemoryOutOfMemory(deltaBlocks: u16) void {
    if (use_fake_harness_surface) {
        z47_memory_runtime_handle_resize_program_memory_out_of_memory(deltaBlocks);
        return;
    }

    if (builtin.os.tag == .freestanding) {
        backToSystem(NOPARAM);
        return;
    }

    var free_memory: i32 = 0;
    var i: i32 = 0;
    while (i < numberOfFreeMemoryRegions) : (i += 1) {
        free_memory += getFreeRegion(@intCast(i)).sizeInBlocks;
    }

    std.debug.print(
        "\nOUT OF MEMORY\nMemory claimed: {d} bytes\nFragmented free memory: {d} bytes\n",
        .{ toBytes(deltaBlocks), toBytes(free_memory) },
    );
    exit(-3);
}

pub inline fn allocGmpBytes(sizeInBytes: usize) ?*anyopaque {
    if (use_fake_harness_surface) {
        return z47_memory_runtime_alloc_gmp_bytes(sizeInBytes);
    }

    return malloc(sizeInBytes);
}

pub inline fn reallocGmpBytes(pcMemPtr: ?*anyopaque, newSizeInBytes: usize) ?*anyopaque {
    if (use_fake_harness_surface) {
        return z47_memory_runtime_realloc_gmp_bytes(pcMemPtr, newSizeInBytes);
    }

    return realloc(pcMemPtr, newSizeInBytes);
}

pub inline fn freeGmpBytes(pcMemPtr: ?*anyopaque) void {
    if (use_fake_harness_surface) {
        z47_memory_runtime_free_gmp_bytes(pcMemPtr);
        return;
    }

    free(pcMemPtr);
}
