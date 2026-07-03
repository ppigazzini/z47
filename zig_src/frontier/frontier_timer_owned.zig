// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/timer.c: the kb-timer subsystem and the STOPW timer
// application. Faithful, line-by-line port of the C.
//
// timer.c has fully distinct PC_BUILD and DMCP_BUILD bodies for getUptimeMs,
// _currentTime, refreshTimer (PC: gboolean refreshTimer(gpointer); DMCP: void
// refreshTimer(void)), fnTimerStart, fnTimerEndOfActivity, fnTimerDummy1 and
// fnUpdateTimerApp; all reproduced and gated on dmcp_build. The kb_timer_t
// layout itself differs (timer_will_expire is gint64 on PC, uint32_t on
// DMCP), as does timerLastCalled, and mutexRefreshTimer exists only on DMCP -
// modelled with comptime-selected types. On firmware the DMCP-ROM functions
// (sys_current_ms / rtc_read) are fixed-address jump-table calls (LIBRARY_FN_BASE
// + verified offset); on host the glib helpers (g_get_monotonic_time /
// g_get_real_time) are used, only referenced under !dmcp_build. calcModeNormalGui
// is a no-op macro on firmware (and would be on a keyboard-less sim) and a real
// extern on the GTK sim, so it is gated. DM42_POWERMARKS and
// SAVE_SPACE_DM42_20_TIMER are never defined for the frontier compile, matching
// a host build; those guarded bodies are kept (the !SAVE_SPACE bodies) /
// omitted (the powerMarkerMsF calls) accordingly.
//
// timer.c is not reachable from the testSuite; verification is by build/link
// across every target plus the boundary gates.

const std = @import("std");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const real34_t = abi.Real34;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const realContext_t = abi.RealContext;
const mp_limb_t = usize;
const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]mp_limb_t,
};
const longInteger_t = [1]mpz_struct;
const font_t = opaque {};
const TimerFn = ?*const fn (u16) callconv(.c) void;

// kb_timer_t: timer_will_expire is gint64 (i64) on PC, uint32_t on DMCP.
const ExpireT = if (dmcp_build) u32 else i64;
const kb_timer_t = extern struct {
    func: TimerFn,
    param: u16,
    timer_will_expire: ExpireT,
    state: u8,
};

// ---------------------------------------------------------------------------
// Constants / enum values (verified via C probe against the sim build)
// ---------------------------------------------------------------------------
const TMR_NUMBER: usize = 11;
const TMR_UNUSED: u8 = 0;
const TMR_STOPPED: u8 = 1;
const TMR_RUNNING: u8 = 2;
const TMR_COMPLETED: u8 = 3;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const ERR_REGISTER_LINE: calcRegister_t = 102;

const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_NONE: u8 = 0;

// decContext.h enum: CEILING=0, UP=1, HALF_UP=2, HALF_EVEN=3, HALF_DOWN=4,
// DOWN=5, FLOOR=6, 05UP=7.
const DEC_ROUND_HALF_EVEN: c_int = 3;
const DEC_ROUND_DOWN: c_int = 5;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtTime: u32 = 3;
const amNone: u32 = 5;

const CM_TIMER: u8 = 14;
const TO_TIMER_APP: u8 = 8;
const TIMER_APP_PERIOD: u32 = 100;
const TIMER_APP_STOPPED: u32 = 0xFFFFFFFF;
const NOPARAM: u16 = 9876;

const SCRUPD_AUTO: u8 = 0;
const SCRUPD_MANUAL_STATUSBAR: u8 = 1;
const SCRUPD_MANUAL_MENU: u8 = 4;

const SETTING_WATCHICON: i32 = 132;
const FLAG_RUNTIM: c_uint = 49168;
const SIGMA_PLUS: u16 = 1;
const SOFTMENU_STACK_SIZE: usize = 8;
const MNU_TIMERF: i16 = 1400;
const AIM_BUFFER_LENGTH: usize = 1024;
const Y_POSITION_OF_REGISTER_T_LINE: u32 = 24;
const Y_POSITION_OF_REGISTER_Z_LINE: u32 = 60;
const vmNormal: c_int = 0;

// constant blob offsets (constantPointers.h).
const OFF_const_3600: u32 = 5448;
const OFF_const34_1: u32 = 16312;

// ---------------------------------------------------------------------------
// softmenu / softmenuStack structs (typeDefinitions.h)
// ---------------------------------------------------------------------------
const softmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    softkeyItem: [*c]const i16,
};
const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};

// ---------------------------------------------------------------------------
// Globals (extern var)
// ---------------------------------------------------------------------------
extern var timeLastOp0: u32;
extern var timeLastOp1: u32;
extern var timeLastOp: u32;
extern var nextTimerRefresh: u32;
extern var skippedStackLines: bool_t;
extern var timerStartTime: u32;
extern var timerValue: u32;
extern var timerTotalTime: u32;
extern var timerCraAndDeciseconds: u8;
extern var rbr1stDigit: bool_t;
extern var watchIconEnabled: bool_t;
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var lastErrorCode: u8;
extern var programRunStop: u8;
extern var screenUpdatingMode: u8;
extern var errorMessage: [*c]u8;
extern var tmpString: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var statisticalSumsPointer: ?*real_t;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;
// `softmenu` is a C ARRAY (const softmenu_t softmenu[]); bind its address with
// @extern, not a pointer-typed extern (which loads the data as an address).
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t;
extern const standardFont: font_t;
extern const numericFont: font_t;

