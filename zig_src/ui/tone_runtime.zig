const builtin = @import("builtin");
const tone_build_options = @import("tone_build_options");

const firmware_lcd_refresh_offset: usize = 48;
const LcdRefreshFn = *const fn () callconv(.c) void;

pub const FLAG_QUIET: i32 = 0x8019;

pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn audioTone(frequency: u32) void;
extern fn refreshLcd(unused_data: ?*anyopaque) void;

fn firmwareRefreshDisplay() void {
	const refresh: LcdRefreshFn = @ptrFromInt(tone_build_options.library_fn_base + firmware_lcd_refresh_offset);
	refresh();
}

pub fn zigToneRefreshDisplay() void {
	if (builtin.target.os.tag == .freestanding) {
		firmwareRefreshDisplay();
	} else {
		refreshLcd(null);
	}
}
