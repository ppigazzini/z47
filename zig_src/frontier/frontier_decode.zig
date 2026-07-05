// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/programming/decode.c: the opcode -> display-string
// decoder used by the program editor and step display. decodeOneStep (and the
// _XPORT/_ALIAS variants) render one program step into tmpString; decodeOp
// formats instruction parameters (registers, labels, flags, numbers, menus,
// shuffles, KEYG/KEYX pairs); decodeLiteral renders embedded literals
// (numbers, strings, complex, date/time/DMS angles); _decodeNumeral applies
// the digit-grouping / radix / exponent display rules. The shuffleReg /
// supDigit / baseChars / angleChars tables are exported (print.c and
// manage.c index them) and live in QSPI on old_hw exactly like the C TO_QSPI.
//
// Faithful, line-by-line port of the C. The host-only listPrograms /
// listLabelsAndPrograms debug dumps have NO callers anywhere in the tree
// (only a commented-out reference in config.c) and are omitted. The sprintf
// bug-path diagnostics and !DMCP_BUILD printf diagnostics carry no control
// flow and are dropped, matching the sibling owners. Not reachable from the
// testSuite; verified by build/link on every target plus the boundary gates.

const std = @import("std");
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// TO_QSPI data tables go to the executable QSPI region on old_hw DM42.
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
const bool_t = u32;
const angularMode_t = c_int;

const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier_char_string = @import("frontier_char_string.zig"); // M-callconv: Zig-to-Zig
const frontier_conversion_units = @import("frontier_conversion_units.zig"); // M-callconv: Zig-to-Zig
const frontier_date_time = @import("frontier_date_time.zig"); // M-callconv: Zig-to-Zig
const frontier_display = @import("frontier_display.zig"); // M-callconv: Zig-to-Zig
const frontier_items = @import("frontier_items.zig"); // M-callconv: Zig-to-Zig
const frontier_next_step = @import("frontier_next_step.zig"); // M-callconv: Zig-to-Zig
const realContext_t = abi.RealContext;
const font_t = abi.Font;

const item_t = abi.Item;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / items.h / display.h)
// ---------------------------------------------------------------------------
const REGISTER_X_IN_KS_CODE: u8 = 100;
const REGISTER_K_IN_KS_CODE: u8 = 111;
const FIRST_LOCAL_REGISTER_IN_KS_CODE: u8 = 112;
const LAST_LOCAL_REGISTER_IN_KS_CODE: u8 = 210;
const REGISTER_M_IN_KS_CODE: u8 = 211;
const REGISTER_W_IN_KS_CODE: u8 = 224;

const LAST_UC_LOCAL_LABEL: u8 = 111;
const FIRST_LC_LOCAL_LABEL: u8 = 112;
const LAST_LOCAL_LABEL: u8 = 123;

const FLAG_X: u8 = 100;
const FLAG_K: u8 = 111;
const FIRST_LOCAL_FLAG: u8 = 112;
const LAST_LOCAL_FLAG: u8 = 143;
const FLAG_M: u8 = 211;
const FLAG_W: u8 = 224;

const CNST_BEYOND_250: u8 = 250;
const SYSTEM_FLAG_NUMBER: u8 = 250;
const VALUE_0: u8 = 251;
const VALUE_1: u8 = 252;
const STRING_LABEL_VARIABLE: u8 = 253;
const INDIRECT_REGISTER: u8 = 254;
const INDIRECT_VARIABLE: u8 = 255;

const PARAM_DECLARE_LABEL: u16 = 1;
const PARAM_LABEL: u16 = 2;
const PARAM_REGISTER: u16 = 3;
const PARAM_FLAG: u16 = 4;
const PARAM_NUMBER_8: u16 = 5;
const PARAM_NUMBER_16: u16 = 6;
const PARAM_COMPARE: u16 = 7;
const PARAM_KEYG_KEYX: u16 = 8;
const PARAM_SKIP_BACK: u16 = 9;
const PARAM_NUMBER_8_16: u16 = 10;
const PARAM_SHUFFLE: u16 = 11;
const PARAM_MENU: u16 = 12;

const PTP_STATUS: u16 = 0x1e00;
const PTP_NONE: u16 = 0 << 9;
const PTP_LITERAL: u16 = 13 << 9;
const PTP_REM: u16 = 14 << 9;
const PTP_DISABLED: u16 = 15 << 9;

const BINARY_SHORT_INTEGER: u8 = 1;
const BINARY_REAL34: u8 = 3;
const BINARY_COMPLEX34: u8 = 4;
const STRING_SHORT_INTEGER: u8 = 7;
const STRING_LONG_INTEGER: u8 = 8;
const STRING_REAL34: u8 = 9;
const STRING_COMPLEX34: u8 = 10;
const STRING_TIME: u8 = 11;
const STRING_DATE: u8 = 12;
const STRING_ANGLE_RADIAN: u8 = 18;
const STRING_ANGLE_GRAD: u8 = 19;
const STRING_ANGLE_DEGREE: u8 = 20;
const STRING_ANGLE_DMS: u8 = 21;
const STRING_ANGLE_MULTPI: u8 = 22;

const ITM_REG_X: u16 = 527;
const ITM_REG_M: u16 = 2336;
const SFL_TDM24: u16 = 463;
const SFL_MONIT: u16 = 2251;
const ITM_PNORM: u16 = 2704;
const ITM_INFINITY: u16 = 924; // pNorm_inf_RNORM
const ITM_INTEGRAL: u16 = 1700;
const ITM_INTEGRAL_YX: u16 = 1690;
const ITM_op_j: u16 = 1830;
const ITM_op_j_pol: u16 = 1795;
const FIRST_CONSTANT: u16 = 128; // CST_01
const LAST_CONSTANT: u16 = 212; // CST_84

const TAM_MAX_MASK: u16 = 0x3fff;

const MODE_RTF: u16 = 1;
const MODE_NRM: u16 = 2;
const MODE_ALIAS: u16 = 3;

const TEMP_REGISTER_1: calcRegister_t = 135;
const dtDate: u32 = 4;
const dtShortInteger: u32 = 8;
const amNone: angularMode_t = 5;
const amNoneU: u32 = @bitCast(@as(c_int, amNone));

const SHORT_INTEGER_SIZE_IN_BLOCKS: u16 = 2;
const REAL34_SIZE_IN_BYTES: u32 = 16;
const TMP_STR_LENGTH: usize = 2560;

const CM_PEM: u8 = 3;

const FLAG_POLAR: c_int = 0x8006;
const FLAG_CPXj: c_int = 0x8005;
const FLAG_MULTx: c_int = 0x801b;
const FLAG_CPXMULT: c_int = 0x8044;

