const header_owned = @import("program_serialization_header_owned.zig");
const load_apply_owned = @import("program_serialization_load_apply_owned.zig");
const save_owned = @import("program_serialization_save_owned.zig");
const runtime = @import("program_serialization_runtime.zig");

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

    const header = header_owned.parseLoadHeader();
    if (!header.valid) {
        return;
    }
    const loaded_version = header.loaded_version;
    const program_size_in_bytes = header.program_size_in_bytes;
    load_apply_owned.applyLoadedProgram(program_size_in_bytes);

    if (loaded_version < runtime.OLDEST_COMPATIBLE_PROGRAM_VERSION) {
        runtime.showWarning(" \n   !!! Program version is too old !!!\nNot compatible with current version\n \nIt will not be loaded.");
        return;
    }

    runtime.temporaryInformation = runtime.TI_PROGRAM_LOADED;
}