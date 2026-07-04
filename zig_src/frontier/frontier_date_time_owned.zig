// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/dateTime.c: the date/time layer. It hosts Julian-day
// composition/decomposition (composeJulianDay/decomposeJulianDay and the
// Gregorian/Julian halves), leap-year/valid-day checks, the day-of-week and
// week-of-year computations, the date/time fn* commands, the RTC date/time
// get/set, and the date/time display-string formatters. It is exercised by the
// testSuite (dToJ, jToDT, dtToJ, dateTo, toDate, xToDate, day/month/year/wday,
// HMStoTM, HRtoTM, addition_date, isLeap...), so correctness is verified by
// `zig build test`.
//
// This is a faithful, line-by-line port of the C. It re-declares the shared
// patterns from the registerValueConversions owner (the constants blob with
// cst34()/cstR() align(1) helpers, the real34/real op wrappers, reg34(), the
// dt_t/tm_t structs, the fixed-address RTC SDK idiom, extra_info-gated
// moreInfoOnError) — that owner is a sibling whose private decls cannot be
// imported, so they are repeated here with identical definitions.
//
// The helpers composeJulianDay/decomposeJulianDay/isValidDay/internalDateToJulianDay
// are exported with C linkage and exact ABI because the registerValueConversions
// owner imports them as externs.

const builtin = @import("builtin");
const std = @import("std");
const frontier_build_options = @import("frontier_build_options");