const constants = @extern([*]const u8, .{ .name = "constants" });
inline fn cst(offset: u32) *align(1) const real_t {
    return @ptrCast(constants + offset);
}
inline fn cst34(offset: u32) *align(1) const real34_t {
    return @ptrCast(constants + offset);
}
const const_3600 = cst(OFF_const_3600);
const const34_1 = cst34(OFF_const34_1);

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------
extern fn liftStack() void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn convertLongIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, ctxt: *realContext_t) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool_t, padWithBlanks: bool_t) [*c]const u8;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn refreshScreen(source: u16) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn clearRegister(regist: calcRegister_t) void;
extern fn clearRegisterLine(regist: calcRegister_t, clearTop: bool_t, clearBottom: bool_t) void;
extern fn fnStatSum(sum: u16) void;
extern fn fnSwapXY(unusedButMandatoryParameter: u16) void;
extern fn fnSigmaAddRem(plusMinus: u16) void;
extern fn fnBeep(unusedButMandatoryParameter: u16) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlagChanged(sf: i32) void;
extern fn showSoftmenu(id: i16) void;
extern fn popSoftmenu() void;
extern fn displayShiftAndTamBuffer() void;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: c_int, showLeadingCols: bool_t, showEndingCols: bool_t) u32;
extern fn realToUint32C47(r: *const real_t, err: ?*bool_t) u32;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strlen(s: [*c]const u8) usize;

// GMP.
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_set_ui"(p: *mpz_struct, v: c_ulong) void;
extern fn @"__gmpz_mul_ui"(r: *mpz_struct, op: *const mpz_struct, v: c_ulong) void;
extern fn @"__gmpz_add_ui"(r: *mpz_struct, op: *const mpz_struct, v: c_ulong) void;

// decNumber / decQuad behind the real* macros.
extern fn decNumberFromUInt32(r: *real_t, v: u32) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberGetBCD(src: *align(1) const real_t, bcd: [*c]u8) *real_t;
// decQuadToNumber/decQuadFromNumber are macros over decimal128ToNumber/From.
extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;
extern fn decimal128FromNumber(dst: *real34_t, src: *align(1) const real_t, ctx: *realContext_t) *real34_t;
extern fn decQuadAdd(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, real_context: *realContext_t) void;

// libc.
fn stpcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8 {
    var d = dst;
    var s = src;
    while (s[0] != 0) {
        d[0] = s[0];
        d += 1;
        s += 1;
    }
    d[0] = 0;
    return d;
}

// host-only glib externs (referenced under !dmcp_build).
extern fn g_get_monotonic_time() i64;
extern fn g_get_real_time() i64;

// host-only GUI extern (real fn on the GTK sim, no-op macro on firmware).
extern fn calcModeNormalGui() void;


// ---------------------------------------------------------------------------
// DMCP-ROM trampolines (fixed-address on firmware).
// ---------------------------------------------------------------------------
const gpointer = ?*anyopaque;
const tm_t = extern struct {
    hour: u8,
    min: u8,
    sec: u8,
    csec: u8,
    dow: u8,
};
const dt_t = extern struct {
    year: u16,
    month: u8,
    day: u8,
};
inline fn sys_current_ms() u32 {
    const f: *const fn () callconv(.c) u32 = @ptrFromInt(LIBRARY_FN_BASE + 524);
    return f();
}
inline fn rtc_read(tm: *tm_t, dt: *dt_t) void {
    const f: *const fn (*tm_t, *dt_t) callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 204);
    f(tm, dt);
}
// lcd_refresh is a fixed-address ROM call on firmware (LIBRARY_FN_BASE+48),
// only referenced under dmcp_build.
inline fn lcd_refresh() void {
    const f: *const fn () callconv(.c) void = @ptrFromInt(LIBRARY_FN_BASE + 48);
    f();
}
// refreshLcd is the same C symbol on both builds but with different signatures:
// DMCP `void refreshLcd(void)`, host `gboolean refreshLcd(gpointer)`. Bind it
// once with the signature matching the build being compiled.
const RefreshLcdFn = if (dmcp_build) *const fn () callconv(.c) void else *const fn (gpointer) callconv(.c) c_int;
const refreshLcd = @extern(RefreshLcdFn, .{ .name = "refreshLcd" });

