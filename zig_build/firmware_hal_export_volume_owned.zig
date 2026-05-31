const audio_bridge_owned = @import("firmware_hal_audio_bridge_owned.zig");

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
