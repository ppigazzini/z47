const warning_bridge_owned = @import("firmware_hal_warning_bridge_owned.zig");

pub fn showWarning(str: [*c]u8) void {
    warning_bridge_owned.showWarning(str);
}

pub fn fnDiskInfo(unused_but_mandatory_parameter: u16) void {
    warning_bridge_owned.fnDiskInfo(unused_but_mandatory_parameter);
}
