const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/error.c: the error-display core. displayCalcErrorMessage
// is called by essentially every owner — it sets lastErrorCode (which the
// testSuite asserts, e.g. arccos(String) -> Error24), errorMessageRegisterLine
// and screenUpdatingMode. displayDomainErrorMessage, fnRaiseError, fnErrorMessage,
// the bug-screen renderer (displayBugScreen) and the two big string tables
// (errorMessages, commonBugScreenMessages — imported by other C files as
// `extern const char [N][SIZE]`) live here too.
//
// Faithful, line-by-line port. The IR_PRINTING branch of displayCalcErrorMessage
// is omitted (IR_PRINTING is never defined for any z47 build). moreInfoOnError is
// PC-only (gated on !dmcp_build); the EXTRA_INFO sprintf register-type hints in
// fnErrorMessage are host-only and reduced to a fixed moreInfoOnError() string as
// in the sibling owners. typeError is exported unconditionally: upstream defines
// it whenever EXTRA_INFO_ON_CALC_ERROR != 1, which is true for both the firmware
// and testSuite C builds; the frontier object is compiled once with
// extra_info_on_calc_error = true (host default) yet the testSuite C consumers are
// compiled with TESTSUITE_BUILD (EXTRA_INFO == 0) and reference typeError, so it
// must always be present. error.c is the only definer, so no duplicate-symbol risk.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const dmcp_build: bool = frontier_build_options.dmcp_build;

// Rarely-hot bug-screen code and the two TO_QSPI string tables go to the
// executable QSPI region on the flash-limited old_hw DM42 (matches the sibling
// distribution owners' code_section).
const code_section = if (frontier_build_options.dmcp_build and frontier_build_options.old_hw)
    ".qspi"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};
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
// Opaque font handle; the bug screen only takes its address.
const font_t = opaque {};

const calcRegister_t = i16;
const angularMode_t = c_int;

// ---------------------------------------------------------------------------
// Constants / enum values (defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const NUMBER_OF_ERROR_CODES: u8 = 127;
const SIZE_OF_EACH_ERROR_MESSAGE: usize = 48;
const NUMBER_OF_BUG_SCREEN_MESSAGES: usize = 10;
const SIZE_OF_EACH_BUG_SCREEN_MESSAGE: usize = 100;

const CM_BUG_ON_SCREEN: u8 = 10;
const SCRUPD_AUTO: u8 = 0x00;
const bugMsgValueFor: usize = 0;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_Z: calcRegister_t = 102;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const amNone: angularMode_t = 5;
const amAngleMask: u32 = 15;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;

const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_OUT_OF_RANGE: u8 = 8;

const PGM_RUNNING: u8 = 1;
const FLAG_SPCRES: c_int = 0x8017;
const FLAG_ALPHA: c_uint = 0x800e;

const SCREEN_WIDTH: i16 = 400;
const LCD_SET_VALUE: c_int = 0; // PC: 0; firmware: LCD_INVERT_DATA defined -> 0
const vmNormal: c_int = 0;

const DEC_ROUND_DOWN: c_int = 5;

// ---------------------------------------------------------------------------
// Constant blob (shared `constants` symbol by byte offset).
// ---------------------------------------------------------------------------
const constants = @extern([*]const u8, .{ .name = "constants" });
const OFF_const34_1 = 15804;
inline fn cst34(offset: u32) *align(1) const real34_t {
    return @ptrCast(constants + offset);
}
const const34_1 = cst34(OFF_const34_1);

// const_NaN is a `const real_t *` global pointer (the address is the value).
extern var const_NaN: *const real_t;

// ---------------------------------------------------------------------------
// Globals (extern var)
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var errorMessageRegisterLine: calcRegister_t;
extern var screenUpdatingMode: u8;
extern var previousCalcMode: u8;
extern var calcMode: u8;
extern var cursorEnabled: u8;
extern var programRunStop: u8;
extern var errorMessage: [*c]u8;
extern var ctxtReal34: realContext_t;
extern const standardFont: font_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getSystemFlag(flag: c_int) bool;
extern fn clearSystemFlag(flag: c_uint) void;
extern fn hideCursor() void;

