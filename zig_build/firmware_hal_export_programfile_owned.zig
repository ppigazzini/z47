const programfile_bridge_owned = @import("firmware_hal_programfile_bridge_owned.zig");

pub fn saveProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return programfile_bridge_owned.saveProgramfile(fpath, fname, data);
}

pub fn loadProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return programfile_bridge_owned.loadProgramfile(fpath, fname, data);
}