const noBaseOverride: u8 = 0;
const NOIRFRAC: c_int = 0; // irfracOption_t

const multiply_param: u16 = 0; // typeDefinitions.h: multiply = 0
const divide_param: u16 = 0x8000; // typeDefinitions.h: divide = 0x8000

const LAST_ITEM: u32 = 2860;

// STD_* glyph strings (fonts.h).
const STD_RIGHT_ARROW = "\xa1\x92";
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_SPACE_PUNCTUATION = "\xa0\x08";
const STD_SUB_10 = "\xa4\x7d";
const STD_SUP_MINUS = "\xa1\x6b";
const STD_DEGREE = "\x80\xb0";
const STD_SUP_r = "\xa4\x93";
const STD_SUP_g = "\xa4\x88";
const STD_SUP_pir = "\xac\x66";
const STD_INFINITY = "\xa2\x1e";
const STD_CROSS = "\x80\xd7";
const STD_DOT = "\x80\xb7";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
const STD_WCOMMA = "\xa7\x88";

// ---------------------------------------------------------------------------
// TO_QSPI data tables (exported: print.c uses shuffleReg, manage.c uses
// baseChars/angleChars).
// ---------------------------------------------------------------------------
pub export const shuffleReg linksection(code_section) = [4]u8{ 'x', 'y', 'z', 't' };
// STD_SUP_0 .. STD_SUP_9 ("\xa1\x60" .. "\xa1\x69").
pub export const supDigit linksection(code_section) = [24]u8{
    0xa1, 0x60, 0xa1, 0x61, 0xa1, 0x62, 0xa1, 0x63, 0xa1, 0x64,
    0xa1, 0x65, 0xa1, 0x66, 0xa1, 0x67, 0xa1, 0x68, 0xa1, 0x69,
    0,    0,    0,    0,
};
// "??" then STD_BASE_1 .. STD_BASE_16 ("\xa4\x60" .. "\xa4\x6f").
pub export const baseChars linksection(code_section) = [36]u8{
    '?',  '?',
    0xa4, 0x60, 0xa4, 0x61, 0xa4, 0x62, 0xa4, 0x63,
    0xa4, 0x64, 0xa4, 0x65, 0xa4, 0x66, 0xa4, 0x67,
    0xa4, 0x68, 0xa4, 0x69, 0xa4, 0x6a, 0xa4, 0x6b,
    0xa4, 0x6c, 0xa4, 0x6d, 0xa4, 0x6e, 0xa4, 0x6f,
    0,    0,
};
// STD_SUP_r STD_SUP_g STD_DEGREE "??" STD_SUP_pir.
pub export const angleChars linksection(code_section) = [12]u8{
    0xa4, 0x93, 0xa4, 0x88, 0x80, 0xb0, '?', '?', 0xac, 0x66, 0, 0,
};

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var tmpString: [*c]u8;
extern var tmpStringLabelOrVariableName: [*c]u8;
extern var aimBuffer: [*c]u8;
extern var currentStep: [*c]u8;
extern var firstFreeProgramByte: [*c]u8;
extern var calcMode: u8;
extern var decodedIntegerBase: u32;
extern var currentAngularMode: angularMode_t;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingRight: u8;
extern const indexOfItems: [LAST_ITEM + 1]item_t;
extern const registerFlagLetters: [27]u8;
extern var ctxtReal34: realContext_t;
extern const standardFont: font_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------

extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn getSystemFlag(sf: c_int) bool;


extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn getRegisterDataPointer(regist: calcRegister_t) *anyopaque;







extern fn decQuadFromString(r: *align(1) real34_t, s: [*c]const u8, ctx: *realContext_t) *align(1) real34_t;
extern fn abs(x: c_int) c_int;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
inline fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    // stpcpy semantics: copy incl. NUL, return pointer to dest's NUL.
    var d = dest;
    var s = source;
    while (s[0] != 0) {
        d[0] = s[0];
        d += 1;
        s += 1;
    }
    d[0] = 0;
    return d;
}
const reg34 = abi.registerReal34;
inline fn stringToReal34(source: [*c]const u8, destination: *align(1) real34_t) void {
    _ = decQuadFromString(destination, source, &ctxtReal34);
}
inline fn toBytes(n: u16) u32 {
    return @as(u32, n) << 2;
}
inline fn productSign() [*c]const u8 {
    return if (getSystemFlag(FLAG_MULTx)) STD_CROSS else STD_DOT;
}
inline fn complexUnit() [*c]const u8 {
    return if (getSystemFlag(FLAG_CPXj)) STD_op_j else STD_op_i;
}

// The gap-character macros from defines.h.
fn ltStr() [*c]const u8 {
    return if (gapItemLeft == 0) "\x01\x01" else @ptrCast(&indexOfItems[gapItemLeft].itemSoftmenuName);
}
fn rtStr() [*c]const u8 {
    return if (gapItemRight == 0) "\x01\x01" else @ptrCast(&indexOfItems[gapItemRight].itemSoftmenuName);
}
fn rxStr() [*c]const u8 {
    return @ptrCast(&indexOfItems[gapItemRadix].itemSoftmenuName);
}
fn gapChar1Left() [*c]const u8 {
    const l = ltStr();
    if (l[0] != 0 and l[1] == 0 and l[2] == 0) {
        return switch (l[0]) {
            ',' => ",\x01",
            '.' => ".\x01",
            '\'' => "'\x01",
            '_' => "_\x01",
            else => l,
        };
    }
    return l;
}
fn gapChar1Right() [*c]const u8 {
    const r = rtStr();
    if (r[0] != 0 and (r[1] == 0 or (r[1] != 0 and r[2] == 0))) {
        return switch (r[0]) {
            ',' => ",\x01",
            '.' => ".\x01",
            '\'' => "'\x01",
            '_' => "_\x01",
            else => r,
        };
    }
    return r;
}
fn gapChar1Radix() [*c]const u8 {
    const r = rxStr();
    if (r[0] != 0 and (r[1] == 0 or (r[1] != 0 and r[2] == 0))) {
        return switch (r[0]) {
            ',' => ",\x01",
            '.' => ".\x01",
            else => r,
        };
    }
    return r;
}
fn radix34MarkChar() u8 {
    const r = gapChar1Radix();
    return if (r[0] == ',' or (r[0] == STD_WCOMMA[0] and r[1] == STD_WCOMMA[1])) ',' else '.';
}
inline fn groupWidthLeft() u8 {
    return grpGroupingLeft;
}
inline fn groupWidthRight() u8 {
    return grpGroupingRight;
}
inline fn groupLeftDisabled() bool {
    return grpGroupingLeft == 0 or gapItemLeft == 0;
}
inline fn groupRightDisabled() bool {
    return grpGroupingRight == 0 or gapItemRight == 0;
}

