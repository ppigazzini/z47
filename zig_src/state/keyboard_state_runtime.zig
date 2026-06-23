const std = @import("std");
const builtin = @import("builtin");
pub const bool_t = bool;
pub const is_dmcp_build = builtin.target.os.tag == .freestanding;

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

// items.h codes (probed against src/c47/items.h). The original keyboard scaffold
// carried stale values for this block (e.g. ITM_A=132, ITM_UP1=1, ITM_BACKSPACE=3),
// which silently broke caseReplacements / keyReplacements / the keyCC NIM path; the
// testSuite did not exercise those branches. Corrected to the true item codes here.
pub const ITM_A: i16 = 550;
pub const ITM_Z: i16 = 575;
pub const ITM_a: i16 = 576;
pub const ITM_z: i16 = 601;
pub const ITM_sigma: i16 = 646;
pub const ITM_SIGMA: i16 = 620;
pub const ITM_delta: i16 = 631;
pub const ITM_DELTA: i16 = 605;
pub const ITM_NULL: i16 = 0;
pub const ITM_SPACE: i16 = 806;
pub const ITM_EXIT1: i16 = 1737;
pub const ITM_UP1: i16 = 1733;
pub const ITM_DOWN1: i16 = 1735;
pub const ITM_BACKSPACE: i16 = 1738;
pub const ITM_ENTER: i16 = 35;
pub const ITM_toREAL: i16 = 1691;
pub const ITM_CC: i16 = 1730;
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

pub const FLAG_USER: i32 = 32788; // probed (was a stale 43 in the original scaffold)
pub const FLAG_FRACT: u32 = 0x8007;
pub const FLAG_IRFRAC: u32 = 0x8047;
pub const FLAG_IRFRQ: i32 = 0xc048;

pub const TI_NO_INFO: u8 = 0;

pub const PGM_WAITING: u8 = 2;
pub const PGM_RUNNING: u8 = 1;
pub const PGM_PAUSED: u8 = 3;

pub const SCRUPD_MANUAL_STACK: u8 = 0x02;
pub const SCRUPD_MANUAL_MENU: u8 = 0x04;
pub const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 0x20;
pub const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;
pub const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;

pub const FLAG_INTING: i32 = 0xc025;
pub const FLAG_SOLVING: i32 = 0xc026;
pub const ITM_RS: i16 = 1725;

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

pub const USER_DM42: u8 = 45;
pub const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
pub const USER_R47bk_fg: u8 = 62;
pub const USER_R47fg_bk: u8 = 63;
pub const USER_R47fg_g: u8 = 64;

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
        (lastKeyItemDetermined == ITM_RS or lastKeyItemDetermined == ITM_EXIT1) and
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

// --- fnKeyBackspace dependencies --------------------------------------------
pub const TI_VIEW_REGISTER: u8 = 15;
pub const TI_ARE_YOU_SURE: u8 = 9;
pub const TI_SHOW_REGISTER: u8 = 14;
pub const TI_SHOW_REGISTER_BIG: u8 = 75;
pub const TI_SHOW_REGISTER_SMALL: u8 = 76;
pub const TI_SHOW_REGISTER_TINY: u8 = 77;
pub const TI_SHOWNOTHING: u8 = 93;
pub const SCRUPD_AUTO: u8 = 0;
pub const ITM_DROP: i16 = 37;
pub const ITM_CLX: i16 = 41;
pub const ITM_T_LEFT_ARROW: u16 = 1952;
pub const FLAG_CLX_DROP: i32 = 32859;
pub const CATALOG_MVAR: i16 = 18;
pub const CM_CONFIRMATION: u8 = 11;
pub const CM_BUG_ON_SCREEN: u8 = 10;
pub const PGM_STOPPED: u8 = 0;
pub const Y_POSITION_OF_AIM_LINE: u32 = 132;
pub const vmNormal: c_int = 0;
pub const NOPARAM: u16 = 9876;

pub extern var catalog: i16;
pub extern var xCursor: u32;
pub extern var T_cursorPos: i16;
pub extern var alphaCursor: i16;
pub extern var previousCalcMode: u8;
pub extern var shiftF: bool_t;
pub extern var shiftG: bool_t;
pub extern var currentStep: [*c]u8;
pub extern var currentLocalStepNumber: u16;
pub extern var programListEnd: bool_t;
pub extern var pemCursorIsZerothStep: bool_t;
pub extern var asnKey: [4]u8;
// standardFont is a `const font_t`; we only need its address for showString().
pub const standardFont = @extern(*const anyopaque, .{ .name = "standardFont" });

pub extern fn strlen(s: [*c]const u8) usize;
pub extern fn tamProcessInput(item: u16) void;
pub extern fn closeShowMenu() void;
pub extern fn showFunctionName(itm: i16, delay_ms: i16, arg: [*c]const u8) void;
pub extern fn stringLastGlyph(str: [*c]const u8) i16;
pub extern fn stringNextGlyph(str: [*c]const u8, pos: i16) i16;
pub extern fn showString(str: [*c]const u8, font: ?*const anyopaque, x: u32, y: u32, video_mode: c_int, show_leading: bool_t, show_ending: bool_t) u32;
pub extern fn pemAlpha(item: i16) void;
pub extern fn defineCurrentStep() void;
pub extern fn scrollPemBackwards() void;
pub extern fn deleteStepsFromTo(from: [*c]u8, to: [*c]u8) void;
pub extern fn findNextStep(step: [*c]u8) [*c]u8;
pub extern fn findPreviousStep(step: [*c]u8) [*c]u8;
pub extern fn deleteAlphaCharacter(current_cursor: *i16) void;
pub extern fn assignLeaveAlpha() void;
pub extern fn assignToKey(data: [*c]const u8) void;
pub extern fn fnBackspaceTimerApp() void;
pub extern fn fnT_ARROW(command: u16) void;
// _assignToMenu (keyboard.c 748-807) is ported in keyboard_state_shared.zig.
pub const ERROR_CANNOT_ASSIGN_HERE: u8 = 47;
pub extern fn assignToMyMenu(position: u16) void;
pub extern fn assignToMyAlpha(position: u16) void;
pub extern fn assignToUserMenu(position: u16) void;
// SHOWMODE macro (defines.h): a normal-mode SHOW/VIEW temporaryInformation state.
pub inline fn isShowMode() bool {
    return calcMode == CM_NORMAL and (temporaryInformation == TI_SHOW_REGISTER or
        temporaryInformation == TI_SHOW_REGISTER_BIG or
        temporaryInformation == TI_SHOW_REGISTER_SMALL or
        temporaryInformation == TI_SHOW_REGISTER_TINY or
        temporaryInformation == TI_SHOWNOTHING);
}

// --- fnKeyUp / fnKeyDown dependencies ---------------------------------------
const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};
const softmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    softkeyItem: [*c]const i16,
};
const subroutineLevelHeader_t = extern struct {
    returnProgramNumber: i16,
    returnLocalStep: u16,
    numberOfLocalFlags: u8,
    numberOfLocalRegisters: u8,
    subroutineLevel: u16,
    ptrToNextLevel: u16,
    ptrToPreviousLevel: u16,
};

