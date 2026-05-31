const buzz_bridge_owned = @import("firmware_hal_buzz_bridge_owned.zig");
const play_bridge_owned = @import("firmware_hal_play_bridge_owned.zig");

pub fn buzz(frequency: u32, ms_delay: u32) void {
    buzz_bridge_owned.buzz(frequency, ms_delay);
}

pub fn fnBuzz(unused_but_mandatory_parameter: u16) void {
    buzz_bridge_owned.fnBuzz(unused_but_mandatory_parameter);
}

pub fn fnPlay(regist: u16) void {
    play_bridge_owned.fnPlay(regist);
}
