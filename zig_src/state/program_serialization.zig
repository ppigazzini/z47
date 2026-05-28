const runtime = @import("program_serialization_runtime.zig");

fn toBlocks(byteCount: usize) u16 {
    return @intCast((byteCount + (runtime.BYTES_PER_BLOCK - 1)) >> runtime.BPB);
}

fn toBytes(blockCount: usize) usize {
    return blockCount << runtime.BPB;
}

fn offsetPointer(ptr: [*c]u8, delta: isize) [*c]u8 {
    const base: isize = @intCast(@intFromPtr(ptr));
    return @ptrFromInt(@as(usize, @intCast(base + delta)));
}

fn addSpaceAfterPrograms(size: u16) void {
    if (runtime.freeProgramBytes < size) {
        const oldBeginOfProgramMemory = runtime.beginOfProgramMemory;
        const programSizeInBlocks: usize = runtime.getRamSizeInBlocks() - runtime.toC47MemPtr(runtime.beginOfProgramMemory);
        const newProgramSizeInBlocks = toBlocks(toBytes(programSizeInBlocks) - runtime.freeProgramBytes + size);
        const growBytes = toBytes(newProgramSizeInBlocks - programSizeInBlocks);

        runtime.freeProgramBytes +%= @intCast(growBytes);
        runtime.resizeProgramMemory(newProgramSizeInBlocks);
        const delta: isize = @intCast(@as(i64, @intCast(@intFromPtr(runtime.beginOfProgramMemory))) - @as(i64, @intCast(@intFromPtr(oldBeginOfProgramMemory))));
        runtime.currentStep = offsetPointer(runtime.currentStep, delta);
        runtime.firstDisplayedStep = offsetPointer(runtime.firstDisplayedStep, delta);
        runtime.beginOfCurrentProgram = offsetPointer(runtime.beginOfCurrentProgram, delta);
        runtime.endOfCurrentProgram = offsetPointer(runtime.endOfCurrentProgram, delta);
    }

    runtime.firstFreeProgramByte = offsetPointer(runtime.firstFreeProgramByte, @intCast(size));
    runtime.freeProgramBytes -%= size;
}

fn addEndNeeded() bool {
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

pub export fn fnSaveProgram(label: u16) void {
    if (runtime.checkPower()) {
        return;
    }

    const savedCurrentLocalStepNumber = runtime.currentLocalStepNumber;
    const savedCurrentProgramNumber = runtime.currentProgramNumber;
    defer {
        runtime.currentLocalStepNumber = savedCurrentLocalStepNumber;
        runtime.currentProgramNumber = savedCurrentProgramNumber;
    }

    if (!runtime.selectProgram(label)) {
        return;
    }

    const ret = runtime.openSaveProgram();
    if (ret != runtime.FILE_OK) {
        if (ret != runtime.FILE_CANCEL) {
            runtime.displayWriteError();
        }
        return;
    }
    defer runtime.closeFile();

    runtime.writeLiteral("PROGRAM_FILE_FORMAT\n");
    runtime.writeU8Line(runtime.BACKUP_FORMAT);
    runtime.writeLiteral("C47_program_file_version\n");
    runtime.writeU32Line(runtime.PROGRAM_VERSION);

    var currentSizeInBytes = @intFromPtr(runtime.endOfCurrentProgram) - @intFromPtr(runtime.beginOfCurrentProgram);
    if (runtime.currentProgramNumber == runtime.numberOfPrograms) {
        currentSizeInBytes -= 2;
    }

    runtime.writeLiteral("PROGRAM\n");
    runtime.writeU32Line(@intCast(currentSizeInBytes));

    var index: usize = 0;
    while (index < currentSizeInBytes) : (index += 1) {
        runtime.writeU8Line(runtime.beginOfCurrentProgram[index]);
    }

    if (runtime.currentProgramNumber == runtime.numberOfPrograms) {
        runtime.writeU8Line(255);
        runtime.writeU8Line(255);
    }

    runtime.temporaryInformation = runtime.TI_SAVED;
}

pub export fn fnLoadProgram(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    const ret = runtime.openLoadProgram();
    if (ret != runtime.FILE_OK) {
        if (ret != runtime.FILE_CANCEL) {
            runtime.displayReadError();
        }
        return;
    }
    defer runtime.closeFile();

    var key_buffer: [256]u8 = undefined;
    var value_buffer: [256]u8 = undefined;
    var loaded_version: u32 = 0;

    runtime.readLine(key_buffer[0..]);
    if (runtime.lineEquals(key_buffer[0..].ptr, "PROGRAM_FILE_FORMAT")) {
        runtime.readLine(value_buffer[0..]);
    } else {
        runtime.showWarning(" \nThis is not a C47 program\n\nIt will not be loaded.");
        return;
    }

    runtime.readLine(key_buffer[0..]);
    runtime.readLine(value_buffer[0..]);
    if (runtime.lineEquals(key_buffer[0..].ptr, "C47_program_file_version")) {
        loaded_version = runtime.parseU32Line(value_buffer[0..].ptr);
        if (loaded_version < runtime.OLDEST_COMPATIBLE_PROGRAM_VERSION) {
            runtime.showWarning(" \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
            return;
        }
    } else if (runtime.lineEquals(key_buffer[0..].ptr, "WP43_program_file_version")) {
        loaded_version = runtime.parseU32Line(value_buffer[0..].ptr);
        runtime.showWarning(" \nThis is a WP43 program\nWP43 program support is experimental\nSome instructions may not be \ncompatible with the C47 and may\ncrash the calculator.");
    } else {
        runtime.showWarning(" \nThis is not a C47 program\n \nIt will not be loaded.");
        return;
    }

    runtime.readLine(key_buffer[0..]);
    runtime.readLine(value_buffer[0..]);
    if (!runtime.lineEquals(key_buffer[0..].ptr, "PROGRAM")) {
        return;
    }

    const program_size_in_bytes: u32 = runtime.parseU32Line(value_buffer[0..].ptr);

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