pub const MNU_TAMALPHA: i16 = 1913;
pub const MNU_REG: i16 = 2066;
pub const MNU_FLG: i16 = 2067;
pub const MNU_EQN: i16 = 1327;
pub const MNU_PLOT_ASSESS: i16 = 1396;
pub const MNU_TAMSTO: i16 = 1387;
pub const MNU_TAMRCL: i16 = 1912;
pub const MNU_alpha_omega: i16 = 1383;
pub const MNU_ALPHAintl: i16 = 1384;
pub const MNU_ALPHA_OMEGA: i16 = 1377;
pub const MNU_ALPHAINTL: i16 = 1374;
pub const ITM_MENU: i16 = 1520;
pub const ITM_NOP: u16 = 1542;
pub const ITM_1: u16 = 541;
pub const ITM_9: u16 = 549;
pub const ITM_2: u16 = 542;
pub const ITM_0: u16 = 540;
pub const ITM_Max: u16 = 2654;
pub const ITM_Min: u16 = 2655;
pub const TM_KEY: u16 = 10012;
pub const TM_NEWMENU: u16 = 10011;
pub const AC_UPPER: u8 = 0;
pub const AC_LOWER: u8 = 1;
pub const RBR_GLOBAL: u8 = 0;
pub const RBR_LOCAL: u8 = 1;
pub const RBR_NAMED: u8 = 2;
pub const RBR_INCDEC1: i32 = 10;
pub const LAST_GLOBAL_REGISTER_SCREEN: i32 = 120;
pub const FIRST_LOCAL_REGISTER: i32 = 7000;
pub const FIRST_NAMED_VARIABLE: i32 = 256;
pub const LAST_RESERVED_VARIABLE: i32 = 2047;
pub const FIRST_RESERVED_VARIABLE: i32 = 2000;
pub const NUMBER_OF_LETTERED_VARIABLES: i32 = 26;
pub const INVALID_VARIABLE: u16 = 2199;
pub const PLOT_NXT: u16 = 1;
pub const PLOT_REV: u16 = 2;
// `#define arrowCasechange false` (defines.h) — always-false compile constant.
pub const arrowCasechange = false;

pub extern var softmenuStack: [8]softmenuStack_t; // SOFTMENU_STACK_SIZE
// softmenu[] is a flexible `const softmenu_t[]`; take its base address.
pub const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
pub extern var currentSubroutineLevelData: [*c]subroutineLevelHeader_t;
pub extern var dynamicMenuItem: i16;
pub extern var numberOfFormulae: u16;
pub extern var currentFormula: u16;
pub extern var currentSolverVariable: u16;
pub extern var graphVariabl1: i16; // calcRegister_t = int16_t
pub extern var plotStatMx: [8]u8;
pub extern var rbr1stDigit: bool_t;
pub extern var rbrMode: u8;
pub extern var currentRegisterBrowserScreen: i16;
pub extern var numberOfNamedVariables: u16;
pub extern var currentAsnScr: u8;
pub extern var currentFntScr: u8;
pub extern var numScreensStandardFont: u8;
pub extern var numScreensNumericFont: u8;
pub extern var numScreensTinyFont: u8;
pub extern var alphaCase: u8;

pub extern fn currentMenu() i16;
pub extern fn fnAlphaCursorHome(unused: u16) void;
pub extern fn fnAlphaCursorEnd(unused: u16) void;
pub extern fn resetAlphaSelectionBuffer() void;
pub extern fn addItemToBuffer(item: u16) void;
pub extern fn fnProgrammableMenu(unused: u16) void;
pub extern fn isJMAlphaSoftmenu(menu_id: i16) bool_t;
pub extern fn currentSoftmenuScrolls() bool_t;
pub extern fn closeNim() void;
pub extern fn closeAim() void;
pub extern fn fnBst(unused: u16) void;
pub extern fn fnSst(unused: u16) void;
pub extern fn refreshLcd(unused_data: ?*anyopaque) c_int; // gboolean refreshLcd(gpointer) on PC_BUILD
pub extern fn fnPlotStat(unused: u16) void;
pub extern fn fnUpTimerApp() void;
pub extern fn fnDownTimerApp() void;
pub extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
// menuUp / menuDown / stayInAIM ports (keyboard.c 3296-3373 / 3577-3592).
pub const ERROR_NONE: u8 = 0;
pub const CATALOG_NONE: i16 = 0;
pub const NUMBER_OF_DYNAMIC_SOFTMENUS: i16 = 22;
pub const MNU_ALPHAMATH: i16 = 1375;
pub extern fn setCatalogLastPos() void;
pub extern fn changeToALPHA() void;

pub fn menuUp() void {
    const menuId: i16 = softmenuStack[0].softmenuId;
    const sm: i16 = softmenu[@intCast(menuId)].menuItem;
    screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
    if (temporaryInformation == TI_NO_INFO and lastErrorCode == ERROR_NONE) {
        screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
    }
    if ((sm == -MNU_alpha_omega or sm == -MNU_ALPHAintl) and alphaCase == AC_LOWER) {
        alphaCase = AC_UPPER;
        showAlphaModeonGui();
        softmenuStack[0].softmenuId -= 1;
    } else if ((sm == -MNU_ALPHAMISC or sm == -MNU_ALPHAMATH or sm == -MNU_ALPHA) and alphaCase == AC_LOWER and arrowCasechange) {
        alphaCase = AC_UPPER;
        showAlphaModeonGui();
    } else {
        const itemShift: i16 = if (catalog == CATALOG_NONE) 18 else 6;
        const numItems: i16 = if (menuId < NUMBER_OF_DYNAMIC_SOFTMENUS) dynamicSoftmenu[@intCast(menuId)].numItems else softmenu[@intCast(menuId)].numItems;
        if ((softmenuStack[0].firstItem + itemShift) < numItems) {
            softmenuStack[0].firstItem += itemShift;
        } else {
            softmenuStack[0].firstItem = 0;
        }
        setCatalogLastPos();
    }
    doRefreshSoftMenu = true;
}

pub fn menuDown() void {
    const menuId: i16 = softmenuStack[0].softmenuId;
    const sm: i16 = softmenu[@intCast(menuId)].menuItem;
    screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
    if (temporaryInformation == TI_NO_INFO and lastErrorCode == ERROR_NONE) {
        screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
    }
    if ((sm == -MNU_ALPHA_OMEGA or sm == -MNU_ALPHAINTL) and alphaCase == AC_UPPER) {
        alphaCase = AC_LOWER;
        showAlphaModeonGui();
        softmenuStack[0].softmenuId += 1;
    } else if ((sm == -MNU_ALPHAMISC or sm == -MNU_ALPHAMATH or sm == -MNU_ALPHA) and alphaCase == AC_UPPER and arrowCasechange) {
        alphaCase = AC_LOWER;
        showAlphaModeonGui();
    } else {
        const itemShift: i16 = if (catalog == CATALOG_NONE) 18 else 6;
        if ((softmenuStack[0].firstItem - itemShift) >= 0) {
            softmenuStack[0].firstItem -= itemShift;
        } else if ((softmenuStack[0].firstItem - itemShift) >= -5) {
            softmenuStack[0].firstItem = 0;
        } else {
            const numItems: i16 = if (menuId < NUMBER_OF_DYNAMIC_SOFTMENUS) dynamicSoftmenu[@intCast(menuId)].numItems else softmenu[@intCast(menuId)].numItems;
            softmenuStack[0].firstItem = @divTrunc(@divTrunc(numItems - 1, 6), @divTrunc(itemShift, 6)) * itemShift;
        }
        setCatalogLastPos();
    }
    doRefreshSoftMenu = true;
}