// ===========================================================================
// Static helpers
// ===========================================================================
fn getStringLabelOrVariableName(stringAddress: [*c]u8) void {
    var stringLength: u8 = stringAddress[0];
    const nameStart: [*c]u8 = stringAddress + 1;
    // The length byte is taken from the program step on trust. A corrupt step can
    // claim a name longer than the bytes that remain in program memory, so clamp
    // it to firstFreeProgramByte before xcopy reads the name; without this a
    // damaged imported program would read past the program region. When the name
    // would start at or past firstFreeProgramByte there are no valid bytes left,
    // so read nothing rather than skipping the clamp and reading unbounded.
    if (@intFromPtr(nameStart) >= @intFromPtr(firstFreeProgramByte)) {
        stringLength = 0;
    } else if (stringLength > @intFromPtr(firstFreeProgramByte) - @intFromPtr(nameStart)) {
        stringLength = @intCast(@intFromPtr(firstFreeProgramByte) - @intFromPtr(nameStart));
    }
    _ = frontier_char_string.xcopy(@ptrCast(tmpStringLabelOrVariableName), @ptrCast(nameStart), stringLength);
    tmpStringLabelOrVariableName[stringLength] = 0;
}

fn getIndirectRegister(paramAddress: [*c]u8, op: [*c]const u8) void {
    const opParam: u8 = paramAddress[0];
    if (opParam < REGISTER_X_IN_KS_CODE) { // Global register from 00 to 99
        abi.fmtBufZ(tmpString[0..2560], "{s} " ++ STD_RIGHT_ARROW ++ "{d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
    } else if (opParam <= REGISTER_K_IN_KS_CODE) { // Lettered register from X to K
        abi.fmtBufZ(tmpString[0..2560], "{s} " ++ STD_RIGHT_ARROW ++ "{s}", .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[ITM_REG_X + opParam - REGISTER_X_IN_KS_CODE].itemSoftmenuName))) });
    } else if (opParam <= LAST_LOCAL_REGISTER_IN_KS_CODE) { // Local register from .00 to .98
        abi.fmtBufZ(tmpString[0..2560], "{s} " ++ STD_RIGHT_ARROW ++ ".{d:0>2}", .{ std.mem.span(op), @as(u32, @intCast(@as(c_int, opParam) - FIRST_LOCAL_REGISTER_IN_KS_CODE)) });
    } else if (opParam <= REGISTER_W_IN_KS_CODE) { // Lettered register from M to S and E to W
        abi.fmtBufZ(tmpString[0..2560], "{s} " ++ STD_RIGHT_ARROW ++ "{s}", .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[ITM_REG_M + opParam - REGISTER_M_IN_KS_CODE].itemSoftmenuName))) });
    } else {
        abi.fmtBufZ(tmpString[0..2560], "\nIn function getIndirectRegister: {s} " ++ STD_RIGHT_ARROW ++ " {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
    }
}

fn getIndirectVariable(stringAddress: [*c]u8, op: [*c]const u8) void {
    var str: [*c]u8 = tmpString;
    getStringLabelOrVariableName(stringAddress);
    str = stringCopy(str, op);
    str = stringCopy(str, " " ++ STD_RIGHT_ARROW ++ STD_LEFT_SINGLE_QUOTE);
    str = stringCopy(str, tmpStringLabelOrVariableName);
    str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
}

