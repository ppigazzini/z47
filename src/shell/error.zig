const std = @import("std");
const consts = abi.constants;
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/error.c: the error-display core. displayCalcErrorMessage
// is called by essentially every owner — it sets lastErrorCode (which the
// testSuite asserts, e.g. arccos(String) -> Error24), errorMessageRegisterLine
// and screenUpdatingMode. displayDomainErrorMessage, fnRaiseError, fnErrorMessage,
// the bug-screen renderer (displayBugScreen), the packed error-message pool
// behind errorMessageOf and the commonBugScreenMessages table (imported by other
// C files as `extern const char [N][SIZE]`) live here too.
//
// Faithful, line-by-line port. The IR_PRINTING tail of displayCalcErrorMessage
// lives here as printErrorTrace, which the engine's entry point calls once it
// has recorded the error status. moreInfoOnError is
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
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const DECNUMUNITS = 25;
const abi = @import("abi"); // shared ABI bindings
const frontier_char_string = @import("display/text/char_string.zig");
const frontier_debug = @import("debug.zig");
const frontier_register_value_conversions = @import("register_value_conversions.zig");
const frontier_screen = @import("display/screen.zig");
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
// Opaque font handle; the bug screen only takes its address.
const font_t = abi.Font;

const calcRegister_t = i16;
const angularMode_t = c_int;

// ---------------------------------------------------------------------------
// Constants / enum values (defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const NUMBER_OF_ERROR_CODES: u8 = 129; // defines.h: 129 (not 127); error 128 = ERROR_TI_UNDO_FAILED. The bounds check below rejected codes 127/128 when this was 127.
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
const const34_1 = consts.const34_1();

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

// lcd_fill_rect is a DMCP SDK fixed-address library call on firmware
// (LIBRARY_FN_BASE+60); on host it is a real symbol from the GTK layer. The jump
// table sits at a different address on each board -- 0x08000201 on the DM42 and
// 0x08000301 on the DM42n, per each SDK's lft_ifc.h -- so the base is selected,
// never assumed. Hardcoding the DM42 one sends the DMCP5 image to the wrong entry.
const LIBRARY_FN_BASE: usize = if (frontier_build_options.old_hw) 0x08000201 else 0x08000301;
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcdFillRect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}

// from the now-Zig register-value-conversions owner.