pub inline fn softmenuItemAt(index: i16) i16 {
    return softmenu[@intCast(index)].menuItem;
}
pub inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData.*.numberOfLocalRegisters;
}
// modulo(n, d) macro (defines.h, valid for d > 0): C truncated remainder lifted
// into the non-negative range.
pub fn modulo(n: i32, d: i32) i32 {
    const r = @rem(n, d);
    return if (r < 0) r + d else r;
}
const bugMsgRbrMode: usize = 8;
pub fn bugScreenRbrMode(func_name: [*:0]const u8, key_str: [*:0]const u8, mode: u8) void {
    const fmt = commonBugScreenMessages + bugMsgRbrMode * SIZE_OF_EACH_BUG_SCREEN_MESSAGE;
    _ = sprintf(errorMessage, fmt, func_name, key_str, @as(c_int, mode));
    displayBugScreen(errorMessage);
}

// --- fnKeyEnter dependencies ------------------------------------------------
const formulaHeader_t = extern struct {
    pointerToFormulaData: u16,
    sizeInBlocks: u8,
    unused: u8,
};

pub const FLAG_ERPN: i32 = 32837;
pub const FLAG_ASLIFT: u32 = 49187;
pub const ERROR_RAM_FULL: u8 = 11;
pub const TI_UNDO_DISABLED: u8 = 49;
pub const NIM_REGISTER_LINE: i16 = 100;
pub const dtString: u32 = 5;
pub const EQUATION_PARSER_MVAR: u16 = 0;
pub const MNU_ALPHA: i16 = 1922;
pub const MNU_EQ_EDIT: i16 = 1399;
pub const LINE_FULL: u16 = 0;
pub const CM_ERROR_MESSAGE: u8 = 9;
const STRLGINT_HEADER_SIZE: usize = 4; // sizeof(strLgIntHeader_t)
pub const C47_NULL: u16 = 65535;

pub extern var nimWhenButtonPressed: bool_t;
pub extern var ram: [*c]u32;
pub extern var allFormulae: [*c]formulaHeader_t;
pub extern var tmpString: [*c]u8;

pub extern fn saveForUndo() void;
pub extern fn liftStack() void;
pub extern fn copySourceRegisterToDestRegister(r_source: i16, r_dest: i16) void;
pub extern fn calcModeNormal() void;
pub extern fn popSoftmenu() void;
pub extern fn menu(n: u8) i16;
pub extern fn undo() void;
pub extern fn fnUndo(unused: u16) void;
pub extern fn mimEnter(commit: bool_t) void;
pub extern fn setEquation(equation_id: u16, equation_string: [*c]const u8) void;
pub extern fn parseEquation(equation_id: u16, parse_mode: u16, buffer: [*c]u8, mvar_buffer: [*c]u8) void;
pub extern fn deleteEquation(equation_id: u16) void;
pub extern fn refreshRegisterLine(regist: i16) void;
pub extern fn fnRegAddTimerApp(unused: u16) void;
pub extern fn printTraceX(where_: u16) void;
pub extern fn getRegisterDataPointer(regist: i16) [*c]u8; // void* in C (byte arithmetic)
pub extern fn reallocateRegister(regist: i16, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn xcopy(dest: [*c]u8, source: [*c]const u8, n: u32) [*c]u8;

// TO_BLOCKS(n): bytes -> 4-byte blocks (BYTES_PER_BLOCK = 4, BPB = 2).
pub inline fn toBlocks(n: u32) u16 {
    return @intCast((n + 3) >> 2);
}
// REGISTER_STRING_DATA(reg): skip the 4-byte string/long-int header.
pub inline fn registerStringData(regist: i16) [*c]u8 {
    return getRegisterDataPointer(regist) + STRLGINT_HEADER_SIZE;
}
// TO_PCMEMPTR(p): block number -> RAM pointer, or null for the C47_NULL sentinel.
pub inline fn toPcMemPtr(p: u16) ?[*]u8 {
    if (p == C47_NULL) return null;
    return @ptrCast(ram + p);
}

// --- fnKeyExit dependencies -------------------------------------------------
pub const MNU_SYSFL: i16 = 1379;
pub const MNU_GRAPHS: i16 = 2374;
pub const MNU_PLOT_FUNC: i16 = 2028;
pub const MNU_HOME: i16 = 1921;
pub const MNU_MyMenu: i16 = 1349;
pub const MNU_M_EDIT: i16 = 1348;
pub const MNU_PFN: i16 = 1403;
pub const MNU_AIMCATALOG: i16 = 2552;
pub const MNU_EIMCATALOG: i16 = 2227;
pub const MNU_HIST: i16 = 1401;
pub const MNU_PLOTTING: i16 = 2107;
pub const MNU_MODEL: i16 = 2081;
pub const MNU_REGR: i16 = 2080;
pub const MNU_TIMERF: i16 = 1400;
pub const MNU_YESNO: i16 = 2244;
pub const MNU_MVAR: i16 = 1398;
pub const SOLVER_STATUS_INTERACTIVE: u16 = 2;
pub const SOLVER_STATUS_EQUATION_MODE: u16 = 8204;
pub const SOLVER_STATUS_EQUATION_INTEGRATE: u16 = 4;
pub const SOLVER_STATUS_SINGLE_VARIABLE: u16 = 16;
pub const FLAG_BASE_HOME: i32 = 32862;
pub const FLAG_BASE_MYM: i32 = 32860;
pub const ERROR_SOLVER_ABORT: u8 = 60;
pub const dtShortInteger: u32 = 8;
pub const EQ_PLOT_LU: u16 = 5;
pub const PLOT_NOTHING: u16 = 5;
pub const SIGMA_NONE: i8 = 0;
pub const RESTORING_STATS: usize = 102;
pub const NP_INT_BASE: u8 = 3;
pub const SCREEN_WIDTH: u32 = 400;
pub const LCD_SET_VALUE: c_int = 0;
pub const force_status: u8 = 1; // `force` enumerator passed to printStatus()
const SIZE_OF_EACH_ERROR_MESSAGE: usize = 48;

pub extern var currentSolverStatus: u16;
pub extern var systemFlags0: u64;
pub extern var systemFlags1: u64;
pub extern var numberOfTamMenusToPop: i16;
pub extern var currentInputVariable: u16;
pub extern var nimNumberPart: u8;
pub extern var matrixIndex: u16;
pub extern var statMx: [8]u8;
pub extern var reDraw: bool_t;
pub extern var last_CM: u8;
pub extern var lastPlotMode: u16;
pub extern var plotSelection: u16;
pub extern var SAVED_SIGMA_lastAddRem: i8;
pub extern var BASE_OVERRIDEONCE: bool_t;
const errorMessages_base = @extern([*c]const u8, .{ .name = "errorMessages" });
pub inline fn errorMessageAt(row: usize) [*c]const u8 {
    return errorMessages_base + row * SIZE_OF_EACH_ERROR_MESSAGE;
}

pub extern fn leaveAsmMode() void;
pub extern fn leaveTamModeIfEnabled() void;
pub extern fn showSoftmenu(id: i16) void;
pub extern fn fnEqSolvGraph(unused: u16) void;
pub extern fn updateMatrixHeightCache() void;
pub extern fn mimFinalize() void;
pub extern fn findNamedVariable(variable_name: [*c]const u8) i16;
pub extern fn calcSigma(max_offset: u16) void;
pub extern fn pemCloseAlphaInput() void;
pub extern fn pemCloseNumberInput() void;
pub extern fn extractPFNMenus() void;
pub extern fn fnLeaveTimerApp() void;
pub extern fn fnRefreshState() void;
pub extern fn fnItemTimerApp(unused: u16) void;
pub extern fn fnClDrawMx(origin: u8) void;
pub extern fn printStatus(row: u8, line1: [*c]const u8, forced: u8) void;
pub extern fn restoreStats() void;
pub extern fn forceSBupdate() void;
pub extern fn isAlphaSubmenu(n: u8) bool_t;
// lcd_fill_rect is a DMCP ROM function-table macro on firmware (lft_ifc.h:61,
// LIBRARY_FN_BASE + 60) and a real GTK-layer symbol on host. jm_show_calc_state is
// a host-only telltale (no-op unless PC_BUILD_TELLTALE) -> no-op on firmware. Both
// are reconstructed lane-aware here so handlers that reach clearScreen / the
// telltale (keyExit, keyBackspace) can run on the DMCP lanes. This mirrors the
// established, build/link-verified frontier ROM-trampoline pattern (cf.
// frontier_status_bar_owned.zig, same +60 offset and LIBRARY_FN_BASE).
const LIBRARY_FN_BASE: usize = if (builtin.target.cpu.model == &std.Target.arm.cpu.cortex_m4) 0x08000201 else 0x08000301;
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = if (!is_dmcp_build) @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" }) else {};
pub inline fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime is_dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}
const JmShowCalcStateFn = *const fn (comment: [*c]const u8) callconv(.c) void;
fn jmShowCalcStateNoop(comment: [*c]const u8) callconv(.c) void {
    _ = comment; // host-only telltale; no-op on firmware
}
const jm_show_calc_state_impl: JmShowCalcStateFn = if (is_dmcp_build) &jmShowCalcStateNoop else @extern(JmShowCalcStateFn, .{ .name = "jm_show_calc_state" });
pub inline fn jm_show_calc_state(comment: [*c]const u8) void {
    jm_show_calc_state_impl(comment);
}
pub fn stayInAIM() void {
    if (calcMode == CM_AIM and (currentMenu() != -MNU_ALPHA and currentMenu() != -MNU_MyAlpha)) {
        changeToALPHA();
        setSystemFlag(@intCast(FLAG_ALPHA));
    }
    if (calcMode != CM_AIM and (currentMenu() == -MNU_ALPHA or menu(1) == -MNU_ALPHA)) {
        setSystemFlag(@intCast(FLAG_ALPHA));
        calcMode = CM_AIM;
    }
    refreshModeGui();
}
// clearScreen(cnt) macro (screen.h, !MONITOR_CLRSCR): full-screen fill + SB update.
pub fn clearScreen() void {
    lcd_fill_rect(0, 0, SCREEN_WIDTH, 240, LCD_SET_VALUE);
    forceSBupdate();
}

