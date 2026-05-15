pub const freeMemoryRegion_t = extern struct {
    blockAddress: u16,
    sizeInBlocks: u16,
};

pub const BPB: u5 = 2;
pub const BYTES_PER_BLOCK: u32 = 1 << BPB;

pub extern var numberOfFreeMemoryRegions: i32;
pub extern var beginOfProgramMemory: [*c]u8;
pub extern var firstFreeProgramByte: [*c]u8;
pub extern var gmpMemInBytes: usize;
pub extern var c47MemInBlocks: usize;

pub extern fn freeListAlloc(sizeInBlocks: usize) ?*anyopaque;
pub extern fn freeListRealloc(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) ?*anyopaque;
pub extern fn freeListReduce(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) void;
pub extern fn freeListFree(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;

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

pub inline fn getRamSizeInBlocks() u16 {
    return z47_memory_runtime_get_ram_size_in_blocks();
}

pub inline fn getFreeRegion(index: u16) freeMemoryRegion_t {
    return z47_memory_runtime_get_free_region(index);
}

pub inline fn setFreeRegion(index: u16, region: freeMemoryRegion_t) void {
    z47_memory_runtime_set_free_region(index, region);
}

pub inline fn toC47MemPtr(mem_ptr: [*c]u8) u16 {
    return z47_memory_runtime_to_c47_mem_ptr(mem_ptr);
}

pub inline fn scaleExtraSize(sizeInBlocks: usize, extraFraction: f32) usize {
    return z47_memory_runtime_scale_extra_size(sizeInBlocks, extraFraction);
}

pub inline fn copyBytes(dest: [*c]u8, source: [*c]const u8, n: u32) void {
    _ = z47_memory_runtime_copy_bytes(dest, source, n);
}

pub inline fn handleResizeProgramMemoryOutOfMemory(deltaBlocks: u16) void {
    z47_memory_runtime_handle_resize_program_memory_out_of_memory(deltaBlocks);
}

pub inline fn allocGmpBytes(sizeInBytes: usize) ?*anyopaque {
    return z47_memory_runtime_alloc_gmp_bytes(sizeInBytes);
}

pub inline fn reallocGmpBytes(pcMemPtr: ?*anyopaque, newSizeInBytes: usize) ?*anyopaque {
    return z47_memory_runtime_realloc_gmp_bytes(pcMemPtr, newSizeInBytes);
}

pub inline fn freeGmpBytes(pcMemPtr: ?*anyopaque) void {
    z47_memory_runtime_free_gmp_bytes(pcMemPtr);
}
