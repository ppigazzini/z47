const play_owned = @import("firmware_hal_play_owned.zig");

pub fn fnPlay(regist: u16) void {
    play_owned.fnPlay(regist);
}
