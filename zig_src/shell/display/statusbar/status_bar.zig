// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/statusBar.c: the status-bar renderer. Faithful,
// line-by-line port. forceSBupdate / timeChanged / showDateTime / showFracMode /
// showHideAlphaMode / showHideHourGlass / light_ASB_icon / kill_ASB_icon /
// drawBattery / refreshStatusBar are public and shared by both builds; the
// file-static helpers (showRealComplexResult, showComplexMode, showAngularMode,
// showBaseMode, showStringAndClear, showMatrixMode, showTvmMode, showIntegerMode,
// showOverflowCarry, clearINT_MX_TVM_MODE, showStackSize, showHideWatch,
// showHideSerialIO, showHidePrinter, showHideUserMode) are private. The
// SBlastIntegerBaseShown / SBAlphaModeLastShown / SBhourglassShown / alphaOutput /
// reInstateIntegerModeDisplay / reInstateOCModeDisplay file globals live here.
//
// showHideUsbLowBattery is firmware-only (#if DMCP_BUILD); showHideStackLift and
// mockupSB are host-only (#if !DMCP_BUILD / #if PC_BUILD). The DEBUG_INSTEAD_STATUS_BAR
// (==0) and ANALYSE_REFRESH / BATTERYTEST (#undef'd) branches are dead and omitted.
// On firmware the DMCP-ROM screen calls (lcd_fill_rect, bitblt24 behind
// setBlackPixel/setWhitePixel, get_vbat) are fixed-address jump-table calls
// (LIBRARY_FN_BASE + verified offset); on host they are real GTK-layer symbols.
//
// statusBar.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const std = @import("std");
const status_bar_geometry = @import("status_bar_geometry.zig"); // std-only status-bar geometry
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const angularMode_t = c_int;
const videoMode_t = c_int;
const font_t = abi.Font;
const abi = @import("abi"); // L1 shared bindings
const frontier_date_time = @import("../../convert/date_time.zig"); // M-callconv: Zig-to-Zig
const frontier_plotstat = @import("../../plot/plotstat.zig"); // M-callconv: Zig-to-Zig
const frontier_screen = @import("../screen.zig"); // M-callconv: Zig-to-Zig
const frontier_timer = @import("../../timer.zig"); // M-callconv: Zig-to-Zig
const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;

// ---------------------------------------------------------------------------
// Constants (defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const SOFTMENU_STACK_SIZE: usize = 8;

const vmNormal: videoMode_t = 0;
const vmReverse: videoMode_t = 1;
const LCD_SET_VALUE: c_int = 0;
const LCD_EMPTY_VALUE: c_int = 255;
const SCREEN_WIDTH: i16 = 400;

const force: u8 = 1;
const timed: u8 = 0;

// X positions
const X_TIME: i32 = 45;
const X_REAL_COMPLEX: i32 = 136;
const X_COMPLEX_MODE: i32 = 146;
const X_COMPLEX_MODE_ADJ: i32 = -8;
const X_ANGULAR_MODE: i32 = 160;
const X_FRAC_MODE: i32 = 187;
const X_BASE_MODE: i32 = 187;
const X_INT_MX_TVM_MODE: i32 = 264;
const X_OVERFLOW_CARRY: i32 = 294;
const X_ALPHA_MODE: i32 = 304;
const X_HOURGLASS: i32 = 315;
const X_HOURGLASS_GRAPHS: i32 = 140;
const X_SSIZE_BEGIN: i32 = 329;
const X_ASM: i32 = 340;
const X_SERIAL_IO: i32 = 362;
const X_PRINTER: i32 = 362;
const X_USER_MODE: i32 = 376;
const X_BATTERY: i32 = 389;
const X_STOPWATCH: i32 = 344;
const X_SHIFT_L: i32 = 0;
const X_SHIFT_R: i32 = X_PRINTER - 1; // 361
const Y_POSITION_OF_REGISTER_T_LINE: i32 = 24;
const Y_SHIFT_LO: i32 = Y_POSITION_OF_REGISTER_T_LINE;
const DX_BATTERY: i32 = 8;
const DY_BATTERY: i32 = 20;
const MAX_DENMAX: u32 = 9999;

// calc modes
const CM_REGISTER_BROWSER: u8 = 5;
const CM_FLAG_BROWSER: u8 = 6;
const CM_ASN_BROWSER: u8 = 17;
const CM_FONT_BROWSER: u8 = 7;
const CM_PLOT_STAT: u8 = 8;
const CM_CONFIRMATION: u8 = 11;
const CM_MIM: u8 = 12;
const CM_TIMER: u8 = 14;
const CM_GRAPH: u8 = 15;
const CM_PEM: u8 = 3;
const CM_EIM: u8 = 13;

// program run state
const PGM_RUNNING: u8 = 1;
const PGM_WAITING: u8 = 2;

// timer
const TMR_RUNNING: u8 = 2;
const TO_ASM_ACTIVE: u8 = 9;
const TIMER_APP_STOPPED: u32 = 0xFFFFFFFF;

// settings flags (didSystemFlagChange / get / set)
const SETTING_WATCHICON: i32 = 132;
const SETTING_SINT_WS: i32 = 130;
const SETTING_SINT_MODE: i32 = 131;
const SETTING_AMODE: i32 = 128;
const SETTING_DMX: i32 = 129;
const SETTING_SIOICON: i32 = 133;
const SETTING_PRINTERICON: i32 = 134;

// system flags
const FLAG_POLAR: i32 = 32774;
const FLAG_TOPHEX: i32 = 32856;
const FLAG_FRACT: i32 = 32775;
const FLAG_IRFRAC: i32 = 32839;
const FLAG_PROPFR: i32 = 32776;
const FLAG_DENFIX: i32 = 32778;
const FLAG_DENANY: i32 = 32777;
const FLAG_OVERFLOW: i32 = 32780;
const FLAG_CARRY: i32 = 32779;
const FLAG_SSIZE8: i32 = 32792;
const FLAG_ERPN: i32 = 32837;
const FLAG_USB: i32 = 49192;
const FLAG_LOWBAT: i32 = 49173;
const FLAG_TDM24: i32 = 32768;
const FLAG_alphaCAP: u32 = 49167;
const FLAG_NUMLOCK: i32 = 32835;
const FLAG_MULTx: i32 = 32795;
const FLAG_ASLIFT: i32 = 49187;
const FLAG_GROW: i32 = 32797;
const FLAG_CPXRES_REAL: i32 = 32772;
const FLAG_USER: i32 = 32788;
const FLAG_ENDPMT: i32 = 49193;

// status-bar update flags (defines.h)
const FLAG_SBdate: i32 = 0x802C;
const FLAG_SBtime: i32 = 0x802D;
const FLAG_SBwoy: i32 = 0x8057;
const FLAG_SBcr: i32 = 0x802E;
const FLAG_SBcpx: i32 = 0x802F;
const FLAG_SBang: i32 = 0x8030;
const FLAG_SBfrac: i32 = 0x8031;
const FLAG_SBint: i32 = 0x8032;
const FLAG_SBmx: i32 = 0x8033;
const FLAG_SBtvm: i32 = 0x8034;
const FLAG_SBoc: i32 = 0x8035;
const FLAG_SBss: i32 = 0x8036;
const FLAG_SBstpw: i32 = 0x8037;
const FLAG_SBser: i32 = 0x8038;
const FLAG_SBprn: i32 = 0x8039;
const FLAG_SBbatV: i32 = 0x803A;
const FLAG_SBshfR: i32 = 0x803B;

// angular modes
const amRadian: angularMode_t = 0;
const amMultPi: angularMode_t = 4;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;

// char modes
const NC_NORMAL: u8 = 0;
const NC_SUBSCRIPT: u8 = 1;
const NC_SUPERSCRIPT: u8 = 2;
const AC_UPPER: u8 = 0;
const AC_LOWER: u8 = 1;

// short integer modes
const SIM_1COMPL: u8 = 1;
const SIM_2COMPL: u8 = 2;
const SIM_UNSIGN: u8 = 0;
const SIM_SIGNMT: u8 = 3;

// screen update mode
const SCRUPD_MANUAL_STATUSBAR: u8 = 1;

// catalog
const CATALOG_MVAR: i16 = 18;

// menu IDs used by showTvmMode.
const MNU_TVM_v: i16 = 1368;
const MNU_FIN_v: i16 = 1331;
const MNU_AMORT_v: i16 = 2382;

