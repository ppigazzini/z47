// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/programming/input.c: fnInput, fnVarMnu, fnPause, fnKey,
// fnKeyType, fnPutKey, fnEntryQ and the file-static _getKeyArg. This is a
// faithful, line-by-line port of the C.
//
// fnPause and fnKey have fully distinct PC_BUILD and DMCP_BUILD bodies, both
// reproduced and gated on dmcp_build. On firmware the DMCP-ROM functions
// (lcd_refresh / wait_for_key_release / key_pop / key_empty / sys_current_ms /
// sys_delay / sys_sleep / sys_timer_start / sys_timer_disable) are fixed-address
// jump-table calls (LIBRARY_FN_BASE + verified offset); on host the equivalent
// path uses the linkable GTK helpers (g_timeout_add / g_main_context_iteration /
// g_source_remove / gtk_events_pending / gtk_main_iteration / refreshLcd), only
// referenced under !dmcp_build. The DMCP status-bit macros (CLR_ST/SET_ST/ST) are
// modelled over the fixed-address sdb.calc_state word. The PC-only gTime /
// gRemoveTimer / gTimerId state and the gTimer callback live here on the host.
// The IR_PRINTING printInputPrompt call is omitted (IR_PRINTING is never defined
// for any z47 build).
//
// input.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;
const SDB_BASE: usize = if (old_hw) 0x10002000 else 0x20000000;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const real34_t = extern struct { bytes: [16]u8 };
const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
const longInteger_t = [1]mpz_struct;

// ---------------------------------------------------------------------------
// Constants / enum values (verified via C probe)
// ---------------------------------------------------------------------------
const PGM_RUNNING: u8 = 1;
const PGM_WAITING: u8 = 2;
const PGM_PAUSED: u8 = 3;
const PGM_KEY_PRESSED_WHILE_PAUSED: u8 = 4;

const TI_TRUE: u8 = 13;
const TI_FALSE: u8 = 12;
const MNU_MVAR: i16 = 1398;

const TO_KB_ACTV: u8 = 10;
const PROGRAM_KB_ACTV: u32 = 60000;
const TO_KB_ACTV_MEDIUM: u32 = 6000;
const TIMER_IDX_REFRESH_SLEEP: c_int = 0;

const SCRUPD_MANUAL_STATUSBAR: u8 = 1;
const SCRUPD_AUTO: u8 = 0;

const LAST_NAMED_VARIABLE: u16 = 1999;
const SCREENDUMP: i16 = 9875;

const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERR_REGISTER_LINE: calcRegister_t = 102; // REGISTER_Z
const REGISTER_X: calcRegister_t = 100;
const amNone: u32 = 5;
const amAngleMask: u32 = 15;
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const DEC_ROUND_DOWN: c_int = 5;

const FLAG_USB: c_int = 0xc028;

// DMCP status bits (dmcp.h: BIT(n)).
const STAT_RUNNING: u32 = 1 << 1;
const STAT_SUSPENDED: u32 = 1 << 2;
const STAT_KEYUP_WAIT: u32 = 1 << 3;
const STAT_PGM_END: u32 = 1 << 9;
const STAT_CLK_WKUP_FLAG: u32 = 1 << 12;

// constant blob offsets (constantPointers.h).
const OFF_const34_1: u32 = 15804;
const OFF_const34_65535: u32 = 16284;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var programRunStop: u8;
extern var currentInputVariable: u16;
extern var currentMvarLabel: u16;
extern var temporaryInformation: u8;
extern var lastKeyCode: u8;
extern var lastItem: i16;
extern var entryStatus: u8;
extern var screenUpdatingMode: u8;
extern var errorMessage: [*c]u8;
extern var ctxtReal34: realContext_t;

const constants = @extern([*]const u8, .{ .name = "constants" });
inline fn cst34(offset: u32) *align(1) const real34_t {
    return @ptrCast(constants + offset);
}
const const34_1 = cst34(OFF_const34_1);
const const34_65535 = cst34(OFF_const34_65535);

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------
extern fn fnRecall(r: u16) void;
extern fn showSoftmenu(id: i16) void;
extern fn refreshScreen(source: u16) void;
extern fn leaveTamModeIfEnabled() void;
extern fn dmcpResetAutoOff() void;
extern fn fnTimerStart(nr: u8, param: u16, time: u32) void;
extern fn setLastKeyCode(key: c_int) void;
extern fn convertKeyCode(key: c_int) c_int;
extern fn standardScreenDump() void;
extern fn resetShiftState() void;
extern fn resetKeytimers() void;
extern fn emptyKeyBuffer() bool_t;
extern fn outKeyBuffer(outKey: *u8) bool_t;
extern fn getSystemFlag(flag: c_int) bool_t;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*]u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool_t, padWithBlanks: bool_t) [*c]const u8;
extern fn convertLongIntegerRegisterToReal34(source: calcRegister_t, destination: *real34_t) void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn liftStack() void;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;

