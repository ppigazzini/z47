const pointer_owned = @import("program_serialization_pointer.zig");
const runtime = @import("program_serialization_runtime.zig");

pub fn addSpaceAfterPrograms(size: u16) void {
    if (runtime.freeProgramBytes < size) {
        const old_begin_of_program_memory = runtime.beginOfProgramMemory;
        const program_size_in_blocks: usize = runtime.getRamSizeInBlocks() - runtime.toC47MemPtr(runtime.beginOfProgramMemory);
        const new_program_size_in_blocks = pointer_owned.toBlocks(pointer_owned.toBytes(program_size_in_blocks) - runtime.freeProgramBytes + size);
        const grow_bytes = pointer_owned.toBytes(new_program_size_in_blocks - program_size_in_blocks);

        // freeProgramBytes is a uint16_t: a 65536-byte growth adds 0 in the C by
        // silent modular conversion, and fnLoadProgram admits a size that
        // reaches exactly that. Truncate rather than trap on the narrowing too.
        runtime.freeProgramBytes +%= @truncate(grow_bytes);
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

// The last step of the last program, walked from that program's own first step: a
// step whose last two bytes happen to spell END is not the END itself.
fn findLastStep() [*c]const u8 {
    var step = runtime.programList[@as(usize, runtime.numberOfPrograms) - 1].instructionPointer;
    while (!(runtime.isAtEndOfProgram(step) or runtime.isAtEndOfPrograms(step))) { // END or .END.
        step = runtime.findNextStep(step);
    }
    return step;
}

pub fn addEndNeeded() bool {
    if (runtime.firstFreeProgramByte <= runtime.beginOfProgramMemory) {
        return false;
    }
    if (runtime.firstFreeProgramByte == runtime.beginOfProgramMemory + 1) {
        return true;
    }
    if (runtime.isAtEndOfProgram(findLastStep())) {
        return false;
    }
    return true;
}

// The program memory holds one empty program -- a lone END -- which READP drops
// before loading, rather than leaving it in front of the new one.
pub fn delEndNeeded() bool {
    if (runtime.firstFreeProgramByte <= runtime.beginOfProgramMemory) {
        return false;
    }
    // the last program's own first step. A step ending 133 178 is not taken for a 2nd END
    return runtime.isAtEndOfProgram(runtime.programList[@as(usize, runtime.numberOfPrograms) - 1].instructionPointer);
}