// Cold date/time code (interactive, infrequent) runs from executable QSPI on
// the flash-limited old_hw DM42 (XIP), keeping pkg1 main FLASH free for
// always-on owners. Host/dmcp5/macos use the normal section (no-op there).
const code_section = if (frontier_build_options.dmcp_build and frontier_build_options.old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const dmcp_build: bool = frontier_build_options.dmcp_build;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const calcRegister_t = i16;
const angularMode_t = c_int;

// GMP mpz_struct. The limb width == pointer width on every z47 target (64-bit on
// Linux and Win64, 32-bit on ARM32 firmware) — NOT c_ulong, which is 32-bit on Win64.
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;

// ---------------------------------------------------------------------------
// Constants / enum values
// ---------------------------------------------------------------------------
const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtTime: u32 = 3;
const dtDate: u32 = 4;

const amNone: angularMode_t = 5;
const amAngleMask: u32 = 15;
const amNoneU: u32 = @bitCast(amNone);

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
const TEMP_REGISTER_1: calcRegister_t = 135;

const REAL34_SIZE_IN_BLOCKS: u16 = 4;

const ERROR_NONE: u8 = 0;
const ERROR_BAD_TIME_OR_DATE_INPUT: u8 = 2;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

const DEC_ROUND_HALF_UP: c_int = 2;
const DEC_ROUND_DOWN: c_int = 5;
const DEC_ROUND_FLOOR: c_int = 6;

const FLAG_TDM24: c_int = 0x8000;
const FLAG_YMD: c_int = 0xc001;
const FLAG_DMY: c_int = 0xc002;
const FLAG_MDY: c_int = 0xc003;
const FLAG_ASLIFT: c_uint = 0xc023;

const ITM_DMY: u16 = 1453;
const ITM_MDY: u16 = 1528;
const ITM_YMD: u16 = 1649;
const ITM_HRtoTM: i16 = 1686;
const ITM_JUL_GREG_1582: u16 = 2147;
const ITM_JUL_GREG_1752: u16 = 2148;
const ITM_JUL_GREG_1873: u16 = 2149;
const ITM_JUL_GREG_1949: u16 = 2150;
const ITM_WOY_ISO: u16 = 2501;
const ITM_WOY_US: u16 = 2502;
const ITM_WOY_ME: u16 = 2503;
const NOPARAM: u16 = 9876;

const YY_TRACKING: u16 = 1;
const YY_OFF: u16 = 2;
const YY_MASK_TRACKING: u16 = 0x4000;
const YY_MASK_OFF: u16 = 0x8000;

const TI_FALSE: u8 = 12;
const TI_DAY_OF_WEEK: u8 = 36;
const TI_DISP_JULIAN: u8 = 83;
const TI_DISP_WOY: u8 = 118;
const TI_WOY: u8 = 120;
const TI_WOY_RULE: u8 = 121;

const CM_NIM: u8 = 2;

// ---------------------------------------------------------------------------
// Constant blob
// ---------------------------------------------------------------------------


// const34_* named pointers (match the C macros that name these blob entries).
const const34_43200 = consts.const34_43200();
const const34_86400 = consts.const34_86400();
const const34_2 = consts.const34_2();
const const34_28 = consts.const34_28();
const const34_400 = consts.const34_400();
const const34__4712 = consts.const34__4712();
const const34_1 = consts.const34_1();
const const34_31 = consts.const34_31();
const const34_12 = consts.const34_12();
const const34_14 = consts.const34_14();
const const34_4800 = consts.const34_4800();
const const34_1461 = consts.const34_1461();
const const34_4 = consts.const34_4();
const const34_367 = consts.const34_367();
const const34_4900 = consts.const34_4900();
const const34_100 = consts.const34_100();
const const34_3 = consts.const34_3();
const const34_9 = consts.const34_9();
const const34_7 = consts.const34_7();
const const34_5001 = consts.const34_5001();
const const34_275 = consts.const34_275();
const const34_1729777 = consts.const34_1729777();
const const34_1401 = consts.const34_1401();
const const34_274277 = consts.const34_274277();
const const34_146097 = consts.const34_146097();
const const34_38 = consts.const34_38();
const const34_153 = consts.const34_153();
const const34_5 = consts.const34_5();
const const34_4716 = consts.const34_4716();
const const34_1on2 = consts.const34_1on2();
const const34_24 = consts.const34_24();
const const34_3600 = consts.const34_3600();
const const34_60 = consts.const34_60();
const const34_maxDate = consts.const34_maxDate();
const const34_maxTime = consts.const34_maxTime();
const const34_1e6 = consts.const34_1e6();
const const34_1on10 = consts.const34_1on10();
const const34_32075 = consts.const34_32075();
const const_86400 = consts.const_86400();

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var firstGregorianDay: u32;
extern var firstDayOfWeek: u8;
extern var firstWeekOfYearDay: u8;
extern var temporaryInformation: u8;
extern var lastCenturyHighUsed: u16;
extern var calcMode: u8;
extern var cancelFilename: bool;
extern var lastErrorCode: u8;
extern var errorMessage: [*c]u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;

// ---------------------------------------------------------------------------
// Linkable function externs
// ---------------------------------------------------------------------------
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, size_blocks: u16, tag: u32) void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn displayCalcErrorMessage(error_code: u8, err_message_line: calcRegister_t, err_register_line: calcRegister_t) void;
const c_moreInfoOnError = @extern(*const fn (m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void, .{ .name = "moreInfoOnError" });
extern fn saveLastX() bool;
extern fn liftStack() void;
extern fn undo() void;
extern fn fnSwapXY(p: u16) void;
extern fn fnDropY(p: u16) void;
extern fn addItemToNimBuffer(item: i16) void;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn timeToReal34(hms: u16) void;
extern fn adjustResult(result: calcRegister_t, dropY: bool, setCpxRes: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn setSystemFlag(flag: c_uint) void;
extern fn clearSystemFlag(flag: c_uint) void;

// Register conversions provided (exported) by the registerValueConversions owner.
extern fn convertReal34RegisterToDateRegister(source: calcRegister_t, destination: calcRegister_t, handleYY: bool) void;
extern fn convertReal34ToLongIntegerRegister(real34: *align(1) const real34_t, dest: calcRegister_t, roundingMode: c_int) void;
extern fn convertLongIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertLongIntegerRegisterToReal34(source: calcRegister_t, destination: *real34_t) void;
extern fn convertLongIntegerRegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertReal34RegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertTimeRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;
extern fn convertLongIntegerToLongIntegerRegister(lgInt: *const mpz_struct, regist: calcRegister_t) void;
extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: c_int, real_context: *realContext_t) void;

// real34 comparison functions (linkable real externs).
extern fn real34CompareEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;
extern fn real34CompareGreaterEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;

// ---------------------------------------------------------------------------
// decNumber / decQuad externs
// ---------------------------------------------------------------------------
extern fn decQuadFromInt32(r: *real34_t, v: i32) *real34_t;
extern fn decQuadFromUInt32(r: *real34_t, v: u32) *real34_t;
extern fn decQuadToInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) i32;
extern fn decQuadToUInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) u32;
extern fn decQuadAdd(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadDivide(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadMultiply(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadSubtract(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadToIntegralValue(r: *real34_t, a: *align(1) const real34_t, ctx: *realContext_t, round: c_int) *real34_t;
extern fn decQuadCopyAbs(r: *real34_t, a: *align(1) const real34_t) *real34_t;
extern fn decQuadCompare(r: *real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadIsZero(v: *align(1) const real34_t) u32;
extern fn decQuadIsNaN(v: *align(1) const real34_t) u32;

extern fn decimal128ToNumber(src: *align(1) const real34_t, dst: *real_t) *real_t;

extern fn decNumberSubtract(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(r: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;

// ---------------------------------------------------------------------------
// GMP externs
// ---------------------------------------------------------------------------
extern fn @"__gmpz_init"(p: *mpz_struct) void;
extern fn @"__gmpz_clear"(p: *mpz_struct) void;
extern fn @"__gmpz_set_ui"(p: *mpz_struct, v: c_ulong) void;
const longIntegerInit = @"__gmpz_init";
const longIntegerFree = @"__gmpz_clear";
inline fn uInt32ToLongInteger(v: u32, p: *mpz_struct) void {
    @"__gmpz_set_ui"(p, v);
}

// ---------------------------------------------------------------------------
// DMCP / PC date path
// ---------------------------------------------------------------------------
const dt_t = abi.DateShort;
const tm_t = abi.TimeShort;
const Tm = extern struct {
    sec: c_int,
    min: c_int,
    hour: c_int,
    mday: c_int,
    mon: c_int,
    year: c_int,
    wday: c_int,
    yday: c_int,
    isdst: c_int,
};
extern fn time(t: ?*i64) i64;
extern fn localtime(t: *const i64) *Tm;
extern fn strftime(buf: [*]u8, max: usize, fmt: [*:0]const u8, tm: *const Tm) usize;
extern fn sprintf(buf: [*]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strcpy(dst: [*]u8, src: [*:0]const u8) [*c]u8;
extern fn strcat(dst: [*]u8, src: [*:0]const u8) [*c]u8;

const rtc_read: *const fn (*tm_t, *dt_t) callconv(.c) void = if (dmcp_build)
    @ptrFromInt(0x08000201 + 204)
else
    undefined;
const rtc_write: *const fn (*tm_t, *dt_t) callconv(.c) void = if (dmcp_build)
    @ptrFromInt(0x08000201 + 208)
else
    undefined;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8) void {
    if (comptime extra_info) c_moreInfoOnError(m1, m2, null, null);
}
inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}

// real34 bit macros.
inline fn real34IsNegative(v: *align(1) const real34_t) bool {
    return (v.bytes[15] & 0x80) == 0x80;
}
inline fn real34SetNegativeSign(v: *real34_t) void {
    v.bytes[15] |= 0x80;
}
inline fn real34Copy(src: *align(1) const real34_t, dst: *real34_t) void {
    dst.* = src.*;
}
inline fn real34IsZero(v: *align(1) const real34_t) bool {
    return decQuadIsZero(v) != 0;
}
inline fn real34IsNaN(v: *align(1) const real34_t) bool {
    return decQuadIsNaN(v) != 0;
}

// real34 ops (use &ctxtReal34).
inline fn uInt32ToReal34(src: u32, dst: *real34_t) void {
    _ = decQuadFromUInt32(dst, src);
}
inline fn int32ToReal34(src: i32, dst: *real34_t) void {
    _ = decQuadFromInt32(dst, src);
}
inline fn real34Add(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadAdd(res, a, b, &ctxtReal34);
}
inline fn real34Subtract(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadSubtract(res, a, b, &ctxtReal34);
}
inline fn real34Multiply(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadMultiply(res, a, b, &ctxtReal34);
}
inline fn real34Divide(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadDivide(res, a, b, &ctxtReal34);
}
inline fn real34CopyAbs(src: *align(1) const real34_t, dst: *real34_t) void {
    _ = decQuadCopyAbs(dst, src);
}
inline fn real34ToIntegralValue(src: *align(1) const real34_t, dst: *real34_t, mode: c_int) void {
    _ = decQuadToIntegralValue(dst, src, &ctxtReal34, mode);
}
inline fn real34Compare(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadCompare(res, a, b, &ctxtReal34);
}
inline fn real34ToInt32(src: *align(1) const real34_t) i32 {
    return decQuadToInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn real34ToUInt32(src: *align(1) const real34_t) u32 {
    return decQuadToUInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn real34ToReal(src: *align(1) const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}

// real ops.
inline fn realSubtract(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realMultiply(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realDivide(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}

// modulo(n, d) macro: this version works only if d > 0.
//   ((n)%(d)<0 ? (n)%(d)+(d) : (n)%(d))
inline fn modulo(n: i32, d: i32) i32 {
    const r = @rem(n, d);
    return if (r < 0) r + d else r;
}

inline fn SET_TI_TRUE_FALSE(condition: bool) void {
    temporaryInformation = TI_FALSE + @as(u8, @intFromBool(condition));
}

// ===========================================================================
// Implementation
// ===========================================================================
pub export fn fnSetDateFormat(dateFormat: u16) linksection(code_section) callconv(.c) void {
    switch (dateFormat) {
        ITM_DMY => {
            clearSystemFlag(@bitCast(FLAG_MDY));
            clearSystemFlag(@bitCast(FLAG_YMD));
            setSystemFlag(@bitCast(FLAG_DMY));
        },
        ITM_MDY => {
            clearSystemFlag(@bitCast(FLAG_DMY));
            clearSystemFlag(@bitCast(FLAG_YMD));
            setSystemFlag(@bitCast(FLAG_MDY));
        },
        ITM_YMD => {
            clearSystemFlag(@bitCast(FLAG_MDY));
            clearSystemFlag(@bitCast(FLAG_DMY));
            setSystemFlag(@bitCast(FLAG_YMD));
        },
        else => {},
    }
}

pub export fn internalDateToJulianDay(source: *const real34_t, destination: *real34_t) linksection(code_section) callconv(.c) void {
    real34Subtract(source, const34_43200, destination);
    real34Divide(destination, const34_86400, destination);
    real34ToIntegralValue(destination, destination, DEC_ROUND_FLOOR);
}

pub export fn julianDayToInternalDate(source: *const real34_t, destination: *real34_t) linksection(code_section) callconv(.c) void {
    real34ToIntegralValue(source, destination, DEC_ROUND_FLOOR);
    real34Multiply(destination, const34_86400, destination);
    real34Add(destination, const34_43200, destination);
}

pub export fn checkDateArgument(regist: calcRegister_t, jd: *real34_t) linksection(code_section) callconv(.c) bool {
    switch (getRegisterDataType(regist)) {
        dtDate => {
            internalDateToJulianDay(reg34(regist), jd);
            return true;
        },
        dtReal34 => {
            if (getRegisterAngularMode(regist) == amNone) {
                reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNoneU); // make sure TEMP_REGISTER_1 is not of dtDate type here
                convertReal34RegisterToDateRegister(regist, TEMP_REGISTER_1, false); //no !YYsystem needed here
                if (getRegisterDataType(TEMP_REGISTER_1) != dtDate) {
                    return false; // invalid date
                }
                internalDateToJulianDay(reg34(TEMP_REGISTER_1), jd);
                return true;
            }
            // fallthrough
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function checkDateArgument:", "data type cannot be converted to date!");
            return false;
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function checkDateArgument:", "data type cannot be converted to date!");
            return false;
        },
    }
}

pub export fn isLeapYear(year: *const real34_t) linksection(code_section) callconv(.c) bool {
    var val: real34_t = undefined;
    var val2: real34_t = undefined;
    var y400: i32 = undefined; // year mod 400
    var isGregorian: bool = undefined;

    composeJulianDay(year, const34_2, const34_28, &val);
    uInt32ToReal34(firstGregorianDay, &val2);
    isGregorian = real34CompareGreaterEqual(&val, &val2);

    real34Divide(year, const34_400, &val);
    real34ToIntegralValue(&val, &val, DEC_ROUND_FLOOR);
    real34Multiply(&val, const34_400, &val);
    real34Subtract(year, &val, &val);
    y400 = real34ToInt32(&val);

    if (y400 == 0) {
        return true;
    } else if (isGregorian and (@rem(y400, 100) == 0)) {
        return false;
    }

    return (@rem(y400, 4) == 0);
}

pub export fn isValidDay(year: *const real34_t, month: *const real34_t, day: *const real34_t) linksection(code_section) callconv(.c) bool {
    var val: real34_t = undefined;

    // Year (this rejects year -4713 and earlier)
    real34ToIntegralValue(year, &val, DEC_ROUND_FLOOR);
    real34Subtract(year, &val, &val);
    if (!real34IsZero(&val)) {
        return false;
    }
    real34Compare(year, const34__4712, &val);
    if (real34ToInt32(&val) < 0) {
        return false;
    }

    // Day
    real34ToIntegralValue(day, &val, DEC_ROUND_FLOOR);
    real34Subtract(day, &val, &val);
    if (!real34IsZero(&val)) {
        return false;
    }
    real34Compare(day, const34_1, &val);
    if (real34ToInt32(&val) < 0) {
        return false;
    }
    real34Compare(day, const34_31, &val);
    if (real34ToInt32(&val) > 0) {
        return false;
    }

    // Month
    real34ToIntegralValue(month, &val, DEC_ROUND_FLOOR);
    real34Subtract(month, &val, &val);
    if (!real34IsZero(&val)) {
        return false;
    }
    real34Compare(month, const34_1, &val);
    if (real34ToInt32(&val) < 0) {
        return false;
    }
    real34Compare(month, const34_12, &val);
    if (real34ToInt32(&val) > 0) {
        return false;
    }

    // Thirty days hath September...
    if (real34ToInt32(day) == 31) {
        switch (real34ToInt32(month)) {
            2, 4, 6, 9, 11 => {
                return false;
            },
            else => {
                return true;
            },
        }
    }

    // February
    if (real34ToInt32(month) == 2) {
        if (real34ToInt32(day) == 30) {
            return false;
        } else if ((real34ToInt32(day) == 29) and (!isLeapYear(year))) {
            return false;
        }
    }

    // Check for Julian-Gregorian gap
    if (firstGregorianDay > 0) { // Gregorian
        var y: real34_t = undefined;
        var m: real34_t = undefined;
        var d: real34_t = undefined;
        composeJulianDay(year, month, day, &val);
        decomposeJulianDay(&val, &y, &m, &d);
        if (!real34CompareEqual(year, &y) or !real34CompareEqual(month, &m) or !real34CompareEqual(day, &d)) {
            return false;
        }
    }

    // Valid date
    return true;
}

fn divInt(p: *align(1) const real34_t, q: *align(1) const real34_t, r: *real34_t) linksection(code_section) void {
    var tmp: real34_t = undefined;
    real34Divide(p, q, &tmp);
    real34ToIntegralValue(&tmp, r, DEC_ROUND_DOWN);
}
fn divInt2(p: *align(1) const real34_t, q: *align(1) const real34_t, r: *real34_t) linksection(code_section) void {
    var tmp: real34_t = undefined;
    real34Divide(p, q, &tmp);
    real34ToIntegralValue(&tmp, r, DEC_ROUND_FLOOR);
}
fn modInt(p: *align(1) const real34_t, q: *align(1) const real34_t, r: *real34_t) linksection(code_section) void {
    var tmp: real34_t = undefined;
    divInt2(p, q, &tmp);
    real34Multiply(&tmp, q, &tmp);
    real34Subtract(p, &tmp, r);
}

pub export fn composeJulianDay(year: *const real34_t, month: *const real34_t, day: *const real34_t, jd: *real34_t) linksection(code_section) callconv(.c) void {
    var fg: real34_t = undefined;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;

    uInt32ToReal34(firstGregorianDay, &fg);
    real34Copy(year, &y);
    real34Copy(month, &m);
    real34Copy(day, &d);
    composeJulianDay_g(&y, &m, &d, jd);
    if ((firstGregorianDay > 0) and real34CompareLessThan(jd, &fg)) {
        composeJulianDay_j(&y, &m, &d, jd);
    }
}

// Gregorian
pub export fn composeJulianDay_g(year: *const real34_t, month: *const real34_t, day: *const real34_t, jd: *real34_t) linksection(code_section) callconv(.c) void {
    var m_14_12: real34_t = undefined; // round_down((month - 14) / 12)
    var a: real34_t = undefined;

    // round_down((month - 14) / 12)
    real34Subtract(month, const34_14, &m_14_12);
    divInt(&m_14_12, const34_12, &m_14_12);

    real34Add(year, const34_4800, &a);
    real34Add(&a, &m_14_12, &a);
    real34Multiply(&a, const34_1461, &a);
    divInt(&a, const34_4, jd);

    real34Multiply(&m_14_12, const34_12, &a);
    real34Subtract(month, &a, &a);
    real34Subtract(&a, const34_2, &a);
    real34Multiply(&a, const34_367, &a);
    divInt(&a, const34_12, &a);
    real34Add(jd, &a, jd);

    real34Add(year, const34_4900, &a);
    real34Add(&a, &m_14_12, &a);
    divInt(&a, const34_100, &a);
    real34Multiply(&a, const34_3, &a);
    divInt(&a, const34_4, &a);
    real34Subtract(jd, &a, jd);

    real34Add(jd, day, jd);
    real34Subtract(jd, const34_32075, jd);
}

// Julian
pub export fn composeJulianDay_j(year: *const real34_t, month: *const real34_t, day: *const real34_t, jd: *real34_t) linksection(code_section) callconv(.c) void {
    var a: real34_t = undefined;

    real34Multiply(year, const34_367, jd);

    real34Subtract(month, const34_9, &a);
    divInt(&a, const34_7, &a);
    real34Add(&a, year, &a);
    real34Add(&a, const34_5001, &a);
    real34Multiply(&a, const34_7, &a);
    divInt(&a, const34_4, &a);
    real34Subtract(jd, &a, jd);

    real34Multiply(month, const34_275, &a);
    divInt(&a, const34_9, &a);
    real34Add(jd, &a, jd);

    real34Add(jd, day, jd);
    real34Add(jd, const34_1729777, jd);
}

pub export fn decomposeJulianDay(jd: *const real34_t, year: *real34_t, month: *real34_t, day: *real34_t) linksection(code_section) callconv(.c) void {
    var e: real34_t = undefined;
    var h: real34_t = undefined;
    var tmp1: real34_t = undefined;

    real34Add(jd, const34_1401, &e);
    uInt32ToReal34(firstGregorianDay, &tmp1);
    // proleptic Gregorian calendar is used if firstGregorianDay == 0: for special purpose only!
    if ((firstGregorianDay == 0) or real34CompareGreaterEqual(jd, &tmp1)) { // Gregorian
        real34Multiply(jd, const34_4, &tmp1);
        real34Add(&tmp1, const34_274277, &tmp1);
        divInt2(&tmp1, const34_146097, &tmp1);
        real34Multiply(&tmp1, const34_3, &tmp1);
        divInt2(&tmp1, const34_4, &tmp1);
        real34Subtract(&tmp1, const34_38, &tmp1);
        real34Add(&e, &tmp1, &e);
    }

    real34Multiply(&e, const34_4, &e);
    real34Add(&e, const34_3, &e);

    modInt(&e, const34_1461, &h);
    divInt2(&h, const34_4, &h);
    real34Multiply(&h, const34_5, &h);
    real34Add(&h, const34_2, &h);

    modInt(&h, const34_153, day);
    divInt2(day, const34_5, day);
    real34Add(day, const34_1, day);

    divInt2(&h, const34_153, month);
    real34Add(month, const34_2, month);
    modInt(month, const34_12, month);
    real34Add(month, const34_1, month);

    divInt2(&e, const34_1461, year);
    real34Subtract(year, const34_4716, year);
    real34Subtract(const34_14, month, &tmp1);
    divInt2(&tmp1, const34_12, &tmp1);
    real34Add(year, &tmp1, year);
}

pub export fn julianDayToDayOfWeek(jd: *real34_t) linksection(code_section) callconv(.c) u32 {
    var dow: real34_t = undefined;
    modInt(jd, const34_7, &dow);
    real34Add(&dow, const34_1, &dow);
    return real34ToUInt32(&dow);
}

pub export fn getJulianDayOfWeek(regist: calcRegister_t) linksection(code_section) callconv(.c) u32 {
    var date34: real34_t = undefined;
    if (checkDateArgument(regist, &date34)) {
        return julianDayToDayOfWeek(&date34);
    } else {
        return 0;
    }
}

pub export fn checkDateRange(date34: *const real34_t) linksection(code_section) callconv(.c) void {
    if (real34CompareGreaterEqual(date34, const34_maxDate) or real34IsNegative(date34)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function checkDateRange:", "value of date type is too large");
        return;
    }
}

pub export fn hmmssToSeconds(src: *const real34_t, dest: *real34_t) linksection(code_section) callconv(.c) void {
    var time34: real34_t = undefined;
    var real34: real34_t = undefined;
    var value34: real34_t = undefined;
    var sign: i32 = undefined;

    sign = @intFromBool(real34IsNegative(src));

    // Hours
    real34CopyAbs(src, &time34);
    real34ToIntegralValue(&time34, &real34, DEC_ROUND_DOWN);
    real34Multiply(&real34, const34_3600, dest);

    // Minutes
    real34Subtract(&time34, &real34, &time34);
    real34Multiply(&time34, const34_100, &time34);
    real34ToIntegralValue(&time34, &real34, DEC_ROUND_DOWN);
    real34Multiply(const34_60, &real34, &value34);
    real34Add(dest, &value34, dest);

    // Seconds
    real34Subtract(&time34, &real34, &time34);
    real34Multiply(&time34, const34_100, &time34);
    real34Add(dest, &time34, dest);

    // Sign
    if (sign != 0) {
        real34SetNegativeSign(dest);
    }
}

pub export fn hmmssInRegisterToSeconds(regist: calcRegister_t) linksection(code_section) callconv(.c) void {
    var real34: real34_t = undefined;

    real34Copy(reg34(regist), &real34);
    reallocateRegister(regist, dtTime, 0, amNoneU);
    hmmssToSeconds(&real34, reg34(regist));
    checkTimeRange(reg34(regist));
}

pub export fn checkTimeRange(time34: *const real34_t) linksection(code_section) callconv(.c) void {
    var t: real34_t = undefined;

    real34CopyAbs(time34, &t);
    if (real34CompareGreaterEqual(&t, const34_maxTime)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function checkTimeRange:", "value of time type is too large");
        return;
    }
}

pub export fn getWeekOfYear(jd: *real34_t) linksection(code_section) callconv(.c) u32 {
    var dsow: real34_t = undefined;
    var sow: real34_t = undefined;
    var rdow: real34_t = undefined;

    uInt32ToReal34(@bitCast(modulo(@as(i32, @intCast(julianDayToDayOfWeek(jd))) - firstDayOfWeek, 7)), &dsow);
    real34Subtract(jd, &dsow, &sow); // 1st day of the week containing the date

    uInt32ToReal34(@bitCast(modulo(@as(i32, firstWeekOfYearDay) - firstDayOfWeek, 7)), &dsow);
    real34Add(&sow, &dsow, &rdow); // reference day of the week containing the date

    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j1: real34_t = undefined;
    decomposeJulianDay(&rdow, &y, &m, &d); // Get the correct year (may be different from the year of jd)
    composeJulianDay(&y, const34_1, const34_1, &j1); // 1st of january of the correct year

    const dow: i32 = modulo(@intCast(julianDayToDayOfWeek(&j1)), 7);
    if (firstWeekOfYearDay < dow) { // if the reference day of the week containing the 1st of january is part of previous year…
        real34Add(&j1, const34_7, &j1); // … skip to next week
    }

    uInt32ToReal34(@bitCast(modulo(dow - firstDayOfWeek, 7)), &dsow);
    real34Subtract(&j1, &dsow, &j1); // 1st day of the 1st week of the year

    var woy: real34_t = undefined;
    real34Subtract(&sow, &j1, &woy); // number of days between the 2 dates
    real34Divide(&woy, const34_7, &woy); // number of weeks
    real34Add(&woy, const34_1, &woy); // first week has number 1
    return real34ToUInt32(&woy);
}

pub export fn fnJulianToDateTime(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var date: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            liftStack();
            convertLongIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
            julianDayToInternalDate(reg34(REGISTER_Y), &date);
            reallocateRegister(REGISTER_Y, dtDate, 0, amNoneU);
            real34Copy(&date, reg34(REGISTER_Y));
            reallocateRegister(REGISTER_X, dtTime, 0, amNoneU);
            real34Copy(const34_1on2, reg34(REGISTER_X)); //Added offset so 0.00 -> 12:00:00
            real34Multiply(reg34(REGISTER_X), const34_3600, reg34(REGISTER_X));
            real34Multiply(reg34(REGISTER_X), const34_24, reg34(REGISTER_X));
        },
        dtReal34 => {
            liftStack(); // After a stack lift, X is a real 34 of random value
            real34Add(reg34(REGISTER_Y), const34_1on2, reg34(REGISTER_Y)); //handle 0.5 offset
            copySourceRegisterToDestRegister(REGISTER_Y, REGISTER_X);

            //Get IP in Y
            reallocateRegister(REGISTER_Y, dtDate, 0, amNoneU); // after this, content of Y is random
            real34ToIntegralValue(reg34(REGISTER_X), reg34(REGISTER_Y), DEC_ROUND_DOWN);

            //Get FP in x
            var y: real_t = undefined;
            var x: real_t = undefined;
            real34ToReal(reg34(REGISTER_Y), &y); // IP
            real34ToReal(reg34(REGISTER_X), &x); // Org
            realSubtract(&x, &y, &x, &ctxtReal39); // FP = Org - IP
            realMultiply(&x, const_86400, &x, &ctxtReal39); // (3600*24*(FP))          // round seconds
            x.exponent += 3; // x = x * 1000            // to 0.001s
            realToIntegralValue(&x, &x, DEC_ROUND_HALF_UP, &ctxtReal39); // round (3600*24*1000*(FP))
            realDivide(&x, const_86400, &x, &ctxtReal39); // (round (3600*24*1000*(FP))) / (3600*24)
            x.exponent -= 3; // x = x / 1000

            //Convert date to Y
            julianDayToInternalDate(reg34(REGISTER_Y), &date);
            reallocateRegister(REGISTER_Y, dtDate, 0, amNoneU);
            real34Copy(&date, reg34(REGISTER_Y));

            //Convert x to time to X
            var tmp: real_t = undefined;
            realMultiply(const_86400, &x, &tmp, &ctxtReal39); // tmp is now seconds
            reallocateRegister(REGISTER_X, dtTime, 0, amNoneU); // this must be in front of the next line, otherwise accuracy is gone
            convertRealToReal34ResultRegister(&tmp, REGISTER_X);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnJulianToDateTime:", "data type cannot be converted to date!");
            return;
        },
    }

    // check range
    checkDateRange(reg34(REGISTER_Y));
    if (lastErrorCode != 0) {
        undo();
    }
}

pub export fn fnDateToJulian(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var jd34: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    if (checkDateArgument(REGISTER_X, &jd34)) {
        convertReal34ToLongIntegerRegister(&jd34, REGISTER_X, DEC_ROUND_FLOOR);
    }
}

pub export fn fnDateTimeToJulian(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var jd34: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    if (getRegisterDataType(REGISTER_X) == dtDate and getRegisterDataType(REGISTER_Y) == dtTime) {
        if (checkDateArgument(REGISTER_X, &jd34)) {
            fnSwapXY(0);
        }
    }

    if (checkDateArgument(REGISTER_Y, &jd34) and getRegisterDataType(REGISTER_X) == dtTime) {
        convertReal34ToLongIntegerRegister(&jd34, REGISTER_Y, DEC_ROUND_DOWN); //Y is truncated date in real
        convertLongIntegerRegisterToReal34Register(REGISTER_Y, REGISTER_Y);
        timeToReal34(3); //X is now Real seconds
        real34Divide(reg34(REGISTER_X), const34_86400, reg34(REGISTER_X)); //X is now in days
        real34Add(reg34(REGISTER_X), reg34(REGISTER_Y), reg34(REGISTER_X));
        real34Subtract(reg34(REGISTER_X), const34_1on2, reg34(REGISTER_X)); //handle 0.5 offset
        adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
    }
}

pub export fn fnIsLeap(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;

    if (checkDateArgument(REGISTER_X, &j)) {
        decomposeJulianDay(&j, &y, &m, &d);
        SET_TI_TRUE_FALSE(isLeapYear(&y));
    }
}

pub export fn fnSetFirstGregorianDay(param: u16) linksection(code_section) callconv(.c) void {
    var jd34: real34_t = undefined;
    const fgd: u32 = firstGregorianDay;

    if (param != NOPARAM) {
        switch (param) {
            ITM_JUL_GREG_1752 => firstGregorianDay = 2361222, // 14 Sept 1752
            ITM_JUL_GREG_1949 => firstGregorianDay = 2433191, // 1 Oct   1949
            ITM_JUL_GREG_1582 => firstGregorianDay = 2299161, // 15 Oct  1582
            ITM_JUL_GREG_1873 => firstGregorianDay = 2405160, // 1 Jan   1873
            else => {},
        }
        temporaryInformation = TI_DISP_JULIAN;
        return;
    }

    if ((getRegisterDataType(REGISTER_X) == dtReal34) and (getRegisterAngularMode(REGISTER_X) == amNone)) {
        firstGregorianDay = 0; // proleptic Gregorian mode
        if (checkDateArgument(REGISTER_X, &jd34)) {
            firstGregorianDay = real34ToUInt32(&jd34);
        } else {
            firstGregorianDay = fgd;
        }
        temporaryInformation = TI_DISP_JULIAN;
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            if (getRegisterDataType(REGISTER_X) == dtDate) {
                c_moreInfoOnError("In function fnSetFirstGregorianDay:", "data type is disabled as input because of complicated Julian-Gregorian issue!", null, null);
            } else {
                c_moreInfoOnError("In function fnSetFirstGregorianDay:", "data type cannot be interpreted as a date!", null, null);
            }
        }
    }
}

pub export fn fnGetFirstGregorianDay(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var j: real34_t = undefined;

    uInt32ToReal34(firstGregorianDay, &j);
    liftStack();
    reallocateRegister(REGISTER_X, dtDate, 0, amNoneU);
    julianDayToInternalDate(&j, reg34(REGISTER_X));
}

pub export fn fnYYDflt(tmp: u16) linksection(code_section) callconv(.c) void {
    if (tmp == YY_TRACKING) {
        lastCenturyHighUsed = YY_MASK_TRACKING; //0x4000;
    } else if (tmp == YY_OFF) {
        lastCenturyHighUsed = YY_MASK_OFF; //0x8000;
    } else if (tmp < 100) { //allow lowest range 0100 -> 0199
        lastCenturyHighUsed = 0;
    } else {
        lastCenturyHighUsed = tmp;
    }
}

pub export fn fnXToDateRegister(regist: calcRegister_t) linksection(code_section) callconv(.c) void {
    if (!saveLastX()) {
        return;
    }

    switch (getRegisterDataType(regist)) {
        dtDate => {
            // already in date: do nothing
        },
        dtReal34 => {
            if (getRegisterAngularMode(regist) == amNone) {
                convertReal34RegisterToDateRegister(regist, regist, false); //no !YYsystem needed here; //change this "false" to "YYSystem" to make [x->D] respect YY
                checkDateRange(reg34(regist));
                temporaryInformation = TI_DAY_OF_WEEK;
                if (lastErrorCode != 0) {
                    undo();
                }
            } else {
                // fallthrough
                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, regist);
                moreInfoOnError("In function fnXToDate:", "data type cannot be converted to date!");
                return;
            }
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, regist);
            moreInfoOnError("In function fnXToDate:", "data type cannot be converted to date!");
            return;
        },
    }
}

pub export fn fnXToDate(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnXToDateRegister(REGISTER_X);
}

pub export fn fnYear(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    if (checkDateArgument(REGISTER_X, &j)) {
        decomposeJulianDay(&j, &y, &m, &d);
        convertReal34ToLongIntegerRegister(&y, REGISTER_X, DEC_ROUND_FLOOR);
    }
}

pub export fn fnMonth(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    if (checkDateArgument(REGISTER_X, &j)) {
        decomposeJulianDay(&j, &y, &m, &d);
        convertReal34ToLongIntegerRegister(&m, REGISTER_X, DEC_ROUND_FLOOR);
    }
}

pub export fn fnDay(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    if (checkDateArgument(REGISTER_X, &j)) {
        decomposeJulianDay(&j, &y, &m, &d);
        convertReal34ToLongIntegerRegister(&d, REGISTER_X, DEC_ROUND_FLOOR);
    }
}

pub export fn fnWday(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    const dayOfWeek: u32 = getJulianDayOfWeek(REGISTER_X);
    var result: mpz_struct = undefined;

    if (!saveLastX()) {
        return;
    }

    if (dayOfWeek != 0) {
        longIntegerInit(&result);
        uInt32ToLongInteger(dayOfWeek, &result);
        convertLongIntegerToLongIntegerRegister(&result, REGISTER_X);
        longIntegerFree(&result);
        temporaryInformation = TI_DAY_OF_WEEK;
    }
}

pub export fn fnDateTo(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    if (checkDateArgument(REGISTER_X, &j)) {
        liftStack();
        setSystemFlag(FLAG_ASLIFT);
        liftStack();
        decomposeJulianDay(&j, &y, &m, &d);
        convertReal34ToLongIntegerRegister(&y, if (getSystemFlag(FLAG_YMD)) REGISTER_Z else REGISTER_X, DEC_ROUND_FLOOR);
        convertReal34ToLongIntegerRegister(&m, if (getSystemFlag(FLAG_MDY)) REGISTER_Z else REGISTER_Y, DEC_ROUND_FLOOR);
        convertReal34ToLongIntegerRegister(&d, if (getSystemFlag(FLAG_DMY)) REGISTER_Z else if (getSystemFlag(FLAG_MDY)) REGISTER_Y else REGISTER_X, DEC_ROUND_FLOOR);
    }
}

pub export fn fnToDate(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;
    var part: [3]*real34_t = undefined;
    const r = [3]calcRegister_t{ REGISTER_Z, REGISTER_Y, REGISTER_X };
    var i: i32 = undefined;

    if (!saveLastX()) {
        return;
    }

    if (getSystemFlag(FLAG_DMY)) {
        part[0] = &d;
        part[1] = &m;
        part[2] = &y;
    } else if (getSystemFlag(FLAG_MDY)) {
        part[0] = &m;
        part[1] = &d;
        part[2] = &y;
    } else {
        part[0] = &y;
        part[1] = &m;
        part[2] = &d;
    }

    i = 0;
    while (i < 3) : (i += 1) {
        const idx: usize = @intCast(i);
        switch (getRegisterDataType(r[idx])) {
            dtLongInteger => {
                convertLongIntegerRegisterToReal34(r[idx], part[idx]);
            },
            dtReal34 => {
                if (getRegisterAngularMode(r[idx]) == amNone) {
                    real34ToIntegralValue(reg34(r[idx]), part[idx], DEC_ROUND_DOWN);
                } else {
                    // fallthrough
                    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                    moreInfoOnError("In function fnToDate:", "data type cannot be converted to a real34!");
                    return;
                }
            },
            else => {
                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function fnToDate:", "data type cannot be converted to a real34!");
                return;
            },
        }
    }

    if (!isValidDay(&y, &m, &d)) {
        displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        moreInfoOnError("In function fnToDate:", "Invalid date input like 30 Feb.");
        return;
    }

    // valid date
    fnDropY(NOPARAM);
    if (lastErrorCode == ERROR_NONE) {
        fnDropY(NOPARAM);
        if (lastErrorCode == ERROR_NONE) {
            composeJulianDay(&y, &m, &d, &j);
            reallocateRegister(REGISTER_X, dtDate, 0, amNoneU);
            julianDayToInternalDate(&j, reg34(REGISTER_X));

            // check range
            checkDateRange(reg34(REGISTER_X));
            temporaryInformation = TI_DAY_OF_WEEK;
        }
    }
    if (lastErrorCode != 0) {
        undo();
    }
}

pub export fn fnToHr(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (!saveLastX()) {
        return;
    }

    switch (getRegisterDataType(REGISTER_X)) {
        dtTime => {
            convertTimeRegisterToReal34Register(REGISTER_X, REGISTER_X);
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnToHr:", "data type cannot be converted to a real34!");
            return;
        },
    }
}

pub export fn fnHMStoTM(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (!saveLastX()) {
        return;
    }

    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
        },
        dtTime => {
            // already in hours: do nothing
            return;
        },
        dtReal34 => {
            if (getRegisterAngularMode(REGISTER_X) == amNone) {
                // break
            } else {
                // fallthrough
                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function fnHMStoTM:", "data type cannot be converted to time!");
                return;
            }
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnHMStoTM:", "data type cannot be converted to time!");
            return;
        },
    }
    hmmssInRegisterToSeconds(REGISTER_X);
    if (lastErrorCode != 0) {
        undo();
    }
}

pub export fn fnHRtoTM(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    switch (calcMode) { //JM vv
        CM_NIM => {
            addItemToNimBuffer(ITM_HRtoTM);
        },
        else => { //JM ^^
            if (!saveLastX()) {
                return;
            }
        },
    }

    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToTimeRegister(REGISTER_X, REGISTER_X);
        },
        dtTime => {
            // already in hours: do nothing
        },
        dtReal34 => {
            if (getRegisterAngularMode(REGISTER_X) == amNone) {
                convertReal34RegisterToTimeRegister(REGISTER_X, REGISTER_X);
            } else {
                // fallthrough
                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function fnHRtoTM:", "data type cannot be converted to time!");
                return;
            }
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnError("In function fnHRtoTM:", "data type cannot be converted to time!");
            return;
        },
    }
    checkTimeRange(reg34(REGISTER_X));
    if (lastErrorCode != 0) {
        undo();
    }
}