// --- keyboardTweak.c fnCla / fnCln dependencies -----------------------------
pub const AIM_REGISTER_LINE: i16 = 100;
pub extern var nextChar: u8;
pub extern var scrLock: u8;
pub extern var yCursor: u32;
pub extern var cursorFont: ?*const anyopaque;
pub extern var cursorEnabled: bool_t;
pub extern fn clearRegisterLine(regist: i16, clear_top: bool_t, clear_bottom: bool_t) void;
pub extern fn fnEqCla() void;
pub extern fn fnKeyBackspace(unused: u16) void; // canonical (Zig export on host, C on dmcp)

// --- keyboardTweak.c fnT_ARROW dependencies ---------------------------------
pub const ITM_T_RIGHT_ARROW: u16 = 1953;
pub const ITM_T_LLEFT_ARROW: u16 = 1954;
pub const ITM_T_RRIGHT_ARROW: u16 = 1955;
pub const ITM_T_UP_ARROW: u16 = 1926;
pub const ITM_T_DOWN_ARROW: u16 = 1928;
pub extern var displayAIMbufferoffset: i16;
pub extern var current_cursor_x: u16;
pub extern var current_cursor_y: u16;
pub extern var multiEdLines: u8;
pub extern fn stringPrevGlyph(str: [*c]const u8, pos: i16) i16;
pub extern fn incOffset() void;
pub extern fn findOffset() void;

// --- keyboardTweak.c GUI-mode helpers ---------------------------------------
pub const SCRUPD_SKIP_MENU_ONE_TIME: u8 = 64;
pub extern fn showHideAlphaMode() void;
// calcMode*Gui are real functions only on host (empty macros on the DMCP lane).
pub extern fn calcModeAimGui() void;
pub extern fn calcModeNormalGui() void;

// --- keyboardTweak.c shift-state helpers ------------------------------------
pub const SCRUPD_MANUAL_SHIFT_STATUS: u8 = 8;
pub const TO_FG_LONG: u8 = 0;
pub const TO_CL_LONG: u8 = 1;
pub const TO_FG_TIMR: u8 = 2;
pub const TO_FN_LONG: u8 = 3;
pub const TO_3S_CTFF: u8 = 5;
pub const TO_AUTO_REPEAT: u8 = 7;
pub const timed: u8 = 0;
pub extern var cleanupAfterShift: bool_t;
pub extern fn showShiftStateF() void;
pub extern fn showShiftStateG() void;
pub extern fn clearShiftState() void;
pub extern fn show_f_jm() void;
pub extern fn show_g_jm() void;
pub extern fn clear_fg_jm() void;
pub extern fn force_refresh(mode: u8) void;
pub extern fn fnTimerStop(nr: u8) void;

