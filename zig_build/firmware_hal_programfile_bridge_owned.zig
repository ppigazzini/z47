const callbacks_owned = @import("firmware_hal_callbacks_owned.zig");

pub fn saveProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return callbacks_owned.saveProgramfile(fpath, fname, data);
}

pub fn loadProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return callbacks_owned.loadProgramfile(fpath, fname, data);
}
