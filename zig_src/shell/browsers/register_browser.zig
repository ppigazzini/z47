// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/browsers/registerBrowser.c: registerBrowser (the register
// browser application) and its two file-static helpers _showRegisterInRbr and
// registerName. This is a faithful, line-by-line port of the C. The
// SAVE_SPACE_DM42_8 guard compiled the whole file out of old-HW single-file DM42
// builds; that guard is never enabled for the packages z47 ships, so the code is
// always present here. The modulo()/min()/max() macros and the register-data
// pointer macros are reproduced inline; showString returns uint32_t in C and is
// truncated to int16_t exactly as the implicit assignment does.
//
// registerBrowser.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const std = @import("std");
const frontier_build_options = @import("frontier_build_options");

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const videoMode_t = c_int;
const abi = @import("abi"); // shared ABI bindings
const frontier_char_string = @import("../display/text/char_string.zig");
const frontier_debug = @import("../debug.zig");
const frontier_display = @import("../display/display.zig");
const frontier_screen = @import("../display/screen.zig");
const frontier_screen_snap = @import("../display/screen_snap.zig");
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;

const registerHeader_t = abi.RegisterHeader;
const namedVariableHeader_t = abi.NamedVariableHeader;
const reservedVariableHeader_t = abi.ReservedVariableHeader;
const matrixHeader_t = abi.MatrixHeader;
const font_t = abi.Font;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const CM_REGISTER_BROWSER: u8 = 5;
const CM_AIM: u8 = 1;
const FLAG_ALPHA: c_uint = 0x800e;
const vmNormal: videoMode_t = 0;
const SCREEN_WIDTH: i16 = 400;
const NOPARAM: u16 = 9876;
const TMP_STR_LENGTH: i32 = 2560;

const RBR_GLOBAL: u8 = 0;
const RBR_LOCAL: u8 = 1;
const RBR_NAMED: u8 = 2;
const RBR_INCDEC1: c_int = 10;
const LAST_SPARE_REGISTER: c_int = 125; // REGISTER_W
// LAST_GLOBAL_REGISTER_SCREEN = LAST_SPARE_REGISTER - modulo(LAST_SPARE_REGISTER, RBR_INCDEC1) = 125 - 5 = 120
const LAST_GLOBAL_REGISTER_SCREEN: c_int = 120;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_W: calcRegister_t = 125;
const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;
const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
const FIRST_RESERVED_VARIABLE: c_int = 2000;
const LAST_RESERVED_VARIABLE: c_int = 2047;
const NUMBER_OF_LETTERED_VARIABLES: c_int = 26;

// data types (typeDefinitions.h dataType_t).
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtLongInteger: u32 = 0;
const dtShortInteger: u32 = 8;
const dtString: u32 = 5;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtConfig: u32 = 9;

const amAngleMask: u32 = 15;
const amPolar: u32 = 16;
const LI_NEGATIVE: u32 = 1;

const LIMITEXP: bool_t = true;
const FRONTSPACE: bool_t = true;
const LIMITIRFRAC: c_int = 1;
const noBaseOverride: u8 = 0;

// REAL34/COMPLEX34/CONFIG sizes (TO_BYTES = blocks<<2; real34=16B, complex34=32B).
const REAL34_SIZE_IN_BYTES: i16 = 16;
const COMPLEX34_SIZE_IN_BYTES: i16 = 32;
const REAL34_SIZE_IN_BLOCKS: u32 = 4;
const COMPLEX34_SIZE_IN_BLOCKS: u32 = 8;
const CONFIG_SIZE_IN_BYTES: i16 = 840; // TO_BYTES(TO_BLOCKS(sizeof(dtConfigDescriptor_t))), verified via C probe

const sizeof_strLgIntHeader_t: i16 = 4;
const sizeof_matrixHeader_t: u32 = 4;

