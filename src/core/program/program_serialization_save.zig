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
        var label_name: [256]u8 = undefined; // a global label name is a 1-byte-length string, so up to 255 bytes
        if (!runtime.globalLabelNameAt(i, &label_name)) {
            continue;
        }
        const label = runtime.findNamedLabel(&label_name, runtime.GLOBAL_LABELS);
        const old_program_number = runtime.currentProgramNumber;
        runtime.selectProgram(label);
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

    // c43's `_selectProgram` is void: an out-of-range label raises the error and
    // the save CONTINUES with whatever program is current. Gating the save on it
    // was a z47 divergence the frozen oracle could not see (REPORT-31 M31-3).
    runtime.selectProgram(label);

    const ret = runtime.openSaveProgram(path);
    if (ret != runtime.FILE_OK) {
        if (ret != runtime.FILE_CANCEL) {
            runtime.displayWriteError();
        }
        // No restore here, and none on the cancel path: c43 leaves the selected
        // program current when the file cannot be opened, and only puts the
        // saved numbers back after a completed write. A `defer` restoring on
        // every path was the second divergence this lane could not see.
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

    runtime.currentLocalStepNumber = saved_current_local_step_number;
    runtime.currentProgramNumber = saved_current_program_number;
    runtime.temporaryInformation = runtime.TI_SAVED;
}