// GMP.
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_set_ui"(p: *mpz_struct, v: c_ulong) void;

// decQuad (real34) helpers.
extern fn decQuadToIntegralValue(res: *real34_t, src: *align(1) const real34_t, ctx: *realContext_t, round: c_int) *real34_t;
extern fn decQuadToUInt32(src: *align(1) const real34_t, ctx: *realContext_t, round: c_int) u32;
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;
extern fn real34CompareGreaterEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool_t;

// GTK / glib (host only). Referenced under !dmcp_build.
const gpointer = ?*anyopaque;
const GSourceFunc = *const fn (gpointer) callconv(.c) c_int;
extern fn refreshLcd(unusedData: gpointer) c_int;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;
extern fn g_source_remove(tag: c_uint) c_int;
extern fn g_main_context_default() ?*anyopaque;
extern fn g_main_context_iteration(context: ?*anyopaque, may_block: c_int) c_int;
extern fn g_timeout_add(interval: c_uint, function: GSourceFunc, data: gpointer) c_uint;

// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (fixed-address on firmware; never referenced on host).
// ---------------------------------------------------------------------------
fn romCall0v(comptime offset: usize) void {
    const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + offset);
    f();
}
inline fn lcd_refresh() void {
    romCall0v(48);
}
inline fn sys_sleep() void {
    romCall0v(536);
}
inline fn wait_for_key_release(tout: c_int) void {
    const f: *const fn (c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 420);
    f(tout);
}
inline fn key_pop() c_int {
    const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 392);
    return f();
}
inline fn key_empty() c_int {
    const f: *const fn () callconv(.c) c_int = @ptrFromInt(LIBRARY_FN_BASE + 380);
    return f();
}
inline fn sys_current_ms() u32 {
    const f: *const fn () callconv(.c) u32 = @ptrFromInt(LIBRARY_FN_BASE + 524);
    return f();
}
inline fn sys_delay(ms: u32) void {
    const f: *const fn (u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 516);
    f(ms);
}
inline fn sys_timer_start(timer_ix: c_int, ms_value: u32) void {
    const f: *const fn (c_int, u32) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 504);
    f(timer_ix, ms_value);
}
inline fn sys_timer_disable(timer_ix: c_int) void {
    const f: *const fn (c_int) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 500);
    f(timer_ix);
}

// DMCP status-bit accessors over the fixed-address sdb.calc_state word.
inline fn calcState() *volatile u32 {
    return @ptrFromInt(SDB_BASE);
}
inline fn stSet(bit: u32) void {
    calcState().* |= bit;
}
inline fn stClr(bit: u32) void {
    calcState().* &= ~bit;
}
inline fn stVal(bit: u32) bool {
    return (calcState().* & bit) != 0;
}

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn reg34(reg: calcRegister_t) *align(1) const real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn real34ToIntegralValue(source: *align(1) const real34_t, destination: *real34_t, mode: c_int) void {
    _ = decQuadToIntegralValue(destination, source, &ctxtReal34, mode);
}
inline fn real34ToUInt32(source: *align(1) const real34_t) u32 {
    return decQuadToUInt32(source, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn runningOnSimOrUSB() bool {
    if (comptime dmcp_build) {
        return getSystemFlag(FLAG_USB);
    } else {
        return true;
    }
}
inline fn moreInfoOnErr(where: [*:0]const u8, hint: [*:0]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnError(where, hint, null, null);
        }
    }
}

// ---------------------------------------------------------------------------
// PC-only gTimer state (input.c file globals under #if PC_BUILD).
// ---------------------------------------------------------------------------
pub export var gTime: i32 = 0;
pub export var gRemoveTimer: bool_t = false;
pub export var gTimerId: c_uint = 0;

fn gTimer(user_data: gpointer) callconv(.c) c_int {
    _ = user_data;
    gTime += 1;
    if (gRemoveTimer) {
        return 0; // FALSE
    } else {
        return 1; // TRUE
    }
}

