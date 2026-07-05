const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47Extensions/textfiles.c: copyRegisterToClipboardString2
// (clipboard formatting with the matrix "too large for transfer" fallback),
// stackregister_csv_out (the register-range CSV exporter, USING tmpString) and
// tmpString_csv_out (the alpha-buffer CSV line). This is a faithful,
// line-by-line port of the C. The TO_QSPI ClipBoardMsg[] string table is
// reproduced as a fixed-width [30]-byte row array; the VERBOSE_LEVEL>=1 debug
// blocks are dead (VERBOSE_LEVEL == -1) and omitted.
//
// textfiles.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");

// The TO_QSPI string table goes to the executable QSPI region on the
// flash-limited old_hw DM42, matching the sibling owners' code_section.
const code_section = if (frontier_build_options.dmcp_build and frontier_build_options.old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const calcRegister_t = i16;
const bool_t = bool;
const matrixHeader_t = abi.MatrixHeader;
const registerHeader_t = abi.RegisterHeader;
const abi = @import("abi"); // L1 shared bindings
const namedVariableHeader_t = abi.NamedVariableHeader;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const dtLongInteger: u32 = 0;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;

const TMP_STR_LENGTH: usize = 2560;

const REGISTER_X: i16 = 100;
const REGISTER_W: i16 = 125;
const FIRST_GLOBAL_REGISTER: i16 = 0;
const FIRST_LOCAL_REGISTER: i16 = 7000;
const LAST_LOCAL_REGISTER: i16 = 7098;
const FIRST_NAMED_VARIABLE: i16 = 256;
const LAST_NAMED_VARIABLE: i16 = 1999;

// graphText.h
const CSV_NEWLINE = "\n";
const CSV_TAB = "\t";
const CSV_STR = "\"";

// ClipBoardMsg indices.
const NUMBER_OF_CLIPBOARD_MSG: usize = 6;
const SIZE_OF_EACH_CLIPBOARD_MSG: usize = 30; // sizeof(nstr.itemName)

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var tmpString: [*c]u8;
extern var allNamedVariables: [*c]namedVariableHeader_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;
extern fn copyRegisterToClipboardString(regist: calcRegister_t, clipboardString: [*c]u8, forPrinter: bool_t) void;
extern fn addChrBothSides(t: u8, str: [*c]u8) void;
extern fn addStrBothSides(str: [*c]u8, str_b: [*c]u8, str_e: [*c]u8) void;
extern fn letteredRegisterName(regist: calcRegister_t) u8;
extern fn utf8ToString(utf8: [*c]const u8, str: [*c]u8) void;
extern fn stringToASCII(str: [*c]const u8, ascii: [*c]u8) void;
extern fn export_append_line(inputstring: [*c]const u8) i16;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
// REGISTER_MATRIX_HEADER(a) == (matrixHeader_t *)getRegisterDataPointer(a).
const regMatrixHeader = abi.registerMatrixHeader;
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}

// ---------------------------------------------------------------------------
// ClipBoardMsg table (TO_QSPI const nstr[]). Each row is a 30-byte name field.
// ---------------------------------------------------------------------------
fn clipRow(comptime s: []const u8) [SIZE_OF_EACH_CLIPBOARD_MSG]u8 {
    var row = std.mem.zeroes([SIZE_OF_EACH_CLIPBOARD_MSG]u8);
    @memcpy(row[0..s.len], s);
    return row;
}

const ClipBoardMsg linksection(code_section) = [NUMBER_OF_CLIPBOARD_MSG][SIZE_OF_EACH_CLIPBOARD_MSG]u8{
    clipRow("Real matrix "), // 0
    clipRow(" too large for transfer"), // 1
    clipRow("Complex matrix "), // 2
    clipRow("res/PROGRAMS"), // 3
    clipRow("C47_LOG.TXT"), // 4
    clipRow("Alpha buffer: "), // 5
};

inline fn clipMsg(n: usize) [*c]const u8 {
    return @ptrCast(&ClipBoardMsg[n]);
}