pub export fn fnDate(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var j: real34_t = undefined;

    if (comptime dmcp_build) {
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;

        rtc_read(&timeInfo, &dateInfo);
        uInt32ToReal34(dateInfo.year, &y);
        uInt32ToReal34(dateInfo.month, &m);
        uInt32ToReal34(dateInfo.day, &d);
    } else {
        const epoch: i64 = time(null);
        const timeInfo = localtime(&epoch);

        int32ToReal34(timeInfo.year + 1900, &y);
        int32ToReal34(timeInfo.mon + 1, &m);
        int32ToReal34(timeInfo.mday, &d);
    }

    composeJulianDay(&y, &m, &d, &j);
    liftStack();
    reallocateRegister(REGISTER_X, dtDate, 0, amNoneU);
    julianDayToInternalDate(&j, reg34(REGISTER_X));
    temporaryInformation = TI_DAY_OF_WEEK;
}

pub export fn fnTime(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var time34: real34_t = undefined;

    if (comptime dmcp_build) {
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;

        rtc_read(&timeInfo, &dateInfo);
        uInt32ToReal34(@as(u32, timeInfo.hour) * 3600 + @as(u32, timeInfo.min) * 60 + @as(u32, timeInfo.sec), &time34);
    } else {
        const epoch: i64 = time(null);
        const timeInfo = localtime(&epoch);

        uInt32ToReal34(@as(u32, @intCast(timeInfo.hour)) * 3600 + @as(u32, @intCast(timeInfo.min)) * 60 + @as(u32, @intCast(timeInfo.sec)), &time34);
    }

    liftStack();
    reallocateRegister(REGISTER_X, dtTime, 0, amNoneU);
    real34Copy(&time34, reg34(REGISTER_X));
}

