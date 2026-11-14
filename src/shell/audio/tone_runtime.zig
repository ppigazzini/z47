const builtin = @import("builtin");
const rom = @import("dmcp_rom");

pub const FLAG_QUIET: i32 = 0x8019;

pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn audioTone(frequency: u32) void;
extern fn refreshLcd(unused_data: ?*anyopaque) c_int;

pub fn zigToneRefreshDisplay() void {
    if (builtin.target.os.tag == .freestanding) {
        rom.lcd_refresh();
    } else {
        _ = refreshLcd(null);
    }
}