// STD_* macro byte sequences (fonts.h).
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_ELLIPSIS = "\xa0\x26";
const STD_CORRESPONDS_TO = "\xa2\x58";

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var hourGlassIconEnabled: bool_t;
extern var cursorEnabled: u8;
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var currentRegisterBrowserScreen: i16;
extern var rbrMode: u8;
extern var showContent: bool_t;
extern var rbr1stDigit: bool_t;
extern var tmpString: [*c]u8;
extern var numberOfNamedVariables: u16;
extern var allNamedVariables: [*c]namedVariableHeader_t;
// allReservedVariables[] is a C array; its symbol address is the table base.
const allReservedVariables = @extern([*]const reservedVariableHeader_t, .{ .name = "allReservedVariables" });

const subroutineLevelHeader_t = abi.SubroutineLevelHeader;
extern var currentSubroutineLevelData: *subroutineLevelHeader_t;

extern const standardFont: font_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*]u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn getRegisterMaxDataLengthInBlocks(regist: calcRegister_t) u16;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn clearSystemFlag(flag: c_uint) void;

// stringCopy (charString.h): stpcpy semantics — copy incl. NUL, return ptr to NUL.
fn stringCopy(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    const l: u32 = @intCast(strlen(source));
    return @as([*c]u8, @ptrCast(frontier_char_string.xcopy(dest, source, l + 1))) + l;
}
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strncat(dst: [*c]u8, src: [*c]const u8, n: usize) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
const reg34 = abi.registerReal34;
const regComplex34 = abi.registerComplex34;
const regStringData = abi.registerString;
const regMatrixHeader = abi.registerMatrixHeader;
inline fn getRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getComplexRegisterAngularMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amAngleMask;
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amPolar;
}
inline fn getRegisterLongIntegerSign(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
// TO_BYTES(n) = ((uint32_t)n) << 2.
inline fn toBytes(n: u32) u32 {
    return n << 2;
}
// modulo(n, d) with d > 0: (n%d<0 ? n%d+d : n%d). All in C int arithmetic.
inline fn modulo(n: c_int, d: c_int) c_int {
    const r = @rem(n, d);
    return if (r < 0) r + d else r;
}

const currentNumberOfLocalRegisters = struct {
    inline fn get() u8 {
        return currentSubroutineLevelData.numberOfLocalRegisters;
    }
};

// ===========================================================================
// _showRegisterInRbr (static)
// ===========================================================================
fn showRegisterInRbr(regist: calcRegister_t, registerNameWidth: i16) void {
    switch (getRegisterDataType(regist)) {
        dtReal34 => {
            if (showContent) {
                frontier_display.real34ToDisplayString(reg34(regist), getRegisterAngularMode(regist), tmpString, &standardFont, SCREEN_WIDTH - 1 - registerNameWidth, 34, @intFromBool(!LIMITEXP), @intFromBool(!FRONTSPACE), LIMITIRFRAC);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{d} bytes", .{@as(i32, REAL34_SIZE_IN_BYTES)});
            }
        },
        dtComplex34 => {
            if (showContent) {
                frontier_display.complex34ToDisplayString(regComplex34(regist), tmpString, &standardFont, SCREEN_WIDTH - 1 - registerNameWidth, 34, @intFromBool(!LIMITEXP), @intFromBool(!FRONTSPACE), LIMITIRFRAC, @intCast(getComplexRegisterAngularMode(regist)), @intFromBool(getComplexRegisterPolarMode(regist) != 0));
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{d} bytes", .{@as(i32, COMPLEX34_SIZE_IN_BYTES)});
            }
        },
        dtLongInteger => {
            if (showContent) {
                if (regist >= FIRST_RESERVED_VARIABLE) {
                    copySourceRegisterToDestRegister(regist, 135); // TEMP_REGISTER_1
                    frontier_display.longIntegerRegisterToDisplayString(135, tmpString, TMP_STR_LENGTH, SCREEN_WIDTH - 1 - registerNameWidth, 50, 0);
                } else if (getRegisterLongIntegerSign(regist) == LI_NEGATIVE) {
                    frontier_display.longIntegerRegisterToDisplayString(regist, tmpString, TMP_STR_LENGTH, SCREEN_WIDTH - 1 - registerNameWidth, 50, 0);
                } else {
                    frontier_display.longIntegerRegisterToDisplayString(regist, tmpString, TMP_STR_LENGTH, SCREEN_WIDTH - 9 - registerNameWidth, 50, 0);
                }
            } else {
                if (regist >= FIRST_RESERVED_VARIABLE) {
                    abi.fmtBufZ(tmpString[0..2560], "4 bytes", .{});
                } else {
                    abi.fmtBufZ(tmpString[0..2560], "{d} bits " ++ STD_CORRESPONDS_TO ++ " 4+{d} bytes", .{ toBytes(getRegisterMaxDataLengthInBlocks(regist)) * 8, toBytes(getRegisterMaxDataLengthInBlocks(regist)) });
                }
            }
        },
        dtShortInteger => {
            if (showContent) {
                frontier_display.shortIntegerToDisplayString(regist, tmpString, 0, noBaseOverride);
            } else {
                _ = strcpy(tmpString, "64 bits " ++ STD_CORRESPONDS_TO ++ " 8 bytes");
            }
        },
        dtString => {
            if (showContent) {
                _ = strcpy(tmpString, STD_LEFT_SINGLE_QUOTE);
                _ = strncat(tmpString, regStringData(regist), @intCast(stringByteLength(regStringData(regist)) + 1));
                _ = strcat(tmpString, STD_RIGHT_SINGLE_QUOTE);
                if (frontier_char_string.stringWidth(tmpString, &standardFont, false, true) >= SCREEN_WIDTH - 12 - registerNameWidth) { // 12 is the width of STD_ELLIPSIS
                    frontier_char_string.stringAfterPixels(tmpString, &standardFont, SCREEN_WIDTH - 12 - registerNameWidth, false, true)[0] = 0;
                    _ = strcat(tmpString + @as(usize, @intCast(stringByteLength(tmpString))), STD_ELLIPSIS);
                }
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{d} character{s} " ++ STD_CORRESPONDS_TO ++ " 4+{d} bytes", .{ @as(u32, @intCast(frontier_char_string.stringGlyphLength(regStringData(regist)))), std.mem.span(if (frontier_char_string.stringGlyphLength(regStringData(regist)) == 1) @as([*c]const u8, "") else @as([*c]const u8, "s")), toBytes(getRegisterMaxDataLengthInBlocks(regist)) });
            }
        },
        dtTime => {
            if (showContent) {
                frontier_display.timeToDisplayString(regist, tmpString, 1);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{d} bytes", .{@as(i32, REAL34_SIZE_IN_BYTES)});
            }
        },
        dtDate => {
            if (showContent) {
                frontier_display.dateToDisplayString(regist, tmpString);
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{d} bytes", .{@as(i32, REAL34_SIZE_IN_BYTES)});
            }
        },
        dtReal34Matrix => {
            if (showContent) {
                frontier_display.real34MatrixToDisplayString(regist, tmpString);
            } else {
                const matrixHeader = regMatrixHeader(regist);
                const elements: u16 = @as(u16, matrixHeader.matrixRows) *% @as(u16, matrixHeader.matrixColumns);
                abi.fmtBufZ(tmpString[0..2560], "{d} element{s} " ++ STD_CORRESPONDS_TO ++ " {d}+{d} bytes", .{ @as(u32, elements), std.mem.span(if (elements == 1) @as([*c]const u8, "") else @as([*c]const u8, "s")), sizeof_matrixHeader_t, toBytes(@as(u32, elements) * REAL34_SIZE_IN_BLOCKS) });
            }
        },
        dtComplex34Matrix => {
            if (showContent) {
                frontier_display.complex34MatrixToDisplayString(regist, tmpString);
            } else {
                const matrixHeader = regMatrixHeader(regist);
                const elements: u16 = @as(u16, matrixHeader.matrixRows) *% @as(u16, matrixHeader.matrixColumns);
                abi.fmtBufZ(tmpString[0..2560], "{d} element{s} " ++ STD_CORRESPONDS_TO ++ " {d}+{d} bytes", .{ @as(u32, elements), std.mem.span(if (elements == 1) @as([*c]const u8, "") else @as([*c]const u8, "s")), sizeof_matrixHeader_t, toBytes(@as(u32, elements) * COMPLEX34_SIZE_IN_BLOCKS) });
            }
        },
        dtConfig => {
            if (showContent) {
                _ = strcpy(tmpString, "Configuration data");
            } else {
                abi.fmtBufZ(tmpString[0..2560], "{d} bytes", .{@as(i32, CONFIG_SIZE_IN_BYTES)});
            }
        },
        else => {
            abi.fmtBufZ(tmpString[0..2560], "Data type {s}: to be coded", .{std.mem.span(frontier_debug.getDataTypeName(@intCast(getRegisterDataType(regist)), false, true))});
        },
    }
}

// ===========================================================================
// registerName (static)
// ===========================================================================
fn registerName(s: [*c]u8, regist: calcRegister_t) void {
    _ = s; // C passes tmpString but writes the global tmpString directly
    if (REGISTER_X <= regist and regist <= REGISTER_W) {
        tmpString[0] = frontier_screen_snap.letteredRegisterName(regist);
        _ = strcpy(tmpString + 1, ":");
    } else {
        abi.fmtBufZ(tmpString[0..2560], "R{d:0>2}:", .{@as(u32, @intCast(regist))});
    }
}

// ===========================================================================
// registerBrowser
// ===========================================================================
pub export fn registerBrowser(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    var registerNameWidth: i16 = undefined;

    hourGlassIconEnabled = false;

    if (calcMode != CM_REGISTER_BROWSER) {
        if (calcMode == CM_AIM) {
            frontier_screen.hideCursor();
            cursorEnabled = 0;
        }

        previousCalcMode = calcMode;
        calcMode = CM_REGISTER_BROWSER;
        clearSystemFlag(FLAG_ALPHA);
        return;
    }

    if (currentRegisterBrowserScreen == 9999) { // Init
        currentRegisterBrowserScreen = REGISTER_X;
        rbrMode = RBR_GLOBAL;
        showContent = true;
        rbr1stDigit = true;
    }

    if (rbrMode == RBR_GLOBAL) { // Global registers
        var row: i16 = 0;
        while (row < 10) : (row += 1) {
            const regist: calcRegister_t = @intCast(modulo(@as(c_int, currentRegisterBrowserScreen) + row, LAST_GLOBAL_REGISTER_SCREEN + RBR_INCDEC1));
            if (regist <= LAST_SPARE_REGISTER) {
                registerName(tmpString, regist);

                registerNameWidth = @truncate(@as(i32, @bitCast(frontier_screen.showString(tmpString, &standardFont, 1, @intCast(219 - 22 * row), vmNormal, 0, 1))));

                if ((regist < REGISTER_X and @rem(regist, 5) == 4) or (regist >= REGISTER_X and @rem(regist, 4) == 3)) {
                    frontier_screen.drawSinglePixelFullWidthLine(218 - 22 * row);
                }

                showRegisterInRbr(regist, registerNameWidth);

                _ = frontier_screen.showString(tmpString, &standardFont, @intCast(SCREEN_WIDTH - frontier_char_string.stringWidth(tmpString, &standardFont, false, true) - 1), @intCast(219 - 22 * row), vmNormal, 0, 1);
            }
        }
    } else if (rbrMode == RBR_LOCAL) { // Local registers
        if (currentNumberOfLocalRegisters.get() != 0) {
            var row: i16 = 0;
            while (row < 10) : (row += 1) {
                const regist: calcRegister_t = currentRegisterBrowserScreen + row;
                if (regist < FIRST_LOCAL_REGISTER + @as(i16, currentNumberOfLocalRegisters.get())) {
                    abi.fmtBufZ(tmpString[0..2560], "R.{d:0>2}:", .{@as(u32, @intCast(@as(c_int, regist) - FIRST_LOCAL_REGISTER))});

                    registerNameWidth = @truncate(@as(i32, @bitCast(frontier_screen.showString(tmpString, &standardFont, 1, @intCast(219 - 22 * row), vmNormal, 1, 1))));

                    if (@rem(regist, 5) == 1) {
                        frontier_screen.drawSinglePixelFullWidthLine(218 - 22 * row);
                    }

                    showRegisterInRbr(regist, registerNameWidth);

                    _ = frontier_screen.showString(tmpString, &standardFont, @intCast(SCREEN_WIDTH - frontier_char_string.stringWidth(tmpString, &standardFont, false, true)), @intCast(219 - 22 * row), vmNormal, 0, 1);
                }
            }
        } else { // no local register allocated
            rbrMode = RBR_NAMED;
            registerBrowser(NOPARAM);
        }
    } else if (rbrMode == RBR_NAMED) { // Named variables
        var row: i16 = 0;
        while (row < 10) : (row += 1) {
            var regist: calcRegister_t = currentRegisterBrowserScreen + row;
            if (regist < FIRST_NAMED_VARIABLE + @as(i16, @bitCast(numberOfNamedVariables))) { // Named variables
                _ = stringCopy(tmpString, @as([*c]u8, @ptrCast(&allNamedVariables[@intCast(regist - FIRST_NAMED_VARIABLE)].variableName)) + 1);
                _ = stringCopy(tmpString + @as(usize, @intCast(stringByteLength(tmpString))), ":");

                registerNameWidth = @truncate(@as(i32, @bitCast(frontier_screen.showString(tmpString, &standardFont, 1, @intCast(219 - 22 * row), vmNormal, 1, 1))));

                if ((@rem(regist, 5) == 1) or (regist == FIRST_NAMED_VARIABLE + @as(i16, @bitCast(numberOfNamedVariables)) - 1)) {
                    frontier_screen.drawSinglePixelFullWidthLine(218 - 22 * row);
                }

                showRegisterInRbr(regist, registerNameWidth);

                _ = frontier_screen.showString(tmpString, &standardFont, @intCast(SCREEN_WIDTH - frontier_char_string.stringWidth(tmpString, &standardFont, false, true)), @intCast(219 - 22 * row), vmNormal, 0, 1);
            } else { // Reserved variables
                if (regist < FIRST_RESERVED_VARIABLE) {
                    regist -= FIRST_NAMED_VARIABLE + @as(i16, @bitCast(numberOfNamedVariables));
                    regist += @as(i16, FIRST_RESERVED_VARIABLE) + @as(i16, NUMBER_OF_LETTERED_VARIABLES);
                }

                if (regist <= LAST_RESERVED_VARIABLE) { // Named variables
                    abi.fmtBufZ(tmpString[0..2560], "{s}:", .{std.mem.span(@as([*c]const u8, @ptrCast(&allReservedVariables[@intCast(@as(c_int, regist) - FIRST_RESERVED_VARIABLE)].reservedVariableName)) + 1)});

                    registerNameWidth = @truncate(@as(i32, @bitCast(frontier_screen.showString(tmpString, &standardFont, 1, @intCast(219 - 22 * row), vmNormal, 1, 1))));

                    if (@rem(regist, 5) == 1) {
                        frontier_screen.drawSinglePixelFullWidthLine(218 - 22 * row);
                    }

                    showRegisterInRbr(regist, registerNameWidth);

                    _ = frontier_screen.showString(tmpString, &standardFont, @intCast(SCREEN_WIDTH - frontier_char_string.stringWidth(tmpString, &standardFont, false, true)), @intCast(219 - 22 * row), vmNormal, 0, 1);
                }
            }
        }
    }
}