// ---------------------------------------------------------------------------
// real* macro wrappers
// ---------------------------------------------------------------------------
inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn uInt32ToReal(source: u32, destination: *real_t) void {
    _ = decNumberFromUInt32(destination, source);
}
inline fn realMultiply(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realDivide(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realGetCoefficient(source: *align(1) const real_t, destination: [*c]u8) void {
    _ = decNumberGetBCD(source, destination);
}
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
inline fn realToReal34(source: *align(1) const real_t, destination: *real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}
inline fn real34Add(o1: *align(1) const real34_t, o2: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadAdd(res, o1, o2, &ctxtReal34);
}
inline fn longIntegerInit(op: *mpz_struct) void {
    @"__gmpz_init"(op);
}
inline fn longIntegerFree(op: *mpz_struct) void {
    @"__gmpz_clear"(op);
}
inline fn uInt32ToLongInteger(source: u32, destination: *mpz_struct) void {
    @"__gmpz_set_ui"(destination, source);
}
inline fn longIntegerMultiplyUInt(op: *const mpz_struct, uint: u32, result: *mpz_struct) void {
    @"__gmpz_mul_ui"(result, op, uint);
}
inline fn longIntegerAddUInt(op: *const mpz_struct, uint: u32, result: *mpz_struct) void {
    @"__gmpz_add_ui"(result, op, uint);
}
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn moreInfoOnErr(where: [*:0]const u8, hint: [*:0]const u8) void {
    if (comptime extra_info) {
        moreInfoOnError(where, hint, null, null);
    }
}

// ---------------------------------------------------------------------------
// Globals defined by timer.c
// ---------------------------------------------------------------------------
// C `kb_timer_t timer[TMR_NUMBER]` is a .bss global -> ZERO-initialized, so every
// slot starts state=TMR_UNUSED(0). `= undefined` left garbage: refreshTimerPc
// calls timer[i].func.?(…) whenever state==TMR_RUNNING(2), so a garbage state of 2
// would invoke a garbage func pointer (heap-layout-dependent crash). Match C.
pub export var timer: [TMR_NUMBER]kb_timer_t = std.mem.zeroes([TMR_NUMBER]kb_timer_t);
pub export var timerLastCalled: if (dmcp_build) u32 else i64 = 0;

comptime {
    if (dmcp_build) {
        @export(&mutexRefreshTimer, .{ .name = "mutexRefreshTimer", .linkage = .strong });
    }
}
var mutexRefreshTimer: bool_t = false;

pub export var remainingMsecCountdown: u32 = 0;

// ===========================================================================
// getUptimeMs
// ===========================================================================
pub export fn getUptimeMs() callconv(.c) u32 {
    if (comptime dmcp_build) {
        return sys_current_ms();
    } else {
        return @intCast(@divTrunc(g_get_monotonic_time(), 1000));
    }
}

// ===========================================================================
// fnTicks
// ===========================================================================
pub export fn fnTicks(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const tim: u32 = getUptimeMs() / 100;

    var lgInt: longInteger_t = undefined;
    liftStack();
    longIntegerInit(&lgInt[0]);
    uInt32ToLongInteger(tim, &lgInt[0]);
    convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
    longIntegerFree(&lgInt[0]);
}

// ===========================================================================
// LastOpTimerReStart
// ===========================================================================
pub export fn LastOpTimerReStart(func: u16) callconv(.c) void {
    _ = func;
    timeLastOp0 = getUptimeMs() / 100;
}

// ===========================================================================
// LastOpTimerLap
// ===========================================================================
pub export fn LastOpTimerLap(func: u16) callconv(.c) void {
    _ = func;
    timeLastOp1 = getUptimeMs() / 100;
    if (timeLastOp1 >= timeLastOp0) {
        timeLastOp = timeLastOp1 - timeLastOp0;
    } else {
        // C: ((int)(0xFFFFFFFF) / 100 - timeLastOp0) + timeLastOp1.
        // (int)0xFFFFFFFF == -1 and -1/100 == 0 (C truncation toward zero), so
        // the int term is 0; the mixed int/uint32 arithmetic wraps in u32.
        timeLastOp = (0 -% timeLastOp0) +% timeLastOp1;
    }
    if (timeLastOp > 30 * 24 * 60 * 60 * 10) {
        timeLastOp = 0;
    }
}

// ===========================================================================
// fnLastT
// ===========================================================================
pub export fn fnLastT(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var lgInt: longInteger_t = undefined;
    liftStack();
    longIntegerInit(&lgInt[0]);
    uInt32ToLongInteger(timeLastOp, &lgInt[0]);
    convertLongIntegerToLongIntegerRegister(&lgInt[0], REGISTER_X);
    longIntegerFree(&lgInt[0]);
}

// ===========================================================================
// fnRebuildTimerRefresh (DMCP body; no-op on host)
// ===========================================================================
pub export fn fnRebuildTimerRefresh() callconv(.c) void {
    if (comptime dmcp_build) {
        if (mutexRefreshTimer == false) {
            nextTimerRefresh = 0;
            var i: usize = 0;
            while (i < TMR_NUMBER) : (i += 1) {
                if (timer[i].state == TMR_RUNNING) {
                    const next: u32 = timer[i].timer_will_expire;
                    if (nextTimerRefresh != 0 and next < nextTimerRefresh) {
                        nextTimerRefresh = next;
                    }
                    if (nextTimerRefresh == 0) {
                        nextTimerRefresh = next;
                    }
                }
            }
        }
    }
}

// ===========================================================================
// refreshTimer (PC: gboolean refreshTimer(gpointer); DMCP: void refreshTimer(void))
// ===========================================================================
fn refreshTimerPc(data: gpointer) callconv(.c) c_int {
    _ = data;
    const now: i64 = g_get_monotonic_time();
    if (now < timerLastCalled) {
        var i: usize = 0;
        while (i < TMR_NUMBER) : (i += 1) {
            if (timer[i].state == TMR_RUNNING) {
                timer[i].state = TMR_COMPLETED;
                timer[i].func.?(timer[i].param);
            }
        }
    } else {
        var i: usize = 0;
        while (i < TMR_NUMBER) : (i += 1) {
            if (timer[i].state == TMR_RUNNING) {
                if (timer[i].timer_will_expire <= now) {
                    timer[i].state = TMR_COMPLETED;
                    timer[i].func.?(timer[i].param);
                }
            }
        }
    }
    timerLastCalled = now;
    return 1; // TRUE
}

fn refreshTimerDmcp() callconv(.c) void {
    const now: u32 = sys_current_ms();
    if (now < timerLastCalled) {
        var i: usize = 0;
        while (i < TMR_NUMBER) : (i += 1) {
            if (timer[i].state == TMR_RUNNING) {
                timer[i].state = TMR_COMPLETED;
                mutexRefreshTimer = true;
                timer[i].func.?(timer[i].param);
                mutexRefreshTimer = false;
            }
        }
    } else {
        var i: usize = 0;
        while (i < TMR_NUMBER) : (i += 1) {
            if (timer[i].state == TMR_RUNNING) {
                if (timer[i].timer_will_expire <= now) {
                    timer[i].state = TMR_COMPLETED;
                    mutexRefreshTimer = true;
                    timer[i].func.?(timer[i].param);
                    mutexRefreshTimer = false;
                }
            }
        }
    }
    timerLastCalled = now;
    fnRebuildTimerRefresh();
}

comptime {
    @export(if (dmcp_build) &refreshTimerDmcp else &refreshTimerPc, .{ .name = "refreshTimer", .linkage = .strong });
}

// ===========================================================================
// fnTimerDummy1
// ===========================================================================
pub export fn fnTimerDummy1(param: u16) callconv(.c) void {
    if (comptime !dmcp_build) {
        _ = printf("fnTimerDummy1 called  %u\n", @as(c_uint, param));
    }
}

// ===========================================================================
// fnTimerEndOfActivity
// ===========================================================================
pub export fn fnTimerEndOfActivity(param: u16) callconv(.c) void {
    if (comptime !dmcp_build) {
        _ = printf("fnTimerEndOfActivity called  %u\n", @as(c_uint, param));
    } else {
        // DM42_POWERMARKS never defined for the frontier compile.
        if (skippedStackLines) {
            screenUpdatingMode = SCRUPD_AUTO | SCRUPD_MANUAL_MENU;
            skippedStackLines = false;
            refreshScreen(32);
        }
    }
}

// ===========================================================================
// fnTimerReset
// ===========================================================================
pub export fn fnTimerReset() callconv(.c) void {
    timerLastCalled = 0;
    var i: usize = 0;
    while (i < TMR_NUMBER) : (i += 1) {
        timer[i].state = TMR_UNUSED;
        timer[i].func = &fnTimerDummy1;
        timer[i].param = 0;
    }
    if (comptime dmcp_build) {
        mutexRefreshTimer = false;
    }
    fnRebuildTimerRefresh();
}

// ===========================================================================
// fnTimerConfig
// ===========================================================================
pub export fn fnTimerConfig(nr: u8, func: TimerFn, param: u16) callconv(.c) void {
    if (nr < TMR_NUMBER) {
        timer[nr].func = func;
        timer[nr].param = param;
        timer[nr].state = TMR_STOPPED;
    }
    fnRebuildTimerRefresh();
}

// ===========================================================================
// fnTimerStart (NOTE: the runtime extern fnTimerStart symbol is THIS definition)
// ===========================================================================
pub export fn fnTimerStartImpl(nr: u8, param: u16, time: u32) callconv(.c) void {
    if (comptime dmcp_build) {
        const now: u32 = sys_current_ms();
        if (nr < TMR_NUMBER) {
            timer[nr].param = param;
            timer[nr].timer_will_expire = now +% time;
            timer[nr].state = TMR_RUNNING;
        }
    } else {
        const now: i64 = g_get_monotonic_time();
        if (nr < TMR_NUMBER) {
            timer[nr].param = param;
            timer[nr].timer_will_expire = now + @as(i64, time) * 1000;
            if (timer[nr].timer_will_expire < 0) {
                timer[nr].timer_will_expire = @as(i64, time) * 1000;
            }
            timer[nr].state = TMR_RUNNING;
        }
    }
    fnRebuildTimerRefresh();
}

comptime {
    @export(&fnTimerStartImpl, .{ .name = "fnTimerStart", .linkage = .strong });
}

// ===========================================================================
// fnTimerStop
// ===========================================================================
pub export fn fnTimerStop(nr: u8) callconv(.c) void {
    if (nr < TMR_NUMBER and timer[nr].state != TMR_UNUSED) {
        timer[nr].state = TMR_STOPPED;
    }
    fnRebuildTimerRefresh();
}

// ===========================================================================
// fnTimerExec
// ===========================================================================
pub export fn fnTimerExec(nr: u8) callconv(.c) void {
    if (nr < TMR_NUMBER and timer[nr].state == TMR_RUNNING) {
        timer[nr].state = TMR_COMPLETED;
        timer[nr].func.?(timer[nr].param);
    }
}

// ===========================================================================
// fnTimerDel
// ===========================================================================
pub export fn fnTimerDel(nr: u8) callconv(.c) void {
    if (nr < TMR_NUMBER) {
        timer[nr].state = TMR_UNUSED;
    }
    fnRebuildTimerRefresh();
}

// ===========================================================================
// fnTimerGetParam
// ===========================================================================
pub export fn fnTimerGetParam(nr: u8) callconv(.c) u16 {
    var result: u16 = 0;
    if (nr < TMR_NUMBER) {
        result = timer[nr].param;
    }
    return result;
}

// ===========================================================================
// fnTimerGetStatus
// ===========================================================================
pub export fn fnTimerGetStatus(nr: u8) callconv(.c) u8 {
    var result: u8 = TMR_UNUSED;
    if (nr < TMR_NUMBER) {
        result = timer[nr].state;
    }
    return result;
}

// ===========================================================================
// Timer application
// ===========================================================================
fn currentTime() u32 {
    if (comptime dmcp_build) {
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;
        rtc_read(&timeInfo, &dateInfo);
        return @as(u32, timeInfo.hour) * 3600000 +
            @as(u32, timeInfo.min) * 60000 +
            @as(u32, timeInfo.sec) * 1000 +
            @as(u32, timeInfo.csec) * 10;
    } else {
        return @intCast(@divTrunc(@mod(g_get_real_time(), 86400000000), 1000));
    }
}

fn antirewinder(currTime: u32) void {
    if (currTime < timerStartTime) {
        timerValue += 86400000 - timerStartTime;
        if (timerTotalTime > 0) {
            timerTotalTime += 86400000 - timerStartTime;
        }
        timerStartTime = 0;
    } else if (currTime >= timerStartTime + 3600000) {
        timerValue += 3600000;
        if (timerTotalTime > 0) {
            timerTotalTime += 3600000;
        }
        timerStartTime += 3600000;
    }
}

fn getTimerValue() u32 {
    const currTime: u32 = currentTime();
    if (timerStartTime == TIMER_APP_STOPPED) {
        return timerValue;
    }
    antirewinder(currTime);
    return currTime - timerStartTime + timerValue;
}

// ===========================================================================
// fnItemTimerApp
// ===========================================================================
pub export fn fnItemTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    calcMode = CM_TIMER;
    rbr1stDigit = true;
    if (timerStartTime != TIMER_APP_STOPPED) {
        fnTimerStartImpl(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
    }
}

// ===========================================================================
// fnDecisecondTimerApp
// ===========================================================================
pub export fn fnDecisecondTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    timerCraAndDeciseconds ^= 0x80;
}

// ===========================================================================
// _realToUInt32 (file static)
// ===========================================================================
fn realToUInt32(re: *const real_t, mode: c_int, value32: *u32, overflow: *bool_t) void {
    var bcd: [76]u8 = undefined;
    var real: real_t = undefined;
    var lgInt: longInteger_t = undefined;

    realToIntegralValue(re, &real, mode, &ctxtReal75);
    const sign: u8 = real.bits & 0x80;
    realGetCoefficient(&real, &bcd);

    longIntegerInit(&lgInt[0]);
    uInt32ToLongInteger(bcd[0], &lgInt[0]);

    var i: i32 = 1;
    while (i < real.digits) : (i += 1) {
        longIntegerMultiplyUInt(&lgInt[0], 10, &lgInt[0]);
        longIntegerAddUInt(&lgInt[0], bcd[@intCast(i)], &lgInt[0]);
    }

    while (real.exponent > 0) {
        longIntegerMultiplyUInt(&lgInt[0], 10, &lgInt[0]);
        real.exponent -= 1;
    }

    overflow.* = false;

    // Upstream splits on the GMP limb width: OS32BIT (32-bit limbs, e.g. the
    // DM42 thumb firmware) vs OS64BIT (64-bit limbs, host/sim/DMCP5). mp_limb_t
    // = usize, so @bitSizeOf selects the matching branch at comptime.
    if (@bitSizeOf(mp_limb_t) == 32) { // OS32BIT
        value32.* = if (lgInt[0]._mp_size == 0) 0 else @truncate(lgInt[0]._mp_d[0]);
        if (sign != 0 or lgInt[0]._mp_size > 1) {
            overflow.* = true;
        }
    } else { // OS64BIT
        value32.* = if (lgInt[0]._mp_size == 0) 0 else @truncate(lgInt[0]._mp_d[0] & 0x00000000ffffffff);
        if (sign != 0 or lgInt[0]._mp_size > 1 or (lgInt[0]._mp_d[0] & 0xffffffff00000000) != 0) {
            overflow.* = true;
        }
    }

    longIntegerFree(&lgInt[0]);
}

// ===========================================================================
// inputHelper
// ===========================================================================
pub export fn inputHelper(regist: u16, val: *u32, overflow: *bool_t) callconv(.c) bool_t {
    var tmp: real_t = undefined;

    switch (getRegisterDataType(@bitCast(regist))) {
        dtTime => {
            real34ToReal(reg34(@bitCast(regist)), &tmp);
            tmp.exponent += 3;
            realToUInt32(&tmp, DEC_ROUND_DOWN, val, overflow);
        },
        dtReal34 => {
            real34ToReal(reg34(@bitCast(regist)), &tmp);
            realMultiply(&tmp, const_3600, &tmp, &ctxtReal39);
            tmp.exponent += 3;
            realToUInt32(&tmp, DEC_ROUND_HALF_EVEN, val, overflow);
        },
        dtLongInteger => {
            convertLongIntegerRegisterToReal(@bitCast(regist), &tmp, &ctxtReal39);
            realMultiply(&tmp, const_3600, &tmp, &ctxtReal39);
            tmp.exponent += 3;
            realToUInt32(&tmp, DEC_ROUND_HALF_EVEN, val, overflow);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) {
                _ = sprintf(errorMessage, "cannot recall %s to the stopwatch", getRegisterDataTypeName(@bitCast(regist), true, false));
                moreInfoOnErr("In function inputHelper:", errorMessage);
            }
            return false;
        },
    }
    return true;
}