// real34 compares (mathematics/comparisonReals.c).
extern fn real34CompareLessEqual(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;
extern fn real34CompareLessThan(a: *align(1) const real34_t, b: *align(1) const real34_t) bool;

// decQuad helpers (the real34 macros).
extern fn decQuadFromUInt32(r: *real34_t, v: u32) *real34_t;
extern fn decQuadToUInt32(r: *align(1) const real34_t, ctx: *realContext_t, round: c_int) u32;

// libc.
extern fn strlen(s: [*c]const u8) usize;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
const reg34 = abi.registerReal34;
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

// STD_* macro byte sequences (src/c47/fonts.h).
const STD_INFINITY = "\xa2\x1e";
const STD_DELTA = "\x83\x94";
const STD_GREATER_EQUAL = "\xa2\x65";

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

// The error and status messages, one per error code. They are not stored as
// fixed-width rows: errorMessagePool below packs them back to back, so a short
// message costs its own length and not the width of the longest one.
const errorMessageTexts = [NUMBER_OF_ERROR_CODES][]const u8{
    "No error",
    "An argument exceeds the function domain",
    "Bad time or date input",
    "Undefined op-code",
    "Overflow at +" ++ STD_INFINITY,
    "Overflow at -" ++ STD_INFINITY,
    "No such label found",
    "No such function",
    "Out of range",
    "Illegal digit in integer input for this base",
    "Input is too long",
    "RAM is full",
    "Stack clash",
    "Operation is undefined in this mode",
    "Word size is too small",
    "Too few data points for this statistic",
    "Distribution parameter out of valid range",
    "I/O error",
    "Invalid or corrupted data",
    "Flash memory is write protected",
    "No root found",
    "Matrix mismatch",
    "Singular matrix",
    "Flash memory is full",
    "Invalid input data type for this operation",
    "No MVAR found in selected program",
    "Please enter a NEW name",
    "Cannot delete a predefined item",
    "No statistic data present",
    "Item to be coded",
    "Function to be coded for that data type",
    "Input data types do not match",
    "This system flag is write protected",
    "Output would exceed 508 characters",
    "This does not work with an empty string",
    "No backup data found",
    "Undefined source variable",
    "This variable is write protected",
    "No matrix indexed",
    "Not enough memory for such a matrix",
    "No errors for selected model",
    "Large " ++ STD_DELTA ++ " and opposite signs, may be a pole",
    "Solver reached local extremum, no root",
    STD_GREATER_EQUAL ++ "1 initial guess lies out of the domain",
    "The function values seem constant",
    "Syntax error in this equation",
    "This equation formula is too complex",
    "This item cannot be assigned here",
    "Invalid name",
    "Too many variables",
    "Non-programmable command, please remove",
    "No global label in this program",
    "Invalid input data type for polar/rect mode",
    "Bad input",
    "No program specified",
    "Cannot write file ",
    "Function has changed, please replace",
    "Variable required, please select variable",
    "HEX/DEC/OCT/BIN not usable with iCPX",
    "Undefined menu name",
    "Operation aborted",
    "Reserved variable name",
    "Invalid register type/angle",
    "Printing Is Disabled",
    "No string in alpha register", // 64  ERROR_NO_STRING_IN_ALPHA_REGISTER (42S alpha ops)
    "No equation defined", // 65  ERROR_NO_EQUATION_DEFINED
    "Nesting too deep", // 66  ERROR_NESTING_TOO_DEEP
    "", // 67
    "", // 68
    "", // 69
    "", // 70
    "", // 71
    "", // 72
    "", // 73
    "", // 74
    "", // 75
    "", // 76
    "", // 77
    "", // 78
    "", // 79
    "", // 80
    "", // 81
    "", // 82
    "", // 83
    "", // 84
    "", // 85
    "", // 86
    "", // 87
    "", // 88
    "", // 89
    "", // 90
    "", // 91
    "", // 92
    "", // 93
    "", // 94
    "", // 95
    "", // 96
    "", // 97
    "", // 98
    "", // 99
    " Loading state file ...",
    " Saving state file ...",
    " Loading stats ...",
    " Solving for real/complex root ...",
    " Calculating graph coordinates ...",
    " Re-calculating sums ... ",
    " Solving for real root ...",
    "Backup restored",
    "State file loaded",
    "Programs and equations loaded",
    "appended",
    "Global and local registers loaded",
    "(w/ local flags)",
    "System settings loaded",
    "Statistical data loaded",
    "User variables loaded",
    "Program file loaded",
    "All global user flags cleared",
    "All data, programs and definitions cleared",
    "All user menus cleared",
    "All user variables cleared",
    "All user programs deleted",
    "All user menus deleted",
    "All user variables deleted",
    "Data file loaded",
    "Data file saved",
    "Not available on the simulator",
    "Only available on the simulator",
    "Undo failed: likely no memory",
};

// Every message, NUL terminator included, laid end to end in one blob with no
// padding between them, plus a per-code byte offset into it. The pool and the
// offsets are file-local: errorMessageOf is the only way to reach a message.
const errorMessagePoolSize = blk: {
    var size: usize = 0;
    for (errorMessageTexts) |text| size += text.len + 1;
    break :blk size;
};

const errorMessagePool linksection(code_section) = blk: {
    var pool: [errorMessagePoolSize]u8 = undefined;
    var at: usize = 0;
    for (errorMessageTexts) |text| {
        @memcpy(pool[at..][0..text.len], text);
        pool[at + text.len] = 0;
        at += text.len + 1;
    }
    break :blk pool;
};

const errorMessageOffset linksection(code_section) = blk: {
    var offsets: [NUMBER_OF_ERROR_CODES]u16 = undefined;
    var at: u16 = 0;
    for (errorMessageTexts, 0..) |text, code| {
        offsets[code] = at;
        at += @intCast(text.len + 1);
    }
    break :blk offsets;
};

pub export fn errorMessageOf(errorCode: u8) linksection(code_section) callconv(.c) [*c]const u8 {
    return @ptrCast(&errorMessagePool[errorMessageOffset[errorCode]]);
}

// ---------------------------------------------------------------------------
// moreInfoOnError. Upstream defines the printf console popup only for PC_BUILD;
// on firmware the Zig math owners still call moreInfoOnError unconditionally, so
// a no-op stub is provided there. Reproduce both: a no-op on firmware, the real
// popup on host.
// ---------------------------------------------------------------------------
pub fn moreInfoOnErrorImpl(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void {
    var utf8m1: [2000]u8 = undefined;
    var utf8m2: [2000]u8 = undefined;
    var utf8m3: [2000]u8 = undefined;
    var utf8m4: [2000]u8 = undefined;

    if (@intFromPtr(m1) == 0) {
        frontier_char_string.stringToUtf8("No error message available!", &utf8m1);
        _ = printf("\n%s\n", &utf8m1);
    } else if (m2 == null) {
        frontier_char_string.stringToUtf8(m1, &utf8m1);
        _ = printf("\n%s\n\n", &utf8m1);
    } else if (m3 == null) {
        frontier_char_string.stringToUtf8(m1, &utf8m1);
        frontier_char_string.stringToUtf8(m2.?, &utf8m2);
        _ = printf("\n%s\n%s\n\n", &utf8m1, &utf8m2);
    } else if (m4 == null) {
        frontier_char_string.stringToUtf8(m1, &utf8m1);
        frontier_char_string.stringToUtf8(m2.?, &utf8m2);
        frontier_char_string.stringToUtf8(m3.?, &utf8m3);
        _ = printf("\n%s\n%s\n%s\n\n", &utf8m1, &utf8m2, &utf8m3);
    } else {
        frontier_char_string.stringToUtf8(m1, &utf8m1);
        frontier_char_string.stringToUtf8(m2.?, &utf8m2);
        frontier_char_string.stringToUtf8(m3.?, &utf8m3);
        frontier_char_string.stringToUtf8(m4.?, &utf8m4);
        _ = printf("\n%s\n%s\n%s\n%s\n\n", &utf8m1, &utf8m2, &utf8m3, &utf8m4);
    }
}

fn moreInfoOnErrorStub(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) callconv(.c) void {
    _ = m1;
    _ = m2;
    _ = m3;
    _ = m4;
}

// The C symbol `moreInfoOnError` exists on every target: the real popup where the
// hints are compiled in, a no-op stub everywhere else. Upstream guards every call
// site with EXTRA_INFO_ON_CALC_ERROR, which is 0 on firmware AND in the testSuite;
// owners here call it unconditionally, so the gate lives on the symbol instead.
comptime {
    @export(if (dmcp_build or !extra_info) &moreInfoOnErrorStub else &moreInfoOnErrorImpl, .{ .name = "moreInfoOnError", .linkage = .strong });
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
            frontier_register_value_conversions.convertLongIntegerRegisterToReal34(REGISTER_X, &r);
        },
        dtReal34 => {
            if (getRegisterAngularMode(REGISTER_X) == amNone) {
                real34Copy(reg34(REGISTER_X), &r);
            } else {
                badDataType();
                return;
            }
        },
        else => {
            badDataType();
            return;
        },
    }

    if (real34CompareLessEqual(const34_1, &r) and real34CompareLessThan(&r, &maxErr)) {
        displayCalcErrorMessage(@truncate(real34ToUInt32(&r)), ERR_REGISTER_LINE, REGISTER_X);
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        if (comptime extra_info) {
            abi.fmtBufZ(errorMessage[0..512], "the argument is not less than {d} or is negative!", .{@as(c_uint, NUMBER_OF_ERROR_CODES)});
            moreInfoOnErr("In function fnErrorMessage:", errorMessage);
        }
    }
}

