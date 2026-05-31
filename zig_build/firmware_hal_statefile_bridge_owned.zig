const callbacks_owned = @import("firmware_hal_callbacks_owned.zig");

pub fn saveStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return callbacks_owned.saveStatefile(fpath, fname, data);
}

pub fn loadStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return callbacks_owned.loadStatefile(fpath, fname, data);
}