pub export fn fnSetDate(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime dmcp_build) {
        cancelFilename = true;
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;
        var j: real34_t = undefined;
        var y: real34_t = undefined;
        var m: real34_t = undefined;
        var d: real34_t = undefined;

        if (checkDateArgument(REGISTER_X, &j)) {
            rtc_read(&timeInfo, &dateInfo);
            decomposeJulianDay(&j, &y, &m, &d);
            dateInfo.year = @intCast(real34ToUInt32(&y));
            dateInfo.month = @intCast(real34ToUInt32(&m));
            dateInfo.day = @intCast(real34ToUInt32(&d));
            rtc_write(&timeInfo, &dateInfo);
        }
    }
}

pub export fn fnSetTime(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (comptime dmcp_build) {
        cancelFilename = true;
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;
        var time34: real34_t = undefined;
        var timeVal: i32 = undefined;

        if (getRegisterDataType(REGISTER_X) == dtTime) {
            if (real34IsNegative(reg34(REGISTER_X)) or real34IsNaN(reg34(REGISTER_X)) or real34CompareGreaterEqual(reg34(REGISTER_X), const34_86400)) {
                displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
            } else {
                rtc_read(&timeInfo, &dateInfo);
                real34Multiply(reg34(REGISTER_X), const34_100, &time34);
                real34ToIntegralValue(&time34, &time34, DEC_ROUND_DOWN);
                timeVal = real34ToInt32(&time34);
                timeInfo.csec = @intCast(@mod(timeVal, 100));
                timeVal = @divTrunc(timeVal, 100);
                timeInfo.sec = @intCast(@mod(timeVal, 60));
                timeVal = @divTrunc(timeVal, 60);
                timeInfo.min = @intCast(@mod(timeVal, 60));
                timeVal = @divTrunc(timeVal, 60);
                timeInfo.hour = @intCast(timeVal);
                rtc_write(&timeInfo, &dateInfo);
            }
        } else if (getRegisterDataType(REGISTER_X) == dtReal34) {
            if (real34IsNegative(reg34(REGISTER_X)) or real34IsNaN(reg34(REGISTER_X)) or real34CompareGreaterEqual(reg34(REGISTER_X), const34_24)) {
                displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
            } else {
                rtc_read(&timeInfo, &dateInfo);
                real34Multiply(reg34(REGISTER_X), const34_1e6, &time34);
                real34ToIntegralValue(&time34, &time34, DEC_ROUND_DOWN);
                timeVal = real34ToInt32(&time34);
                timeInfo.csec = @intCast(@mod(timeVal, 100));
                timeVal = @divTrunc(timeVal, 100);
                timeInfo.sec = @intCast(@mod(timeVal, 100));
                timeVal = @divTrunc(timeVal, 100);
                timeInfo.min = @intCast(@mod(timeVal, 100));
                timeVal = @divTrunc(timeVal, 100);
                timeInfo.hour = @intCast(timeVal);
                if (timeInfo.sec <= 59 and timeInfo.min <= 59 and timeInfo.hour <= 23) {
                    rtc_write(&timeInfo, &dateInfo);
                } else {
                    displayCalcErrorMessage(ERROR_BAD_TIME_OR_DATE_INPUT, ERR_REGISTER_LINE, REGISTER_X);
                }
            }
        } else {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        }
    }
}

