const payload_bytes_owned = @import("register_metadata_payload_bytes_owned.zig");
const stack_runtime = @import("stack_runtime.zig");

extern fn z47_register_metadata_config_size_in_blocks() u16;
extern fn isMemoryBlockAvailable(size_in_blocks: usize, num_blocks: u16, extra_fraction: f32) bool;

fn bytesPerBlock() comptime_int {
    return payload_bytes_owned.bytesPerBlock();
}

fn toBlocks(bytes: usize) u16 {
    return payload_bytes_owned.toBlocks(bytes);
}

pub fn strLgIntHeaderSizeInBlocks() u16 {
    return toBlocks(@sizeOf(payload_bytes_owned.strLgIntHeader_t));
}

pub fn matrixHeaderSizeInBlocks() u16 {
    return toBlocks(@sizeOf(payload_bytes_owned.matrixHeader_t));
}

pub fn real34SizeInBlocks() u16 {
    return stack_runtime.real34SizeInBlocks();
}

pub fn complex34SizeInBlocks() u16 {
    return real34SizeInBlocks() * 2;
}

pub fn shortIntegerSizeInBlocks() u16 {
    return 2;
}

pub fn configSizeInBlocks() u16 {
    return z47_register_metadata_config_size_in_blocks();
}

pub fn memoryBlockAvailable(size_in_blocks: u16) bool {
    return isMemoryBlockAvailable(size_in_blocks, 2, 0.1);
}

pub fn alignLongIntegerBlocks(size_in_blocks: u16) u16 {
    const limb_size_in_bytes = @sizeOf(usize);
    const limb_size_in_blocks = toBlocks(limb_size_in_bytes);

    if ((@as(usize, size_in_blocks) * bytesPerBlock()) % limb_size_in_bytes != 0) {
        return @intCast(((@as(usize, size_in_blocks) / limb_size_in_blocks) + 1) * limb_size_in_blocks);
    }

    return size_in_blocks;
}

pub fn initializeMatrixHeader1x1(data_ptr: ?*anyopaque) void {
    payload_bytes_owned.setMatrixRowsColumns(data_ptr, 1, 1);
}