const audio_volume_owned = @import("firmware_hal_audio_volume_owned.zig");

pub fn audioTone(frequency: u32) void {
    audio_volume_owned.audioTone(frequency);
}

pub fn dm42Squeak() void {
    audio_volume_owned.dm42Squeak();
}

pub fn fnSetVolume(volume: u16) void {
    audio_volume_owned.fnSetVolume(volume);
}

pub fn getBeepVolume() u16 {
    return audio_volume_owned.getBeepVolume();
}

pub fn fnGetVolume(unused_but_mandatory_parameter: u16) void {
    audio_volume_owned.fnGetVolume(unused_but_mandatory_parameter);
}

pub fn fnVolumeUp(unused_but_mandatory_parameter: u16) void {
    audio_volume_owned.fnVolumeUp(unused_but_mandatory_parameter);
}

pub fn fnVolumeDown(unused_but_mandatory_parameter: u16) void {
    audio_volume_owned.fnVolumeDown(unused_but_mandatory_parameter);
}
