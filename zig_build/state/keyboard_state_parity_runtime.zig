pub const bool_t = bool;

pub const calcKey_t = extern struct {
    primaryAim: i16,
    gShiftedAim: i16,
};

pub const tam_state_t = extern struct {
    mode: u8,
    alpha: bool_t,
};

pub const ITM_A: i16 = 100;
pub const ITM_Z: i16 = 125;
pub const ITM_a: i16 = 126;
pub const ITM_z: i16 = 151;
pub const ITM_sigma: i16 = 170;
pub const ITM_SIGMA: i16 = 171;
pub const ITM_delta: i16 = 172;
pub const ITM_DELTA: i16 = 173;
pub const ITM_NULL: i16 = 174;
pub const ITM_SPACE: i16 = 175;
pub const ITM_EXIT1: i16 = 176;
pub const ITM_UP1: i16 = 177;
pub const ITM_DOWN1: i16 = 178;
pub const ITM_BACKSPACE: i16 = 179;
pub const ITM_ENTER: i16 = 180;
pub const ITM_toREAL: i16 = 181;
pub const ITM_CC: i16 = 182;
pub const ITM_UP1_ITEM: i16 = 183;
pub const ITM_DOWN1_ITEM: i16 = 184;
pub const ITM_EXIT1_ITEM: i16 = 185;
pub const ITM_BACKSPACE_ITEM: i16 = 186;
pub const ITM_dotD: i16 = 187;
pub const KEY_COMPLEX: i16 = 188;

pub const CM_NORMAL: u8 = 0;
pub const CM_AIM: u8 = 1;
pub const CM_EIM: u8 = 2;
pub const CM_PEM: u8 = 3;
pub const CM_ASSIGN: u8 = 4;
pub const CM_NIM: u8 = 5;
pub const CM_REGISTER_BROWSER: u8 = 6;
pub const CM_FLAG_BROWSER: u8 = 7;
pub const CM_FONT_BROWSER: u8 = 8;
pub const CM_PLOT_STAT: u8 = 9;
pub const CM_MIM: u8 = 10;
pub const CM_TIMER: u8 = 11;
pub const CM_GRAPH: u8 = 12;
pub const CM_ASN_BROWSER: u8 = 13;
pub const CM_LISTXY: u8 = 14;

pub const FLAG_USER: i32 = 1;
pub const FLAG_FRACT: u32 = 3;
pub const FLAG_IRFRAC: u32 = 4;
pub const FLAG_IRFRQ: i32 = 5;

pub const TI_NO_INFO: u8 = 0;

pub const PGM_WAITING: u8 = 1;

pub const SCRUPD_MANUAL_STACK: u8 = 0x02;
pub const SCRUPD_MANUAL_MENU: u8 = 0x04;
pub const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 0x20;

pub extern var calcMode: u8;
pub extern var itemToBeAssigned: i16;
pub extern var lastKeyCode: i16;
pub extern var tam: tam_state_t;
pub extern var kbd_usr: [37]calcKey_t;
pub extern var currentFlgScr: u8;
pub extern var lastErrorCode: u8;
pub extern var temporaryInformation: u8;
pub extern var programRunStop: u8;
pub extern var screenUpdatingMode: u8;
pub extern var keyActionProcessed: bool_t;
pub extern var ListXYposition: i16;

pub extern fn getSystemFlag(flag: i32) bool_t;
pub extern fn clearSystemFlag(flag: u32) void;
pub extern fn runFunction(item: i16) void;
pub extern fn addItemToNimBuffer(item: i16) void;
pub extern fn refreshScreen(reason: i16) void;
pub extern fn z47_keyboard_state_runtime_standard_key(index: u16, key: *calcKey_t) void;
extern fn z47_keyboard_state_retained_processKeyAction(item: i16) void;
extern fn z47_keyboard_state_retained_fnKeyEnter(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_retained_fnKeyExit(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_retained_fnKeyCC(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_retained_fnKeyBackspace(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_retained_fnKeyUp(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_retained_fnKeyDown(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_retained_fnKeyDotD(unused_but_mandatory_parameter: u16) void;

pub inline fn kbdStdAt(index: usize) calcKey_t {
    var key: calcKey_t = undefined;
    z47_keyboard_state_runtime_standard_key(@intCast(index), &key);
    return key;
}

pub inline fn maxAbs(item: i16) u16 {
    if (item < 0) {
        return @intCast(-item);
    }
    return @intCast(item);
}

pub fn processKeyActionRetained(item: i16) void {
    z47_keyboard_state_retained_processKeyAction(item);
}

pub fn fnKeyEnterRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_retained_fnKeyEnter(unused_but_mandatory_parameter);
}

pub fn fnKeyExitRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_retained_fnKeyExit(unused_but_mandatory_parameter);
}

pub fn fnKeyCCRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_retained_fnKeyCC(unused_but_mandatory_parameter);
}

pub fn fnKeyBackspaceRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_retained_fnKeyBackspace(unused_but_mandatory_parameter);
}

pub fn fnKeyUpRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_retained_fnKeyUp(unused_but_mandatory_parameter);
}

pub fn fnKeyDownRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_retained_fnKeyDown(unused_but_mandatory_parameter);
}

pub fn fnKeyDotDRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_retained_fnKeyDotD(unused_but_mandatory_parameter);
}