// fnErrorMessage's X-register refusal: the diagnostic names the offending data
// type, so it is composed per call rather than shared as a literal.
fn badDataType() void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    if (comptime extra_info) {
        abi.fmtBufZ(errorMessage[0..512], "data type {s} cannot be used for this function!", .{std.mem.span(frontier_debug.getRegisterDataTypeName(REGISTER_X, false, false))});
        moreInfoOnErr("In function fnErrorMessage:", errorMessage);
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
// The error-report entry point moved to the base kernel
// (engine/kernel/error_report.zig): its normal path is pure state recording, not
// display. Only the defensive bug-screen branch is UI, and it is installed here
// as the host boundary's reportBugError hook. The engine reaches the entry point
// intra-core; the shell owners that call it (displayDomainErrorMessage below)
// resolve it through this extern re-declaration.
pub extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, disUsedCanBeRemoved: calcRegister_t) callconv(.c) void;

// printErrorTrace: the OPTION_IR_PRINTING tail of displayCalcErrorMessage.
//
// error.c runs this straight after recording lastErrorCode: with a TAM command
// still pending it first flushes that command to the trace, then prints the
// error text -- prefixed with the offending name for a reserved-variable clash.
// Everything it touches is shell state (the TAM buffer, the printer's trace_done
// latch, the error-message table and the IR printer), so it stays with error.c's
// port while the engine keeps the entry point and calls this once the status is
// recorded.
//
// OPTION_IR_PRINTING is defined unconditionally at defines.h:72 and undefined
// only by DMCP packages 1 and 3, so this is live on the simulator, in the
// testSuite, on DMCP5 and on packages 2 and 4. With the option off nothing here
// runs -- the tmpString write included, exactly as the #if leaves it.
const ir_printing: bool = frontier_build_options.ir_printing;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_RESERVED_VARIABLE_NAME: u8 = 61;

