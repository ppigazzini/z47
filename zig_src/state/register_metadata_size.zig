const build_options = @import("register_metadata_build_options");
const payload_bytes_owned = @import("register_metadata_payload_bytes.zig");
const stack_runtime = @import("stack_runtime.zig");

const use_fake_register_metadata_harness_surface =
    @hasDecl(build_options, "use_fake_register_metadata_harness_surface") and
    build_options.use_fake_register_metadata_harness_surface;

// sizeof(dtConfigDescriptor_t) is fixed at 840 bytes by the upstream
// compatibility contract; the record is explicitly padded to that length.
const CONFIG_DESCRIPTOR_SIZE_IN_BYTES: usize = 840;

extern fn z47_register_metadata_config_size_in_blocks() u16;
extern fn isMemoryBlockAvailable(size_in_blocks: usize, num_blocks: u16, extra_fraction: f32) bool;

const align_blocks = @import("align_blocks.zig"); // std-only long-integer block alignment
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
    if (use_fake_register_metadata_harness_surface) {
        return z47_register_metadata_config_size_in_blocks();
    }
    return toBlocks(CONFIG_DESCRIPTOR_SIZE_IN_BYTES);
}

pub fn memoryBlockAvailable(size_in_blocks: u16) bool {
    return isMemoryBlockAvailable(size_in_blocks, 2, 0.1);
}

pub fn alignLongIntegerBlocks(size_in_blocks: u16) u16 {
    return align_blocks.alignLongIntegerBlocks(size_in_blocks, bytesPerBlock(), toBlocks(@sizeOf(usize)));
}

pub fn initializeMatrixHeader1x1(data_ptr: ?*anyopaque) void {
    payload_bytes_owned.setMatrixRowsColumns(data_ptr, 1, 1);
}
