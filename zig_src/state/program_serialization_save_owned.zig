const runtime = @import("program_serialization_runtime.zig");

pub fn saveProgram(label: u16) void {
    saveProgramToPath(label, runtime.ioPathSaveProgram);
}

// Port of fnSaveAllPrograms: walk every global label and write each program
// (whose first global label it is) to ioPathSaveAllPrograms, which writes
// directly to PROGRAMS/ALLPGMS without the interactive file-picker dialog.
pub fn saveAllPrograms() void {
    const saved_current_local_step_number = runtime.currentLocalStepNumber;
    const saved_current_program_number = runtime.currentProgramNumber;
    defer {
        runtime.currentLocalStepNumber = saved_current_local_step_number;
        runtime.currentProgramNumber = saved_current_program_number;
    }

    var i: u16 = 0;
    while (i < runtime.numberOfLabels) : (i += 1) {
        var label_name: [16]u8 = undefined;
        if (!runtime.globalLabelNameAt(i, &label_name)) {
            continue;
        }
        const label = runtime.findNamedLabel(&label_name);
        const old_program_number = runtime.currentProgramNumber;
        _ = runtime.selectProgram(label);
        if (runtime.currentProgramNumber != old_program_number) {
            saveProgramToPath(label, runtime.ioPathSaveAllPrograms);
        }
    }
}

pub fn saveProgramToPath(label: u16, path: c_int) void {
    if (runtime.checkPower()) {
        return;
    }

    const saved_current_local_step_number = runtime.currentLocalStepNumber;
    const saved_current_program_number = runtime.currentProgramNumber;
    defer {
        runtime.currentLocalStepNumber = saved_current_local_step_number;
        runtime.currentProgramNumber = saved_current_program_number;
    }

    if (!runtime.selectProgram(label)) {
        return;
    }

    const ret = runtime.openSaveProgram(path);
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

    var current_size_in_bytes = @intFromPtr(runtime.endOfCurrentProgram) - @intFromPtr(runtime.beginOfCurrentProgram);
    if (runtime.currentProgramNumber == runtime.numberOfPrograms) {
        current_size_in_bytes -= 2;
    }

    runtime.writeLiteral("PROGRAM\n");
    runtime.writeU32Line(@intCast(current_size_in_bytes));

    var index: usize = 0;
    while (index < current_size_in_bytes) : (index += 1) {
        runtime.writeU8Line(runtime.beginOfCurrentProgram[index]);
    }

    if (runtime.currentProgramNumber == runtime.numberOfPrograms) {
        runtime.writeU8Line(255);
        runtime.writeU8Line(255);
    }

    runtime.temporaryInformation = runtime.TI_SAVED;
}