// ===========================================================================
// fnSetCountDownTimerApp
// ===========================================================================
pub export fn fnSetCountDownTimerApp(regist: u16) callconv(.c) void {
    var overflow: bool_t = undefined;
    var input: u32 = undefined;
    if (!inputHelper(regist, &input, &overflow)) {
        return;
    }
    if (overflow) {
        remainingMsecCountdown = 0;
    } else {
        fnResetTimerApp(NOPARAM);
        fnStopTimerApp();
        remainingMsecCountdown = input;
    }
}

// ===========================================================================
// fnResetTimerApp
// ===========================================================================
pub export fn fnResetTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    timerValue = 0;
    timerTotalTime = 0;
    remainingMsecCountdown = 0;
    if (timerStartTime != TIMER_APP_STOPPED) {
        timerStartTime = currentTime();
        fnTimerStartImpl(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
    }
    rbr1stDigit = true;
}

// ===========================================================================
// fnStartStopTimerApp
// ===========================================================================
pub export fn fnStartStopTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (timerStartTime == TIMER_APP_STOPPED) {
        setSystemFlag(FLAG_RUNTIM);
        timerStartTime = currentTime();
        fnTimerStartImpl(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
    } else {
        fnStopTimerApp();
    }
    rbr1stDigit = true;
}