extern var tam: abi.TamState;
extern var printerState: abi.PrinterState;
extern var tmpString: [*c]u8;
extern fn printTrace(func: i16, param: u16) callconv(.c) void;
extern fn printTraceError(errorString: [*c]u8) callconv(.c) void;

pub export fn printErrorTrace(errorCode: u8) callconv(.c) void {
    if (comptime !ir_printing) return;

    if (tam.mode != 0 and errorCode != ERROR_LABEL_NOT_FOUND and !printerState.trace_done) {
        printTrace(tam.function, @bitCast(tam.value));
    }

    if (lastErrorCode == ERROR_RESERVED_VARIABLE_NAME) {
        _ = sprintf(tmpString, "%s: %s", errorMessageOf(lastErrorCode), errorMessage);
    } else {
        _ = sprintf(tmpString, "%s", errorMessageOf(lastErrorCode));
    }
    printTraceError(tmpString);
}

// reportBugError: the shell implementation of the host bug-report hook. It fires
// only for an out-of-range error code or register line -- a programming error,
// never a normal calculation error -- so it formats the diagnostic and paints
// the bug screen. The condition order mirrors the original entry point (error
// code checked before register line).
pub export fn reportBugError(errorCode: u8, errMessageRegisterLine: calcRegister_t) callconv(.c) void {
    if (errorCode >= NUMBER_OF_ERROR_CODES or errorCode == 0) {
        abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "displayCalcErrorMessage", @as(c_int, errorCode), "errorCode" });
        displayBugScreen(@ptrCast(errorMessage));
    } else {
        abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "displayCalcErrorMessage", @as(c_int, errMessageRegisterLine), "errMessageRegisterLine" });
        abi.fmtBufZ(errorMessage[strlen(errorMessage)..512], "Must be from 100 (register X) to 103 (register T)", .{});
        displayBugScreen(@ptrCast(errorMessage));
    }
}

// ---------------------------------------------------------------------------
// displayDomainErrorMessage
// ---------------------------------------------------------------------------
pub export fn displayDomainErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, disUsedCanBeRemoved: calcRegister_t) callconv(.c) void {
    const running: bool = programRunStop == PGM_RUNNING;
    const spcres: bool = getSystemFlag(FLAG_SPCRES);

    if (!spcres or !running) {
        displayCalcErrorMessage(errorCode, errMessageRegisterLine, disUsedCanBeRemoved);
    }
    if (spcres) {
        frontier_register_value_conversions.convertRealToResultRegister(const_NaN, REGISTER_X, amNone);
    }
}

