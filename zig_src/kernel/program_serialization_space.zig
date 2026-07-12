const pointer_owned = @import("program_serialization_pointer.zig");
const runtime = @import("program_serialization_runtime.zig");

pub fn addSpaceAfterPrograms(size: u16) void {
    if (runtime.freeProgramBytes < size) {
        const old_begin_of_program_memory = runtime.beginOfProgramMemory;
        const program_size_in_blocks: usize = runtime.getRamSizeInBlocks() - runtime.toC47MemPtr(runtime.beginOfProgramMemory);
        const new_program_size_in_blocks = pointer_owned.toBlocks(pointer_owned.toBytes(program_size_in_blocks) - runtime.freeProgramBytes + size);
        const grow_bytes = pointer_owned.toBytes(new_program_size_in_blocks - program_size_in_blocks);

        runtime.freeProgramBytes +%= @intCast(grow_bytes);
        runtime.resizeProgramMemory(new_program_size_in_blocks);
        const delta: isize = @intCast(@as(i64, @intCast(@intFromPtr(runtime.beginOfProgramMemory))) - @as(i64, @intCast(@intFromPtr(old_begin_of_program_memory))));
        runtime.currentStep = pointer_owned.offsetPointer(runtime.currentStep, delta);
        runtime.firstDisplayedStep = pointer_owned.offsetPointer(runtime.firstDisplayedStep, delta);
        runtime.beginOfCurrentProgram = pointer_owned.offsetPointer(runtime.beginOfCurrentProgram, delta);
        runtime.endOfCurrentProgram = pointer_owned.offsetPointer(runtime.endOfCurrentProgram, delta);
    }

    runtime.firstFreeProgramByte = pointer_owned.offsetPointer(runtime.firstFreeProgramByte, @intCast(size));
    runtime.freeProgramBytes -%= size;
}

pub fn addEndNeeded() bool {
    if (runtime.firstFreeProgramByte <= runtime.beginOfProgramMemory) {
        return false;
    }
    if (runtime.firstFreeProgramByte == runtime.beginOfProgramMemory + 1) {
        return true;
    }
    if (runtime.isAtEndOfProgram(runtime.firstFreeProgramByte - 2)) {
        return false;
    }
    return true;
}