// ===========================================================================
// fnInput
// ===========================================================================
pub export fn fnInput(regist: u16) callconv(.c) void {
    if (programRunStop == PGM_RUNNING) {
        programRunStop = PGM_WAITING;
        currentInputVariable = regist;
        fnRecall(regist);
        refreshScreen(10);
        if (comptime dmcp_build) {
            lcd_refresh();
        } else {
            _ = refreshLcd(null);
        }
        // IR_PRINTING printInputPrompt omitted (never defined for z47).
    }
}

// ===========================================================================
// fnVarMnu
// ===========================================================================
pub export fn fnVarMnu(label: u16) callconv(.c) void {
    currentMvarLabel = label;
    showSoftmenu(-MNU_MVAR);
}

// ---------------------------------------------------------------------------
// goToSleepForMs / pauseKeyExit (DMCP_BUILD-only file statics).
// ---------------------------------------------------------------------------
fn goToSleepForMs(sleepTime: u32) void {
    if (sleepTime == 1) {
        return;
    }
    if (sleepTime > 1) {
        sys_timer_start(TIMER_IDX_REFRESH_SLEEP, sleepTime);
    }
    stClr(STAT_RUNNING);
    stClr(STAT_KEYUP_WAIT);
    stSet(STAT_SUSPENDED);
    while (true) {
        sys_sleep();
        if (!(!stVal(STAT_PGM_END) and key_empty() != 0 and emptyKeyBuffer() and !stVal(STAT_CLK_WKUP_FLAG))) break;
    }
    stClr(STAT_CLK_WKUP_FLAG);
    stClr(STAT_SUSPENDED);
    stSet(STAT_RUNNING);
    if (sleepTime > 1) {
        sys_timer_disable(TIMER_IDX_REFRESH_SLEEP);
    }
}

fn pauseKeyExit(key: c_int, prevStop: *u8) bool_t {
    if ((key == 36 or key == 33) and prevStop.* == PGM_RUNNING) {
        programRunStop = PGM_WAITING;
        prevStop.* = PGM_WAITING;
    }
    setLastKeyCode(key);
    fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, PROGRAM_KB_ACTV);
    wait_for_key_release(0);
    _ = key_pop();
    return true;
}

// ===========================================================================
// fnPause
// ===========================================================================
pub export fn fnPause(dur: u16) callconv(.c) void {
    var duration: i32 = dur;
    if (duration == 99) {
        if (!runningOnSimOrUSB()) {
            duration = 2 * 60 * 60 * 10; // 2 hours
        } else {
            duration = 0x7FFFFFFF;
        }
    }

    var previousProgramRunStop: u8 = programRunStop;
    programRunStop = PGM_PAUSED;

    if (previousProgramRunStop != PGM_RUNNING) {
        leaveTamModeIfEnabled();
    }

    if (comptime dmcp_build) {
        if (previousProgramRunStop != PGM_RUNNING and dur != 99) {
            screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
            refreshScreen(12);
        }
        lcd_refresh();
        wait_for_key_release(0);
        _ = key_pop();
        const targetMs: u32 = sys_current_ms() +% @as(u32, @intCast(duration)) *% 10;
        var i: i32 = 0;
        while ((if (dur == 99) true else i < duration) and (programRunStop == PGM_PAUSED or programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED)) : (i += 1) {
            var key: c_int = key_pop();
            key = convertKeyCode(key);
            if (key > 0) {
                if (key == 28 or key == 11) { // f key on C47 and R47
                    wait_for_key_release(0);
                    continue;
                }
                if (key == 99) { // spurious screen-dump code
                    continue;
                }
                if (key == 44) { // DISP special SCREEN DUMP
                    standardScreenDump();
                    lastItem = SCREENDUMP;
                    dmcpResetAutoOff();
                    resetShiftState();
                    resetKeytimers();
                    stClr(STAT_KEYUP_WAIT);
                    wait_for_key_release(0);

                    var outKey: u8 = undefined;
                    while (!emptyKeyBuffer()) {
                        _ = outKeyBuffer(&outKey);
                    }

                    _ = key_pop();
                    continue;
                }
                if (pauseKeyExit(key, &previousProgramRunStop)) {
                    break;
                }
            }
            if (dur == 99) {
                if (sys_current_ms() >= targetMs and !runningOnSimOrUSB()) {
                    break;
                }
                dmcpResetAutoOff();
                goToSleepForMs(0);
            } else {
                dmcpResetAutoOff();
                fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, if (programRunStop == PGM_RUNNING) PROGRAM_KB_ACTV else TO_KB_ACTV_MEDIUM);
                sys_delay(100);
            }
        }
        if (dur != 0 and (dur == 99 or previousProgramRunStop != PGM_RUNNING)) {
            screenUpdatingMode = SCRUPD_AUTO;
            refreshScreen(1201);
            lcd_refresh();
        }
    } else { // PC_BUILD
        if (gTimerId != 0) {
            _ = g_source_remove(gTimerId);
            gTimerId = 0;
        }
        if (duration == 0) {
            _ = g_main_context_iteration(g_main_context_default(), 0);
        } else {
            gTime = 0;
            gRemoveTimer = false;

            gTimerId = g_timeout_add(100, &gTimer, null);
            _ = refreshLcd(null);
            var i: i32 = 1;
            while (gTime <= duration and (programRunStop == PGM_PAUSED or programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED)) {
                _ = g_main_context_iteration(g_main_context_default(), if (duration == 0) 0 else 1);
                if (gTime == i) {
                    i += 1;
                    if (previousProgramRunStop != PGM_RUNNING and programRunStop != PGM_PAUSED) {
                        screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
                        refreshScreen(12);
                        _ = refreshLcd(null);
                    }
                }
            }
            gRemoveTimer = true;
        }
    }
    if (programRunStop == PGM_WAITING) {
        previousProgramRunStop = PGM_WAITING;
    }
    programRunStop = previousProgramRunStop;
    if (programRunStop != PGM_RUNNING) {
        screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
        refreshScreen(13);
        if (comptime dmcp_build) {
            lcd_refresh();
        } else {
            _ = refreshLcd(null);
        }
    }
}

