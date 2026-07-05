const pointer_owned = @import("program_serialization_pointer.zig");
const runtime = @import("program_serialization_runtime.zig");
const space_owned = @import("program_serialization_space.zig");

pub fn applyLoadedProgram(program_size_in_bytes: u32) void {
    var value_buffer: [256]u8 = undefined;

    if (space_owned.addEndNeeded()) {
        space_owned.addSpaceAfterPrograms(2);
        (runtime.firstFreeProgramByte - 2)[0] = @intCast((runtime.ITM_END >> 8) | 0x80);
        (runtime.firstFreeProgramByte - 1)[0] = @intCast(runtime.ITM_END & 0xff);
        runtime.firstFreeProgramByte[0] = 0xff;
        (runtime.firstFreeProgramByte + 1)[0] = 0xff;
        runtime.scanLabelsAndPrograms();
    }

    space_owned.addSpaceAfterPrograms(@intCast(program_size_in_bytes));
    const start_of_program = pointer_owned.offsetPointer(runtime.firstFreeProgramByte, -@as(isize, @intCast(program_size_in_bytes)));
    var index: u32 = 0;
    while (index < program_size_in_bytes) : (index += 1) {
        runtime.readLine(value_buffer[0..]);
        start_of_program[index] = runtime.parseU8Line(value_buffer[0..].ptr);
    }

    runtime.firstFreeProgramByte[0] = 0xff;
    (runtime.firstFreeProgramByte + 1)[0] = 0xff;
    runtime.scanLabelsAndPrograms();
    runtime.goToLastProgram();
}