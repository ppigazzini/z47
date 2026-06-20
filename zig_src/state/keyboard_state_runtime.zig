pub const bool_t = bool;
pub const is_dmcp_build = @import("builtin").target.os.tag == .freestanding;

pub const calcKey_t = extern struct {
    keyId: i16,
    primary: i16,
    fShifted: i16,
    gShifted: i16,
    keyLblAim: i16,
    primaryAim: i16,
    fShiftedAim: i16,
    gShiftedAim: i16,
    primaryTam: i16,
};

pub const tam_state_t = extern struct {
    mode: u16,
    function: i16,
    alpha: bool_t,
    currentOperation: i16,
    dot: bool_t,
    indirect: bool_t,
    digitsSoFar: i16,
    value0: i16,
    value: i16,
    min: i16,
    max: i16,
    key: i16,
    keyAlpha: bool_t,
    keyDot: bool_t,
    keyIndirect: bool_t,
    keyInputFinished: bool_t,
};

pub const ITM_A: i16 = 132;
pub const ITM_Z: i16 = 157;
pub const ITM_a: i16 = 158;
pub const ITM_z: i16 = 183;
pub const ITM_sigma: i16 = 104;
pub const ITM_SIGMA: i16 = 431;
pub const ITM_delta: i16 = 105;
pub const ITM_DELTA: i16 = 432;
pub const ITM_NULL: i16 = 1911;
pub const ITM_SPACE: i16 = 32;
pub const ITM_EXIT1: i16 = 0;
pub const ITM_UP1: i16 = 1;
pub const ITM_DOWN1: i16 = 2;
pub const ITM_BACKSPACE: i16 = 3;
pub const ITM_ENTER: i16 = 35;
pub const ITM_toREAL: i16 = 1691;
pub const ITM_CC: i16 = 1730;
pub const ITM_UP1_ITEM: i16 = 1733;
pub const ITM_DOWN1_ITEM: i16 = 1735;
pub const ITM_EXIT1_ITEM: i16 = 1737;
pub const ITM_BACKSPACE_ITEM: i16 = 1738;
pub const ITM_dotD: i16 = 1741;
pub const KEY_COMPLEX: i16 = 1848;

pub const CM_NORMAL: u8 = 0;
pub const CM_AIM: u8 = 1;
pub const CM_NIM: u8 = 2;
pub const CM_PEM: u8 = 3;
pub const CM_ASSIGN: u8 = 4;
pub const CM_REGISTER_BROWSER: u8 = 5;
pub const CM_FLAG_BROWSER: u8 = 6;
pub const CM_FONT_BROWSER: u8 = 7;
pub const CM_PLOT_STAT: u8 = 8;
pub const CM_MIM: u8 = 12;
pub const CM_EIM: u8 = 13;
pub const CM_TIMER: u8 = 14;
pub const CM_GRAPH: u8 = 15;
pub const CM_ASN_BROWSER: u8 = 17;
pub const CM_LISTXY: u8 = 18;

pub const FLAG_USER: i32 = 43;
pub const FLAG_FRACT: u32 = 0x8007;
pub const FLAG_IRFRAC: u32 = 0x8047;
pub const FLAG_IRFRQ: i32 = 0xc048;

pub const TI_NO_INFO: u8 = 0;

pub const PGM_WAITING: u8 = 2;
const PGM_RUNNING: u8 = 1;
const PGM_PAUSED: u8 = 3;

pub const SCRUPD_MANUAL_STACK: u8 = 0x02;
pub const SCRUPD_MANUAL_MENU: u8 = 0x04;
pub const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 0x20;
const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;

const FLAG_INTING: i32 = 0xc025;
const FLAG_SOLVING: i32 = 0xc026;
const ITM_RS: i16 = 1725;

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
pub extern var calcModel: u8;
pub extern var lastKeyItemDetermined: i16;