// lcd_fill_rect is a DMCP SDK fixed-address library call on firmware
// (LIBRARY_FN_BASE+60); on host it is a real symbol from the GTK layer.
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcdFillRect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(0x08000201 + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}
extern fn showString(str: [*:0]const u8, font: *const font_t, x: u32, y: u32, video_mode: c_int, show_leading_cols: bool, show_ending_cols: bool) u32;
extern fn stringWidth(str: [*:0]const u8, font: *const font_t, with_leading: bool, with_ending: bool) i16;
extern fn stringToUtf8(src: [*:0]const u8, dst: [*]u8) void;

// from the now-Zig register-value-conversions owner.
extern fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: angularMode_t) void;
extern fn convertLongIntegerRegisterToReal34(source: calcRegister_t, destination: *real34_t) void;

// real34 compares (mathematics/comparisonReals.c).
extern fn real34CompareLessEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;

// decQuad helpers (the real34 macros).
extern fn decQuadFromUInt32(r: *real34_t, v: u32) *real34_t;
extern fn decQuadToUInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) u32;

// libc.
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn reg34(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn uInt32ToReal34(src: u32, dst: *real34_t) void {
    _ = decQuadFromUInt32(dst, src);
}
inline fn real34ToUInt32(src: *align(1) const real34_t) u32 {
    return decQuadToUInt32(src, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn real34Copy(src: *align(1) const real34_t, dst: *real34_t) void {
    dst.* = src.*;
}

// ---------------------------------------------------------------------------
// String tables (TO_QSPI const char [N][SIZE]).
// Each C string is copied into a zero-filled fixed-width row.
// ---------------------------------------------------------------------------
fn bugRow(comptime s: []const u8) [SIZE_OF_EACH_BUG_SCREEN_MESSAGE]u8 {
    var row = std.mem.zeroes([SIZE_OF_EACH_BUG_SCREEN_MESSAGE]u8);
    @memcpy(row[0..s.len], s);
    return row;
}
fn errRow(comptime s: []const u8) [SIZE_OF_EACH_ERROR_MESSAGE]u8 {
    var row = std.mem.zeroes([SIZE_OF_EACH_ERROR_MESSAGE]u8);
    @memcpy(row[0..s.len], s);
    return row;
}

// STD_* macro byte sequences (src/c47/fonts.h).
const STD_INFINITY = "\xa2\x1e";
const STD_DELTA = "\x83\x94";
const STD_GREATER_EQUAL = "\xa2\x65";
const STD_SPACE_PUNCTUATION = "\xa0\x08";

// PRIu8 -> u, PRId16 -> d, PRIu32 -> u, PRIu16 -> u (preprocessor expansion).
pub export const commonBugScreenMessages linksection(code_section) = [NUMBER_OF_BUG_SCREEN_MESSAGES][SIZE_OF_EACH_BUG_SCREEN_MESSAGE]u8{
    bugRow("In function %s:%d is an unexpected value for %s!"),
    bugRow("In function %s: unexpected calcMode value (%u) while processing key %s!"),
    bugRow("In function %s: no named variables defined!"),
    bugRow("In function %s: %d is an unexpected value returned by findGlyph!"),
    bugRow("In function %s: %u is an unexpected %s value!"),
    bugRow("In function %s: data type %s is unknown!"),
    bugRow("In function %s: regist=%d must be less than %d!"),
    bugRow("In function %s: %s %d is not defined! Must be from 0 to %u"),
    bugRow("In function %s: unexpected case while processing key %s! %u is an unexpected value for rbrMode."),
    bugRow(""),
};

pub export const errorMessages linksection(code_section) = [NUMBER_OF_ERROR_CODES][SIZE_OF_EACH_ERROR_MESSAGE]u8{
    errRow("No error"),
    errRow("An argument exceeds the function domain"),
    errRow("Bad time or date input"),
    errRow("Undefined op-code"),
    errRow("Overflow at +" ++ STD_INFINITY),
    errRow("Overflow at -" ++ STD_INFINITY),
    errRow("No such label found"),
    errRow("No such function"),
    errRow("Out of range"),
    errRow("Illegal digit in integer input for this base"),
    errRow("Input is too long"),
    errRow("RAM is full"),
    errRow("Stack clash"),
    errRow("Operation is undefined in this mode"),
    errRow("Word size is too small"),
    errRow("Too few data points for this statistic"),
    errRow("Distribution parameter out of valid range"),
    errRow("I/O error"),
    errRow("Invalid or corrupted data"),
    errRow("Flash memory is write protected"),
    errRow("No root found"),
    errRow("Matrix mismatch"),
    errRow("Singular matrix"),
    errRow("Flash memory is full"),
    errRow("Invalid input data type for this operation"),
    errRow("No MVAR found in selected program"),
    errRow("Please enter a NEW name"),
    errRow("Cannot delete a predefined item"),
    errRow("No statistic data present"),
    errRow("Item to be coded"),
    errRow("Function to be coded for that data type"),
    errRow("Input data types do not match"),
    errRow("This system flag is write protected"),
    errRow("Output would exceed 508 characters"),
    errRow("This does not work with an empty string"),
    errRow("No backup data found"),
    errRow("Undefined source variable"),
    errRow("This variable is write protected"),
    errRow("No matrix indexed"),
    errRow("Not enough memory for such a matrix"),
    errRow("No errors for selected model"),
    errRow("Large " ++ STD_DELTA ++ " and opposite signs, may be a pole"),
    errRow("Solver reached local extremum, no root"),
    errRow(STD_GREATER_EQUAL ++ "1 initial guess lies out of the domain"),
    errRow("The function values seem constant"),
    errRow("Syntax error in this equation"),
    errRow("This equation formula is too complex"),
    errRow("This item cannot be assigned here"),
    errRow("Invalid name"),
    errRow("Too many variables"),
    errRow("Non-programmable command, please remove"),
    errRow("No global label in this program"),
    errRow("Invalid input data type for polar/rect mode"),
    errRow("Bad input"),
    errRow("No program specified"),
    errRow("Cannot write file "),
    errRow("Function has changed, please replace"),
    errRow("Variable required, please select variable"),
    errRow("HEX/DEC/OCT/BIN not usable with iCPX"),
    errRow("Undefined menu name"),
    errRow("Operation aborted"),
    errRow("Reserved variable name"),
    errRow("Invalid register type/angle"),
    errRow("Printing Is Disabled"),
    errRow(""), // 64
    errRow(""), // 65
    errRow(""), // 66
    errRow(""), // 67
    errRow(""), // 68
    errRow(""), // 69
    errRow(""), // 70
    errRow(""), // 71
    errRow(""), // 72
    errRow(""), // 73
    errRow(""), // 74
    errRow(""), // 75
    errRow(""), // 76
    errRow(""), // 77
    errRow(""), // 78
    errRow(""), // 79
    errRow(""), // 80
    errRow(""), // 81
    errRow(""), // 82
    errRow(""), // 83
    errRow(""), // 84
    errRow(""), // 85
    errRow(""), // 86
    errRow(""), // 87
    errRow(""), // 88
    errRow(""), // 89
    errRow(""), // 90
    errRow(""), // 91
    errRow(""), // 92
    errRow(""), // 93
    errRow(""), // 94
    errRow(""), // 95
    errRow(""), // 96
    errRow(""), // 97
    errRow(""), // 98
    errRow(""), // 99
    errRow("  Loading state file ..."),
    errRow("  Saving state file ..."),
    errRow("  Loading stats ..."),
    errRow("  Solving for real/complex root ..."),
    errRow("  Calculating graph coordinates ..."),
    errRow("  Re-calculating sums ... "),
    errRow("  Solving for real root ..."),
    errRow("Backup restored"),
    errRow("State file loaded"),
    errRow("Programs and equations loaded"),
    errRow("appended"),
    errRow("Global and local registers loaded"),
    errRow("(w/ local flags)"),
    errRow("System settings loaded"),
    errRow("Statistical data loaded"),
    errRow("User variables loaded"),
    errRow("Program file loaded"),
    errRow("All global user flags cleared"),
    errRow("All data, programs and definitions cleared"),
    errRow("All user menus cleared"),
    errRow("All user variables cleared"),
    errRow("All user programs deleted"),
    errRow("All user menus deleted"),
    errRow("All user variables deleted"),
    errRow("Not available on the simulator"),
    errRow("Only available on the simulator"),
    errRow("Undo failed: likely no memory"),
};

// ---------------------------------------------------------------------------
// moreInfoOnError. Upstream defines the printf console popup only for PC_BUILD;
// the error_legacy.c shim supplied a no-op stub for !PC_BUILD because the Zig
// math owners call moreInfoOnError unconditionally. Reproduce both: a no-op on
// firmware, the real popup on host.
// ---------------------------------------------------------------------------
fn moreInfoOnErrorImpl(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void {
    var utf8m1: [2000]u8 = undefined;
    var utf8m2: [2000]u8 = undefined;
    var utf8m3: [2000]u8 = undefined;
    var utf8m4: [2000]u8 = undefined;

    if (@intFromPtr(m1) == 0) {
        stringToUtf8("No error message available!", &utf8m1);
        _ = printf("\n%s\n", &utf8m1);
    } else if (m2 == null) {
        stringToUtf8(m1, &utf8m1);
        _ = printf("\n%s\n\n", &utf8m1);
    } else if (m3 == null) {
        stringToUtf8(m1, &utf8m1);
        stringToUtf8(m2.?, &utf8m2);
        _ = printf("\n%s\n%s\n\n", &utf8m1, &utf8m2);
    } else if (m4 == null) {
        stringToUtf8(m1, &utf8m1);
        stringToUtf8(m2.?, &utf8m2);
        stringToUtf8(m3.?, &utf8m3);
        _ = printf("\n%s\n%s\n%s\n\n", &utf8m1, &utf8m2, &utf8m3);
    } else {
        stringToUtf8(m1, &utf8m1);
        stringToUtf8(m2.?, &utf8m2);
        stringToUtf8(m3.?, &utf8m3);
        stringToUtf8(m4.?, &utf8m4);
        _ = printf("\n%s\n%s\n%s\n%s\n\n", &utf8m1, &utf8m2, &utf8m3, &utf8m4);
    }
}

fn moreInfoOnErrorStub(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void {
    _ = m1;
    _ = m2;
    _ = m3;
    _ = m4;
}

// The C symbol `moreInfoOnError` exists on every target: the real popup on host,
// a no-op stub on firmware (matching error.c's #if PC_BUILD + the legacy shim's
// !PC_BUILD stub). Zig math owners call it unconditionally.
comptime {
    @export(if (dmcp_build) &moreInfoOnErrorStub else &moreInfoOnErrorImpl, .{ .name = "moreInfoOnError", .linkage = .strong });
}

// ---------------------------------------------------------------------------
// fnRaiseError / fnErrorMessage
// ---------------------------------------------------------------------------
pub export fn fnRaiseError(errorCode: u16) callconv(.c) void {
    displayCalcErrorMessage(@truncate(errorCode), ERR_REGISTER_LINE, REGISTER_X);
}

pub export fn fnErrorMessage(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var r: real34_t = undefined;
    var maxErr: real34_t = undefined;
    uInt32ToReal34(NUMBER_OF_ERROR_CODES, &maxErr);

    switch (getRegisterDataType(REGISTER_X)) {
        dtLongInteger => {
            convertLongIntegerRegisterToReal34(REGISTER_X, &r);
        },
        dtReal34 => {
            if (getRegisterAngularMode(REGISTER_X) == amNone) {
                real34Copy(reg34(REGISTER_X), &r);
            } else {
                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnErr("In function fnErrorMessage:", "data type cannot be used for this function!");
                return;
            }
        },
        else => {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            moreInfoOnErr("In function fnErrorMessage:", "data type cannot be used for this function!");
            return;
        },
    }

    if (real34CompareLessEqual(const34_1, &r) and real34CompareLessThan(&r, &maxErr)) {
        displayCalcErrorMessage(@truncate(real34ToUInt32(&r)), ERR_REGISTER_LINE, REGISTER_X);
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnErr("In function fnErrorMessage:", "the argument is not less than NUMBER_OF_ERROR_CODES or is negative!");
    }
}

// EXTRA_INFO console hint helper (compiled out on firmware, like the siblings).
inline fn moreInfoOnErr(where: [*:0]const u8, hint: [*:0]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnErrorImpl(where, hint, null, null);
        }
    }
}

// ---------------------------------------------------------------------------
// displayCalcErrorMessage
// ---------------------------------------------------------------------------
pub export fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) callconv(.c) void {
    const bugFmt: [*:0]const u8 = @ptrCast(&commonBugScreenMessages[bugMsgValueFor]);
    if (errorCode >= NUMBER_OF_ERROR_CODES or errorCode == 0) {
        _ = sprintf(errorMessage, bugFmt, "displayCalcErrorMessage", @as(c_int, errorCode), "errorCode");
        displayBugScreen(@ptrCast(errorMessage));
    } else if (errMessageRegisterLine > REGISTER_T or errMessageRegisterLine < REGISTER_X) {
        _ = sprintf(errorMessage, bugFmt, "displayCalcErrorMessage", @as(c_int, errMessageRegisterLine), "errMessageRegisterLine");
        _ = sprintf(errorMessage + strlen(errorMessage), "Must be from 100 (register X) to 103 (register T)");
        displayBugScreen(@ptrCast(errorMessage));
    } else if (errRegisterLine > REGISTER_T or errRegisterLine < REGISTER_X) {
        _ = sprintf(errorMessage, bugFmt, "displayCalcErrorMessage", @as(c_int, errRegisterLine), "errRegisterLine");
        _ = sprintf(errorMessage + strlen(errorMessage), "Must be from 100 (register X) to 103 (register T)");
        displayBugScreen(@ptrCast(errorMessage));
    } else {
        lastErrorCode = errorCode;
        errorMessageRegisterLine = errMessageRegisterLine;
        screenUpdatingMode = SCRUPD_AUTO;
        // IR_PRINTING block omitted (never defined for any z47 build).
    }
}

// ---------------------------------------------------------------------------
// displayDomainErrorMessage
// ---------------------------------------------------------------------------
pub export fn displayDomainErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) callconv(.c) void {
    const running: bool = programRunStop == PGM_RUNNING;
    const spcres: bool = getSystemFlag(FLAG_SPCRES);

    if (!spcres or !running) {
        displayCalcErrorMessage(errorCode, errMessageRegisterLine, errRegisterLine);
    }
    if (spcres) {
        convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
    }
}

// ---------------------------------------------------------------------------
// nextWord (file-static helper)
// ---------------------------------------------------------------------------
fn nextWord(str: [*c]const u8, pos: *i16, word: [*c]u8) void {
    var i: i16 = 0;

    while (str[@intCast(pos.*)] != 0 and str[@intCast(pos.*)] != ' ') {
        word[@intCast(i)] = str[@intCast(pos.*)];
        i += 1;
        pos.* += 1;
    }

    word[@intCast(i)] = 0;

    while (str[@intCast(pos.*)] == ' ') {
        pos.* += 1;
    }
}

// ---------------------------------------------------------------------------
// displayBugScreen
// ---------------------------------------------------------------------------
pub export fn displayBugScreen(msg: [*:0]const u8) callconv(.c) void {
    if (calcMode != CM_BUG_ON_SCREEN) {
        var y: i16 = undefined;
        var pos: i16 = undefined;
        var line: [100]u8 = undefined;
        var word: [50]u8 = undefined;
        var message: [1000]u8 = undefined;
        var firstWordOfLine: bool = undefined;

        previousCalcMode = calcMode;
        calcMode = CM_BUG_ON_SCREEN;
        clearSystemFlag(FLAG_ALPHA);
        hideCursor();
        cursorEnabled = 0;

        const lineZ: [*:0]const u8 = @ptrCast(&line);
        const wordZ: [*:0]const u8 = @ptrCast(&word);

        lcdFillRect(0, 20, @intCast(SCREEN_WIDTH), 220, LCD_SET_VALUE);

        y = 20;
        _ = showString("This is most likely a bug in the firmware!", &standardFont, 1, @intCast(y), vmNormal, true, false);
        y += 20;

        _ = strcpy(&message, msg);
        _ = strcat(&message, " Try to reproduce this and report a bug. Press EXIT to leave.");

        pos = 0;
        line[0] = 0;
        firstWordOfLine = true;

        nextWord(&message, &pos, &word);
        while (word[0] != 0) {
            if (@as(c_int, stringWidth(lineZ, &standardFont, true, true)) + (if (firstWordOfLine) @as(c_int, 0) else @as(c_int, 4)) + @as(c_int, stringWidth(wordZ, &standardFont, true, true)) >= SCREEN_WIDTH) { // 4 is the width of STD_SPACE_PUNCTUATION
                _ = showString(lineZ, &standardFont, 1, @intCast(y), vmNormal, true, false);
                y += 20;
                line[0] = 0;
                firstWordOfLine = true;
            }

            if (firstWordOfLine) {
                _ = strcpy(&line, &word);
                firstWordOfLine = false;
            } else {
                _ = strcat(&line, STD_SPACE_PUNCTUATION);
                _ = strcat(&line, &word);
            }

            nextWord(&message, &pos, &word);
        }

        if (line[0] != 0) {
            _ = showString(lineZ, &standardFont, 1, @intCast(y), vmNormal, true, false);
        }
    }
}

// ---------------------------------------------------------------------------
// typeError (EXTRA_INFO_ON_CALC_ERROR != 1 in C; always provided here — see header).
// ---------------------------------------------------------------------------
pub export fn typeError() callconv(.c) void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
}
