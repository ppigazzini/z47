const statefile_bridge_owned = @import("firmware_hal_statefile_bridge_owned.zig");
const programfile_bridge_owned = @import("firmware_hal_programfile_bridge_owned.zig");
const warning_bridge_owned = @import("firmware_hal_warning_bridge_owned.zig");

pub fn saveStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return statefile_bridge_owned.saveStatefile(fpath, fname, data);
}

pub fn loadStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return statefile_bridge_owned.loadStatefile(fpath, fname, data);
}

pub fn saveProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return programfile_bridge_owned.saveProgramfile(fpath, fname, data);
}

pub fn loadProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return programfile_bridge_owned.loadProgramfile(fpath, fname, data);
}

pub fn showWarning(str: [*c]u8) void {
    warning_bridge_owned.showWarning(str);
}

pub fn fnDiskInfo(unused_but_mandatory_parameter: u16) void {
    warning_bridge_owned.fnDiskInfo(unused_but_mandatory_parameter);
}