// ===========================================================================
// fnStopTimerApp
// ===========================================================================
pub export fn fnStopTimerApp() callconv(.c) void {
    if (timerStartTime != TIMER_APP_STOPPED) {
        const msec: u32 = currentTime();
        timerValue += msec - timerStartTime;
        if (timerTotalTime > 0) {
            timerTotalTime += msec - timerStartTime;
        }
        timerStartTime = TIMER_APP_STOPPED;
        fnTimerStop(TO_TIMER_APP);
    }
    clearSystemFlag(FLAG_RUNTIM);
    if (watchIconEnabled) {
        setSystemFlagChanged(SETTING_WATCHICON);
        watchIconEnabled = false;
    }
}

// ===========================================================================
// fnShowTimerApp
// ===========================================================================
pub export fn fnShowTimerApp() callconv(.c) void {
    if (calcMode == CM_TIMER) {
        const msec: u32 = getTimerValue();
        clearRegisterLine(REGISTER_T, true, true);

        var remainingMsec: i64 = 0;
        if (remainingMsecCountdown > 0) {
            remainingMsec = @as(i64, remainingMsecCountdown) - @as(i64, msec);
            clearRegisterLine(REGISTER_Z, true, true);
        }

        tmpString[0] = 0;

        if (timerTotalTime > 0) {
            const tmsec: u32 = msec - timerValue + timerTotalTime;

            if (remainingMsecCountdown > 0) {
                remainingMsec = @as(i64, remainingMsecCountdown) - @as(i64, tmsec);
            }

            if ((timerCraAndDeciseconds & 0x80) != 0) {
                _ = sprintf(tmpString, "%2u:%02u:%02u.%u" ++ STD_SUP_BOLD_T ++ "  ", tmsec / 3600000, tmsec % 3600000 / 60000, tmsec % 60000 / 1000, tmsec % 1000 / 100);
            } else {
                _ = sprintf(tmpString, "%2u:%02u:%02u" ++ STD_SUP_BOLD_T ++ STD_SPACE_PUNCTUATION ++ STD_SPACE_FIGURE ++ "  ", tmsec / 3600000, tmsec % 3600000 / 60000, tmsec % 60000 / 1000);
            }
        }

        if ((timerCraAndDeciseconds & 0x80) != 0) {
            _ = sprintf(tmpString + strlen(tmpString), "%2u:%02u:%02u.%u ", msec / 3600000, msec % 3600000 / 60000, msec % 60000 / 1000, msec % 1000 / 100);
        } else {
            _ = sprintf(tmpString + strlen(tmpString), "%2u:%02u:%02u" ++ STD_SPACE_PUNCTUATION ++ STD_SPACE_FIGURE ++ " ", msec / 3600000, msec % 3600000 / 60000, msec % 60000 / 1000);
        }

        if (rbr1stDigit) {
            _ = sprintf(tmpString + strlen(tmpString), "[%02u]", @as(u32, timerCraAndDeciseconds & 0x7f));
        } else if (aimBuffer[AIM_BUFFER_LENGTH / 2] == 0) {
            _ = sprintf(tmpString + strlen(tmpString), "[" ++ STD_CURSOR ++ STD_SPACE_FIGURE ++ "]");
        } else {
            _ = sprintf(tmpString + strlen(tmpString), "[%d" ++ STD_CURSOR ++ "]", @as(i32, aimBuffer[AIM_BUFFER_LENGTH / 2]) - '0');
        }
        _ = showString(tmpString, &numericFont, 1, Y_POSITION_OF_REGISTER_T_LINE, vmNormal, true, true);

        if (remainingMsecCountdown > 0) {
            if (remainingMsec > 0) {
                tmpString[0] = 0;
                if ((timerCraAndDeciseconds & 0x80) != 0) {
                    _ = sprintf(tmpString, "%2u:%02u:%02u.%u" ++ STD_HOURGLASS_WH ++ "  ", @as(u32, @intCast(remainingMsec)) / 3600000, @as(u32, @intCast(remainingMsec)) % 3600000 / 60000, @as(u32, @intCast(remainingMsec)) % 60000 / 1000, @as(u32, @intCast(remainingMsec)) % 1000 / 100);
                } else {
                    _ = sprintf(tmpString, "%2u:%02u:%02u" ++ STD_HOURGLASS_WH ++ STD_SPACE_PUNCTUATION ++ STD_SPACE_FIGURE ++ "  ", @as(u32, @intCast(remainingMsec)) / 3600000, @as(u32, @intCast(remainingMsec)) % 3600000 / 60000, @as(u32, @intCast(remainingMsec)) % 60000 / 1000);
                }
                _ = showString(tmpString, &numericFont, 1, Y_POSITION_OF_REGISTER_Z_LINE, vmNormal, true, true);
            } else if (remainingMsec < 0) {
                remainingMsec = 0;
                remainingMsecCountdown = 0;
                fnBeep(NOPARAM);
            }
        }

        var timerMenu: bool_t = false;
        var i: usize = 0;
        while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
            if (softmenu[@intCast(softmenuStack[i].softmenuId)].menuItem == -MNU_TIMERF) {
                timerMenu = true;
                break;
            }
        }
        if (!timerMenu) {
            showSoftmenu(-MNU_TIMERF);
        }
        if (softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_TIMERF) {
            if (comptime !dmcp_build) {
                calcModeNormalGui();
            }
        }
    }
}

