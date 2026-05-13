pub const FLAG_BCD: u16 = 0x8059;
pub const FLAG_SBfrac: u16 = 0x8031;
pub const FLAG_SBtime: u16 = 0x802d;
pub const FLAG_SBwoy: u16 = 0x8057;
pub const FLAG_FRACT: u16 = 0x8007;
pub const FLAG_IRFRAC: u16 = 0x8047;
pub const FLAG_IRFRQ: u16 = 0xc048;

pub const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;

pub extern var systemFlags0: u64;
pub extern var systemFlags1: u64;
pub extern var lastIntegerBase: u32;
pub extern var screenUpdatingMode: u8;

pub extern fn fnRefreshState() void;
pub extern fn reallyClearStatusBar(info: u8) void;
pub extern fn fnChangeBaseJM(base: u16) void;

extern fn z47_flags_retained_setSystemFlag(sf: u32) void;
extern fn z47_flags_retained_clearSystemFlag(sf: u32) void;
extern fn z47_flags_retained_flipSystemFlag(sf: u32) void;
extern fn z47_flags_retained_getSystemFlag(sf: i32) bool;
extern fn z47_flags_retained_didSystemFlagChange(sf: i32) bool;
extern fn z47_flags_retained_setSystemFlagChanged(sf: i32) void;
extern fn z47_flags_retained_setAllSystemFlagChanged() void;
extern fn z47_flags_retained_forceSystemFlag(sf: u32, set: i32) void;

pub fn retainedSetSystemFlag(sf: u32) void {
    z47_flags_retained_setSystemFlag(sf);
}

pub fn retainedClearSystemFlag(sf: u32) void {
    z47_flags_retained_clearSystemFlag(sf);
}

pub fn retainedFlipSystemFlag(sf: u32) void {
    z47_flags_retained_flipSystemFlag(sf);
}

pub fn retainedGetSystemFlag(sf: i32) bool {
    return z47_flags_retained_getSystemFlag(sf);
}

pub fn retainedDidSystemFlagChange(sf: i32) bool {
    return z47_flags_retained_didSystemFlagChange(sf);
}

pub fn retainedSetSystemFlagChanged(sf: i32) void {
    z47_flags_retained_setSystemFlagChanged(sf);
}

pub fn retainedSetAllSystemFlagChanged() void {
    z47_flags_retained_setAllSystemFlagChanged();
}

pub fn retainedForceSystemFlag(sf: u32, set: i32) void {
    z47_flags_retained_forceSystemFlag(sf, set);
}
