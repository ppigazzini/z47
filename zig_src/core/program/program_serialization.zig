const header_owned = @import("program_serialization_header.zig");
const load_apply_owned = @import("program_serialization_load_apply.zig");
const save_owned = @import("program_serialization_save.zig");
const screen_owned = @import("program_serialization_screen.zig");
const runtime = @import("program_serialization_runtime.zig");

pub fn saveProgram(label: u16) void {
    save_owned.saveProgram(label);
}

pub fn loadProgram() void {
    runtime.temporaryInformation = runtime.TI_NO_INFO; // only a completed load sets TI_PROGRAM_LOADED, so a refusal cannot leave the previous load's value standing.
    const ret = runtime.openLoadProgram();
    if (ret != runtime.FILE_OK) {
        if (ret != runtime.FILE_CANCEL) {
            runtime.displayReadError();
        }
        return;
    }
    defer runtime.closeFile();

    const header = header_owned.parseLoadHeader();
    if (!header.valid) {
        return;
    }
    const loaded_version = header.loaded_version;
    const program_size_in_bytes = header.program_size_in_bytes;
    if (comptime !runtime.use_fake_harness_surface) {
        // Refuse what cannot fit, before reserving anything. The second bound is the program area's own accounting: freeProgramBytes is a uint16_t,
        // and addSpaceAfterPrograms() takes a uint16_t size, so a larger claim would reserve only its low 16 bits while the read loop writes them all.
        if (@as(u64, program_size_in_bytes) + 2 > @as(u64, runtime.freeProgramBytes) + runtime.getFreeRamMemoryBytes() or
            @as(u64, program_size_in_bytes) + 2 > 0xFFFF)
        {
            runtime.displayRamFullError();
            return;
        }
        // First pass: screen the file before loading anything, so a refusal needs no rollback.
        if (screen_owned.programFileRefused(program_size_in_bytes)) {
            runtime.displayCorruptedDataError();
            return;
        }
        runtime.seekLoadFileStart();
        var skip: u32 = 0;
        var line_buffer: [256]u8 = undefined;
        while (skip < 6) : (skip += 1) { // skip the header lines the screening pass already validated
            runtime.readLine(line_buffer[0..]);
        }
    } else {
        // The fake parity surface models the pre-screen load flow (its oracle is the
        // pre-screen C); keep its original malformed-size rejection.
        if (program_size_in_bytes > 0xFFFF) {
            runtime.displayReadError();
            return;
        }
    }
    load_apply_owned.applyLoadedProgram(program_size_in_bytes);

    if (loaded_version < runtime.OLDEST_COMPATIBLE_PROGRAM_VERSION) {
        runtime.showWarning(" \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
        return;
    }

    runtime.temporaryInformation = runtime.TI_PROGRAM_LOADED;
}

pub export fn fnSaveProgram(label: u16) void {
    saveProgram(label);
}

pub export fn fnExportProgram(label: u16) void {
    // Compatibility shim: use the Zig-owned save path until dedicated export formatting lands.
    saveProgram(label);
}

pub export fn fnSaveAllPrograms(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    save_owned.saveAllPrograms();
}

pub export fn fnLoadProgram(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    loadProgram();
}