// ===========================================================================
// fnUpdateTimerApp
// ===========================================================================
pub export fn fnUpdateTimerApp() callconv(.c) void {
    if (calcMode == CM_TIMER) {
        fnShowTimerApp();
        displayShiftAndTamBuffer();
        if (comptime dmcp_build) {
            refreshLcd();
            lcd_refresh();
        } else {
            _ = refreshLcd(null);
        }
    }
}

// ===========================================================================
// fnRegAddTimerApp (ENTER)
// ===========================================================================
pub export fn fnRegAddTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _ = printf("fnRegAddTimerApp\n");
    if (rbr1stDigit) {
        var tmp: real_t = undefined;
        uInt32ToReal(getTimerValue() / 100, &tmp);
        tmp.exponent -= 1;
        reallocateRegister(timerCraAndDeciseconds & 0x7f, dtTime, 0, amNone);
        realToReal34(&tmp, reg34(@as(calcRegister_t, timerCraAndDeciseconds & 0x7f)));
        fnUpTimerApp();
    } else if (aimBuffer[AIM_BUFFER_LENGTH / 2] == 0) {
        rbr1stDigit = true;
    } else {
        timerCraAndDeciseconds = (timerCraAndDeciseconds & 0x80) + @as(u8, @intCast(aimBuffer[AIM_BUFFER_LENGTH / 2] - '0'));
        rbr1stDigit = true;
    }
}