pub export fn fnWeekOfYear(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var jd34: real34_t = undefined;

    if (!saveLastX()) {
        return;
    }

    if (checkDateArgument(REGISTER_X, &jd34)) {
        const woy: u32 = getWeekOfYear(&jd34);
        var li: mpz_struct = undefined;
        longIntegerInit(&li);
        uInt32ToLongInteger(woy, &li);
        convertLongIntegerToLongIntegerRegister(&li, REGISTER_X);
        temporaryInformation = TI_WOY;
        longIntegerFree(&li);
    }
}

pub export fn fnSetWeekOfYearRule(param: u16) linksection(code_section) callconv(.c) void {
    if (param != NOPARAM) {
        switch (param) {
            ITM_WOY_ISO => {
                firstDayOfWeek = 1;
                firstWeekOfYearDay = 4;
            },
            ITM_WOY_US => {
                firstDayOfWeek = 7;
                firstWeekOfYearDay = 6;
            },
            ITM_WOY_ME => {
                firstDayOfWeek = 6;
                firstWeekOfYearDay = 5;
            },
            else => {},
        }
        temporaryInformation = TI_DISP_WOY;
    }
}

pub export fn fnGetWeekOfYearRule(unusedButMandatoryParameter: u16) linksection(code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var fdow: real34_t = undefined;
    var fwoyd: real34_t = undefined;

    uInt32ToReal34(firstDayOfWeek, &fdow);
    uInt32ToReal34(firstWeekOfYearDay, &fwoyd);
    real34Multiply(&fwoyd, const34_1on10, &fwoyd);
    liftStack();
    reallocateRegister(REGISTER_X, dtReal34, 0, amNoneU);
    real34Add(&fdow, &fwoyd, reg34(REGISTER_X));
    temporaryInformation = TI_WOY_RULE;
}