// ===========================================================================
// copyRegisterToClipboardString2
// ===========================================================================
pub export fn copyRegisterToClipboardString2(regist: calcRegister_t, clipboardString: [*c]u8) callconv(.c) void {
    switch (getRegisterDataType(regist)) {
        dtLongInteger, dtTime, dtDate, dtString, dtShortInteger => {
            copyRegisterToClipboardString(regist, clipboardString, false);
            addChrBothSides(34, clipboardString); // JMCSV
        },

        dtReal34Matrix => {
            const matrixHeader = regMatrixHeader(regist);
            const rows: u16 = matrixHeader.matrixRows;
            const columns: u16 = matrixHeader.matrixColumns;
            if (@as(u32, rows) * @as(u32, columns) * 46 < TMP_STR_LENGTH) {
                copyRegisterToClipboardString(regist, clipboardString, false);
            } else {
                _ = sprintf(clipboardString, "%s%ux%u%s", clipMsg(0), @as(c_uint, rows), @as(c_uint, columns), clipMsg(1)); // Real matrix   too large for transfer
            }
        },

        dtComplex34Matrix => {
            const matrixHeader = regMatrixHeader(regist);
            const rows: u16 = matrixHeader.matrixRows;
            const columns: u16 = matrixHeader.matrixColumns;
            if (@as(u32, rows) * @as(u32, columns) * 92 < TMP_STR_LENGTH) {
                copyRegisterToClipboardString(regist, clipboardString, false);
            } else {
                _ = sprintf(clipboardString, "%s%ux%u%s", clipMsg(2), @as(c_uint, rows), @as(c_uint, columns), clipMsg(1)); // Complex matrix   too large for transfer
            }
        },

        else => {
            copyRegisterToClipboardString(regist, clipboardString, false);
        },
    }
}

// ===========================================================================
// stackregister_csv_out  (USING tmpString !!)
// ===========================================================================
pub export fn stackregister_csv_out(reg_b: i16, reg_e: i16, oneLine: bool_t) callconv(.c) void {
    var tmp_b: [100]u8 = undefined;
    var tmp_e: [100]u8 = undefined;

    var ix: i16 = reg_b;
    while (ix <= reg_e) {
        tmpString[0] = 0;
        tmp_b[0] = 0;
        tmp_e[0] = 0;
        if (REGISTER_X <= ix and ix <= REGISTER_W) {
            tmp_b[1] = 0;
            tmp_b[0] = letteredRegisterName(ix);
            _ = strcat(&tmp_b, CSV_TAB);
        } else if (FIRST_GLOBAL_REGISTER <= ix and ix < REGISTER_X) {
            abi.fmtBufZ(&tmp_b, CSV_STR ++ "R{d:0>2}" ++ CSV_STR ++ CSV_TAB, .{@as(u32, @intCast(ix))});
        } else if (FIRST_LOCAL_REGISTER <= ix and ix <= LAST_LOCAL_REGISTER) {
            abi.fmtBufZ(&tmp_b, CSV_STR ++ "R.{d:0>3}" ++ CSV_STR ++ CSV_TAB, .{@as(u32, @intCast(@as(c_int, ix) - 100))});
        } else if (FIRST_NAMED_VARIABLE <= ix and ix <= LAST_NAMED_VARIABLE) {
            abi.fmtBufZ(&tmp_b, CSV_STR ++ "N{d:0>3}" ++ CSV_STR ++ CSV_TAB ++ CSV_STR ++ "{s}" ++ CSV_STR ++ CSV_TAB, .{ @as(u32, @intCast(@as(c_int, ix) - 100)), std.mem.span(@as([*c]const u8, @ptrCast(&allNamedVariables[@intCast(ix - FIRST_NAMED_VARIABLE)].variableName)) + 1) });
        }

        var tmpString2: [TMP_STR_LENGTH]u8 = undefined;
        copyRegisterToClipboardString2(ix, tmpString);
        utf8ToString(tmpString, &tmpString2);
        stringToASCII(&tmpString2, tmpString);

        if (!oneLine or ix == reg_e) { // use tabs, except at the last register, use newline
            _ = strcat(&tmp_e, CSV_NEWLINE);
        } else {
            _ = strcat(&tmp_e, CSV_TAB);
        }

        addStrBothSides(tmpString, &tmp_b, &tmp_e);

        _ = export_append_line(tmpString); // Output append to CSV file

        ix += 1;
    }
}

// ===========================================================================
// tmpString_csv_out
// ===========================================================================
pub export fn tmpString_csv_out(nn: u8) callconv(.c) void {
    _ = export_append_line(CSV_STR); // Output append to CSV file
    _ = export_append_line(clipMsg(nn)); // "Alpha buffer: " //Output append to CSV file
    _ = export_append_line(CSV_STR); // Output append to CSV file
    _ = export_append_line(CSV_TAB); // Output append to CSV file
    _ = export_append_line(CSV_STR); // Output append to CSV file
    _ = export_append_line(tmpString); // Output append to CSV file    //aimBuffer now in tmpString
    _ = export_append_line(CSV_STR); // Output append to CSV file
    _ = export_append_line(CSV_NEWLINE); // Output append to CSV file
}