pub extern var kbd_std_C47: [37]calcKey_t;
pub extern var kbd_std_DM42: [37]calcKey_t;
pub extern var kbd_std_R47f_g: [37]calcKey_t;
pub extern var kbd_std_R47bk_fg: [37]calcKey_t;
pub extern var kbd_std_R47fg_bk: [37]calcKey_t;
pub extern var kbd_std_R47fg_g: [37]calcKey_t;

const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;

pub extern fn getSystemFlag(flag: i32) bool_t;
pub extern fn clearSystemFlag(flag: u32) void;
pub extern fn runFunction(item: i16) void;
pub extern fn addItemToNimBuffer(item: i16) void;
pub extern fn refreshScreen(reason: i16) void;
extern fn z47_keyboard_state_processKeyAction(item: i16) void;
extern fn z47_keyboard_state_fnKeyEnter(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_fnKeyExit(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_fnKeyCC(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_fnKeyBackspace(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_fnKeyUp(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_fnKeyDown(unused_but_mandatory_parameter: u16) void;
extern fn z47_keyboard_state_fnKeyDotD(unused_but_mandatory_parameter: u16) void;

pub inline fn kbdStdAt(index: usize) calcKey_t {
    const selected: *[37]calcKey_t = switch (calcModel) {
        USER_C47 => &kbd_std_C47,
        USER_DM42 => &kbd_std_DM42,
        USER_R47f_g => &kbd_std_R47f_g,
        USER_R47bk_fg => &kbd_std_R47bk_fg,
        USER_R47fg_bk => &kbd_std_R47fg_bk,
        USER_R47fg_g => &kbd_std_R47fg_g,
        else => &kbd_std_C47,
    };
    return selected[index];
}

pub inline fn maxAbs(item: i16) u16 {
    if (item < 0) {
        return @intCast(-item);
    }
    return @intCast(item);
}

pub fn processKeyActionRetained(item: i16) void {
    z47_keyboard_state_processKeyAction(item);
}

pub fn keyEnterRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_fnKeyEnter(unused_but_mandatory_parameter);
}

pub fn keyExitRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_fnKeyExit(unused_but_mandatory_parameter);
}

pub fn keyCCRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_fnKeyCC(unused_but_mandatory_parameter);
}

pub fn keyBackspaceRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_fnKeyBackspace(unused_but_mandatory_parameter);
}

pub fn keyUpRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_fnKeyUp(unused_but_mandatory_parameter);
}

pub fn keyDownRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_fnKeyDown(unused_but_mandatory_parameter);
}

pub fn keyDotDRetained(unused_but_mandatory_parameter: u16) void {
    z47_keyboard_state_fnKeyDotD(unused_but_mandatory_parameter);
}

fn clearStatusbarUpdateFlags(mode: u8) u8 {
    return mode & ~@as(u8, SCRUPD_MANUAL_STATUSBAR | SCRUPD_SKIP_STATUSBAR_ONE_TIME);
}

fn repairStopStatusbarMask(previous_program_run_stop: u8, previous_screen_updating_mode: u8) void {
    if ((previous_program_run_stop == PGM_RUNNING or previous_program_run_stop == PGM_PAUSED) and
        programRunStop == PGM_WAITING and
        (lastKeyItemDetermined == ITM_RS or lastKeyItemDetermined == ITM_EXIT1_ITEM) and
        !getSystemFlag(FLAG_INTING) and
        !getSystemFlag(FLAG_SOLVING)) {
        screenUpdatingMode = clearStatusbarUpdateFlags(previous_screen_updating_mode);
    }
}

