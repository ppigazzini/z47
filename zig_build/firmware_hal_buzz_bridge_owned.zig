const buzz_owned = @import("firmware_hal_buzz_owned.zig");

pub fn buzz(frequency: u32, ms_delay: u32) void {
    buzz_owned.buzz(frequency, ms_delay);
}

pub fn fnBuzz(unused_but_mandatory_parameter: u16) void {
    buzz_owned.fnBuzz(unused_but_mandatory_parameter);
}
