// SPDX-License-Identifier: GPL-3.0-only
const build_options = @import("tone_build_options");
const rom = @import("dmcp_rom");

pub const FLAG_QUIET: i32 = 0x8019;

pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn audioTone(frequency: u32) void;
extern fn refreshLcd(unused_data: ?*anyopaque) c_int;

pub fn zigToneRefreshDisplay() void {
    if (comptime build_options.dmcp_build) {
        rom.lcd_refresh();
    } else {
        _ = refreshLcd(null);
    }
}