pub fn btnPressedHostOverlay(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void {
    const previous_program_run_stop = programRunStop;
    const previous_screen_updating_mode = screenUpdatingMode;

    legacy_host.@"z47_keyboard_state_btnPressed"(not_used, event, data);
    repairStopStatusbarMask(previous_program_run_stop, previous_screen_updating_mode);
}

pub fn btnClickedHostOverlay(not_used: ?*anyopaque, data: ?*anyopaque) void {
    const previous_program_run_stop = programRunStop;
    const previous_screen_updating_mode = screenUpdatingMode;

    legacy_host.@"z47_keyboard_state_btnClicked"(not_used, data);
    repairStopStatusbarMask(previous_program_run_stop, previous_screen_updating_mode);
}

pub fn btnPressedDmcpOverlay(data: ?*anyopaque) void {
    legacy_dmcp.@"z47_keyboard_state_btnPressed"(data);
}

pub fn btnClickedDmcpOverlay(unused: ?*anyopaque, data: ?*anyopaque) void {
    _ = unused;
    btnPressedDmcpOverlay(data);
    btnReleased(data);
}

extern fn btnReleased(data: ?*anyopaque) void;

// --- fnKeyCC dependencies ---------------------------------------------------
pub const REGISTER_X: i16 = 100;
pub const REGISTER_Y: i16 = 101;
pub const dtLongInteger: u8 = 0;
pub const dtReal34: u8 = 1;
pub const dtComplex34: u8 = 2;
pub const dtReal34Matrix: u8 = 6;
pub const dtComplex34Matrix: u8 = 7;
pub const amNone: u8 = 5;
pub const amAngleMask: u32 = 15;
pub const FLAG_POLAR: i32 = 32774;
pub const FLAG_ALPHA: i32 = 32782;
pub const ITM_op_j: i16 = 1830;
pub const ITM_op_j_pol: i16 = 1795;
pub const ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT: u8 = 52;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
pub const ERR_REGISTER_LINE: i16 = 102;
pub extern var doRefreshSoftMenu: bool_t;
pub extern var temporaryFlagRect: bool_t;
pub extern var temporaryFlagPolar: bool_t;
pub extern var aimBuffer: [*c]u8;
pub extern fn setSystemFlag(sf: c_uint) void;
pub extern fn getRegisterDataType(regist: i16) u32;
pub extern fn getRegisterTag(regist: i16) u32;
pub extern fn fnSwapXY(unused: u16) void;
pub extern fn fnReToCx(unused: u16) void;
pub extern fn fnCxToRe(unused: u16) void;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
pub extern fn mimAddNumber(item: i16) void;
pub extern fn pemAddNumber(item: i16, do_insert_in_program: bool_t) void;
pub extern fn getDataTypeName(dt: u16, article: bool_t, pad_with_blanks: bool_t) [*c]const u8;
pub extern fn getRegisterTagName(regist: i16, pad_with_blanks: bool_t) [*c]const u8;
pub extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;
pub inline fn getRegisterAngularMode(regist: i16) u32 {
    return getRegisterTag(regist) & amAngleMask;
}

// commonBugScreenMessages[bugMsgCalcModeWhileProcKey] is the "calcMode while
// processing key" bug format; SIZE_OF_EACH_BUG_SCREEN_MESSAGE = 100 (probed).
// Shared by every fnKey* handler's default (unexpected-calcMode) branch.
pub extern var errorMessage: [*c]u8;
pub extern fn sprintf(buffer: [*c]u8, format: [*c]const u8, ...) c_int;
pub extern fn displayBugScreen(message: [*c]const u8) void;
const SIZE_OF_EACH_BUG_SCREEN_MESSAGE: usize = 100;
const bugMsgCalcModeWhileProcKey: usize = 1;
const commonBugScreenMessages = @extern([*c]const u8, .{ .name = "commonBugScreenMessages" });
pub fn bugScreenWhileProcKey(func_name: [*:0]const u8, key_str: [*:0]const u8) void {
    const fmt = commonBugScreenMessages + bugMsgCalcModeWhileProcKey * SIZE_OF_EACH_BUG_SCREEN_MESSAGE;
    _ = sprintf(errorMessage, fmt, func_name, @as(c_int, calcMode), key_str);
    displayBugScreen(errorMessage);
}

const legacy_host = struct {
    extern fn @"z47_keyboard_state_btnPressed"(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
    extern fn @"z47_keyboard_state_btnClicked"(not_used: ?*anyopaque, data: ?*anyopaque) void;
};

const legacy_dmcp = struct {
    extern fn @"z47_keyboard_state_btnPressed"(data: ?*anyopaque) void;
};