fn decodeOp(paramAddress_arg: [*c]u8, opCode: u16, op: [*c]const u8, paramMode: u16, tamMax: u16) void {
    var paramAddress = paramAddress_arg;
    const opParam: u8 = paramAddress[0];
    paramAddress += 1;

    switch (paramMode) {
        PARAM_DECLARE_LABEL => {
            if (opParam <= 99) { // Local label from 00 to 99
                abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
            } else if (opParam <= LAST_UC_LOCAL_LABEL) { // Local label from A to L
                abi.fmtBufZ(tmpString[0..2560], "{s} {c}", .{ std.mem.span(op), @as(u8, @intCast(@as(c_int, 'A') + (@as(c_int, opParam) - 100))) });
            } else if (opParam <= LAST_LOCAL_LABEL) { // Local label from a to l
                abi.fmtBufZ(tmpString[0..2560], "{s} {c}", .{ std.mem.span(op), @as(u8, @intCast(@as(c_int, 'a') + (@as(c_int, opParam) - FIRST_LC_LOCAL_LABEL))) });
            } else if (opParam == STRING_LABEL_VARIABLE) {
                var str: [*c]u8 = tmpString;
                getStringLabelOrVariableName(paramAddress);
                str = stringCopy(str, op);
                str = stringCopy(str, " " ++ STD_LEFT_SINGLE_QUOTE);
                str = stringCopy(str, tmpStringLabelOrVariableName);
                str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp case PARAM_DECLARE_LABEL: opParam {d} is not a valid label!\n", .{@as(u32, opParam)});
            }
        },

        PARAM_LABEL => {
            if (opParam <= 99) { // Local label from 00 to 99
                abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
            } else if (opParam <= LAST_UC_LOCAL_LABEL) { // Local label from A to L
                abi.fmtBufZ(tmpString[0..2560], "{s} {c}", .{ std.mem.span(op), @as(u8, @intCast(@as(c_int, 'A') + (@as(c_int, opParam) - 100))) });
            } else if (opParam <= LAST_LOCAL_LABEL) { // Local label from a to l
                abi.fmtBufZ(tmpString[0..2560], "{s} {c}", .{ std.mem.span(op), @as(u8, @intCast(@as(c_int, 'a') + (@as(c_int, opParam) - FIRST_LC_LOCAL_LABEL))) });
            } else if (opParam == STRING_LABEL_VARIABLE) {
                var str: [*c]u8 = tmpString;
                getStringLabelOrVariableName(paramAddress);
                str = stringCopy(str, op);
                str = stringCopy(str, " " ++ STD_LEFT_SINGLE_QUOTE);
                str = stringCopy(str, tmpStringLabelOrVariableName);
                str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
            } else if (opParam == INDIRECT_REGISTER) {
                getIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                getIndirectVariable(paramAddress, op);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_LABEL, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            }
        },

        PARAM_REGISTER => {
            if (opParam < REGISTER_X_IN_KS_CODE) { // Global register from 00 to 99
                abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
            } else if (opParam <= REGISTER_K_IN_KS_CODE) { // Lettered register from X to K
                abi.fmtBufZ(tmpString[0..2560], "{s} {s}", .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[ITM_REG_X + opParam - REGISTER_X_IN_KS_CODE].itemSoftmenuName))) });
            } else if (opParam <= LAST_LOCAL_REGISTER_IN_KS_CODE) { // Local register from .00 to .98
                abi.fmtBufZ(tmpString[0..2560], "{s} .{d:0>2}", .{ std.mem.span(op), @as(u32, @intCast(@as(c_int, opParam) - FIRST_LOCAL_REGISTER_IN_KS_CODE)) });
            } else if (opParam <= REGISTER_W_IN_KS_CODE) { // Lettered register from M to S and E to W
                abi.fmtBufZ(tmpString[0..2560], "{s} {s}", .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[ITM_REG_M + opParam - REGISTER_M_IN_KS_CODE].itemSoftmenuName))) });
            } else if (opParam == STRING_LABEL_VARIABLE) {
                var str: [*c]u8 = tmpString;
                getStringLabelOrVariableName(paramAddress);
                str = stringCopy(str, op);
                str = stringCopy(str, " " ++ STD_LEFT_SINGLE_QUOTE);
                str = stringCopy(str, tmpStringLabelOrVariableName);
                str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
            } else if (opParam == INDIRECT_REGISTER) {
                getIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                getIndirectVariable(paramAddress, op);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_REGISTER, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            }
        },

        PARAM_FLAG => {
            if (opParam < FLAG_X) { // Global flag from 00 to 99
                abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
            } else if (FLAG_X <= opParam and opParam <= FLAG_K) { // Lettered flag from X to K
                abi.fmtBufZ(tmpString[0..2560], "{s} {c}", .{ std.mem.span(op), registerFlagLetters[opParam - FLAG_X] });
            } else if (opParam <= LAST_LOCAL_FLAG) { // Local flag from .00 to .31
                abi.fmtBufZ(tmpString[0..2560], "{s} .{d:0>2}", .{ std.mem.span(op), @as(u32, @intCast(@as(c_int, opParam) - FIRST_LOCAL_FLAG)) });
            } else if (opParam < FLAG_M) { // Local flag from .32 to .98 are illegal
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_FLAG, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            } else if (opParam <= FLAG_W) { // Lettered flag from M to S and E to W
                abi.fmtBufZ(tmpString[0..2560], "{s} {c}", .{ std.mem.span(op), registerFlagLetters[opParam - FLAG_M + (FLAG_K - FLAG_X + 1)] });
            } else if (opParam < SYSTEM_FLAG_NUMBER) { // illegal operands
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_FLAG, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            } else if (opParam == SYSTEM_FLAG_NUMBER) {
                if (paramAddress[0] < 64) {
                    abi.fmtBufZ(tmpString[0..2560], "{s} " ++ STD_LEFT_SINGLE_QUOTE ++ "{s}" ++ STD_RIGHT_SINGLE_QUOTE, .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[@as(u16, paramAddress[0]) + SFL_TDM24].itemSoftmenuName))) });
                } else {
                    abi.fmtBufZ(tmpString[0..2560], "{s} " ++ STD_LEFT_SINGLE_QUOTE ++ "{s}" ++ STD_RIGHT_SINGLE_QUOTE, .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[@as(u16, paramAddress[0]) + SFL_MONIT - 64].itemSoftmenuName))) });
                }
            } else if (opParam == INDIRECT_REGISTER) {
                getIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                getIndirectVariable(paramAddress, op);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_FLAG, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            }
        },

        PARAM_NUMBER_8 => {
            if (opParam <= tamMax) { // Value from 0 to 99
                if (tamMax <= 9) {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d}", .{ std.mem.span(op), @as(u32, opParam) });
                } else if (tamMax <= 99) {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
                } else if (tamMax <= 999) {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>3}", .{ std.mem.span(op), @as(u32, opParam) });
                } else {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>4}", .{ std.mem.span(op), @as(u32, opParam) });
                }
            } else if (opParam == INDIRECT_REGISTER) {
                getIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                getIndirectVariable(paramAddress, op);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_NUMBER, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            }
        },

        PARAM_NUMBER_8_16 => {
            if (opParam <= 249) { // Value from 0 to 249
                if (tamMax <= 9) {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d}", .{ std.mem.span(op), @as(u32, opParam) });
                } else if (tamMax <= 99) {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
                } else if (tamMax <= 999) {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>3}", .{ std.mem.span(op), @as(u32, opParam) });
                } else {
                    abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>4}", .{ std.mem.span(op), @as(u32, opParam) });
                }
            } else if (opParam == CNST_BEYOND_250) { // Value from 250 to 499
                abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>3}", .{ std.mem.span(op), 250 + @as(u32, paramAddress[0]) });
            } else if (opParam == INDIRECT_REGISTER) {
                getIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                getIndirectVariable(paramAddress, op);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_NUMBER, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            }
        },

        PARAM_NUMBER_16 => {
            var func: u16 = (@as(u16, (paramAddress - 3)[0]) << 8) +% @as(u16, (paramAddress - 2)[0]);
            func &= 0x7fff;
            if (frontier_items.isFunctionOldParam16(func) != 0) { // original Param16 functions without indirection support (little endian parameter)
                abi.fmtBufZ(tmpString[0..2560], "{s} {d}", .{ std.mem.span(op), @as(u32, opParam) + 256 * @as(u32, paramAddress[0]) });
            } else { // new Param16 functions with indirection support (big endian parameter)
                if (opParam == INDIRECT_REGISTER) {
                    getIndirectRegister(paramAddress, op);
                } else if (opParam == INDIRECT_VARIABLE) {
                    getIndirectVariable(paramAddress, op);
                } else {
                    if (opCode == ITM_PNORM and (@as(u32, opParam) * 256) + paramAddress[0] == ITM_INFINITY) {
                        abi.fmtBufZ(tmpString[0..2560], "{s} {s}", .{ std.mem.span(op), std.mem.span(@as([*c]const u8, STD_INFINITY)) });
                    } else {
                        abi.fmtBufZ(tmpString[0..2560], "{s} {d}", .{ std.mem.span(op), (@as(u32, opParam) * 256) + @as(u32, paramAddress[0]) });
                    }
                }
            }
        },

        PARAM_COMPARE => {
            if (opParam < REGISTER_X_IN_KS_CODE) { // Global register from 00 to 99
                abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>2}", .{ std.mem.span(op), @as(u32, opParam) });
            } else if (opParam <= REGISTER_K_IN_KS_CODE) { // Lettered register from X to K
                abi.fmtBufZ(tmpString[0..2560], "{s} {s}", .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[ITM_REG_X + opParam - REGISTER_X_IN_KS_CODE].itemSoftmenuName))) });
            } else if (opParam <= LAST_LOCAL_REGISTER_IN_KS_CODE) { // Local register from .00 to .98
                abi.fmtBufZ(tmpString[0..2560], "{s} .{d:0>2}", .{ std.mem.span(op), @as(u32, @intCast(@as(c_int, opParam) - FIRST_LOCAL_REGISTER_IN_KS_CODE)) });
            } else if (opParam <= REGISTER_W_IN_KS_CODE) { // Lettered register from M to S and E to W
                abi.fmtBufZ(tmpString[0..2560], "{s} {s}", .{ std.mem.span(op), std.mem.span(@as([*c]const u8, @ptrCast(&indexOfItems[ITM_REG_M + opParam - REGISTER_M_IN_KS_CODE].itemSoftmenuName))) });
            } else if (opParam == STRING_LABEL_VARIABLE) {
                var str: [*c]u8 = tmpString;
                getStringLabelOrVariableName(paramAddress);
                str = stringCopy(str, op);
                str = stringCopy(str, " " ++ STD_LEFT_SINGLE_QUOTE);
                str = stringCopy(str, tmpStringLabelOrVariableName);
                str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
            } else if (opParam == VALUE_0) {
                abi.fmtBufZ(tmpString[0..2560], "{s} 0.", .{std.mem.span(op)});
            } else if (opParam == VALUE_1) {
                abi.fmtBufZ(tmpString[0..2560], "{s} 1.", .{std.mem.span(op)});
            } else if (opParam == INDIRECT_REGISTER) {
                getIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                getIndirectVariable(paramAddress, op);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_COMPARE, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            }
        },

        PARAM_KEYG_KEYX => {
            const secondParam: [*c]u8 = frontier_next_step.findKey2ndParam(paramAddress - 3);
            if (secondParam != null) {
                decodeOp(secondParam + 1, secondParam[0], @ptrCast(&indexOfItems[secondParam[0]].itemCatalogName), PARAM_LABEL, indexOfItems[secondParam[0]].tamMinMax & TAM_MAX_MASK);
                _ = frontier_char_string.xcopy(@ptrCast(tmpString + TMP_STR_LENGTH / 2), @ptrCast(tmpString), @intCast(stringByteLength(tmpString) + 1));
                decodeOp(paramAddress - 1, secondParam[0], op, PARAM_NUMBER_8, 21);
                tmpString[@intCast(stringByteLength(tmpString) + 1)] = 0;
                tmpString[@intCast(stringByteLength(tmpString))] = ' ';
                _ = frontier_char_string.xcopy(@ptrCast(tmpString + @as(usize, @intCast(stringByteLength(tmpString)))), @ptrCast(tmpString + TMP_STR_LENGTH / 2), @intCast(stringByteLength(tmpString + TMP_STR_LENGTH / 2) + 1));
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_KEYG_KEYX, {s} has no valid second key parameter!", .{std.mem.span(op)});
            }
        },

        PARAM_SKIP_BACK => {
            abi.fmtBufZ(tmpString[0..2560], "{s} {d:0>3}", .{ std.mem.span(op), @as(u32, opParam) });
        },

        PARAM_SHUFFLE => {
            abi.fmtBufZ(tmpString[0..2560], "{s} {c}{c}{c}{c}", .{ std.mem.span(op), shuffleReg[opParam & 0x03], shuffleReg[(opParam & 0x0c) >> 2], shuffleReg[(opParam & 0x30) >> 4], shuffleReg[(opParam & 0xc0) >> 6] });
        },

        PARAM_MENU => {
            if (opParam == STRING_LABEL_VARIABLE) {
                var str: [*c]u8 = tmpString;
                getStringLabelOrVariableName(paramAddress);
                str = stringCopy(str, op);
                str = stringCopy(str, " " ++ STD_LEFT_SINGLE_QUOTE);
                str = stringCopy(str, tmpStringLabelOrVariableName);
                str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
            } else if (opParam == INDIRECT_REGISTER) {
                getIndirectRegister(paramAddress, op);
            } else if (opParam == INDIRECT_VARIABLE) {
                getIndirectVariable(paramAddress, op);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: case PARAM_MENU, {s}  {d} is not a valid parameter!", .{ std.mem.span(op), @as(u32, opParam) });
            }
        },

        else => {
            abi.fmtBufZ(tmpString[0..2560], "\nIn function decodeOp: paramMode {d} is not valid!\n", .{@as(u32, paramMode)});
        },
    }
}

