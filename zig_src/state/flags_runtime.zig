pub const FLAG_BCD: u16 = 0x8059;
pub const FLAG_ALPHA: u16 = 0x800e;
pub const FLAG_TDM24: u16 = 0x8000;
pub const FLAG_SBfrac: u16 = 0x8031;
pub const FLAG_SBtime: u16 = 0x802d;
pub const FLAG_SBwoy: u16 = 0x8057;
pub const FLAG_CPXj: u16 = 0x8005;
pub const FLAG_POLAR: u16 = 0x8006;
pub const FLAG_FRACT: u16 = 0x8007;
pub const FLAG_PROPFR: u16 = 0x8008;
pub const FLAG_DENANY: u16 = 0x8009;
pub const FLAG_DENFIX: u16 = 0x800a;
pub const FLAG_CARRY: u16 = 0x800b;
pub const FLAG_OVERFLOW: u16 = 0x800c;
pub const FLAG_LEAD0: u16 = 0x800d;
pub const FLAG_IRFRAC: u16 = 0x8047;
pub const FLAG_IRFRQ: u16 = 0xc048;
pub const FLAG_AMORT_HP12C: u16 = 0x8011;
pub const FLAG_TRACE: u16 = 0x8013;
pub const FLAG_CPXRES: u16 = 0x8004;
pub const FLAG_SPCRES: u16 = 0x8017;
pub const FLAG_SSIZE8: u16 = 0x8018;
pub const FLAG_MULTx: u16 = 0x801b;
pub const FLAG_ENGOVR: u16 = 0x801c;
pub const FLAG_PRTACT: u16 = 0xc020;
pub const FLAG_HPRP: u16 = 0x802b;
pub const FLAG_HPBASE: u16 = 0x803c;
pub const FLAG_2TO10: u16 = 0x803d;
pub const FLAG_FRCYC: u16 = 0x8041;
pub const FLAG_NUMLOCK: u16 = 0x8043;
pub const FLAG_CPXMULT: u16 = 0x8044;
pub const FLAG_ERPN: u16 = 0x8045;
pub const FLAG_LARGELI: u16 = 0x8046;
pub const FLAG_DREAL: u16 = 0x804a;
pub const FLAG_CPXPLOT: u16 = 0x804b;
pub const FLAG_SHOWX: u16 = 0x804c;
pub const FLAG_SHOWY: u16 = 0x804d;
pub const FLAG_PBOX: u16 = 0x804e;
pub const FLAG_PCROS: u16 = 0x804f;
pub const FLAG_PPLUS: u16 = 0x8050;
pub const FLAG_PLINE: u16 = 0x8051;
pub const FLAG_SCALE: u16 = 0x8052;
pub const FLAG_VECT: u16 = 0x8053;
pub const FLAG_NVECT: u16 = 0x8054;
pub const FLAG_MNUp1: u16 = 0x8056;
pub const FLAG_TOPHEX: u16 = 0x8058;
pub const FLAG_PCURVE: u16 = 0x805a;
pub const FLAG_BASE_MYM: u16 = 0x805c;
pub const FLAG_G_DOUBLETAP: u16 = 0x805d;
pub const FLAG_BASE_HOME: u16 = 0x805e;
pub const FLAG_MYM_TRIPLE: u16 = 0x805f;
pub const FLAG_HOME_TRIPLE: u16 = 0x8060;
pub const FLAG_SHFT_4s: u16 = 0x8061;
pub const FLAG_FGLNLIM: u16 = 0x8062;
pub const FLAG_FGLNFUL: u16 = 0x8063;
pub const FLAG_FGGR: u16 = 0x8064;
pub const FLAG_NORM: u16 = 0x8068;
pub const FLAG_K: u16 = 111;
pub const FLAG_M: u16 = 211;
pub const FLAG_W: u16 = 224;

pub const NUMBER_OF_GLOBAL_FLAGS: u16 = 112;
pub const NUMBER_OF_LOCAL_FLAGS: u16 = 32;
pub const LAST_LOCAL_FLAG: u16 = 143;

pub const AC_UPPER: u8 = 0;
pub const AC_LOWER: u8 = 1;

pub const NC_NORMAL: u8 = 0;
pub const NC_SUBSCRIPT: u8 = 1;
pub const NC_SUPERSCRIPT: u8 = 2;

pub const TI_NO_INFO: u8 = 0;
pub const TI_FALSE: u8 = 12;
pub const TI_TRUE: u8 = 13;
pub const TI_CLEAR_ALL_FLAGS: u8 = 96;

pub const NOT_CONFIRMED: u16 = 9878;

pub const JC_NL: u16 = 197;
pub const JC_UC: u16 = 198;
pub const JC_SS: u16 = 214;

pub const TF_H24: u16 = 230;
pub const TF_H12: u16 = 231;
pub const CU_I: u16 = 232;
pub const CU_J: u16 = 233;
pub const PS_DOT: u16 = 234;
pub const PS_CROSS: u16 = 235;
pub const SS_4: u16 = 236;
pub const SS_8: u16 = 237;
pub const CM_RECTANGULAR: u16 = 238;
pub const CM_POLAR: u16 = 239;
pub const DO_SCI: u16 = 240;
pub const DO_ENG: u16 = 241;

pub const ITM_DREAL: u16 = 1899;

pub const PGM_RUNNING: u8 = 1;

pub const SCRUPD_AUTO: u8 = 0x00;
pub const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;

pub extern var systemFlags0: u64;
pub extern var systemFlags1: u64;
pub extern var lastIntegerBase: u32;
pub extern var screenUpdatingMode: u8;
pub extern var temporaryInformation: u8;
pub extern var programRunStop: u8;
pub extern var alphaCase: u8;
pub extern var scrLock: u8;
pub extern var nextChar: u8;
pub extern var globalFlags: [8]u16;
pub extern var currentLocalFlags: [*c]u32;

pub extern fn fnRefreshState() void;
pub extern fn reallyClearStatusBar(info: u8) void;
pub extern fn fnChangeBaseJM(base: u16) void;
pub extern fn leaveTamModeIfEnabled() void;
pub extern fn showAlphaModeonGui() void;

extern fn z47_flags_runtime_handle_write_protected_flag() void;
extern fn z47_flags_runtime_enter_alpha_mode() void;
extern fn z47_flags_runtime_leave_alpha_mode() void;
extern fn z47_flags_runtime_request_clf_all_confirmation() void;

extern fn z47_flags_retained_setSystemFlag(sf: u32) void;
extern fn z47_flags_retained_clearSystemFlag(sf: u32) void;
extern fn z47_flags_retained_flipSystemFlag(sf: u32) void;
extern fn z47_flags_retained_getSystemFlag(sf: i32) bool;
extern fn z47_flags_retained_getFlag(flag: u16) bool;
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

pub fn retainedGetFlag(flag: u16) bool {
    return z47_flags_retained_getFlag(flag);
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

pub fn handleWriteProtectedFlag() void {
    z47_flags_runtime_handle_write_protected_flag();
}

pub fn enterAlphaMode() void {
    z47_flags_runtime_enter_alpha_mode();
}

pub fn leaveAlphaMode() void {
    z47_flags_runtime_leave_alpha_mode();
}

pub fn requestClFAllConfirmation() void {
    z47_flags_runtime_request_clf_all_confirmation();
}