pub export fn getDateString(dateString: [*]u8) linksection(code_section) callconv(.c) void {
    if (comptime dmcp_build) {
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;

        rtc_read(&timeInfo, &dateInfo);
        if (!getSystemFlag(FLAG_TDM24)) { // 2 digit year
            if (getSystemFlag(FLAG_DMY)) {
                _ = sprintf(dateString, "%02d.%02d.%02d", @as(c_int, dateInfo.day), @as(c_int, dateInfo.month), @as(c_int, @intCast(dateInfo.year % 100)));
            } else if (getSystemFlag(FLAG_YMD)) {
                _ = sprintf(dateString, "%02d-%02d-%02d", @as(c_int, @intCast(dateInfo.year % 100)), @as(c_int, dateInfo.month), @as(c_int, dateInfo.day));
            } else if (getSystemFlag(FLAG_MDY)) {
                _ = sprintf(dateString, "%02d/%02d/%02d", @as(c_int, dateInfo.month), @as(c_int, dateInfo.day), @as(c_int, @intCast(dateInfo.year % 100)));
            } else {
                _ = strcpy(dateString, "?? ?? ????");
            }
        } else { // 4 digit year
            if (getSystemFlag(FLAG_DMY)) {
                _ = sprintf(dateString, "%02d.%02d.%04d", @as(c_int, dateInfo.day), @as(c_int, dateInfo.month), @as(c_int, dateInfo.year));
            } else if (getSystemFlag(FLAG_YMD)) {
                _ = sprintf(dateString, "%04d-%02d-%02d", @as(c_int, dateInfo.year), @as(c_int, dateInfo.month), @as(c_int, dateInfo.day));
            } else if (getSystemFlag(FLAG_MDY)) {
                _ = sprintf(dateString, "%02d/%02d/%04d", @as(c_int, dateInfo.month), @as(c_int, dateInfo.day), @as(c_int, dateInfo.year));
            } else {
                _ = strcpy(dateString, "?? ?? ????");
            }
        }
    } else {
        const epoch: i64 = time(null);
        const timeInfo = localtime(&epoch);

        // For the format string : man strftime
        if (!getSystemFlag(FLAG_TDM24)) { // time format = 12H ==> 2 digit year
            if (getSystemFlag(FLAG_DMY)) {
                _ = strftime(dateString, 11, "%d.%m.%y", timeInfo);
            } else if (getSystemFlag(FLAG_YMD)) {
                _ = strftime(dateString, 11, "%y-%m-%d", timeInfo);
            } else if (getSystemFlag(FLAG_MDY)) {
                _ = strftime(dateString, 11, "%m/%d/%y", timeInfo);
            } else {
                _ = strcpy(dateString, "?? ?? ????");
            }
        } else { // 4 digit year
            if (getSystemFlag(FLAG_DMY)) {
                _ = strftime(dateString, 11, "%d.%m.%Y", timeInfo);
            } else if (getSystemFlag(FLAG_YMD)) {
                _ = strftime(dateString, 11, "%Y-%m-%d", timeInfo);
            } else if (getSystemFlag(FLAG_MDY)) {
                _ = strftime(dateString, 11, "%m/%d/%Y", timeInfo);
            } else {
                _ = strcpy(dateString, "?? ?? ????");
            }
        }
    }
}