// ===========================================================================
// _decodeNumeral (static)
// ===========================================================================
fn _decodeNumeral(startPtr: [*c]u8, srcStartPtr: [*c]const u8, isLongInt: bool, updatedTgtPtr: ?*[*c]u8, updatedSrcPtr: ?*[*c]const u8) void {
    var digit: i32 = 0;
    var strPtr: [*c]u8 = startPtr;
    var srcStr: [*c]const u8 = srcStartPtr;

    if (srcStr[0] == '-') {
        srcStr += 1;
    }
    digit = 0;
    while ((srcStr[0] >= '0' and srcStr[0] <= '9') or (srcStr[0] >= 'A' and srcStr[0] <= 'F')) {
        digit += 1;
        srcStr += 1;
    }
    srcStr = srcStartPtr;

    if (srcStr[0] == '-') {
        strPtr[0] = srcStr[0];
        strPtr += 1;
        srcStr += 1;
    }
    while ((srcStr[0] >= '0' and srcStr[0] <= '9') or (srcStr[0] >= 'A' and srcStr[0] <= 'F') or srcStr[0] == '.' or srcStr[0] == ',') {
        if (digit == 0) {
            strPtr[0] = radix34MarkChar();
            strPtr += 1;
            srcStr += 1;
        } else {
            if (!groupRightDisabled() and digit < -1 and @rem(abs(digit), @as(c_int, groupWidthRight())) == 1) {
                const g = gapChar1Right();
                strPtr[0] = g[0];
                strPtr += 1;
                if (g[1] != 1) {
                    strPtr[0] = g[1];
                    strPtr += 1;
                }
            }
            strPtr[0] = srcStr[0];
            strPtr += 1;
            srcStr += 1;
            if (!groupLeftDisabled() and digit > 1 and @rem(digit, @as(i32, groupWidthLeft())) == 1) {
                const g = gapChar1Left();
                strPtr[0] = g[0];
                strPtr += 1;
                if (g[1] != 1) {
                    strPtr[0] = g[1];
                    strPtr += 1;
                }
            }
        }
        digit -= 1;
    }
    if (digit == 0 and !isLongInt) {
        strPtr[0] = radix34MarkChar();
        strPtr += 1;
    }

    if (srcStr[0] == 'e') {
        srcStr += 1;
        const ps = productSign();
        strPtr[0] = ps[0];
        strPtr += 1;
        strPtr[0] = ps[1];
        strPtr += 1;
        strPtr[0] = STD_SUB_10[0];
        strPtr += 1;
        strPtr[0] = STD_SUB_10[1];
        strPtr += 1;
        if (srcStr[0] == '-') {
            strPtr[0] = STD_SUP_MINUS[0];
            strPtr += 1;
            strPtr[0] = STD_SUP_MINUS[1];
            strPtr += 1;
            srcStr += 1;
        } else if (srcStr[0] == '+') {
            srcStr += 1;
        }
        while (srcStr[0] >= '0' and srcStr[0] <= '9') {
            strPtr[0] = supDigit[0 + @as(usize, srcStr[0] - '0') * 2];
            strPtr += 1;
            strPtr[0] = supDigit[1 + @as(usize, srcStr[0] - '0') * 2];
            strPtr += 1;
            srcStr += 1;
        }
    } else if (srcStr[0] == '#') { // input not yet closed
        strPtr[0] = srcStr[0];
        strPtr += 1;
        srcStr += 1;
        while (srcStr[0] >= '0' and srcStr[0] <= '9') {
            strPtr[0] = srcStr[0];
            strPtr += 1;
            srcStr += 1;
        }
    }

    strPtr[0] = 0;
    if (updatedTgtPtr) |p| {
        p.* = strPtr;
    }
    if (updatedSrcPtr) |p| {
        p.* = srcStr;
    }
}