// ===========================================================================
// fnRegAddLapTimerApp (dot)
// ===========================================================================
pub export fn fnRegAddLapTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _ = printf("fnRegAddLapTimerApp\n");
    const msec: u32 = getTimerValue();
    var tmp: real_t = undefined;

    uInt32ToReal(msec / 100, &tmp);
    tmp.exponent -= 1;
    reallocateRegister(timerCraAndDeciseconds & 0x7f, dtTime, 0, amNone);
    realToReal34(&tmp, reg34(@as(calcRegister_t, timerCraAndDeciseconds & 0x7f)));

    fnUpTimerApp();

    if (timerTotalTime > 0) {
        timerTotalTime += msec - timerValue;
    } else {
        timerTotalTime = msec;
    }
    timerValue = 0;
    if (timerStartTime != TIMER_APP_STOPPED) {
        timerStartTime = currentTime();
        fnTimerStartImpl(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
    }
}

// ===========================================================================
// fnAddTimerApp (Send TIM to STATS)
// ===========================================================================
pub export fn fnAddTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _ = printf("fnAddTimerApp\n");
    var tmp: real_t = undefined;

    uInt32ToReal(getTimerValue() / 100, &tmp);
    tmp.exponent -= 1;
    realDivide(&tmp, const_3600, &tmp, &ctxtReal39);

    fnStatSum(0);
    if (lastErrorCode != ERROR_NONE) {
        liftStack();
        clearRegister(REGISTER_X);
        lastErrorCode = ERROR_NONE;
    }
    real34Add(reg34(REGISTER_X), const34_1, reg34(REGISTER_X));
    liftStack();
    realToReal34(&tmp, reg34(REGISTER_X));
    fnSwapXY(NOPARAM);
    fnSigmaAddRem(SIGMA_PLUS);

    refreshScreen(30);
}

