const warning_owned = @import("firmware_hal_warning_owned.zig");

pub fn showWarning(str: [*c]u8) void {
    warning_owned.showWarning(str);
}

pub fn fnDiskInfo(unused_but_mandatory_parameter: u16) void {
    warning_owned.fnDiskInfo(unused_but_mandatory_parameter);
}
