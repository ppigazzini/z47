const export_owned = @import("program_serialization_export.zig");
const runtime = @import("program_serialization_runtime.zig");

pub fn saveProgram(label: u16) void {
    saveProgramToPath(label, runtime.ioPathSaveProgram);
}

// Port of fnSaveAllPrograms: walk every global label and write each program
// (whose first global label it is) both to ioPathSaveAllPrograms as a `.p47`
// byte dump and to ioPathExportRTFAllPrograms as an RTF listing, neither of
// which opens the interactive file-picker dialog. Simulator only; the firmware
// has no such command.
pub fn saveAllPrograms() void {
    if (comptime !runtime.is_host_build) {
        return;
    }
    if (runtime.calcMode == runtime.CM_PEM) { // it selects each program itself, so it needs the same refusal the two writers make
        runtime.displayOperationUndefined();
        return;
    }

    const saved_current_local_step_number = runtime.currentLocalStepNumber;
    const saved_current_program_number = runtime.currentProgramNumber;
    defer {
        runtime.currentLocalStepNumber = saved_current_local_step_number;
        runtime.currentProgramNumber = saved_current_program_number;
    }

    // Seeded to 0 rather than to the current program, so the first global label
    // walked is always written: 0 is not a program number.
    var old_program_number: u16 = 0;
    var i: u16 = 0;
    while (i < runtime.numberOfLabels) : (i += 1) {
        var label_name: [256]u8 = undefined; // a global label name is a 1-byte-length string, so up to 255 bytes
        if (!runtime.globalLabelNameAt(i, &label_name)) {
            continue;
        }
        const label = runtime.findNamedLabel(&label_name, runtime.GLOBAL_LABELS);
        runtime.selectProgram(label);
        if (runtime.currentProgramNumber != old_program_number) {
            runtime.reportProgramExported(label, runtime.currentProgramNumber, &label_name);
            saveProgramToPath(label, runtime.ioPathSaveAllPrograms);
            export_owned.exportProgram(label, runtime.ioPathExportRTFAllPrograms);
        } else {
            runtime.reportProgramNotExported(runtime.currentProgramNumber, &label_name);
        }
        old_program_number = runtime.currentProgramNumber;
    }
}

pub fn saveProgramToPath(label: u16, path: c_int) void {
    if (runtime.calcMode == runtime.CM_PEM) { // as in exportProgram: selectProgram reaches fnGoto, which inserts a GTO step while the editor is open
        runtime.displayOperationUndefined();
        return;
    }
    if (runtime.checkPower()) {
        return;
    }

    const saved_position = runtime.EditorPosition.save();

    // c43's `_selectProgram` is void: an out-of-range label raises the error and
    // the save CONTINUES with whatever program is current. Gating the save on it
    // was a z47 divergence the frozen oracle could not see.
    runtime.selectProgram(label);

    // A program holding a 0 can be neither stored nor run; VALID puts the numbers
    // in. The developer bulk export writes whatever is in memory and is not the user
    // storing one program, so it is not refused.
    if (path != runtime.ioPathSaveAllPrograms and runtime.structProgramHasUnnumbered() != 0) {
        runtime.displayStructureNotNumbered();
        saved_position.restore();
        return;
    }

    const ret = runtime.openSaveProgram(path);
    if (ret != runtime.FILE_OK) {
        if (ret != runtime.FILE_CANCEL) {
            runtime.displayWriteError();
        }
        saved_position.restore();
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

    saved_position.restore();
    runtime.temporaryInformation = runtime.TI_SAVED;
}
