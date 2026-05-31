const warning_bridge_owned = @import("firmware_hal_warning_bridge_owned.zig");
const export_statefile_owned = @import("firmware_hal_export_statefile_owned.zig");
const export_programfile_owned = @import("firmware_hal_export_programfile_owned.zig");

pub fn saveStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return export_statefile_owned.saveStatefile(fpath, fname, data);
}

pub fn loadStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return export_statefile_owned.loadStatefile(fpath, fname, data);
}

pub fn saveProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return export_programfile_owned.saveProgramfile(fpath, fname, data);
}

pub fn loadProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    return export_programfile_owned.loadProgramfile(fpath, fname, data);
}

pub fn showWarning(str: [*c]u8) void {
    warning_bridge_owned.showWarning(str);
}

pub fn fnDiskInfo(unused_but_mandatory_parameter: u16) void {
    warning_bridge_owned.fnDiskInfo(unused_but_mandatory_parameter);
}