// STD_* byte sequences (fonts.h).
const STD_SPACE_3_PER_EM = "\xa0\x04";
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_SUB_A = "\xa4\xd0";
const STD_SUB_MINUS = "\xa0\x8b";
const STD_SUB_F = "\xa4\xd5";
const STD_SUB_b = "\xa4\x9d";
const STD_SUB_f = "\xa4\xa1";
const STD_COMPLEX_C = "\xa1\x02";
const STD_REAL_R = "\xa1\x1d";
const STD_SUN = "\xa2\x99";
const STD_RIGHT_ANGLE = "\xa2\x1f";
const STD_MEASURED_ANGLE = "\xa2\x21";
const STD_SUP_BOLD_r = "\x82\xb3";
const STD_SUP_pir = "\xac\x66";
const STD_SUP_BOLD_g = "\x9d\x4d";
const STD_DEGREE = "\x80\xb0";
const STD_RIGHT_DOUBLE_QUOTE = "\xa0\x1d";
const STD_QUESTION_MARK = "\x3f";
const STD_IRRATIONAL_I = "\xa1\x10";
const STD_ALMOST_EQUAL = "\xa2\x48";
const STD_OVERFLOW_CARRY = "\x80\xa9";
const STD_SPACE_6_PER_EM = "\xa0\x06";
const STD_8 = "\x38";
const STD_4 = "\x34";
const STD_TIMER = "\xa3\xf1";
const STD_SERIAL_IO = "\xa1\x95";
const STD_PRINTER = "\xa3\x99";
const STD_USER_MODE = "\xa4\x2c";
const STD_USB_SYMBOL = "\xa4\x34";
const STD_BATTERY = "\xa4\x2a";
const STD_NEG_EXCLAMATION_MARK = "\xa4\x2f";
const STD_SPACE_HAIR = "\xa0\x0a";
const STD_P = "\x50";
const STD_HOURGLASS_WH = "\xa9\xd6";
const STD_CROSS = "\x80\xd7";
const STD_DOT = "\x80\xb7";

// ---------------------------------------------------------------------------
// Globals (extern var/const)
// ---------------------------------------------------------------------------
extern var calcMode: u8;
extern var programRunStop: u8;
extern var screenUpdatingMode: u8;
extern var lastIntegerBase: u32;
extern var denMax: u32;
extern var fractionDigits: u8;
extern var shortIntegerWordSize: u8;
extern var shortIntegerMode: u8;
extern var currentAngularMode: angularMode_t;
extern var nextChar: u8;
extern var scrLock: u8;
extern var alphaCase: u8;
extern var shiftF: bool_t;
extern var shiftG: bool_t;
extern var catalog: i16;
extern var hourGlassIconEnabled: bool_t;
extern var watchIconEnabled: bool_t;
extern var serialIOIconEnabled: bool_t;
extern var printerIconEnabled: bool_t;
extern var timerStartTime: u32;
extern var raiseString: u8;
extern var compressString: u8;
extern var oldTime: [8]u8;
extern var dateTimeString: [12]u8;
extern var exponentLimit: i16;
extern var vbatVIntegrated: c_int;
// deadKey is a PC_BUILD-only global (referenced only under !dmcp_build).
extern var deadKey: u32;

extern var asmBuffer: [5]u8;
// `softmenu` is a C ARRAY (const softmenu_t softmenu[]), so the symbol address
// IS the data. @extern binds that address; a plain `extern const ...: [*c]...`
// would instead load the array's first bytes as a pointer value (-> SEGV).
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t;
extern const standardFont: font_t;

// tam state (statusBar reads tam.mode / tam.alpha).
const tamState_t = abi.TamState;
extern var tam: tamState_t;

// CATALOG_MVAR pointer comparison uses `catalog` which is i16.

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------
extern fn getSystemFlag(sf: i32) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn didSystemFlagChange(sf: i32) bool_t;
extern fn setSystemFlagChanged(sf: i32) void;
extern fn setAllSystemFlagChanged() void;

extern fn showShiftState() void;
extern fn refreshModeGui() void;

// libc.
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;

// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (fixed-address on firmware; verified in lft_ifc.h).
// lcd_fill_rect: LIBRARY_FN_BASE+60 (lft_ifc.h:61)
// bitblt24:      LIBRARY_FN_BASE+36 (lft_ifc.h:55)
// get_vbat:      LIBRARY_FN_BASE+240 (lft_ifc.h:106)
// On host these are real symbols (GTK / screen layer).
// ---------------------------------------------------------------------------
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}

const Bitblt24Fn = *const fn (x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void;
const c_bitblt24 = @extern(Bitblt24Fn, .{ .name = "bitblt24" });
inline fn bitblt24(x: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) void {
    if (comptime dmcp_build) {
        const f: Bitblt24Fn = @ptrFromInt(LIBRARY_FN_BASE + 36);
        f(x, dx, y, val, blt_op, fill);
    } else {
        c_bitblt24(x, dx, y, val, blt_op, fill);
    }
}
const BLT_OR: c_int = 0;
const BLT_ANDN: c_int = 1;
const BLT_NONE: c_int = 0;
inline fn setBlackPixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_OR, BLT_NONE);
}
inline fn setWhitePixel(x: u32, y: u32) void {
    bitblt24(x, 1, y, 1, BLT_ANDN, BLT_NONE);
}

// get_vbat is firmware-only (only referenced under dmcp_build).
inline fn get_vbat() c_int {
    const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 240);
    return f();
}

// ---------------------------------------------------------------------------
// max/min helpers (C macros).
// ---------------------------------------------------------------------------
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
inline fn minI(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}

// SBARUPD_* macro helpers.
inline fn sbDate() bool {
    return getSystemFlag(FLAG_SBdate);
}
inline fn sbTime() bool {
    return getSystemFlag(FLAG_SBtime);
}
inline fn sbWoY() bool {
    return getSystemFlag(FLAG_SBwoy);
}
inline fn sbComplexResult() bool {
    return getSystemFlag(FLAG_SBcr);
}
inline fn sbComplexMode() bool {
    return getSystemFlag(FLAG_SBcpx);
}
inline fn sbAngularModeBasic() bool {
    return getSystemFlag(FLAG_SBang);
}
inline fn sbFractionModeAndBaseMode() bool {
    return getSystemFlag(FLAG_SBfrac);
}
inline fn sbIntegerMode() bool {
    return getSystemFlag(FLAG_SBint);
}
inline fn sbMatrixMode() bool {
    return getSystemFlag(FLAG_SBmx);
}
inline fn sbTVMMode() bool {
    return getSystemFlag(FLAG_SBtvm);
}
inline fn sbOCCarryMode() bool {
    return getSystemFlag(FLAG_SBoc);
}
inline fn sbStackSize() bool {
    return getSystemFlag(FLAG_SBss);
}
inline fn sbStopWatch() bool {
    return getSystemFlag(FLAG_SBstpw);
}
inline fn sbSerialIO() bool {
    return getSystemFlag(FLAG_SBser);
}
inline fn sbPrinter() bool {
    return getSystemFlag(FLAG_SBprn);
}
inline fn sbBatVoltage() bool {
    return getSystemFlag(FLAG_SBbatV);
}
inline fn sbarShift() bool {
    return getSystemFlag(FLAG_SBshfR);
}
inline fn graphMode() bool {
    return calcMode == CM_PLOT_STAT or calcMode == CM_GRAPH;
}
// plainTextMode / labelText macros (defines.h).
const CM_AIM: u8 = 1;
const CM_ASSIGN: u8 = 4;
const FLAG_ALPHA_SB: i32 = 32782;
const TM_MENU: u16 = 10017;
const TM_LABEL: u16 = 10009;
const TM_LBLONLY: u16 = 10018;
const TM_SOLVE: u16 = 10010;
const TM_STORCL: u16 = 10006;
inline fn plainTextMode() bool {
    return calcMode == CM_AIM or ((calcMode == CM_PEM or calcMode == CM_ASSIGN) and getSystemFlag(FLAG_ALPHA_SB));
}
inline fn labelText() bool {
    return (tam.mode == TM_MENU or tam.mode == TM_LABEL or tam.mode == TM_LBLONLY or tam.mode == TM_SOLVE or tam.mode == TM_STORCL or tam.alpha) and getSystemFlag(FLAG_ALPHA_SB);
}
// X_DATE = (SBARUPD_Time || SBARUPD_WoY) ? 1 : 25
inline fn xDate() i32 {
    return status_bar_geometry.xDate(sbTime(), sbWoY());
}
// X_SHIFT
inline fn xShift() i32 {
    return status_bar_geometry.xShift(getSystemFlag(FLAG_SBshfR), X_SHIFT_R, X_SHIFT_L);
}
// Y_SHIFT
inline fn yShift() i32 {
    return status_bar_geometry.yShift(sbDate(), sbTime(), sbWoY(), sbarShift(), Y_SHIFT_LO);
}
// lowerUnderLine
inline fn lowerUnderLine() i32 {
    return status_bar_geometry.lowerUnderLine(calcMode == CM_REGISTER_BROWSER or calcMode == CM_FLAG_BROWSER);
}

// ---------------------------------------------------------------------------
// File globals defined by statusBar.c
// ---------------------------------------------------------------------------
pub export var SBlastIntegerBaseShown: u8 = 0xFF;
pub export var SBAlphaModeLastShown: u16 = 0xFFFF;
pub export var SBhourglassShown: [2]u8 = undefined;
pub export var alphaOutput: [3]u8 = undefined;
// C file-scope .bss globals -> zero-initialized (false). `= undefined` left a
// garbage bool that could read true before the first write.
pub export var reInstateIntegerModeDisplay: bool_t = false;
pub export var reInstateOCModeDisplay: bool_t = false;