// ===========================================================================
// fnAddLapTimerApp
// ===========================================================================
pub export fn fnAddLapTimerApp(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    _ = printf("fnAddLapTimerApp\n");
    const msec: u32 = getTimerValue();
    var tmp: real_t = undefined;

    uInt32ToReal(msec / 100, &tmp);
    tmp.exponent -= 1;
    realDivide(&tmp, const_3600, &tmp, &ctxtReal39);

    fnStatSum(0);
    if (lastErrorCode != ERROR_NONE) {
        liftStack();
        clearRegister(REGISTER_X);
        lastErrorCode = ERROR_NONE;
    }
    real34Add(reg34(REGISTER_X), const34_1, reg34(REGISTER_X));
    liftStack();
    realToReal34(&tmp, reg34(REGISTER_X));
    fnSwapXY(NOPARAM);
    fnSigmaAddRem(SIGMA_PLUS);

    if (timerTotalTime > 0) {
        timerTotalTime += msec - timerValue;
    } else {
        timerTotalTime = msec;
    }
    timerValue = 0;
    if (timerStartTime != TIMER_APP_STOPPED) {
        timerStartTime = currentTime();
        fnTimerStartImpl(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
    }

    refreshScreen(31);
}

// ===========================================================================
// fnUpTimerApp
// ===========================================================================
pub export fn fnUpTimerApp() callconv(.c) void {
    if ((timerCraAndDeciseconds & 0x7f) >= 99) {
        timerCraAndDeciseconds &= 0x80;
    } else {
        timerCraAndDeciseconds +%= 1;
    }
    rbr1stDigit = true;
}

// ===========================================================================
// fnDownTimerApp
// ===========================================================================
pub export fn fnDownTimerApp() callconv(.c) void {
    if ((timerCraAndDeciseconds & 0x7f) == 0) {
        timerCraAndDeciseconds |= 99;
    } else {
        timerCraAndDeciseconds -%= 1;
    }
    rbr1stDigit = true;
}

// ===========================================================================
// fnDigitKeyTimerApp
// ===========================================================================
pub export fn fnDigitKeyTimerApp(digit: u16) callconv(.c) void {
    if (rbr1stDigit or aimBuffer[AIM_BUFFER_LENGTH / 2] == 0) {
        aimBuffer[AIM_BUFFER_LENGTH / 2] = @intCast(digit + '0');
        aimBuffer[AIM_BUFFER_LENGTH / 2 + 1] = 0;
        rbr1stDigit = false;
    } else {
        timerCraAndDeciseconds = (timerCraAndDeciseconds & 0x80) + @as(u8, @intCast(aimBuffer[AIM_BUFFER_LENGTH / 2] - '0')) * 10 + @as(u8, @intCast(digit));
        rbr1stDigit = true;
    }
}

// ===========================================================================
// fnRecallTimerApp
// ===========================================================================
pub export fn fnRecallTimerApp(regist: u16) callconv(.c) void {
    var overflow: bool_t = undefined;
    var val: u32 = undefined;
    if (!inputHelper(regist, &val, &overflow)) {
        return;
    }
    if (overflow) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            _ = sprintf(errorMessage, "the %s does not fit to uint32_t", getRegisterDataTypeName(@bitCast(regist), true, false));
            moreInfoOnErr("In function fnRecallTimerApp:", errorMessage);
        }
    } else {
        timerValue = val;
        if (timerStartTime != TIMER_APP_STOPPED) {
            timerStartTime = currentTime();
            fnTimerStartImpl(TO_TIMER_APP, TO_TIMER_APP, TIMER_APP_PERIOD);
        }
    }
}

// ===========================================================================
// fnBackspaceTimerApp
// ===========================================================================
pub export fn fnBackspaceTimerApp() callconv(.c) void {
    if (rbr1stDigit) {
        fnResetTimerApp(NOPARAM);
    } else if (aimBuffer[AIM_BUFFER_LENGTH / 2] == 0) {
        rbr1stDigit = true;
    } else {
        aimBuffer[AIM_BUFFER_LENGTH / 2] = 0;
    }
}

// ===========================================================================
// fnLeaveTimerApp
// ===========================================================================
pub export fn fnLeaveTimerApp() callconv(.c) void {
    popSoftmenu();
    rbr1stDigit = true;
    calcMode = previousCalcMode;
    if (watchIconEnabled != (timerStartTime != TIMER_APP_STOPPED)) {
        setSystemFlagChanged(SETTING_WATCHICON);
        watchIconEnabled = !watchIconEnabled;
    }
}

// ===========================================================================
// fnPollTimerApp
// ===========================================================================
pub export fn fnPollTimerApp() callconv(.c) void {
    if (calcMode != CM_TIMER and timerStartTime != TIMER_APP_STOPPED) {
        antirewinder(currentTime());
    }
}

// STD_* byte sequences (fonts.h) used by fnShowTimerApp's sprintf format strings
// (verified via C probe against the sim build).
const STD_SUP_BOLD_T = "\x9d\x40";
const STD_SPACE_PUNCTUATION = "\xa0\x08";
const STD_SPACE_FIGURE = "\xa0\x07";
const STD_CURSOR = "\xa4\x27";
const STD_HOURGLASS_WH = "\xa9\xd6";

extern fn printf(fmt: [*:0]const u8, ...) c_int;