// ---------------------------------------------------------------------------
// nextWord (file-static helper)
// ---------------------------------------------------------------------------
/// Copies the next word of a NULL terminated list of strings, walked as one flow,
/// into word. Separators, part boundaries and a broken trailing lead byte are
/// skipped on the way in. A lead byte with no partner byte can only be the string's
/// own NUL terminator, since a genuine second byte of value 0 would end the C
/// string there too -- so it unambiguously marks a message truncated mid glyph, and
/// the orphan is dropped rather than read as part of a word.
///
/// Words are stepped a whole glyph at a time, never a byte: the second byte of a
/// two byte glyph is free to be anything, including the 0x20 of a separator, so a
/// byte comparison would split such a glyph and leave a lead byte with no partner
/// for the font scan to read past.
///
/// A word too long for word is stopped on a glyph boundary and its remainder is
/// left for the next call, which returns it as a word of its own.
///
/// part is the strings, NULL terminated; p is which string is being read, moved on
/// past exhausted parts; pos is the offset into that string, left just past the
/// word; word receives the word, NUL terminated. Returns true if a word was
/// copied, false when the list is exhausted.
fn nextWord(part: []const ?[*:0]const u8, p: *i16, pos: *i16, word: []u8) bool {
    const maxLen: i16 = @intCast(word.len - 1);
    var str: [*:0]const u8 = undefined;

    while (true) {
        const candidate = part[@intCast(p.*)];

        if (candidate == null) {
            return false;
        }
        str = candidate.?;

        if (str[@intCast(pos.*)] == 0) {
            p.* += 1;
            pos.* = 0;
            continue;
        }

        if (str[@intCast(pos.*)] == ' ') {
            pos.* += 1;
            continue;
        }

        if ((str[@intCast(pos.*)] & 0x80) != 0 and str[@intCast(pos.* + 1)] == 0) {
            p.* += 1;
            pos.* = 0;
            continue;
        }

        break;
    }

    const start = pos.*;

    while (str[@intCast(pos.*)] != 0 and str[@intCast(pos.*)] != ' ') {
        const step: i16 = if ((str[@intCast(pos.*)] & 0x80) != 0) 2 else 1;

        if (step == 2 and str[@intCast(pos.* + 1)] == 0) {
            break;
        }

        if (pos.* - start + step > maxLen) {
            break;
        }

        pos.* += step;
    }

    const len: usize = @intCast(pos.* - start);
    _ = frontier_char_string.xcopy(word.ptr, str + @as(usize, @intCast(start)), @intCast(len));
    word[len] = 0;
    return true;
}

// ---------------------------------------------------------------------------
// displayBugScreen
// ---------------------------------------------------------------------------
pub export fn displayBugScreen(msg: [*:0]const u8) callconv(.c) void {
    if (calcMode != CM_BUG_ON_SCREEN) {
        const bugScreenTail: [*:0]const u8 = "Try to reproduce this and report a bug. Press EXIT to leave.";
        // The width of STD_SPACE_PUNCTUATION in standardFont.
        const SEP_WIDTH: i16 = 4;
        var part: [3]?[*:0]const u8 = undefined;
        var word: [100]u8 = undefined;

        previousCalcMode = calcMode;
        calcMode = CM_BUG_ON_SCREEN;
        clearSystemFlag(FLAG_ALPHA);
        frontier_screen.hideCursor();
        cursorEnabled = 0;

        lcdFillRect(0, 20, @intCast(SCREEN_WIDTH), 220, LCD_SET_VALUE);

        var y: i16 = 20;
        _ = frontier_screen.showString("This is most likely a bug in the firmware!", &standardFont, 1, @intCast(y), vmNormal, @intFromBool(true), @intFromBool(false));
        y += 20;

        part[0] = msg;
        part[1] = bugScreenTail;
        part[2] = null;

        // One word at a time, drawn where it lands: only the word is ever buffered,
        // so the line exists as an x position rather than as a string. The gap
        // between words is the separator's width added to x, so no separator is
        // ever stored or measured.
        var p: i16 = 0;
        var pos: i16 = 0;
        var x: i16 = 1;

        const wordZ: [*:0]const u8 = @ptrCast(&word);
        while (nextWord(&part, &p, &pos, &word)) {
            const w: i16 = frontier_char_string.stringWidth(wordZ, &standardFont, true, true);

            // The first word of a line is kept however wide it is: the next line is
            // no wider.
            if (x != 1 and @as(c_int, x) + @as(c_int, w) >= SCREEN_WIDTH) {
                y += 20;
                x = 1;
            }

            _ = frontier_screen.showString(wordZ, &standardFont, @intCast(x), @intCast(y), vmNormal, @intFromBool(true), @intFromBool(false));
            x += w + SEP_WIDTH;
        }
    }
}

// ---------------------------------------------------------------------------
// typeError (EXTRA_INFO_ON_CALC_ERROR != 1 in C; always provided here — see header).
// ---------------------------------------------------------------------------
pub export fn typeError() callconv(.c) void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
}