// --- keyboardTweak.c openHOMEorMyM dependencies -----------------------------
pub const keypress_fff: bool_t = true;
pub const FLAG_HOME_TRIPLE: i32 = 32864;
pub const FLAG_MYM_TRIPLE: i32 = 32863;
pub const MNU_MyAlpha: i16 = 1350;
pub const MNU_DYNAMIC: i16 = 1394;
pub const ITM_ms: i16 = 1909;
pub const ITM_HASH_JM: i16 = 1872;
pub const ITM_toINT: i16 = 1687;
const item_t = extern struct {
    func: ?*const anyopaque, // void(*)(uint16_t) -- only ever compared, never called
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
pub fn itemFuncIsAddItemToBuffer(item: i16) bool {
    const f = indexOfItems[@intCast(item)].func;
    return f == @as(?*const anyopaque, @ptrCast(&addItemToBuffer));
}
pub fn itemFuncEquals(item: i16, f: ?*const anyopaque) bool {
    return indexOfItems[@intCast(item)].func == f;
}
pub fn indexOfItemsParam(item: i16) u16 {
    return indexOfItems[@intCast(item)].param;
}
pub fn indexOfItemsStatus(item: i16) u16 {
    return indexOfItems[@intCast(item)].status;
}
pub fn addItemToBufferPtr() ?*const anyopaque {
    return @ptrCast(&addItemToBuffer);
}
pub fn indexOfItemsCatalogName(item: i16) [*c]const u8 {
    return &indexOfItems[@intCast(item)].itemCatalogName;
}
pub fn indexOfItemsSoftmenuName(item: i16) [*c]const u8 {
    return &indexOfItems[@intCast(item)].itemSoftmenuName;
}
pub extern var delayCloseNim: bool_t;
pub extern var userKeyLabel: [*c]u8;
pub extern fn isAlphabeticSoftmenu() bool_t;
pub extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;
pub extern fn setCurrentUserMenu(item: i16, func_param: [*c]u8) bool_t;
pub extern fn fnExitAllMenus(unused: u16) void;
pub extern fn showSoftmenuCurrentPart() void;
pub extern fn @"_executeItem"(item: i16, key_code: c_int) void;
pub extern fn showStringEdC47(lastline: u32, offset: i16, edcursor: i16, string: [*c]const u8, x: u32, y: u32, video_mode: c_int, show_leading: bool_t, show_ending: bool_t, noshow1: bool_t) u32;

// ---------------------------------------------------------------------------
// processKeyAction dependencies (keyboard.c 2336-3293).
// ---------------------------------------------------------------------------
pub const ITM_RCL: i16 = 51;
pub const ITM_PERIOD: i16 = 820;
pub const ITM_USERMODE: i16 = 1729;
pub const ITM_AIM: i16 = 1740;
pub const ITM_SNAP: i16 = 1405;
pub const ITM_UP_ARROW: i16 = 893;
pub const ITM_DOWN_ARROW: i16 = 895;
pub const ITM_EXPONENT: i16 = 990;
pub const ITM_UNDO: i16 = 1723;
pub const ITM_BST: i16 = 1734;
pub const ITM_SST: i16 = 1736;
pub const ITM_PR: i16 = 1724;
pub const ITM_RI: i16 = 1871;
pub const ITM_CHS: i16 = 97;
pub const ITM_XEQ: i16 = 3;
pub const ITM_OFF: i16 = 1543;
pub const ITM_SHIFTf: i16 = 1731;
pub const ITM_SHIFTg: i16 = 1732;
pub const ITM_STOP: i16 = 70;
pub const ITM_TIMER_R_S: i16 = 1786;
pub const ITM_TIMER_RCL: i16 = 1779;
pub const ITM_SIGMAPLUS: i16 = 433;
pub const ITM_ADD: i16 = 95;
// Lettered-register items (ITM_A=550 .. ITM_Z=575 already declared).
pub const ITM_D: i16 = 553;
pub const ITM_E: i16 = 554;
pub const ITM_F: i16 = 555;
pub const ITM_H: i16 = 557;
pub const ITM_I: i16 = 558;
pub const ITM_J: i16 = 559;
pub const ITM_K: i16 = 560;
pub const ITM_L: i16 = 561;
pub const ITM_M: i16 = 562;
pub const ITM_N: i16 = 563;
pub const ITM_O: i16 = 564;
pub const ITM_P: i16 = 565;
pub const ITM_S: i16 = 568;
pub const ITM_T: i16 = 569;
pub const ITM_U: i16 = 570;
pub const ITM_W: i16 = 572;
pub const ITM_X: i16 = 573;
pub const ITM_Y: i16 = 574;
pub const CHR_caseUP: i16 = 1878;
pub const CHR_caseDN: i16 = 1879;
pub const CHR_numL: i16 = 2030;
pub const CHR_numU: i16 = 2031;
pub const CHR_num: i16 = 2029;
pub const CHR_case: i16 = 1858;
pub const KEY_fg: i16 = 1893;
pub const NC_NORMAL: u8 = 0;
pub const FLAG_NUMLOCK: i32 = 32835;
pub const FLAG_TOPHEX: i32 = 32856;
pub const TI_COPY_FROM_SHOW: u8 = 94;
pub const TI_STORCL: u8 = 114;
pub const NP_INT_10: u8 = 1;
pub const NP_INT_16: u8 = 2;
pub const NP_REAL_FLOAT_PART: u8 = 4;
pub const REGISTER_Z: i16 = 102;
pub const REGISTER_T: i16 = 103;
pub const REGISTER_A: i16 = 104;
pub const REGISTER_L: i16 = 108;
pub const REGISTER_I: i16 = 109;
pub const REGISTER_M: i16 = 112;
pub const REGISTER_N: i16 = 113;
pub const REGISTER_P: i16 = 114;
pub const REGISTER_E: i16 = 118;
pub const REGISTER_O: i16 = 122;
pub const REGISTER_U: i16 = 123;
pub const FIRST_LABEL: i16 = 2200;
pub const ASSIGN_CLEAR: i16 = -32768;
pub const ASSIGN_LABELS: i16 = 12000;
pub const ASSIGN_NAMED_VARIABLES: i16 = 10000;
pub const ERROR_LABEL_NOT_FOUND: u8 = 6;
// allowShowDigits is a literal-false macro (defines.h:271).
pub const allowShowDigits: bool = false;

pub extern var tamBuffer: [*c]u8;
pub extern var showRegis: u16;
pub extern var showFunctionNameItem: i16;
pub extern var rbrRegister: i16;
pub extern var lastItem: i16;
pub extern var lastUserMode: bool_t;
pub extern var fnAsnDisplayUSER: bool_t;
pub extern var showContent: bool_t;
pub extern var lastIntegerBase: u32;
pub extern var hexDigits: u8;
pub extern var lastParam: i16;
pub extern var currentKeyCode: u8;
pub extern var keyStateCode: u8;
pub extern var lastshiftF: bool_t;

// lowercaseselected macro (keyboard.c:473).
pub fn lowercaseSelected() bool {
    return (alphaCase == AC_LOWER and !lastshiftF) or (alphaCase == AC_UPPER and lastshiftF);
}

pub const normKey_t = extern struct {
    func: i16,
    funcParam: [16]u8,
    used: bool_t,
};
pub extern var Norm_Key_00: normKey_t;

// Norm_Key_00_key macro (defines.h:554): key index of the blank/Norm key per model.
pub fn normKey00Key() i16 {
    return switch (calcModel) {
        USER_C47 => 0,
        USER_DM42 => 0,
        USER_R47f_g => -1,
        USER_R47bk_fg => 10,
        USER_R47fg_bk => 11,
        else => -1,
    };
}

// SHOWMODE macro (defines.h:2187).
pub fn showMode() bool {
    return calcMode == CM_NORMAL and
        (temporaryInformation == TI_SHOW_REGISTER or
            temporaryInformation == TI_SHOW_REGISTER_BIG or
            temporaryInformation == TI_SHOW_REGISTER_SMALL or
            temporaryInformation == TI_SHOW_REGISTER_TINY or
            temporaryInformation == TI_SHOWNOTHING);
}

pub extern fn fnC47Show(fn_show_param: u16) void;
pub extern fn fnFlipFlag(flag: u16) void;
pub extern fn assignGetName1() void;
pub extern fn assignGetName2() void;
pub extern fn assignEnterAlpha() void;
pub extern fn tamEnterMode(func: i16) void;
pub extern fn fnRecall(r: u16) void;
pub extern fn showStep() void;
pub extern fn fnOff(unused: u16) void;
pub extern fn addStepInProgram(func: i16) void;
pub extern fn findNamedLabel(label_name: [*c]const u8) i16;
pub extern fn stringGlyphLength(str: [*c]const u8) i32;
// stringByteLength is a macro: ((int32_t)strlen(str)) (charString.h:48).
pub fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
pub extern fn fnStartStopTimerApp(unused: u16) void;
pub extern fn fnDigitKeyTimerApp(digit: u16) void;
pub extern fn fnRegAddLapTimerApp(unused: u16) void;
pub extern fn fnAddTimerApp(unused: u16) void;
pub extern fn fnAddLapTimerApp(unused: u16) void;
// frmCalcMouseButton* / convertXYToKey dependencies (keyboard.c 1948-2009).
pub const ITM_SOLVE: i16 = 1608;
pub const calcKeyboard_t = extern struct {
    x: c_int,
    y: c_int,
    width: [4]c_int,
    height: [4]c_int,
    keyImage: [4]?*anyopaque,
};
pub extern var calcKeyboard: [43]calcKeyboard_t;
pub extern var currentBezel: c_int;

// btnFnReleased dependencies (keyboard.c 811-917).
pub const ITM_3: i16 = 543;
pub const ITM_4: i16 = 544;
pub const ITM_5: i16 = 545;
pub const ITM_6: i16 = 546;
pub const ITM_7: i16 = 547;
pub const ITM_8: i16 = 548;
pub extern fn btnFnReleased_StateMachine(unused: ?*anyopaque, data: ?*anyopaque) void;
pub extern fn displayShiftAndTamBuffer() void;

// btnFnPressed dependencies (keyboard.c 579-742).
pub extern var releaseOverride: bool_t;
pub extern var FN_key_pressed: i16;
pub extern fn updateAssignTamBuffer() void;
pub extern fn btnFnPressed_StateMachine(unused: ?*anyopaque, data: ?*anyopaque) void;

// btnReleased dependencies (keyboard.c 2032-2306).
pub const SCREENDUMP: i16 = 9875;
pub const PGM_RESUMING: u8 = 5;
pub const PGM_SINGLE_STEP: u8 = 6;
pub const ERROR_UNDEF_SOURCE_VAR: u8 = 36;
pub const ITM_GTO: i16 = 2;
pub const ITM_BASEMENU: i16 = 1334;
pub extern var JM_auto_longpress_enabled: i16;
pub extern var showFunctionNameArg: [*c]u8;
pub extern fn hideFunctionName() void;
pub extern fn insertUserItemInProgram(func: i16, func_param: [*c]u8) void;
pub extern fn runProgram(single_step: bool_t, menu_label: u16) void;
pub extern fn showingProbMenu() bool_t; // PROBMENU macro

// btnPressed dependencies (keyboard.c 1778-1943).
pub const PGM_KEY_PRESSED_WHILE_PAUSED: u8 = 4;
pub const ITM_DENMAX2: i16 = 2551;
pub const ITM_WSIZE: i16 = 1638;
pub const ITM_SETFDIGS: i16 = 2154;
pub extern var lastT_cursorPos: i16;
pub extern fn refreshStatusBar() void;
pub extern fn printTrace(func: i16, param: u16) void;

// executeFunction dependencies (keyboard.c 928-1430).
pub const VAR_LX: i16 = 1206;
pub const VAR_UX: i16 = 1205;
pub const MNU_GAP_R: i16 = 2153;
pub const MNU_GAP_L: i16 = 2151;
pub const MNU_GAP_RX: i16 = 2152;
pub const ITM_GAP_R: i16 = 2161;
pub const ITM_GAP_L: i16 = 2159;
pub const ITM_GAP_RX: i16 = 2160;
pub const MNU_Sfdx: i16 = 1381;
pub const ITM_INTEGRAL: i16 = 1700;
pub const TM_MENU: u16 = 10017;
pub const MNU_TAMINDIRECT: i16 = 2108;
pub const CATALOG_PROG: i16 = 7;
pub const TM_FLAGR: u16 = 10004;
pub const TM_FLAGW: u16 = 10005;
pub const ITM_DELP: i16 = 1425;
pub const ITM_INDIRECTION: i16 = 539;
pub const MNU_Solver: i16 = 1361;
pub const MNU_Grapher: i16 = 1388;
pub const MNU_Sf: i16 = 1380;
pub const MNU_1STDERIV: i16 = 1335;
pub const MNU_2NDDERIV: i16 = 1336;
pub const TM_VALUE: u16 = 10001;
pub const TM_VALUE_CHB: u16 = 10002;
pub const TM_STORCL: u16 = 10006;
pub const TM_LABEL: u16 = 10009;
pub const TM_LBLONLY: u16 = 10018;
pub const TM_SOLVE: u16 = 10010;
pub const TM_M_DIM: u16 = 10007;
pub const TM_REGISTER: u16 = 10003;
pub const TM_CMP: u16 = 10021;
pub const ITM_TAMMAX: i16 = 2110;
pub const ITM_YY_TRACK: i16 = 2237;
pub const ITM_YY_OFF: i16 = 1919;
pub const MNU_MODE: i16 = 1346;
pub const MNU_PREF: i16 = 2037;
pub const ITM_EQ_LEFT: i16 = 995;
pub const ITM_EQ_RIGHT: i16 = 996;
pub const EIM_STATUS: u16 = 256;
pub const EIM_ENABLED: u16 = 256;
pub const ITM_NUMBER_SIGN: i16 = 809;
pub const ITM_DMS2: i16 = 116;
pub const ITM_2BIN: i16 = 1831;
pub const ITM_2OCT: i16 = 1832;
pub const ITM_2DEC: i16 = 1833;
pub const ITM_2HEX: i16 = 1834;
pub const ITM_KEYMAP: i16 = 1958;
pub const ITM_SCR: i16 = 2191;
pub const JC_UC: u16 = 198;
pub const JC_NL: u16 = 197;
pub const ITM_YES: i16 = 2245;
pub const ITM_NO: i16 = 2246;
pub const SCRUPD_ONE_TIME_FLAGS: u8 = 240;
pub extern var hourGlassIconEnabled: bool_t;
pub extern var fnKeyInCatalog: bool_t;
pub extern fn isFunctionItemAMenu(item: i16) bool_t;
pub extern fn reallyRunFunction(func: i16, param: u16) void;
pub extern fn fnAim(unused: u16) void;
pub extern fn isFunctionOldParam16(func: u16) bool_t;
pub extern fn getItemFunc(item_nr: i16) ?*const anyopaque;
pub extern fn tamOperation() i16;
pub extern fn dynmenuGetLabel(menuitem: i16) [*c]u8;
pub extern fn isJMAlphaOnlySoftmenu() bool_t;
pub extern fn fnCFGsettings(unused: u16) void;
pub extern fn fnAlphaCursorLeft(unused: u16) void;
pub extern fn fnAlphaCursorRight(unused: u16) void;
pub extern fn SetSetting(jm_config: u16) void;
pub extern fn setLastintegerBasetoZero() void;
pub extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
pub extern fn fnConstant(constant: u16) void;
pub extern fn fnGetSystemFlag(system_flag: u16) void;

// closeAllCatalogMenus / _closeCatalog dependencies (keyboard.c 398-469).
pub const SOFTMENU_STACK_SIZE: usize = 8;
pub const MNU_ALPHAMISC: i16 = 1378;
pub const MNU_FCNS: i16 = 1330;
pub const MNU_CONST: i16 = 1322;
pub const MNU_CHARS: i16 = 1319;
pub const MNU_VARS: i16 = 1370;
pub const MNU_CATALOG: i16 = 1318;
pub const MNU_TAM: i16 = 1385;
pub const MNU_TAMVARONLY: i16 = 2225;
pub const MNU_TAMNONREG: i16 = 2068;
pub const MNU_TAMCMP: i16 = 1386;
pub const MNU_TAMFLAG: i16 = 1390;
pub const MNU_TAMSHUFFLE: i16 = 1391;
pub const MNU_TAMLABEL: i16 = 1393;
pub const MNU_TAMLBLONLY: i16 = 2226;
pub const ITM_DELITM: i16 = 1455;

// determineItem dependencies (keyboard.c 1511-1734).
pub const TO_FN_EXEC: u8 = 4;
pub const ITM_LBL: i16 = 1;
pub extern var gapItemRadix: u16;
pub extern fn fnTimerExec(nr: u8) void;
pub extern fn Check_Norm_Key_00_Assigned(result: [*c]i16, tempkey: i16) i16;
pub extern fn Setup_MultiPresses(result: i16) void;
pub extern fn Check_MultiPresses(result: [*c]i16, key_no: i8) void;
pub extern fn resetKeytimers() void;

// Norm_Key_00_item_in_layout macro (defines.h:556).
pub fn normKey00ItemInLayout() i16 {
    return switch (calcModel) {
        USER_C47 => ITM_SIGMAPLUS,
        USER_DM42 => ITM_SIGMAPLUS,
        USER_R47f_g => -1,
        USER_R47bk_fg => ITM_NULL,
        USER_R47fg_bk => ITM_NULL,
        else => -1,
    };
}
// RADIX34_MARK_* macros (defines.h 2195-2196): gapChar1Radix preserves Rx[0] /
// Rx[1], so map comma + wide-comma ("\xa7\x88") to ',' else '.'.
pub fn radix34MarkChar() u8 {
    const rx = indexOfItemsSoftmenuName(@intCast(gapItemRadix));
    return if (rx[0] == ',' or (rx[0] == 0xa7 and rx[1] == 0x88)) ',' else '.';
}
pub fn radix34MarkDecItm() i16 {
    return if (radix34MarkChar() == '.') ITM_PERIOD else ITM_COMMA;
}
pub fn radix34MarkNotDecItm() i16 {
    return if (radix34MarkChar() == '.') ITM_COMMA else ITM_PERIOD;
}

pub extern var FN_timeouts_in_progress: bool_t;

// btnFnPressed/Released_StateMachine deps (keyboardTweak.c 729-957).
pub const ST_1_PRESS1: u8 = 1;
pub const ST_2_REL1: u8 = 2;
pub const ST_3_PRESS2: u8 = 3;
pub const ST_4_REL2: u8 = 4;
pub const TIME_FN_12XX_TO_F: u32 = 476;
pub const TIME_FN_DOUBLE_G_TO_NOP: u32 = 448;
pub const TIME_FN_DOUBLE_RELEASE: u32 = 150;
pub const FLAG_G_DOUBLETAP: i32 = 32861;
pub const DEBUGSFN: bool = true; // defines.h:305 (#define DEBUGSFN true)
pub extern var FN_state: u8;
pub extern var FN_key_pressed_last: i16;
pub extern var FN_handle_timed_out_to_EXEC: bool_t;
pub extern var FN_timed_out_to_RELEASE_EXEC: bool_t;
pub extern fn underline_softkey(x_softkey_mask: u16, y_softkey: u16) void;
// BLOCK_DOUBLEPRESS_MENU macro (defines.h:2262).
pub fn blockDoublepressMenu(menu_id: i16, x: i16, y: i16) bool {
    return (menu_id == -MNU_ALPHA and y == 0 and (x == 4 or x == 5)) or
        (menu_id == -MNU_M_EDIT and y == 0 and (x == 4 or x == 5)) or
        (menu_id == -MNU_EQ_EDIT and y == 0 and (x == 4 or x == 5)) or
        (menu_id == -MNU_TAMALPHA and y == 0 and (x == 4 or x == 5));
}

// Check_MultiPresses dependencies (keyboardTweak.c 351-639).
pub const RBX_M1234: u8 = 226;
pub const RBX_M124: u8 = 225;
pub const RBX_M14: u8 = 224;
pub const ITM_DRG: i16 = 1873;
pub const ITM_CLSTK: i16 = 1428;
pub const ITM_EDIT: i16 = 2404;
pub const ITM_CLRMOD: i16 = 2005;
pub const ITM_CLN: i16 = 1875;
pub const ITM_CLA: i16 = 1874;
pub const ITM_XEDIT: i16 = 2420;
pub const ITM_CR: i16 = 1172;
pub const JM_TO_CL_LONG: u32 = 800;
pub const FUNCTION_NOPTIME: i16 = 800;
pub const TM_INTEGRATE: u16 = 10013;
pub extern var LongPressM: u8;
pub extern var longpressDelayedkey2: i16;
pub extern var longpressDelayedkey3: i16;
// LongpressEXIT1 macro (keyboardTweak.c:344).
pub fn longpressExit1() i16 {
    if (calcModel == USER_C47) {
        return if (calcMode == CM_AIM) -MNU_MyAlpha else ITM_BASEMENU;
    }
    return ITM_SNAP;
}

// fg_processing_jm / Check_Norm_Key_00_Assigned / Setup_MultiPresses deps
// (keyboardTweak.c 266-341).
pub const TMR_RUNNING: u8 = 2;
pub const TMR_STOPPED: u8 = 1;
pub const JM_TO_3S_CTFF: u32 = 600;
pub const TO_CL_DROP: u8 = 6;
pub const JM_CLRDROP_TIMER: u32 = 500;
pub extern var JM_SHIFT_HOME_TIMER1: u8;
pub extern var JM_auto_doublepress_autodrop_enabled: i16;
pub extern fn fnTimerGetStatus(nr: u8) u8;
// isR47FAM macro (defines.h:557).
pub fn isR47FAM() bool {
    return calcModel == USER_R47f_g or calcModel == USER_R47bk_fg or calcModel == USER_R47fg_bk or calcModel == USER_R47fg_g;
}

// commonShiftProcessing dependencies (keyboard.c 1437-1507).
pub const JM_TO_FG_LONG: u32 = 580;
pub const JM_SHIFT_TIMER: u32 = 4000;
pub const FLAG_SHFT_4s: i32 = 32865;
pub const FLAG_SH_LONGPRESS: i32 = 32830;
pub const MNU_SHOW: i16 = 2315;
pub extern var Shft_LongPress_f_g: bool_t;
pub extern var Shft_timeouts: bool_t;
pub extern var shiftKeyClearsError: bool_t;
pub extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
pub extern fn fg_processing_jm() void;
// keyboardTweak.c owners exported from keyboard_state.zig; reach their C names.
pub extern fn showShiftState() void;
pub extern fn refreshModeGui() void;

// determineFunctionKeyItem_C47 dependencies (keyboard.c 12-333).
pub const MNU_PROG: i16 = 1392;
pub const MNU_VAR: i16 = 1389;
pub const MNU_CONFIGS: i16 = 2231;
pub const MNU_MATRS: i16 = 1343;
pub const MNU_DATES: i16 = 1325;
pub const MNU_TIMES: i16 = 1366;
pub const MNU_SINTS: i16 = 1332;
pub const MNU_STRINGS: i16 = 1364;
pub const MNU_NUMBRS: i16 = 2230;
pub const MNU_CPXS: i16 = 1324;
pub const MNU_REALS: i16 = 1360;
pub const MNU_ANGLES: i16 = 1314;
pub const MNU_LINTS: i16 = 1338;
pub const MNU_ALLVARS: i16 = 2232;
pub const MNU_PROGS: i16 = 1355;
pub const MNU_MENU: i16 = 2407;
pub const MNU_MENUS: i16 = 1345;
pub const ITM_GTOP: i16 = 1482;
pub const ITM_SOLVE_VAR: i16 = 994;
pub const ITM_DRAW: i16 = 2372;
pub const ITM_CALC: i16 = 1767;
pub const MNU_Solver_TOOL: i16 = 2376;
pub const ITM_FPHERE: i16 = 2377;
pub const ITM_FPPHERE: i16 = 2378;
pub const MNU_Sf_TOOL: i16 = 2375;
pub const ITM_INTEGRAL_YX: i16 = 1690;
pub const ITM_Sfdx_VAR: i16 = 1002;
pub const ITM_PROD_SIGN: i16 = 9999;
pub const ITM_DOT: i16 = 849;
pub const ITM_CROSS: i16 = 855;
pub const ITM_ASSIGN: i16 = 1411;
pub const TM_DELITM: u16 = 10014;
pub const ASSIGN_USER_MENU: i16 = -10000;
pub const FLAG_MULTx: i32 = 32795;
pub const CMP_NAME: i32 = 3;
pub const SOLVER_STATUS_USES_FORMULA: u16 = 256;
pub const SOLVER_STATUS_EQUATION_GRAPHER: u16 = 8192;
pub const SOLVER_STATUS_EQUATION_SOLVER: u16 = 0;
pub const SOLVER_STATUS_EQUATION_1ST_DERIVATIVE: u16 = 8;
pub const SOLVER_STATUS_EQUATION_2ND_DERIVATIVE: u16 = 12;

pub const userMenuItem_t = extern struct {
    item: i16,
    unused: i16,
    argumentName: [16]u8,
};
pub const userMenu_t = extern struct {
    menuName: [16]u8,
    menuItem: [18]userMenuItem_t,
};
pub const dynamicSoftmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    menuContent: [*c]u8,
};
pub extern var userMenuItems: [18]userMenuItem_t;
pub extern var userAlphaItems: [18]userMenuItem_t;
pub const dynamicSoftmenu = @extern([*c]dynamicSoftmenu_t, .{ .name = "dynamicSoftmenu" });
pub extern var userMenus: [*c]userMenu_t;
pub extern var currentUserMenu: u16;
pub extern var currentMvarLabel: u16;
pub extern var numberOfUserMenus: u16;
pub extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparison_type: i32) i32;