// ===========================================================================
// _getKeyArg (file static)
// ===========================================================================
fn getKeyArg(regist: u16) u16 {
    var arg: real34_t = undefined;

    switch (getRegisterDataType(@bitCast(regist))) {
        dtLongInteger => {
            convertLongIntegerRegisterToReal34(@bitCast(regist), &arg);
        },
        dtReal34 => {
            if (getRegisterAngularMode(@bitCast(regist)) == amNone) {
                real34ToIntegralValue(reg34(@bitCast(regist)), &arg, DEC_ROUND_DOWN);
            } else {
                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                if (comptime extra_info) {
                    _ = sprintf(errorMessage, "cannot use %s for the parameter of CASE", getRegisterDataTypeName(REGISTER_X, true, false));
                    moreInfoOnErr("In function _getKeyArg:", errorMessage);
                }
                return 0;
            }
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "cannot use %s for the parameter of CASE", getRegisterDataTypeName(REGISTER_X, true, false));
                moreInfoOnErr("In function _getKeyArg:", errorMessage);
            }
            return 0;
        },
    }

    if (real34CompareLessThan(&arg, const34_1)) {
        return 0;
    } else if (real34CompareGreaterEqual(&arg, const34_65535)) {
        return 65534;
    } else {
        return @intCast(real34ToUInt32(&arg));
    }
}

// ===========================================================================
// fnKey
// ===========================================================================
pub export fn fnKey(regist: u16) callconv(.c) void {
    if (lastKeyCode == 0) {
        temporaryInformation = TI_TRUE;
        if (comptime !dmcp_build) {
            while (gtk_events_pending() != 0) {
                _ = gtk_main_iteration();
            }
        } else {
            dmcpResetAutoOff();
            fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, if (programRunStop == PGM_RUNNING) PROGRAM_KB_ACTV else TO_KB_ACTV_MEDIUM);
        }
    } else {
        temporaryInformation = TI_FALSE;
        if (regist <= LAST_NAMED_VARIABLE) {
            var kc: longInteger_t = undefined;
            @"__gmpz_init"(&kc[0]);
            @"__gmpz_set_ui"(&kc[0], lastKeyCode);
            convertLongIntegerToLongIntegerRegister(&kc[0], @bitCast(regist));
            @"__gmpz_clear"(&kc[0]);
            lastKeyCode = 0;
        } else {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "register %u is out of range", @as(c_uint, regist));
                moreInfoOnErr("In function fnKey:", errorMessage);
            }
        }
    }
}