// ===========================================================================
// forceSBupdate
// ===========================================================================
pub export fn forceSBupdate() callconv(.c) void {
    setAllSystemFlagChanged();
    SBlastIntegerBaseShown = 0xFF;
    SBAlphaModeLastShown = 0xFFFF;
    SBhourglassShown[0] = 0xFF;
    SBhourglassShown[1] = 0xFF;
    oldTime[0] = 0;
    alphaOutput[0] = 0xFF;
    alphaOutput[1] = 0xFF;
    alphaOutput[2] = 0;
    reInstateIntegerModeDisplay = false;
    reInstateOCModeDisplay = false;
}

// ===========================================================================
// timeChanged
// ===========================================================================
pub export fn timeChanged() callconv(.c) bool_t {
    var timeString: [8]u8 = undefined;
    frontier_date_time.getTimeString(&timeString);
    if (strcmp(&timeString, &oldTime) != 0 or oldTime[0] == 0) {
        _ = strcpy(&oldTime, &timeString);
        return true; // timeHasChanged
    } else {
        return false; // !timeHasChanged
    }
}

// ===========================================================================
// showDateTime
// ===========================================================================
pub export fn showDateTime() callconv(.c) bool_t {
    if (timeChanged() == false) { // == !timeHasChanged
        return false;
    }
    if (programRunStop == PGM_RUNNING) {
        return false;
    }

    if (!(sbDate() or sbTime() or sbWoY())) {
        return false;
    }

    var x: u32 = @intCast(xDate());
    lcd_fill_rect(0, 0, x - 0, 20, LCD_SET_VALUE);

    if (sbDate() or sbWoY()) {
        frontier_date_time.getDateString(&dateTimeString);
    }

    if (dateTimeString[0] >= '0' and dateTimeString[0] <= '9') {
        if (sbDate()) {
            x = frontier_screen.showString(&dateTimeString, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(true));
        } else {
            lcd_fill_rect(x, 0, @intCast(X_TIME - @as(i32, @intCast(x))), 20, LCD_SET_VALUE);
            x = @intCast(X_TIME);
        }
        if (sbTime()) {
            x = frontier_screen.showGlyph(if (getSystemFlag(FLAG_TDM24)) " " else STD_SPACE_3_PER_EM, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(true), @intFromBool(false));
            x = frontier_screen.showString(&oldTime, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false));
        }
        if (sbWoY()) {
            x = frontier_screen.showGlyph(STD_SPACE_3_PER_EM, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(true), @intFromBool(false));
            frontier_date_time.getWeekOfYearString(&dateTimeString);
            x = frontier_screen.showString(&dateTimeString, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false));
        }
    }

    lcd_fill_rect(x, 0, @intCast(X_REAL_COMPLEX - @as(i32, @intCast(x))), 20, LCD_SET_VALUE);

    if (yShift() == 0 and xShift() < 200) {
        showShiftState();
    }
    return true;
}

// ===========================================================================
// showRealComplexResult (static)
// ===========================================================================
fn showRealComplexResult() void {
    if (!sbComplexResult()) {
        return;
    }
    var x: i32 = X_REAL_COMPLEX;
    if (didSystemFlagChange(FLAG_CPXRES_REAL)) {
        x = @intCast(frontier_screen.showGlyph(if (getSystemFlag(FLAG_CPXRES_REAL)) STD_COMPLEX_C else STD_REAL_R, &standardFont, @intCast(x), 0, vmNormal, @intFromBool(true), @intFromBool(false), @intFromBool(false)));
        lcd_fill_rect(@intCast(x), 0, @intCast((if (sbComplexResult()) X_COMPLEX_MODE else X_COMPLEX_MODE + X_COMPLEX_MODE_ADJ) - x), 20, LCD_SET_VALUE);
    }
}

// ===========================================================================
// showComplexMode (static)
// ===========================================================================
fn showComplexMode() void {
    if (!sbComplexMode()) {
        return;
    }
    var x: i32 = if (sbComplexResult()) X_COMPLEX_MODE else X_COMPLEX_MODE + X_COMPLEX_MODE_ADJ;
    if (didSystemFlagChange(FLAG_POLAR)) {
        x = @intCast(frontier_screen.showGlyph(if (getSystemFlag(FLAG_POLAR)) STD_SUN else STD_RIGHT_ANGLE, &standardFont, @intCast(x), 0, vmNormal, @intFromBool(true), @intFromBool(true), @intFromBool(false)));
        lcd_fill_rect(@intCast(x), 0, @intCast(X_ANGULAR_MODE - x), 20, LCD_SET_VALUE);
    }
}

// ===========================================================================
// showAngularMode (static)
// ===========================================================================
fn showAngularMode() void {
    if (!(sbAngularModeBasic() or true)) { // SBARUPD_AngularMode == 1
        return;
    }

    var x: u32 = @intCast(X_ANGULAR_MODE);
    if (didSystemFlagChange(SETTING_AMODE)) {
        if (sbAngularModeBasic()) {
            x = frontier_screen.showGlyph(STD_MEASURED_ANGLE, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(true), @intFromBool(false));
        }

        switch (currentAngularMode) {
            amRadian => {
                x = frontier_screen.showGlyph(STD_SUP_BOLD_r, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false), @intFromBool(false));
            },
            amMultPi => {
                x = frontier_screen.showGlyph(STD_SUP_pir, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false), @intFromBool(false));
            },
            amGrad => {
                x = frontier_screen.showGlyph(STD_SUP_BOLD_g, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false), @intFromBool(false));
            },
            amDegree => {
                x = frontier_screen.showGlyph(STD_DEGREE, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false), @intFromBool(false));
            },
            amDMS => {
                x = frontier_screen.showGlyph(STD_RIGHT_DOUBLE_QUOTE, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false), @intFromBool(false));
            },
            else => {
                x = frontier_screen.showGlyph(STD_QUESTION_MARK, &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(false), @intFromBool(false));
            },
        }
        lcd_fill_rect(x, 0, @intCast(X_FRAC_MODE - @as(i32, @intCast(x))), 20, LCD_SET_VALUE);
    }
}

// ===========================================================================
// showBaseMode (static, shares Frac Mode space)
// ===========================================================================
fn showBaseMode() bool_t {
    if (!sbFractionModeAndBaseMode()) {
        return false;
    }

    var SBchanged: bool_t = false;
    const adj: u8 = if (lastIntegerBase >= 2 and didSystemFlagChange(FLAG_TOPHEX)) 0x40 else 0;
    if (@as(u8, @truncate(lastIntegerBase)) +% adj != SBlastIntegerBaseShown) {
        const adj2: u8 = if (lastIntegerBase >= 2 and didSystemFlagChange(FLAG_TOPHEX)) 0x40 else 0;
        SBlastIntegerBaseShown = @as(u8, @truncate(lastIntegerBase)) +% adj2;
        SBchanged = true;
    }

    if (SBchanged) {
        var x: u32 = @intCast(X_BASE_MODE);
        if (lastIntegerBase >= 2) {
            if (getSystemFlag(FLAG_TOPHEX)) {
                x = frontier_screen.showString("#KEY", &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(true));
                lcd_fill_rect(x, 0, 26, 20, LCD_SET_VALUE);
                x = showStringY(STD_SUB_A ++ STD_SUB_MINUS ++ STD_SUB_F, &standardFont, x, -4, vmNormal, true, true);
            } else {
                x = frontier_screen.showString("#BASE", &standardFont, x, 0, vmNormal, @intFromBool(true), @intFromBool(true));
            }
            lcd_fill_rect(x, 0, @intCast(X_INT_MX_TVM_MODE - @as(i32, @intCast(x))), 20, LCD_SET_VALUE);
            return true;
        }
    }
    return false;
}

// showString takes uint32_t y in the C prototype, but statusBar passes negative y
// (e.g. -4) which wraps in the unsigned arg. Reproduce with a 2's-complement cast.
inline fn showStringY(str: [*c]const u8, font: *const font_t, x: u32, y: i32, video: videoMode_t, lead: bool_t, end_: bool_t) u32 {
    return frontier_screen.showString(str, font, x, @bitCast(y), video, @intFromBool(lead), @intFromBool(end_));
}
inline fn showGlyphY(ch: [*c]const u8, font: *const font_t, x: u32, y: i32, video: videoMode_t, lead: bool_t, end_: bool_t, npc: bool_t) u32 {
    return frontier_screen.showGlyph(ch, font, x, @bitCast(y), video, @intFromBool(lead), @intFromBool(end_), @intFromBool(npc));
}

