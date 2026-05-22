const builtin = @import("builtin");

pub const FLAG_QUIET: i32 = 0x8019;

pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn audioTone(frequency: u32) void;
extern fn lcd_refresh() void;
extern fn refreshLcd(unused_data: ?*anyopaque) void;

pub fn zigToneRefreshDisplay() void {
	if (builtin.target.os.tag == .freestanding) {
		lcd_refresh();
	} else {
		refreshLcd(null);
	}
}