// ===========================================================================
// fnKeyType
// ===========================================================================
pub export fn fnKeyType(regist: u16) callconv(.c) void {
    const keyCode: u16 = getKeyArg(regist);
    var kt: longInteger_t = undefined;
    @"__gmpz_init"(&kt[0]);
    var ok = true;
    switch (keyCode) {
        82 => @"__gmpz_set_ui"(&kt[0], 0),
        72 => @"__gmpz_set_ui"(&kt[0], 1),
        73 => @"__gmpz_set_ui"(&kt[0], 2),
        74 => @"__gmpz_set_ui"(&kt[0], 3),
        62 => @"__gmpz_set_ui"(&kt[0], 4),
        63 => @"__gmpz_set_ui"(&kt[0], 5),
        64 => @"__gmpz_set_ui"(&kt[0], 6),
        52 => @"__gmpz_set_ui"(&kt[0], 7),
        53 => @"__gmpz_set_ui"(&kt[0], 8),
        54 => @"__gmpz_set_ui"(&kt[0], 9),
        43, 44, 83 => @"__gmpz_set_ui"(&kt[0], 10),
        // CALCMODEL != USER_R47 (CALCMODEL == USER_C47), so 35/36 -> 12, 71 -> 11.
        35, 36 => @"__gmpz_set_ui"(&kt[0], 12),
        71 => @"__gmpz_set_ui"(&kt[0], 11),
        11, 12, 13, 14, 15, 16 => @"__gmpz_set_ui"(&kt[0], 13),
        21, 22, 23, 24, 25, 26, 31, 32, 33, 34, 41, 42, 45, 51, 55, 61, 65, 75, 81, 84, 85 => @"__gmpz_set_ui"(&kt[0], 12),
        else => {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "keycode %u is out of range", @as(c_uint, keyCode));
                moreInfoOnErr("In function fnKeyType:", errorMessage);
            }
            @"__gmpz_clear"(&kt[0]);
            ok = false;
        },
    }
    if (!ok) return;
    liftStack();
    convertLongIntegerToLongIntegerRegister(&kt[0], REGISTER_X);
    @"__gmpz_clear"(&kt[0]);
}

// ===========================================================================
// fnPutKey
// ===========================================================================
pub export fn fnPutKey(regist: u16) callconv(.c) void {
    var kc: [4]u8 = undefined;
    const keyCode: u16 = getKeyArg(regist);

    programRunStop = PGM_WAITING;

    switch (keyCode) {
        11, 12, 13, 14, 15, 16 => {
            kc[0] = @intCast(keyCode - 10 + '0');
            kc[1] = 0;
            btnFnClicked(null, @ptrCast(&kc));
        },
        21, 22, 23, 24, 25, 26 => {
            _ = sprintf(&kc, "%02u", @as(c_uint, keyCode - 21 + 0));
            btnClicked(null, @ptrCast(&kc));
        },
        31, 32, 33, 34, 35, 36 => {
            _ = sprintf(&kc, "%02u", @as(c_uint, keyCode - 31 + 6));
            btnClicked(null, @ptrCast(&kc));
        },
        41, 42, 43, 44, 45 => {
            _ = sprintf(&kc, "%02u", @as(c_uint, keyCode - 41 + 12));
            btnClicked(null, @ptrCast(&kc));
        },
        51, 52, 53, 54, 55 => {
            _ = sprintf(&kc, "%02u", @as(c_uint, keyCode - 51 + 17));
            btnClicked(null, @ptrCast(&kc));
        },
        61, 62, 63, 64, 65 => {
            _ = sprintf(&kc, "%02u", @as(c_uint, keyCode - 61 + 22));
            btnClicked(null, @ptrCast(&kc));
        },
        71, 72, 73, 74, 75 => {
            _ = sprintf(&kc, "%02u", @as(c_uint, keyCode - 71 + 27));
            btnClicked(null, @ptrCast(&kc));
        },
        81, 82, 83, 84, 85 => {
            _ = sprintf(&kc, "%02u", @as(c_uint, keyCode - 81 + 32));
            btnClicked(null, @ptrCast(&kc));
        },
        else => {
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "keycode %u is out of range", @as(c_uint, keyCode));
                moreInfoOnErr("In function fnPutKey:", errorMessage);
            }
        },
    }

    programRunStop = PGM_WAITING;
}

// ===========================================================================
// fnEntryQ
// ===========================================================================
pub export fn fnEntryQ(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (entryStatus & 0x01 != 0) {
        temporaryInformation = TI_TRUE;
    } else {
        temporaryInformation = TI_FALSE;
    }
}

// btnFnClicked / btnClicked are GTK callbacks (host). fnPutKey is reached only on
// the host (it dispatches through the GTK button handlers); on firmware these are
// never referenced, but the C symbol is declared GtkWidget*/gpointer.
extern fn btnFnClicked(notUsed: ?*anyopaque, data: ?*anyopaque) void;
extern fn btnClicked(notUsed: ?*anyopaque, data: ?*anyopaque) void;
