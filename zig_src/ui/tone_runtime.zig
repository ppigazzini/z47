pub const FLAG_QUIET: i32 = 0x8019;

pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn audioTone(frequency: u32) void;
pub extern fn zigToneRefreshDisplay() void;