// ===========================================================================
// decodeLiteral (static)
// ===========================================================================
fn decodeLiteral(literalAddress_arg: [*c]u8) void {
    var literalAddress = literalAddress_arg;
    decodedIntegerBase = 0;
    const kind: u8 = literalAddress[0];
    literalAddress += 1;
    switch (kind) {
        BINARY_SHORT_INTEGER => {
            reallocateRegister(TEMP_REGISTER_1, dtShortInteger, 0, literalAddress[0]);
            literalAddress += 1;
            _ = frontier_char_string.xcopy(getRegisterDataPointer(TEMP_REGISTER_1), @ptrCast(literalAddress), toBytes(SHORT_INTEGER_SIZE_IN_BLOCKS));
            frontier_display.shortIntegerToDisplayString(TEMP_REGISTER_1, tmpString, @intFromBool(false), noBaseOverride);
        },

        BINARY_REAL34 => {
            var realLiteral: real34_t = undefined;
            _ = frontier_char_string.xcopy(@ptrCast(&realLiteral), @ptrCast(literalAddress), REAL34_SIZE_IN_BYTES);
            frontier_display.real34ToDisplayString(&realLiteral, amNoneU, tmpString, &standardFont, 9999, 34, @intFromBool(false), @intFromBool(false), NOIRFRAC);
        },

        BINARY_COMPLEX34 => {
            var complexLiteral: complex34_t = undefined;
            _ = frontier_char_string.xcopy(@ptrCast(&complexLiteral.real), @ptrCast(literalAddress), REAL34_SIZE_IN_BYTES);
            _ = frontier_char_string.xcopy(@ptrCast(&complexLiteral.imag), @ptrCast(literalAddress + REAL34_SIZE_IN_BYTES), REAL34_SIZE_IN_BYTES);
            frontier_display.complex34ToDisplayString(&complexLiteral, tmpString, &standardFont, 9999, 34, @intFromBool(false), @intFromBool(false), NOIRFRAC, @intCast(@as(u32, @bitCast(currentAngularMode))), @intFromBool(getSystemFlag(FLAG_POLAR)));
        },

        STRING_SHORT_INTEGER => {
            var digit: i32 = 0;
            var gap: u8 = groupWidthLeft();
            var dispStringPtr: [*c]u8 = tmpString;
            var sourceStringPtr: [*c]u8 = tmpStringLabelOrVariableName;
            var base: u8 = literalAddress[0];
            if (base > 16) { // bases above 16 are invalid; baseChars[] only spans 0..16
                base = 0;
            }
            decodedIntegerBase = base;
            getStringLabelOrVariableName(literalAddress + 1);

            if (!groupLeftDisabled()) {
                if (base == 2) {
                    gap = 4;
                } else if (base == 4 or base == 8 or base == 16) {
                    gap = 2;
                }
            }

            if (sourceStringPtr[0] == '-') {
                sourceStringPtr += 1;
            }
            digit = 0;
            while ((sourceStringPtr[0] >= '0' and sourceStringPtr[0] <= '9') or (sourceStringPtr[0] >= 'A' and sourceStringPtr[0] <= 'F')) {
                digit += 1;
                sourceStringPtr += 1;
            }
            sourceStringPtr = tmpStringLabelOrVariableName;

            if (sourceStringPtr[0] == '-') {
                dispStringPtr[0] = sourceStringPtr[0];
                dispStringPtr += 1;
                sourceStringPtr += 1;
            }
            while ((sourceStringPtr[0] >= '0' and sourceStringPtr[0] <= '9') or (sourceStringPtr[0] >= 'A' and sourceStringPtr[0] <= 'F')) {
                dispStringPtr[0] = sourceStringPtr[0];
                dispStringPtr += 1;
                sourceStringPtr += 1;
                if (gap > 0 and digit > 1 and @rem(digit, @as(i32, gap)) == 1) {
                    dispStringPtr[0] = STD_SPACE_PUNCTUATION[0];
                    dispStringPtr += 1;
                    dispStringPtr[0] = STD_SPACE_PUNCTUATION[1];
                    dispStringPtr += 1;
                }
                digit -= 1;
            }
            dispStringPtr[0] = baseChars[@as(usize, base) * 2];
            dispStringPtr += 1;
            dispStringPtr[0] = baseChars[@as(usize, base) * 2 + 1];
            dispStringPtr += 1;
            dispStringPtr[0] = 0;
        },

        STRING_LONG_INTEGER => {
            getStringLabelOrVariableName(literalAddress);
            _decodeNumeral(tmpString, tmpStringLabelOrVariableName, true, null, null);
        },

        STRING_REAL34 => {
            getStringLabelOrVariableName(literalAddress);
            _decodeNumeral(tmpString, tmpStringLabelOrVariableName, false, null, null);
        },

        STRING_ANGLE_RADIAN, STRING_ANGLE_GRAD, STRING_ANGLE_DEGREE, STRING_ANGLE_MULTPI => {
            getStringLabelOrVariableName(literalAddress);
            _decodeNumeral(tmpString, tmpStringLabelOrVariableName, false, null, null);
            switch ((literalAddress - 1)[0]) {
                STRING_ANGLE_RADIAN => _ = strcat(tmpString, STD_SUP_r),
                STRING_ANGLE_GRAD => _ = strcat(tmpString, STD_SUP_g),
                STRING_ANGLE_DEGREE => _ = strcat(tmpString, STD_DEGREE),
                STRING_ANGLE_MULTPI => _ = strcat(tmpString, STD_SUP_pir),
                else => {},
            }
        },

        STRING_COMPLEX34 => {
            var dispStringPtr: [*c]u8 = tmpString;
            var sourceStringPtr: [*c]const u8 = tmpStringLabelOrVariableName;
            getStringLabelOrVariableName(literalAddress);
            _decodeNumeral(dispStringPtr, sourceStringPtr, false, &dispStringPtr, &sourceStringPtr);
            if (!getSystemFlag(FLAG_CPXMULT) and aimBuffer[0] == 0 and tmpString[0] == '0' and tmpString[1] == '.' and tmpString[2] == 0) {
                // remove "0." (not "0.0", "0.00" etc.)
                tmpString[0] = 0;
                dispStringPtr = tmpString;
            }
            if (sourceStringPtr[0] == 'i' or sourceStringPtr[0] == 'j') { // unlikely
                if (getSystemFlag(FLAG_CPXMULT) or aimBuffer[0] != 0 or tmpString[0] != 0) {
                    dispStringPtr[0] = '+';
                    dispStringPtr += 1;
                }
                if (getSystemFlag(FLAG_CPXMULT) or aimBuffer[0] != 0) {
                    const cu = complexUnit();
                    dispStringPtr[0] = cu[0];
                    dispStringPtr += 1;
                    dispStringPtr[0] = cu[1];
                    dispStringPtr += 1;
                }
                sourceStringPtr += 1;
            } else if (sourceStringPtr[0] == '+' or sourceStringPtr[0] == '-') {
                dispStringPtr[0] = sourceStringPtr[0];
                dispStringPtr += 1;
                sourceStringPtr += 1;
                if (!getSystemFlag(FLAG_CPXMULT) and aimBuffer[0] == 0 and (@intFromPtr(dispStringPtr) - @intFromPtr(tmpString)) == 1 and (sourceStringPtr - 1)[0] == '+') {
                    dispStringPtr -= 1;
                }
                if (getSystemFlag(FLAG_CPXMULT) or aimBuffer[0] != 0) {
                    const cu = complexUnit();
                    dispStringPtr[0] = cu[0];
                    dispStringPtr += 1;
                    dispStringPtr[0] = cu[1];
                    dispStringPtr += 1;
                }
                sourceStringPtr += 1;
            }
            if (getSystemFlag(FLAG_CPXMULT) or aimBuffer[0] != 0) {
                const ps = productSign();
                dispStringPtr[0] = ps[0];
                dispStringPtr += 1;
                dispStringPtr[0] = ps[1];
                dispStringPtr += 1;
            }
            _decodeNumeral(dispStringPtr, sourceStringPtr, calcMode == CM_PEM and aimBuffer[0] != 0 and (currentStep + 2 == literalAddress), &dispStringPtr, null);
            if (!getSystemFlag(FLAG_CPXMULT) and aimBuffer[0] == 0) {
                const cu = complexUnit();
                dispStringPtr[0] = cu[0];
                dispStringPtr += 1;
                dispStringPtr[0] = cu[1];
                dispStringPtr += 1;
                dispStringPtr[0] = 0;
            }
        },

        STRING_LABEL_VARIABLE => {
            var str: [*c]u8 = tmpString;
            getStringLabelOrVariableName(literalAddress);
            str = stringCopy(str, STD_LEFT_SINGLE_QUOTE);
            str = stringCopy(str, tmpStringLabelOrVariableName);
            str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
        },

        STRING_DATE => {
            getStringLabelOrVariableName(literalAddress);
            reallocateRegister(TEMP_REGISTER_1, dtDate, 0, amNoneU);
            stringToReal34(tmpStringLabelOrVariableName, reg34(TEMP_REGISTER_1));
            frontier_date_time.julianDayToInternalDate(reg34(TEMP_REGISTER_1), reg34(TEMP_REGISTER_1));
            frontier_display.dateToDisplayString(TEMP_REGISTER_1, tmpString);
        },

        STRING_TIME => {
            var timeStringPtr: [*c]u8 = tmpString;
            var sourceStringPtr: [*c]u8 = tmpStringLabelOrVariableName;
            getStringLabelOrVariableName(literalAddress);
            while (sourceStringPtr[0] != '.' and sourceStringPtr[0] != 0) : (sourceStringPtr += 1) {
                timeStringPtr[0] = sourceStringPtr[0];
                timeStringPtr += 1;
            }
            if (sourceStringPtr[0] == '.') {
                sourceStringPtr += 1;
            }
            timeStringPtr[0] = ':';
            timeStringPtr += 1;
            if (sourceStringPtr[0] != 0) {
                timeStringPtr[0] = sourceStringPtr[0];
                timeStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                timeStringPtr[0] = '0';
                timeStringPtr += 1;
            }
            if (sourceStringPtr[0] != 0) {
                timeStringPtr[0] = sourceStringPtr[0];
                timeStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                timeStringPtr[0] = '0';
                timeStringPtr += 1;
            }
            timeStringPtr[0] = ':';
            timeStringPtr += 1;
            if (sourceStringPtr[0] != 0) {
                timeStringPtr[0] = sourceStringPtr[0];
                timeStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                timeStringPtr[0] = '0';
                timeStringPtr += 1;
            }
            if (sourceStringPtr[0] != 0) {
                timeStringPtr[0] = sourceStringPtr[0];
                timeStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                timeStringPtr[0] = '0';
                timeStringPtr += 1;
            }
            if (sourceStringPtr[0] != 0) {
                timeStringPtr[0] = '.';
                timeStringPtr += 1;
            }
            while (sourceStringPtr[0] != 0) : (sourceStringPtr += 1) {
                timeStringPtr[0] = sourceStringPtr[0];
                timeStringPtr += 1;
            }
            timeStringPtr[0] = 0;
            timeStringPtr += 1;
        },

        STRING_ANGLE_DMS => {
            var angleStringPtr: [*c]u8 = tmpString;
            var sourceStringPtr: [*c]u8 = tmpStringLabelOrVariableName;
            getStringLabelOrVariableName(literalAddress);
            while (sourceStringPtr[0] != '.' and sourceStringPtr[0] != 0) : (sourceStringPtr += 1) {
                angleStringPtr[0] = sourceStringPtr[0];
                angleStringPtr += 1;
            }
            if (sourceStringPtr[0] == '.') {
                sourceStringPtr += 1;
            }
            angleStringPtr[0] = STD_DEGREE[0];
            angleStringPtr += 1;
            angleStringPtr[0] = STD_DEGREE[1];
            angleStringPtr += 1;
            if (sourceStringPtr[0] != 0) {
                angleStringPtr[0] = sourceStringPtr[0];
                angleStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                angleStringPtr[0] = '0';
                angleStringPtr += 1;
            }
            if (sourceStringPtr[0] != 0) {
                angleStringPtr[0] = sourceStringPtr[0];
                angleStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                angleStringPtr[0] = '0';
                angleStringPtr += 1;
            }
            angleStringPtr[0] = '\'';
            angleStringPtr += 1;
            if (sourceStringPtr[0] != 0) {
                angleStringPtr[0] = sourceStringPtr[0];
                angleStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                angleStringPtr[0] = '0';
                angleStringPtr += 1;
            }
            if (sourceStringPtr[0] != 0) {
                angleStringPtr[0] = sourceStringPtr[0];
                angleStringPtr += 1;
                sourceStringPtr += 1;
            } else {
                angleStringPtr[0] = '0';
                angleStringPtr += 1;
            }
            if (sourceStringPtr[0] != 0) {
                angleStringPtr[0] = '.';
                angleStringPtr += 1;
            }
            while (sourceStringPtr[0] != 0) : (sourceStringPtr += 1) {
                angleStringPtr[0] = sourceStringPtr[0];
                angleStringPtr += 1;
            }
            angleStringPtr[0] = '"';
            angleStringPtr += 1;
            angleStringPtr[0] = 0;
            angleStringPtr += 1;
        },

        else => {
            // !DMCP_BUILD printf diagnostics dropped.
        },
    }
}