// ===========================================================================
// showFracMode
// ===========================================================================
pub export fn showFracMode() callconv(.c) void {
    if (!sbFractionModeAndBaseMode()) {
        return;
    }

    if (lastIntegerBase >= 2) {
        _ = showBaseMode();
        return;
    }

    if (didSystemFlagChange(FLAG_FRACT) or didSystemFlagChange(FLAG_IRFRAC) or didSystemFlagChange(FLAG_PROPFR) or didSystemFlagChange(SETTING_DMX) or didSystemFlagChange(FLAG_DENFIX) or didSystemFlagChange(FLAG_DENANY)) {
        var statusMessage: [20]u8 = undefined;
        var x: i32 = X_FRAC_MODE;

        var divStr: [10]u8 = undefined;
        if (getSystemFlag(FLAG_FRACT) or getSystemFlag(FLAG_IRFRAC)) {
            if (getSystemFlag(FLAG_PROPFR)) {
                lcd_fill_rect(@intCast(x), 0, 11, 20, LCD_SET_VALUE);
                raiseString = 3;
                x = @as(i32, @intCast(showStringY("a" ++ STD_SPACE_4_PER_EM, &standardFont, @intCast(x), 0, vmNormal, true, true))) - 3;
                lcd_fill_rect(@intCast(x - 11), 17, 11, 2, LCD_SET_VALUE);
            }
            lcd_fill_rect(@intCast(x), 0, 7 + 15, 20, LCD_SET_VALUE);
            raiseString = 9;
            x = @as(i32, @intCast(showStringY(STD_SUB_b, &standardFont, @intCast(x), 0, vmNormal, true, true))) - 2 - 2;
        } else {
            lcd_fill_rect(@intCast(x), 0, 15, 20, LCD_SET_VALUE);
        }

        const xxSlash: i32 = x;
        x += 8;

        if (lowerUnderLine() - 1 > 0) {
            lcd_fill_rect(@intCast(xxSlash), 0, @intCast(x - xxSlash), @intCast(lowerUnderLine() - 1), LCD_SET_VALUE);
        }

        compressString = 1;
        if (denMax == 0 or denMax > MAX_DENMAX) {
            abi.fmtBufZ(&statusMessage, "max", .{});
        } else {
            abi.fmtBufZ(&statusMessage, "{d}", .{denMax});
        }
        const xx: i32 = x;
        x = @intCast(showStringY(&statusMessage, &standardFont, @intCast(x), lowerUnderLine(), vmNormal, false, true));
        if (lowerUnderLine() > 0) {
            lcd_fill_rect(@intCast(xx + 1), 0, @intCast(x - xx), @intCast(lowerUnderLine()), LCD_SET_VALUE);
        }

        if (!getSystemFlag(FLAG_IRFRAC) and getSystemFlag(FLAG_DENFIX)) {
            raiseString = 3;
            x += 1;
            lcd_fill_rect(@intCast(x), 0, 11, 20, LCD_SET_VALUE);
            x = @intCast(showStringY(STD_SUB_f, &standardFont, @intCast(x), lowerUnderLine(), vmNormal, true, true));
        }

        if ((getSystemFlag(FLAG_IRFRAC)) or (!getSystemFlag(FLAG_IRFRAC) and !getSystemFlag(FLAG_DENFIX) and !getSystemFlag(FLAG_DENANY))) {
            // strcpy(divStr, PRODUCT_SIGN); PRODUCT_SIGN = FLAG_MULTx ? STD_CROSS : STD_DOT
            _ = strcpy(&divStr, if (getSystemFlag(FLAG_MULTx)) STD_CROSS else STD_DOT);
            x += 1;
            lcd_fill_rect(@intCast(x), 0, 11, 20, LCD_SET_VALUE);
            raiseString = 2;
            x = @as(i32, @intCast(showStringY(&divStr, &standardFont, @intCast(x), lowerUnderLine(), vmNormal, true, true))) + (if (getSystemFlag(FLAG_MULTx)) @as(i32, 0) else @as(i32, 2));
        }

        if (getSystemFlag(FLAG_IRFRAC)) {
            _ = strcpy(&divStr, STD_IRRATIONAL_I);
            lcd_fill_rect(@intCast(x), 0, 9, 20, LCD_SET_VALUE);
            raiseString = 1;
            x = @as(i32, @intCast(showStringY(&divStr, &standardFont, @intCast(x), 0, vmNormal, false, false))) + 2;
        }

        if ((getSystemFlag(FLAG_IRFRAC) or getSystemFlag(FLAG_FRACT)) and (fractionDigits > 0 and fractionDigits < 34)) {
            compressString = 1;
            x += 1;
            x = @intCast(showStringY(STD_ALMOST_EQUAL, &standardFont, @intCast(x - 1), 0, vmNormal, true, false));
            if (x >= X_INT_MX_TVM_MODE - 1) {
                lcd_fill_rect(@intCast(X_INT_MX_TVM_MODE - 1), 0, 1, 20, LCD_SET_VALUE);
            }
        }

        if (x <= X_INT_MX_TVM_MODE) {
            lcd_fill_rect(@intCast(x), 0, @intCast(X_INT_MX_TVM_MODE - x), 20, LCD_SET_VALUE);
        }

        frontier_plotstat.plotline2(@intCast(xxSlash), 18, @intCast(xxSlash + 9), 0);
    }
}

// ===========================================================================
// showStringAndClear (static)
// ===========================================================================
fn showStringAndClear(str: [*c]const u8, font: *const font_t, x: u32, y: i32, dx: u32, dy: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) i32 {
    if (str[0] == 0) {
        lcd_fill_rect(x, 0, dx, 20, LCD_SET_VALUE);
        return @intCast(x);
    }

    var col: u32 = undefined;
    var row: u32 = undefined;
    frontier_screen.getStringBounds(str, font, &col, &row);

    const xx: u32 = frontier_screen.showString(str, font, x, @bitCast(y), videoMode, @intFromBool(showLeadingCols), @intFromBool(showEndingCols));
    // The trailing clear region (split into a noinline helper to keep the thumb
    // register allocator from running out of registers on this function).
    showStringAndClearTail(x, y, dx, dy, xx, row);
    return @intCast(xx);
}

noinline fn showStringAndClearTail(x: u32, y: i32, dx: u32, dy: u32, xx: u32, row: u32) void {
    // All width/offset math is uint32_t wrapping in the C, so dx can arrive as a
    // large wrapped value (a negative status-bar width); use wrapping ops (+%/-%)
    // to match instead of Zig's checked arithmetic, which panics on the wrap.
    if (xx < x +% dx) {
        lcd_fill_rect(xx, @intCast(maxI(0, y)), x +% dx -% xx, @intCast(maxI(@as(i32, @intCast(row)), @as(i32, @intCast(dy))) + minI(0, y)), LCD_SET_VALUE);
    }
    if (y < 0) {
        lcd_fill_rect(x, @bitCast(@as(i32, @intCast(row)) + y), dx, dx -% row, LCD_SET_VALUE);
    } else if (y > 0) {
        lcd_fill_rect(x, 0, dx, @bitCast(y - 0), LCD_SET_VALUE);
    }
}

// ===========================================================================
// showMatrixMode (static)
// ===========================================================================
fn showMatrixMode() bool_t {
    if (!sbMatrixMode()) {
        return false;
    }
    const enable: bool_t = calcMode == CM_MIM;
    if (enable) {
        reInstateOCModeDisplay = true;
        reInstateIntegerModeDisplay = true;
        compressString = 1;
        _ = showStringAndClear(if (getSystemFlag(FLAG_GROW)) "grow" else "wrap", &standardFont, @intCast(X_INT_MX_TVM_MODE), 0, @intCast(X_ALPHA_MODE - X_INT_MX_TVM_MODE), 20, vmNormal, true, true);
    }
    return enable;
}

// ===========================================================================
// showTvmMode (static)
// ===========================================================================
fn showTvmMode() bool_t {
    if (!sbTVMMode()) {
        return false;
    }
    const mi = softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem;
    const enable: bool_t = mi == -MNU_TVM_v or mi == -MNU_FIN_v or mi == -MNU_AMORT_v;
    if (enable) {
        reInstateOCModeDisplay = true;
        reInstateIntegerModeDisplay = true;
        compressString = 1;
        _ = showStringAndClear(if (getSystemFlag(FLAG_ENDPMT)) "END " else "BEG ", &standardFont, @intCast(X_INT_MX_TVM_MODE), 0, @intCast(X_ALPHA_MODE - X_INT_MX_TVM_MODE), 20, vmNormal, true, true);
    }
    return enable;
}