pub export fn getTimeString(timeString: [*]u8) linksection(code_section) callconv(.c) void {
    if (comptime dmcp_build) {
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;

        rtc_read(&timeInfo, &dateInfo);
        if (!getSystemFlag(FLAG_TDM24)) {
            _ = sprintf(timeString, "%02d:%02d", @as(c_int, if ((timeInfo.hour % 12) == 0) 12 else timeInfo.hour % 12), @as(c_int, timeInfo.min));
            if (timeInfo.hour >= 12) {
                _ = strcat(timeString, "pm");
            } else {
                _ = strcat(timeString, "am");
            }
        } else {
            _ = sprintf(timeString, "%02d:%02d", @as(c_int, timeInfo.hour), @as(c_int, timeInfo.min));
        }
    } else {
        const epoch: i64 = time(null);
        const timeInfo = localtime(&epoch);

        // For the format string : man strftime
        if (getSystemFlag(FLAG_TDM24)) { // time format = 24H
            _ = strftime(timeString, 8, "%H:%M", timeInfo); // %R don't work on Windows
        } else {
            _ = strftime(timeString, 8, "%I:%M", timeInfo); // I could use %p but in many locals the AM and PM string are empty
            if (timeInfo.hour >= 12) {
                _ = strcat(timeString, "pm");
            } else {
                _ = strcat(timeString, "am");
            }
        }
    }
}

