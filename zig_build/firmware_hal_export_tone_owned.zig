const audio_bridge_owned = @import("firmware_hal_audio_bridge_owned.zig");

pub fn audioTone(frequency: u32) void {
    audio_bridge_owned.audioTone(frequency);
}

pub fn dm42Squeak() void {
    audio_bridge_owned.dm42Squeak();
}