// ===========================================================================
// showIntegerMode (static)
// ===========================================================================
fn showIntegerMode() bool_t {
    const aa: bool_t = didSystemFlagChange(SETTING_SINT_WS);
    const bb: bool_t = didSystemFlagChange(SETTING_SINT_MODE);
    if (!sbIntegerMode()) {
        return false;
    }
    if (aa or bb or reInstateIntegerModeDisplay) {
        reInstateIntegerModeDisplay = false;
        var statusMessage: [10]u8 = undefined;
        const modeChar: u8 = if (shortIntegerMode == SIM_1COMPL) '1' else if (shortIntegerMode == SIM_2COMPL) '2' else if (shortIntegerMode == SIM_UNSIGN) 'u' else if (shortIntegerMode == SIM_SIGNMT) 's' else '?';
        abi.fmtBufZ(&statusMessage, "{s}{d}:{c}", .{ @as([*:0]const u8, if (shortIntegerWordSize <= 9) " " else ""), @as(u32, shortIntegerWordSize), modeChar });
        // strcat(statusMessage, " ")
        const l = strlenZ(&statusMessage);
        statusMessage[l] = ' ';
        statusMessage[l + 1] = 0;
        _ = showStringAndClear(&statusMessage, &standardFont, @intCast(X_INT_MX_TVM_MODE), 0, @intCast(X_OVERFLOW_CARRY - X_INT_MX_TVM_MODE), 20, vmNormal, true, true);
        return true;
    } else {
        return false;
    }
}
inline fn strlenZ(s: [*c]const u8) usize {
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {}
    return i;
}

// ===========================================================================
// showOverflowCarry (static)
// ===========================================================================
fn showOverflowCarry() bool_t {
    const aa: bool_t = didSystemFlagChange(FLAG_OVERFLOW);
    const bb: bool_t = didSystemFlagChange(FLAG_CARRY);
    if (!sbOCCarryMode()) {
        return false;
    }
    if (aa or bb or reInstateOCModeDisplay) {
        reInstateOCModeDisplay = false;
        _ = showStringAndClear(STD_OVERFLOW_CARRY, &standardFont, @intCast(X_OVERFLOW_CARRY), 0, 6, 20, vmNormal, true, true);
        if (!getSystemFlag(FLAG_OVERFLOW)) {
            lcd_fill_rect(@intCast(X_OVERFLOW_CARRY), 2, 6, 7, LCD_SET_VALUE);
        }
        if (!getSystemFlag(FLAG_CARRY)) {
            lcd_fill_rect(@intCast(X_OVERFLOW_CARRY), 12, 6, 7, LCD_SET_VALUE);
        }
        return true;
    } else {
        return false;
    }
}

// ===========================================================================
// clearINT_MX_TVM_MODE (static)
// ===========================================================================
fn clearINT_MX_TVM_MODE() void {
    compressString = 1;
    _ = showStringAndClear("    ", &standardFont, @intCast(X_INT_MX_TVM_MODE), 0, @intCast(X_ALPHA_MODE - X_INT_MX_TVM_MODE), 20, vmNormal, true, true);
}

// SETT_AlphaMode macro.
inline fn settAlphaMode() u16 {
    return @as(u16, nextChar) +%
        (@as(u16, scrLock) << 10) +%
        (@as(u16, alphaCase) << 12) +%
        (@as(u16, @intFromBool(shiftF)) << 13) +%
        (@as(u16, @intFromBool(shiftG)) << 14);
}

// STD_* used by showHideAlphaMode.
const STD_SUB_N = "\xa4\xdd";
const STD_SUP_N = "\xa4\xc3";
const STD_num = "\xa6\x7e";
const STD_SUB_n = "\xa4\xa9";
const STD_SUP_n = "\xa4\x8f";
const STD_n = "\x6e";
const STD_A = "\x41";
const STD_SUP_A = "\xa4\xb6";
const STD_a = "\x61";
const STD_SUB_a = "\xa4\x9c";
const STD_SUP_a = "\xa4\x82";
const STD_BOX = "\xa5\xa2";

// ===========================================================================
// showHideAlphaMode
// ===========================================================================
pub export fn showHideAlphaMode() callconv(.c) void {
    const textModeIconDisplay: bool_t = plainTextMode() or calcMode == CM_EIM or (catalog != 0 and catalog != CATALOG_MVAR) or (tam.mode != 0 and tam.alpha);
    const toSwitchOff: bool_t = !textModeIconDisplay and alphaOutput[0] != 0;

    if (!true or calcMode == CM_GRAPH) { // SBARUPD_AlphaMode == 1
        return;
    }
    var SBchanged: bool_t = false;
    if (SBAlphaModeLastShown != settAlphaMode()) {
        SBAlphaModeLastShown = settAlphaMode();
        SBchanged = true;
    }
    if (didSystemFlagChange(FLAG_alphaCAP) or didSystemFlagChange(FLAG_NUMLOCK) or SBchanged or toSwitchOff or textModeIconDisplay) {
        var status: c_int = 0;
        var nChar: u8 = undefined;
        if (scrLock == NC_NORMAL) {
            nChar = nextChar;
        } else {
            nChar = scrLock;
        }
        if (textModeIconDisplay) {
            var handledDead = false;
            if (comptime !dmcp_build) {
                if (deadKey != 0) {
                    status = 20;
                    handledDead = true;
                }
            }
            if (!handledDead) {
                if (plainTextMode()) {
                    if (alphaCase == AC_UPPER) {
                        setSystemFlag(@bitCast(FLAG_alphaCAP));
                    } else {
                        clearSystemFlag(@bitCast(FLAG_alphaCAP));
                    }
                }

                const subAdj: c_int = if (nChar == NC_SUBSCRIPT) 2 else if (nChar == NC_SUPERSCRIPT) 1 else 0;
                if (getSystemFlag(FLAG_NUMLOCK) and !shiftF and !shiftG) {
                    if (alphaCase == AC_UPPER) {
                        status = 3 - subAdj;
                    } else if (alphaCase == AC_LOWER) {
                        status = 6 - subAdj;
                    }
                } else if (alphaCase == AC_LOWER and shiftF) {
                    status = 12 - subAdj;
                } else if (alphaCase == AC_UPPER and shiftF) {
                    status = 18 - subAdj;
                } else {
                    if (alphaCase == AC_UPPER) {
                        if (shiftG) {
                            status = 3 - subAdj;
                        } else if (!shiftG and !shiftF and !getSystemFlag(FLAG_NUMLOCK)) {
                            status = 12 - subAdj;
                        }
                    } else if (alphaCase == AC_LOWER) {
                        if (shiftG) {
                            status = 3 - subAdj;
                        } else if (!shiftG and !shiftF and !getSystemFlag(FLAG_NUMLOCK)) {
                            status = 18 - subAdj;
                        }
                    }
                }
            }
        }
        var ypos: i32 = 0;
        alphaOutput[0] = 0;
        switch (status) {
            1 => {
                _ = strcpy(&alphaOutput, STD_SUB_N);
                ypos = -2;
            },
            2 => {
                _ = strcpy(&alphaOutput, STD_SUP_N);
                ypos = 0;
            },
            3 => {
                _ = strcpy(&alphaOutput, STD_num);
                ypos = 0;
            },
            4 => {
                _ = strcpy(&alphaOutput, STD_SUB_n);
                ypos = -2;
            },
            5 => {
                _ = strcpy(&alphaOutput, STD_SUP_n);
                ypos = -2;
            },
            6 => {
                _ = strcpy(&alphaOutput, STD_n);
                ypos = 0;
            },
            10 => {
                _ = strcpy(&alphaOutput, STD_SUB_A);
                ypos = -2;
            },
            11 => {
                _ = strcpy(&alphaOutput, STD_SUP_A);
                ypos = 0;
            },
            12 => {
                _ = strcpy(&alphaOutput, STD_A);
                ypos = 0;
            },
            16 => {
                _ = strcpy(&alphaOutput, STD_SUB_a);
                ypos = -2;
            },
            17 => {
                _ = strcpy(&alphaOutput, STD_SUP_a);
                ypos = -2;
            },
            18 => {
                _ = strcpy(&alphaOutput, STD_a);
                ypos = 0;
            },
            20 => {
                if (comptime !dmcp_build) {
                    _ = strcpy(&alphaOutput, STD_BOX);
                    ypos = 0;
                }
            },
            else => {},
        }
        _ = showStringAndClear(&alphaOutput, &standardFont, @intCast(X_ALPHA_MODE), ypos, @intCast(X_HOURGLASS - X_ALPHA_MODE), 18, vmNormal, true, true);
    }
}

