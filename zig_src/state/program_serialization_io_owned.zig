const header_owned = @import("program_serialization_header_owned.zig");
const pointer_owned = @import("program_serialization_pointer_owned.zig");
const save_owned = @import("program_serialization_save_owned.zig");
const space_owned = @import("program_serialization_space_owned.zig");
const runtime = @import("program_serialization_runtime.zig");

fn toBlocks(byte_count: usize) u16 {
    return pointer_owned.toBlocks(byte_count);
}

fn toBytes(block_count: usize) usize {
    return pointer_owned.toBytes(block_count);
}

fn offsetPointer(ptr: [*c]u8, delta: isize) [*c]u8 {
    return pointer_owned.offsetPointer(ptr, delta);
}

fn addSpaceAfterPrograms(size: u16) void {
    space_owned.addSpaceAfterPrograms(size);
}

fn addEndNeeded() bool {
    return space_owned.addEndNeeded();
}

pub fn saveProgram(label: u16) void {
    save_owned.saveProgram(label);
}

pub fn loadProgram() void {
    const ret = runtime.openLoadProgram();
    if (ret != runtime.FILE_OK) {
        if (ret != runtime.FILE_CANCEL) {
            runtime.displayReadError();
        }
        return;
    }
    defer runtime.closeFile();

    var value_buffer: [256]u8 = undefined;
    const header = header_owned.parseLoadHeader();
    if (!header.valid) {
        return;
    }
    const loaded_version = header.loaded_version;
    const program_size_in_bytes = header.program_size_in_bytes;

    if (addEndNeeded()) {
        addSpaceAfterPrograms(2);
        (runtime.firstFreeProgramByte - 2)[0] = @intCast((runtime.ITM_END >> 8) | 0x80);
        (runtime.firstFreeProgramByte - 1)[0] = @intCast(runtime.ITM_END & 0xff);
        runtime.firstFreeProgramByte[0] = 0xff;
        (runtime.firstFreeProgramByte + 1)[0] = 0xff;
        runtime.scanLabelsAndPrograms();
    }

    addSpaceAfterPrograms(@intCast(program_size_in_bytes));
    const start_of_program = offsetPointer(runtime.firstFreeProgramByte, -@as(isize, @intCast(program_size_in_bytes)));
    var index: u32 = 0;
    while (index < program_size_in_bytes) : (index += 1) {
        runtime.readLine(value_buffer[0..]);
        start_of_program[index] = runtime.parseU8Line(value_buffer[0..].ptr);
    }

    runtime.firstFreeProgramByte[0] = 0xff;
    (runtime.firstFreeProgramByte + 1)[0] = 0xff;
    runtime.scanLabelsAndPrograms();
    runtime.goToLastProgram();

    if (loaded_version < runtime.OLDEST_COMPATIBLE_PROGRAM_VERSION) {
        runtime.showWarning(" \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
        return;
    }

    runtime.temporaryInformation = runtime.TI_PROGRAM_LOADED;
}