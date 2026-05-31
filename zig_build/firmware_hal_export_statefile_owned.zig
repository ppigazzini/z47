const statefile_bridge_owned = @import("firmware_hal_statefile_bridge_owned.zig");

pub fn saveStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return statefile_bridge_owned.saveStatefile(fpath, fname, data);
}

pub fn loadStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return statefile_bridge_owned.loadStatefile(fpath, fname, data);
}