// ===========================================================================
// showHideHourGlass
// ===========================================================================
pub export fn showHideHourGlass() callconv(.c) void {
    if (!true) { // SBARUPD_HourGlass == 1
        return;
    }

    if (screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR != 0) {
        switch (calcMode) {
            CM_PEM, CM_REGISTER_BROWSER, CM_FLAG_BROWSER, CM_ASN_BROWSER, CM_FONT_BROWSER, CM_PLOT_STAT, CM_CONFIRMATION, CM_MIM, CM_TIMER, CM_GRAPH => {
                screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
            },
            else => {
                return;
            },
        }
    }

    var statusMessage: [4]u8 = undefined;
    statusMessage[0] = 0;
    statusMessage[1] = 0;
    statusMessage[2] = 0;
    statusMessage[3] = 0;
    var offs: i32 = 0;
    var yoffs: i32 = 0;
    switch (programRunStop) {
        PGM_WAITING => {
            _ = strcpy(&statusMessage, STD_NEG_EXCLAMATION_MARK);
            offs = 0;
        },
        PGM_RUNNING => {
            abi.fmtBufZ(&statusMessage, STD_SPACE_HAIR ++ STD_P, .{});
            offs = 1;
        },
        else => {
            if (hourGlassIconEnabled) {
                _ = strcpy(&statusMessage, STD_HOURGLASS_WH);
                offs = 1;
                yoffs = 5;
            }
        },
    }
    // XX  = GRAPHMODE ? X_HOURGLASS_GRAPHS : X_HOURGLASS
    // XXX = GRAPHMODE ? (SBARUPD_ComplexResult ? X_COMPLEX_MODE : X_COMPLEX_MODE+X_COMPLEX_MODE_ADJ) : X_SSIZE_BEGIN
    const xx: i32 = if (graphMode()) X_HOURGLASS_GRAPHS else X_HOURGLASS;
    const xxx: i32 = if (graphMode()) (if (sbComplexResult()) X_COMPLEX_MODE else X_COMPLEX_MODE + X_COMPLEX_MODE_ADJ) else X_SSIZE_BEGIN;
    if (SBhourglassShown[0] != statusMessage[0] or SBhourglassShown[1] != statusMessage[1]) {
        SBhourglassShown[0] = statusMessage[0];
        SBhourglassShown[1] = statusMessage[1];
        // xxx - xx is negative in graph mode (X_COMPLEX_MODE+ADJ < X_HOURGLASS_GRAPHS);
        // the C passes it to a uint32_t dx, wrapping to a large value that
        // lcd_fill_rect clamps to the screen. @bitCast reproduces that wrap;
        // @intCast would reject the negative value.
        _ = showStringAndClear(&statusMessage, &standardFont, @intCast(xx + offs), yoffs, @bitCast(xxx - xx), 20, vmNormal, false, false);
        frontier_screen.force_SBrefresh(force);
    }
}

// ===========================================================================
// showStackSize (static)
// ===========================================================================
fn showStackSize() void {
    if (!sbStackSize()) {
        return;
    }
    if (didSystemFlagChange(FLAG_SSIZE8)) {
        _ = showStringAndClear(if (getSystemFlag(FLAG_SSIZE8)) STD_SPACE_6_PER_EM ++ STD_8 else STD_SPACE_6_PER_EM ++ STD_4, &standardFont, @intCast(X_SSIZE_BEGIN), 0, @intCast(X_ASM - X_SSIZE_BEGIN), 20, if (getSystemFlag(FLAG_ERPN)) vmNormal else vmReverse, false, true);
    }
}

// ===========================================================================
// light_ASB_icon
// ===========================================================================
pub export fn light_ASB_icon() callconv(.c) void {
    if (!true or calcMode == CM_GRAPH) { // SBARUPD_AlphaMode == 1
        return;
    }
    lcd_fill_rect(@intCast(X_ALPHA_MODE), 18, 9, 2, LCD_EMPTY_VALUE);
    if (!watchIconEnabled) {
        _ = showStringAndClear(&asmBuffer, &standardFont, @intCast(X_ASM), 0, @intCast(X_SERIAL_IO - X_ASM), 20, vmNormal, true, false);
    }
    if (programRunStop != PGM_RUNNING) {
        frontier_screen.force_SBrefresh(force);
    }
}

// ===========================================================================
// kill_ASB_icon
// ===========================================================================
pub export fn kill_ASB_icon() callconv(.c) void {
    if (!true or calcMode == CM_GRAPH) {
        return;
    }
    lcd_fill_rect(@intCast(X_ALPHA_MODE), 18, 9, 2, LCD_SET_VALUE);
    if (!watchIconEnabled) {
        lcd_fill_rect(@intCast(X_ASM), 0, @intCast(X_SERIAL_IO - X_ASM), 20, LCD_SET_VALUE);
    }
    if (programRunStop != PGM_RUNNING) {
        frontier_screen.force_SBrefresh(force);
    }
}

// ===========================================================================
// showHideWatch (static)
// ===========================================================================
fn showHideWatch() void {
    if (!sbStopWatch()) {
        return;
    }
    if (watchIconEnabled != (timerStartTime != TIMER_APP_STOPPED)) {
        setSystemFlagChanged(SETTING_WATCHICON);
        watchIconEnabled = !watchIconEnabled;
    }

    if (didSystemFlagChange(SETTING_WATCHICON)) {
        _ = showStringAndClear(if (watchIconEnabled) STD_TIMER else "", &standardFont, @intCast(X_STOPWATCH), 0, @intCast(X_SERIAL_IO - X_STOPWATCH), 20, vmNormal, true, false);
    }
}

// ===========================================================================
// showHideSerialIO (static)
// ===========================================================================
fn showHideSerialIO() void {
    if (!sbSerialIO()) {
        return;
    }
    if (didSystemFlagChange(SETTING_SIOICON)) {
        _ = showStringAndClear(if (serialIOIconEnabled) STD_SERIAL_IO else "", &standardFont, @intCast(X_SERIAL_IO), 0, @intCast(X_PRINTER - X_SERIAL_IO), 20, vmNormal, true, false);
    }
}

// ===========================================================================
// showHidePrinter (static)
// ===========================================================================
fn showHidePrinter() void {
    if (!sbPrinter()) return;
    if (didSystemFlagChange(SETTING_PRINTERICON)) {
        _ = showStringAndClear(if (printerIconEnabled) STD_PRINTER else "", &standardFont, @intCast(X_PRINTER), 0, @intCast(X_USER_MODE - X_PRINTER), 20, vmNormal, true, false);
    }
}

// ===========================================================================
// showHideUserMode (static)
// ===========================================================================
fn showHideUserMode() void {
    if (!true) { // SBARUPD_UserMode == 1
        return;
    }
    if (didSystemFlagChange(FLAG_USER)) {
        _ = showStringAndClear(if (getSystemFlag(FLAG_USER)) STD_USER_MODE else "", &standardFont, @intCast(X_USER_MODE), 0, @intCast(X_BATTERY - X_USER_MODE), 20, vmNormal, false, false);
        refreshModeGui();
    }
}

// ===========================================================================
// drawBattery
// ===========================================================================
pub export fn drawBattery(voltage: u16) callconv(.c) void {
    lcd_fill_rect(@intCast(X_BATTERY), 0, 11, 20, LCD_SET_VALUE);
    // C: (uint16_t)(min(max(voltage-2000,0),3100) / (float)(((float)3100 - 2000.0f) / (float)DY_BATTERY))
    const vf: f32 = @as(f32, @floatFromInt(minI(maxI(@as(i32, voltage) - 2000, 0), 3100))) / ((@as(f32, 3100) - 2000.0) / @as(f32, @floatFromInt(DY_BATTERY)));
    const vv: u16 = @intFromFloat(vf);
    {
        // C assigns min(vv-1, ...) to a uint16_t: when vv==0, vv-1 is -1 and
        // truncates to 65535 (the loop then simply doesn't run). @intCast would
        // panic on the negative in safety-on builds, so truncate like C.
        var ii: u16 = @truncate(@as(u32, @bitCast(minI(@as(i32, vv) - 1, DY_BATTERY - 1))));
        while (ii <= DY_BATTERY - 1) : (ii += 1) {
            if (ii % 2 == 0) {
                setBlackPixel(@intCast(if (ii < DY_BATTERY - 3) X_BATTERY + 0 else X_BATTERY + 2), @intCast((DY_BATTERY - 1) - @as(i32, ii)));
                setBlackPixel(@intCast(if (ii < DY_BATTERY - 3) X_BATTERY + DX_BATTERY + 0 else X_BATTERY + DX_BATTERY - 2), @intCast((DY_BATTERY - 1) - @as(i32, ii)));
            }
        }
    }
    {
        var ii: u16 = 0;
        while (ii <= minI(@as(i32, vv), DY_BATTERY - 1)) : (ii += 1) {
            var jj: u16 = 0;
            while (jj <= DX_BATTERY) : (jj += 1) {
                if (minI(@as(i32, vv), DY_BATTERY) - @as(i32, ii) > (if (voltage > 2750) @as(i32, 2) else @as(i32, 1)) or (jj > 1 and jj < DX_BATTERY - 1)) {
                    setBlackPixel(@intCast(X_BATTERY + @as(i32, jj)), @intCast((DY_BATTERY - 1) - @as(i32, ii)));
                }
            }
        }
    }
}

// ===========================================================================
// showHideUsbLowBattery (DMCP-only)
// ===========================================================================
fn showHideUsbLowBatteryImpl() callconv(.c) void {
    if (!true) { // SBARUPD_Battery == 1
        lcd_fill_rect(@intCast(X_BATTERY), 0, 11, 20, LCD_SET_VALUE);
        return;
    }
    if (getSystemFlag(FLAG_USB)) {
        _ = frontier_screen.showGlyph(STD_USB_SYMBOL, &standardFont, @intCast(X_BATTERY), 0, vmNormal, 1, 0, 0);
    } else {
        if (sbBatVoltage()) {
            drawBattery(@intCast(minI(get_vbat(), vbatVIntegrated)));
        } else if (getSystemFlag(FLAG_LOWBAT)) {
            _ = frontier_screen.showGlyph(STD_BATTERY, &standardFont, @intCast(X_BATTERY), 0, vmNormal, 1, 0, 0);
        } else {
            lcd_fill_rect(@intCast(X_BATTERY), 0, 11, 20, LCD_SET_VALUE);
        }
    }
}

