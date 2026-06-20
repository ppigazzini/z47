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
const PGM_PAUSED: u8 = 3;

pub const SCRUPD_MANUAL_STACK: u8 = 0x02;
pub const SCRUPD_MANUAL_MENU: u8 = 0x04;
pub const SCRUPD_SKIP_STACK_ONE_TIME: u8 = 0x20;
pub const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;
pub const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;

pub const FLAG_INTING: i32 = 0xc025;
pub const FLAG_SOLVING: i32 = 0xc026;
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
const TI_SHOW_REGISTER_BIG: u8 = 75;
const TI_SHOW_REGISTER_SMALL: u8 = 76;
const TI_SHOW_REGISTER_TINY: u8 = 77;
const TI_SHOWNOTHING: u8 = 93;
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
// Trampoline to the static keyboard.c _assignToMenu (see keyboard_state_legacy.c).
extern fn z47_keyboard_state_assignToMenu(data: [*c]u8) bool_t;
pub fn assignToMenu(data: [*c]u8) void {
    _ = z47_keyboard_state_assignToMenu(data);
}
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
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
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
// menuUp / menuDown are static in keyboard.c — trampoline via the legacy bridge.
extern fn z47_keyboard_state_menuUp() void;
extern fn z47_keyboard_state_menuDown() void;
pub fn menuUp() void {
    z47_keyboard_state_menuUp();
}
pub fn menuDown() void {
    z47_keyboard_state_menuDown();
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
pub extern fn leavePem() void;
pub extern fn fnLeaveTimerApp() void;
pub extern fn fnRefreshState() void;
pub extern fn fnItemTimerApp(unused: u16) void;
pub extern fn fnClDrawMx(origin: u8) void;
pub extern fn printStatus(row: u8, line1: [*c]const u8, forced: u8) void;
pub extern fn restoreStats() void;
pub extern fn forceSBupdate() void;
pub extern fn isAlphaSubmenu(n: u8) bool_t;
pub extern fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void;
// jm_show_calc_state is an empty no-op unless PC_BUILD_TELLTALE; kept for fidelity.
pub extern fn jm_show_calc_state(comment: [*c]const u8) void;
// stayInAIM is static in keyboard.c — trampoline via the legacy bridge.
extern fn z47_keyboard_state_stayInAIM() void;
pub fn stayInAIM() void {
    z47_keyboard_state_stayInAIM();
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
pub extern fn showStringEdC47(lastline: u32, offset: i16, edcursor: i16, string: [*c]const u8, x: u32, y: u32, video_mode: c_int, show_leading: bool_t, show_ending: bool_t, noshow1: bool_t) u32;

const legacy_host = struct {
    extern fn @"z47_keyboard_state_btnPressed"(not_used: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) void;
    extern fn @"z47_keyboard_state_btnClicked"(not_used: ?*anyopaque, data: ?*anyopaque) void;
};

const legacy_dmcp = struct {
    extern fn @"z47_keyboard_state_btnPressed"(data: ?*anyopaque) void;
};