// IS_BASEBLANK_ / IS_EQN_* macros (defines.h 2276 / 2079-2086).
pub fn isBaseBlank(menu_id: i16) bool {
    return menu_id == 0 and !getSystemFlag(FLAG_BASE_MYM) and !getSystemFlag(FLAG_BASE_HOME);
}
pub fn isEqnIntegrate() bool {
    return (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE and
        (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0;
}
pub fn isEqn1stDer() bool {
    return (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0 and
        (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0 and
        (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE;
}
pub fn isEqn2ndDer() bool {
    return (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0 and
        (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) != 0 and
        (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE;
}

// execFnTimeout dependencies (keyboardTweak.c 960-972). btnFnClicked is
// (GtkWidget*, gpointer) on host and (void*, void*) on dmcp -- both two
// pointers, so a single ?*anyopaque signature matches each lane's ABI.
pub extern var FN_timed_out_to_NOP_or_Executed: bool_t;
pub extern fn btnFnClicked(not_used: ?*anyopaque, data: ?*anyopaque) void;

// leavePem dependencies (keyboard.c 2309-2334). Host owner: RAM_SIZE_IN_BLOCKS
// is the !DMCP_BUILD (NEW_HW) value (defines.h:1988).
pub const RAM_SIZE_IN_BLOCKS: u32 = 65534;
pub extern var freeProgramBytes: u16;
pub extern var beginOfProgramMemory: [*c]u8;
pub extern var firstDisplayedStep: [*c]u8;
pub extern var beginOfCurrentProgram: [*c]u8;
pub extern var endOfCurrentProgram: [*c]u8;
pub extern var currentProgramNumber: u16;
pub extern var firstDisplayedLocalStepNumber: u16;
pub const programList_t = extern struct {
    step: i32,
    instructionPointer: [*c]u8,
};
pub extern var programList: [*c]programList_t;
pub extern fn resizeProgramMemory(new_size_in_blocks: u16) void;
pub extern fn scanLabelsAndPrograms() void;
pub extern fn defineFirstDisplayedStep() void;
pub extern fn defineCurrentProgramFromCurrentStep() void;

// processAimInput dependencies (keyboard.c 475-568).
pub const ITM_COLON: i16 = 822;
pub const ITM_COMMA: i16 = 818;
pub const ITM_QUESTION_MARK: i16 = 827;
pub const ITM_UNDERSCORE: i16 = 833;
pub const NC_SUBSCRIPT: u8 = 1;
pub const NC_SUPERSCRIPT: u8 = 2;
pub extern var lastshiftG: bool_t;

// resetShiftState / showAlphaModeonGui are the keyboardTweak.c owners exported
// from keyboard_state.zig; reach them as their canonical C symbols.
pub extern fn resetShiftState() void;
pub extern fn showAlphaModeonGui() void;

// DMCP-only firmware key-buffer / refresh ops. Referenced only inside the
// is_dmcp_build branches of host-exported (PC_BUILD-only) owners, so on the
// dmcp lane the referencing code is dead-stripped before link — same pattern
// as lcd_fill_rect above.
pub extern fn lcd_refresh() void;
pub extern fn key_pop() c_int;
pub extern fn key_push(k1: c_int) c_int;
pub extern fn wait_for_key_release(tout: c_int) void;

const legacy_host = struct {
    extern fn @"z47_keyboard_state_btnPressed"(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
    extern fn @"z47_keyboard_state_btnClicked"(not_used: ?*anyopaque, data: ?*anyopaque) void;
};

const legacy_dmcp = struct {
    extern fn @"z47_keyboard_state_btnPressed"(data: ?*anyopaque) void;
};