// ===========================================================================
// refreshStatusBar
// ===========================================================================
pub export fn refreshStatusBar() callconv(.c) void {
    if (screenUpdatingMode & SCRUPD_MANUAL_STATUSBAR != 0) {
        switch (calcMode) {
            CM_PEM, CM_REGISTER_BROWSER, CM_FLAG_BROWSER, CM_ASN_BROWSER, CM_FONT_BROWSER, CM_PLOT_STAT, CM_CONFIRMATION, CM_MIM, CM_TIMER, CM_GRAPH => {
                screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
            },
            else => {
                return;
            },
        }
    }

    // DEBUG_INSTEAD_STATUS_BAR == 0 -> normal branch.
    if (graphMode()) {
        lcd_fill_rect(0, 0, 158, 20, LCD_SET_VALUE);
    }
    _ = showDateTime();
    if (yShift() == 0 and xShift() < 200) {
        showShiftState();
    }
    if (graphMode()) {
        showHideHourGlass();
        return;
    }
    showRealComplexResult();
    showComplexMode();
    showAngularMode();
    showFracMode();

    if (!showMatrixMode()) {
        if (!showTvmMode()) {
            const aa: bool_t = showIntegerMode();
            const bb: bool_t = showOverflowCarry();
            if (!aa and !bb and (!sbIntegerMode() or !sbOCCarryMode())) {
                clearINT_MX_TVM_MODE();
            }
        }
    }

    showHideAlphaMode();
    showHideHourGlass();
    showStackSize();
    showHideWatch();
    if (frontier_timer.fnTimerGetStatus(TO_ASM_ACTIVE) == TMR_RUNNING and (plainTextMode() or labelText() or catalog != 0)) {
        light_ASB_icon();
    } else {
        kill_ASB_icon();
    }
    showHideSerialIO();
    showHidePrinter();
    if (yShift() == 0 and xShift() > 300) {
        showShiftState();
    }
    showHideUserMode();
    if (comptime dmcp_build) {
        showHideUsbLowBatteryImpl();
    } else {
        showHideStackLiftImpl();
    }
}

// ===========================================================================
// showHideStackLift (!DMCP)
// ===========================================================================
fn showHideStackLiftImpl() callconv(.c) void {
    if (getSystemFlag(FLAG_ASLIFT)) {
        // Draw S
        setBlackPixel(392, 1);
        setBlackPixel(393, 1);
        setBlackPixel(394, 1);
        setBlackPixel(391, 2);
        setBlackPixel(395, 2);
        setBlackPixel(391, 3);
        setBlackPixel(392, 4);
        setBlackPixel(393, 4);
        setBlackPixel(394, 4);
        setBlackPixel(395, 5);
        setBlackPixel(391, 6);
        setBlackPixel(395, 6);
        setBlackPixel(392, 7);
        setBlackPixel(393, 7);
        setBlackPixel(394, 7);
        // Draw L
        setBlackPixel(391, 10);
        setBlackPixel(391, 11);
        setBlackPixel(391, 12);
        setBlackPixel(391, 13);
        setBlackPixel(391, 14);
        setBlackPixel(391, 15);
        setBlackPixel(391, 16);
        setBlackPixel(392, 16);
        setBlackPixel(393, 16);
        setBlackPixel(394, 16);
        setBlackPixel(395, 16);
    } else {
        // Erase S
        setWhitePixel(392, 1);
        setWhitePixel(393, 1);
        setWhitePixel(394, 1);
        setWhitePixel(391, 2);
        setWhitePixel(395, 2);
        setWhitePixel(391, 3);
        setWhitePixel(392, 4);
        setWhitePixel(393, 4);
        setWhitePixel(394, 4);
        setWhitePixel(395, 5);
        setWhitePixel(391, 6);
        setWhitePixel(395, 6);
        setWhitePixel(392, 7);
        setWhitePixel(393, 7);
        setWhitePixel(394, 7);
        // Erase L
        setWhitePixel(391, 10);
        setWhitePixel(391, 11);
        setWhitePixel(391, 12);
        setWhitePixel(391, 13);
        setWhitePixel(391, 14);
        setWhitePixel(391, 15);
        setWhitePixel(391, 16);
        setWhitePixel(392, 16);
        setWhitePixel(393, 16);
        setWhitePixel(394, 16);
        setWhitePixel(395, 16);
    }
}

comptime {
    if (dmcp_build) {
        @export(&showHideUsbLowBatteryImpl, .{ .name = "showHideUsbLowBattery", .linkage = .strong });
    } else {
        @export(&showHideStackLiftImpl, .{ .name = "showHideStackLift", .linkage = .strong });
    }
}

// ===========================================================================
// mockupSB (PC_BUILD-only diagnostic status-bar mockup; called by the GTK sim).
// ===========================================================================
const STD_MODE_F = "\x9e\x9d";
const STD_MODE_G = "\x9e\x9f";