pub export fn getWeekOfYearString(weekOfYearString: [*]u8) linksection(code_section) callconv(.c) void {
    var jd: real34_t = undefined;
    var y: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;

    if (comptime dmcp_build) {
        var timeInfo: tm_t = undefined;
        var dateInfo: dt_t = undefined;

        rtc_read(&timeInfo, &dateInfo);
        uInt32ToReal34(dateInfo.year, &y);
        uInt32ToReal34(dateInfo.month, &m);
        uInt32ToReal34(dateInfo.day, &d);
    } else {
        const epoch: i64 = time(null);
        const timeInfo = localtime(&epoch);

        uInt32ToReal34(@intCast(timeInfo.year + 1900), &y);
        uInt32ToReal34(@intCast(timeInfo.mon + 1), &m);
        uInt32ToReal34(@intCast(timeInfo.mday), &d);
    }

    composeJulianDay(&y, &m, &d, &jd);
    const woy: u32 = getWeekOfYear(&jd);
    var dow: i32 = @intCast(julianDayToDayOfWeek(&jd));
    dow = modulo((dow + 7) - firstDayOfWeek, 7) + 1;
    _ = sprintf(weekOfYearString, "W%02d-%d", @as(c_int, @intCast(woy)), @as(c_int, dow));
}

comptime {
    _ = REAL34_SIZE_IN_BLOCKS;
    _ = builtin;
}