// ===========================================================================
// decodeRem (static)
// ===========================================================================
fn decodeRem(literalAddress_arg: [*c]u8, op: u16) void {
    var literalAddress = literalAddress_arg;
    const kind: u8 = literalAddress[0];
    literalAddress += 1;
    if (kind == STRING_LABEL_VARIABLE) {
        var str: [*c]u8 = tmpString;
        getStringLabelOrVariableName(literalAddress);
        str = stringCopy(str, @ptrCast(&indexOfItems[op].itemCatalogName));
        str = stringCopy(str, " " ++ STD_LEFT_SINGLE_QUOTE);
        str = stringCopy(str, tmpStringLabelOrVariableName);
        str = stringCopy(str, STD_RIGHT_SINGLE_QUOTE);
    }
    // else: !DMCP_BUILD printf diagnostic dropped.
}

// ===========================================================================
// _decodeOneStep (static) and the public entry points
// ===========================================================================
fn _decodeOneStep(step_arg: [*c]u8, textVersion: u16) void {
    var step = step_arg;
    var op: u16 = step[0];
    step += 1;
    if (op & 0x80 != 0) {
        op &= 0x7f;
        op <<= 8;
        op |= step[0];
        step += 1;
    }

    if (op == 0x7fff) { // .END.
        _ = frontier_char_string.xcopy(@ptrCast(tmpString), ".END.", 6);
    } else {
        var nameOp: [36]u8 = undefined;
        nameOp[0] = 0;
        switch (indexOfItems[op].status & PTP_STATUS) {
            PTP_NONE => {
                if (FIRST_CONSTANT <= op and op <= LAST_CONSTANT) {
                    abi.fmtBufZ(&nameOp, "{d: >2}", .{@as(u32, @intCast(@as(c_int, op) - FIRST_CONSTANT + 1))});
                    _ = strcat(&nameOp, " ");
                    _ = strcat(&nameOp, @ptrCast(&indexOfItems[op].itemCatalogName));
                    _ = strcat(&nameOp, " ");
                    _ = strcat(&nameOp, @ptrCast(&indexOfItems[op].itemSoftmenuName));
                }
                if (op == ITM_op_j) {
                    abi.fmtBufZ(&nameOp, "op_{s}", .{std.mem.span(complexUnit())});
                } else if (op == ITM_op_j_pol) {
                    abi.fmtBufZ(&nameOp, "op_{s}" ++ "\xa2\x9a", .{std.mem.span(complexUnit())});
                }
                if (nameOp[0] == 0) {
                    if (textVersion == MODE_ALIAS) {
                        // IR_PRINTING nameAlias: never defined for any z47 build.
                    } else {
                        _ = strcpy(&nameOp, if (indexOfItems[op].itemCatalogName[0] != 0) @as([*c]const u8, @ptrCast(&indexOfItems[op].itemCatalogName)) else @as([*c]const u8, @ptrCast(&indexOfItems[op].itemSoftmenuName)));
                    }
                }
                if (frontier_conversion_units.isItemConversion(@intCast(op))) {
                    frontier_conversion_units.fullConvSoftMenuItemNameInclHPCONV(@intCast(op), &nameOp); //Display only the standard display partner, as a program cannot contain a custom conversion
                }
                abi.fmtBufZ(tmpString[0..2560], "{s}{s}", .{ std.mem.span(@as([*c]const u8, if (FIRST_CONSTANT <= op and op <= LAST_CONSTANT) "# " else "")), std.mem.span(@as([*c]const u8, &nameOp)) });
            },

            PTP_DISABLED => {
                // PC_BUILD printf diagnostic dropped.
            },

            PTP_LITERAL => {
                decodeLiteral(step);
            },

            PTP_REM => {
                decodeRem(step, op);
            },

            else => {
                if (op == ITM_INTEGRAL) {
                    _ = strcpy(&nameOp, @ptrCast(&indexOfItems[op].itemCatalogName));
                } else if (op == ITM_INTEGRAL_YX) {
                    _ = strcpy(&nameOp, @ptrCast(&indexOfItems[op].itemCatalogName));
                } else {
                    if (nameOp[0] == 0) {
                        if (textVersion == MODE_ALIAS) {
                            // IR_PRINTING nameAlias: never defined for any z47 build.
                        } else {
                            _ = strcpy(&nameOp, @ptrCast(&indexOfItems[op].itemCatalogName));
                        }
                    }
                }
                decodeOp(step, op, &nameOp, (indexOfItems[op].status & PTP_STATUS) >> 9, indexOfItems[op].tamMinMax & TAM_MAX_MASK);
            },
        }
    }
}

pub export fn decodeOneStep(step: [*c]u8) callconv(.c) void {
    _decodeOneStep(step, MODE_NRM);
}

pub export fn decodeOneStep_XPORT(step: [*c]u8) callconv(.c) void {
    _decodeOneStep(step, MODE_RTF);
}

pub export fn decodeOneStep_ALIAS(step: [*c]u8) callconv(.c) void {
    _decodeOneStep(step, MODE_ALIAS);
}