fn mockupSBImpl() callconv(.c) void {
    var x: u32 = 0;
    var xx: u32 = 0;
    var statusMessage: [100]u8 = undefined;
    const L0: i32 = 0;
    const L1: i32 = 20;
    const L2: i32 = 40;
    const L3: i32 = 60;
    const L4: i32 = 80;
    const L5: i32 = 100;
    const L6: i32 = 120;
    const L7: i32 = 140;
    const L8: i32 = 160;

    // clearScreen(100) macro
    lcd_fill_rect(0, 0, @intCast(SCREEN_WIDTH), 240, LCD_SET_VALUE);
    forceSBupdate();
    _ = printf("CLEARFULLSCREEN Macro %u\n", @as(c_uint, 100));

    frontier_date_time.getTimeString(&oldTime);
    frontier_date_time.getDateString(&dateTimeString);
    x = showStringY(&dateTimeString, &standardFont, x, L1, vmNormal, true, true);
    xx = x;
    x = showGlyphY(if (getSystemFlag(FLAG_TDM24)) " " else STD_SPACE_3_PER_EM, &standardFont, x, L2, vmNormal, true, true, false);
    x = showStringY(&oldTime, &standardFont, x, L2, vmNormal, true, false);

    x = showGlyphY(STD_SPACE_3_PER_EM, &standardFont, xx, L3, vmNormal, true, true, false);
    frontier_date_time.getWeekOfYearString(&dateTimeString);
    x = showStringY(&dateTimeString, &standardFont, x, L3, vmNormal, true, false);

    _ = showGlyphY(STD_MODE_F, &standardFont, @intCast(xShift()), L0, vmNormal, true, true, false);
    _ = showGlyphY(STD_MODE_F, &standardFont, @intCast(xShift()), L2, vmNormal, true, true, false);
    _ = showGlyphY(STD_MODE_G, &standardFont, @intCast(xShift()), L0, vmNormal, true, true, false);

    x = @intCast(X_REAL_COMPLEX);
    x = showGlyphY(STD_COMPLEX_C, &standardFont, x, 0, vmNormal, true, false, false);
    x = @intCast(X_REAL_COMPLEX);
    x = showGlyphY(STD_REAL_R, &standardFont, x, L1, vmNormal, true, false, false);

    x = @intCast(X_COMPLEX_MODE);
    _ = showGlyphY(STD_SUN, &standardFont, x, 0, vmNormal, true, true, false);
    _ = showGlyphY(STD_RIGHT_ANGLE, &standardFont, x, L1, vmNormal, true, true, false);
    x = @intCast(X_COMPLEX_MODE + X_COMPLEX_MODE_ADJ);
    _ = showGlyphY(STD_SUN, &standardFont, x, L3, vmNormal, true, true, false);
    _ = showGlyphY(STD_RIGHT_ANGLE, &standardFont, x, L4, vmNormal, true, true, false);

    x = @intCast(X_ANGULAR_MODE);
    x = showGlyphY(STD_MEASURED_ANGLE, &standardFont, x, L0, vmNormal, true, true, false);
    _ = showGlyphY(STD_SUP_pir, &standardFont, x, L0, vmNormal, true, false, false);
    _ = showGlyphY(STD_SUP_BOLD_r, &standardFont, x, L1, vmNormal, true, false, false);
    _ = showGlyphY(STD_SUP_BOLD_g, &standardFont, x, L2, vmNormal, true, false, false);
    _ = showGlyphY(STD_DEGREE, &standardFont, x, L3, vmNormal, true, false, false);
    _ = showGlyphY(STD_RIGHT_DOUBLE_QUOTE, &standardFont, x, L4, vmNormal, true, false, false);
    _ = showGlyphY(STD_SUP_pir, &standardFont, x, L5, vmNormal, true, false, false);

    x = @intCast(X_FRAC_MODE);
    x = showStringY("#KEY", &standardFont, x, L5, vmNormal, true, true);
    x = showStringY(STD_SUB_A ++ STD_SUB_MINUS ++ STD_SUB_F, &standardFont, x, L5 - 4, vmNormal, true, true);
    x = @intCast(X_FRAC_MODE);
    x = showStringY("#BASE", &standardFont, x, L4, vmNormal, true, true);

    x = @intCast(X_FRAC_MODE);
    raiseString = 3;
    x = showStringY("a" ++ STD_SPACE_4_PER_EM, &standardFont, x, 0, vmNormal, true, true) -% 3;
    raiseString = 9;
    x = showStringY(STD_SUB_b, &standardFont, x, 0, vmNormal, true, true) -% 2 -% 2;

    var divStr: [10]u8 = undefined;
    compressString = 1;
    xx = x;
    x = showGlyphY("/", &standardFont, x, lowerUnderLine() - 1, vmNormal, false, true, true);
    x = showGlyphY("/", &standardFont, xx +% 4, lowerUnderLine() - 1 - 9, vmNormal, false, true, true) -% 5;
    lcd_fill_rect(xx, 0, x -% xx, @intCast(lowerUnderLine() - 1), LCD_SET_VALUE);

    compressString = 1;
    abi.fmtBufZ(&statusMessage, "max", .{});
    xx = x;
    x = showStringY(&statusMessage, &standardFont, x, lowerUnderLine(), vmNormal, false, true);
    raiseString = 3;
    x +%= 1;
    x = showStringY(STD_SUB_f, &standardFont, x, lowerUnderLine(), vmNormal, true, true);

    compressString = 1;
    abi.fmtBufZ(&statusMessage, "{d}", .{@as(u32, 9999)});
    x = showStringY(&statusMessage, &standardFont, xx, L1 + lowerUnderLine(), vmNormal, false, true);
    compressString = 1;
    x = showStringY(&statusMessage, &standardFont, xx, L2 + lowerUnderLine(), vmNormal, false, true);

    _ = strcpy(&divStr, STD_CROSS);
    raiseString = 2;
    xx = x;
    x = showStringY(&divStr, &standardFont, x +% 1, L1 + lowerUnderLine(), vmNormal, true, true) + 0;
    _ = strcpy(&divStr, STD_IRRATIONAL_I);
    raiseString = 1;
    x = @intCast(maxI(0, @as(i32, @bitCast(x)) - 1));
    x = showStringY(&divStr, &standardFont, x, L1, vmNormal, false, false) +% 2;

    _ = strcpy(&divStr, STD_DOT);
    raiseString = 2;
    xx +%= 1;
    x = showStringY(&divStr, &standardFont, xx, L2 + lowerUnderLine(), vmNormal, true, true) +% 2;
    _ = strcpy(&divStr, STD_IRRATIONAL_I);
    raiseString = 1;
    x = @intCast(maxI(0, @as(i32, @bitCast(x)) - 1));
    x = showStringY(&divStr, &standardFont, x, L2, vmNormal, false, false) +% 2;

    compressString = 1;
    x +%= 1;
    x = showStringY(STD_ALMOST_EQUAL, &standardFont, x -% 1, 0, vmNormal, true, false);

    const modeChar: u8 = if (shortIntegerMode == SIM_1COMPL) '1' else if (shortIntegerMode == SIM_2COMPL) '2' else if (shortIntegerMode == SIM_UNSIGN) 'u' else if (shortIntegerMode == SIM_SIGNMT) 's' else '?';
    abi.fmtBufZ(&statusMessage, "{s}{d}:{c}", .{ @as([*:0]const u8, if (shortIntegerWordSize <= 9) " " else ""), @as(u32, shortIntegerWordSize), modeChar });
    x = showStringY(&statusMessage, &standardFont, @intCast(X_INT_MX_TVM_MODE), 0, vmNormal, true, true);

    x = @intCast(X_INT_MX_TVM_MODE);
    compressString = 1;
    x = showStringY("grow", &standardFont, x, L1, vmNormal, true, true);
    x = @intCast(X_INT_MX_TVM_MODE);
    compressString = 1;
    x = showStringY("wrap", &standardFont, x, L2, vmNormal, true, true);
    compressString = 1;
    _ = showStringY("END", &standardFont, @intCast(X_INT_MX_TVM_MODE), L3, vmNormal, true, true);
    compressString = 1;
    _ = showStringY("BEG", &standardFont, @intCast(X_INT_MX_TVM_MODE), L4, vmNormal, true, true);

    _ = showGlyphY(STD_OVERFLOW_CARRY, &standardFont, @intCast(X_OVERFLOW_CARRY), 0, vmNormal, true, false, false);

    _ = showStringY(STD_A, &standardFont, @intCast(X_ALPHA_MODE), L0, vmNormal, true, false);
    _ = showStringY(STD_SUB_A, &standardFont, @intCast(X_ALPHA_MODE), L1, vmNormal, true, false);
    _ = showStringY(STD_SUP_A, &standardFont, @intCast(X_ALPHA_MODE), L2, vmNormal, true, false);
    _ = showStringY(STD_a, &standardFont, @intCast(X_ALPHA_MODE), L3, vmNormal, true, false);
    _ = showStringY(STD_SUB_a, &standardFont, @intCast(X_ALPHA_MODE), L4, vmNormal, true, false);
    _ = showStringY(STD_SUP_a, &standardFont, @intCast(X_ALPHA_MODE), L5, vmNormal, true, false);
    _ = showStringY(STD_num ++ STD_SUB_N ++ STD_SUP_N, &standardFont, @intCast(X_ALPHA_MODE), L6, vmNormal, true, false);
    _ = showStringY(STD_n ++ STD_SUB_n ++ STD_SUP_n, &standardFont, @intCast(X_ALPHA_MODE), L7, vmNormal, true, false);
    _ = showStringY(STD_BOX, &standardFont, @intCast(X_ALPHA_MODE), L8, vmNormal, true, false);

    _ = showGlyphY(STD_HOURGLASS_WH, &standardFont, @intCast(X_HOURGLASS + 1), L1, vmNormal, true, false, false);
    _ = showGlyphY(STD_NEG_EXCLAMATION_MARK, &standardFont, @intCast(X_HOURGLASS), L3, vmNormal, true, false, false);
    _ = showGlyphY(STD_P, &standardFont, @intCast(X_HOURGLASS + 2), L2, vmNormal, true, false, false);
    _ = showGlyphY(STD_HOURGLASS_WH, &standardFont, @intCast(X_HOURGLASS_GRAPHS), L2, vmNormal, true, false, false);

    _ = strcpy(&asmBuffer, "MM");
    compressString = 1;
    _ = showStringY(&asmBuffer, &standardFont, @intCast(X_ASM), L1, vmNormal, true, false);
    asmBuffer[0] = 0;

    x = @intCast(X_SSIZE_BEGIN);
    x = showGlyphY(STD_SPACE_6_PER_EM, &standardFont, x, 0, vmNormal, true, true, false);
    x = showGlyphY(STD_4, &standardFont, x, 0, vmNormal, true, true, false);
    x = @intCast(X_SSIZE_BEGIN);
    var dd: [6]u8 = undefined;
    abi.fmtBufZ(&dd, STD_SPACE_6_PER_EM ++ STD_8, .{});
    _ = showStringY(&dd, &standardFont, x, L1, vmReverse, false, true);
    _ = showStringY(&dd, &standardFont, x, L2, vmReverse, false, true);
    _ = showStringY(&dd, &standardFont, x, L3, vmReverse, false, true);

    _ = showGlyphY(STD_TIMER, &standardFont, @intCast(X_STOPWATCH), L2, vmNormal, true, false, false);
    _ = showGlyphY(STD_SERIAL_IO, &standardFont, @intCast(X_SERIAL_IO), L1, vmNormal, true, false, false);
    _ = showGlyphY(STD_PRINTER, &standardFont, @intCast(X_PRINTER), L2, vmNormal, true, false, false);
    _ = showGlyphY(STD_USER_MODE, &standardFont, @intCast(X_USER_MODE), L0, vmNormal, false, false, false);
    _ = showGlyphY(STD_USER_MODE, &standardFont, @intCast(X_USER_MODE), L1, vmNormal, false, false, false);
    _ = showGlyphY(STD_USER_MODE, &standardFont, @intCast(X_USER_MODE), L2, vmNormal, false, false, false);

    light_ASB_icon();
    drawBattery(@bitCast(exponentLimit));
    _ = showGlyphY(STD_BATTERY, &standardFont, @intCast(X_BATTERY), L1, vmNormal, true, false, false);
    calcMode = CM_GRAPH;
}

comptime {
    if (!dmcp_build) {
        @export(&mockupSBImpl, .{ .name = "mockupSB", .linkage = .strong });
    }
}
