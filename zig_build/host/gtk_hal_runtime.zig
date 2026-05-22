const std = @import("std");

const NOVAL_U16: u16 = 65410;

pub export fn audioTone(frequency: u32) callconv(.c) void {
    _ = frequency;
}

pub export fn fnSetVolume(volume: u16) callconv(.c) void {
    _ = volume;
}

pub export fn getBeepVolume() callconv(.c) u16 {
    return NOVAL_U16;
}

pub export fn fnGetVolume(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnVolumeUp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnVolumeDown(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnBuzz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn fnPlay(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
}

pub export fn getLineDelay() callconv(.c) u32 {
    return 0;
}

pub export fn setLineDelay(delay: u16) callconv(.c) void {
    _ = delay;
}

pub export fn sendByteIR(byte: u8) callconv(.c) void {
    _ = byte;
}

pub export fn printer_advance_buf(what: c_int) callconv(.c) void {
    _ = what;
}

pub export fn printer_busy_for(what: c_int) callconv(.c) c_int {
    _ = what;
    return 0;
}

pub export fn printer_get_delay() callconv(.c) u16 {
    return 0;
}

pub export fn printer_set_delay(val: u16) callconv(.c) u16 {
    _ = val;
    return 0;
}
