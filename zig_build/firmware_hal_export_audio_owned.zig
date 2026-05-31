const audio_bridge_owned = @import("firmware_hal_audio_bridge_owned.zig");
const buzz_bridge_owned = @import("firmware_hal_buzz_bridge_owned.zig");
const play_bridge_owned = @import("firmware_hal_play_bridge_owned.zig");

pub fn audioTone(frequency: u32) void {
    audio_bridge_owned.audioTone(frequency);
}

pub fn dm42Squeak() void {
    audio_bridge_owned.dm42Squeak();
}

pub fn fnSetVolume(volume: u16) void {
    audio_bridge_owned.fnSetVolume(volume);
}

pub fn getBeepVolume() u16 {
    return audio_bridge_owned.getBeepVolume();
}

pub fn fnGetVolume(unused_but_mandatory_parameter: u16) void {
    audio_bridge_owned.fnGetVolume(unused_but_mandatory_parameter);
}

pub fn fnVolumeUp(unused_but_mandatory_parameter: u16) void {
    audio_bridge_owned.fnVolumeUp(unused_but_mandatory_parameter);
}

pub fn fnVolumeDown(unused_but_mandatory_parameter: u16) void {
    audio_bridge_owned.fnVolumeDown(unused_but_mandatory_parameter);
}

pub fn buzz(frequency: u32, ms_delay: u32) void {
    buzz_bridge_owned.buzz(frequency, ms_delay);
}

pub fn fnBuzz(unused_but_mandatory_parameter: u16) void {
    buzz_bridge_owned.fnBuzz(unused_but_mandatory_parameter);
}

pub fn fnPlay(regist: u16) void {
    play_bridge_owned.fnPlay(regist);
}
