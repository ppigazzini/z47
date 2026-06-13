// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/browsers/flagBrowser.c: the flagBrowser application plus
// the TO_QSPI letteredFlagDisplay[] table. This is a faithful, line-by-line port
// of the C. The SAVE_SPACE_DM42_8FL guard compiled the body out of old-HW
// single-file DM42 builds; that guard is never enabled for the packages z47
// ships, so the code is always present here. lcd_fill_rect is a DMCP-ROM
// fixed-address call on firmware (LIBRARY_FN_BASE+60) and a linkable symbol on
// host, trampolined like the sibling owners. The static `line` is reproduced as a
// module-level var. C integer promotion of int16_t arithmetic is reproduced with
// explicit i32 math.
//
// flagBrowser.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

// The TO_QSPI letteredFlagDisplay table goes to the executable QSPI region on the
// flash-limited old_hw DM42, matching the sibling owners' code_section.
const code_section = if (frontier_build_options.dmcp_build and frontier_build_options.old_hw)
    ".qspi"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// Relocatable read-only DATA (constants whose contents are pointers, e.g.
// letteredFlagDisplay's txt string pointers) cannot live in the truly
// read-only __TEXT section on macOS: dyld applies ASLR rebase fixups to the
// embedded pointers at load time and faults writing the read-only page
// (EXC_BAD_ACCESS code=2). Route such constants to a rebase-capable section.
// QSPI/XIP and ELF .text resolve the pointers at link time, so keep those.
const code_data_section = if (frontier_build_options.dmcp_build and frontier_build_options.old_hw)
    ".qspi"
else if (builtin.target.os.tag == .macos)
    "__DATA_CONST,__const"
else
    ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const videoMode_t = c_int;
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

const item_t = extern struct {
    func: ?*const fn (u16) callconv(.c) void,
    param: u16,
    itemCatalogName: [16]u8,
    itemSoftmenuName: [16]u8,
    tamMinMax: u16,
    status: u16,
};

// letteredFlagDisplay_t { const char *txt; int16_t position; } (8 bytes).
const letteredFlagDisplay_t = extern struct {
    txt: [*:0]const u8,
    position: i16,
};
const font_t = opaque {};

// ---------------------------------------------------------------------------
// Constants / enum values (verified via C probe)
// ---------------------------------------------------------------------------
const CM_FLAG_BROWSER: u8 = 6;
const CM_AIM: u8 = 1;
const FLAG_ALPHA: c_uint = 0x800e;

const FIRST_SCREEN: u8 = 1;
const LAST_SCREEN: u8 = 5;
const STATUS_SCREEN: u8 = 1;
const SYSTEM_FLAGS_SCREEN_1: u8 = 2;
const SYSTEM_FLAGS_SCREEN_2: u8 = 3;
const GLOBAL_FLAGS_SCREEN: u8 = 4;
const LETTERED_AND_LOCAL_FLAGS_SCREEN: u8 = 5;

const CHARS_PER_LINE: i32 = 80;
const SCREEN_WIDTH: i16 = 400;

const FLAG_X: i16 = 100;
const FLAG_W: i16 = 224;
const FLAG_K: i16 = 111;
const FLAG_M: i16 = 211;

const NUMBER_OF_SYSTEM_FLAGS: i16 = 105;
const NUMBER_OF_LOCAL_FLAGS: i16 = 32;
const FIRST_LOCAL_FLAG: i16 = 112;

const LCD_EMPTY_VALUE: c_int = 255;
const vmNormal: videoMode_t = 0;
const vmReverse: videoMode_t = 1;

const REGISTER_X: calcRegister_t = 100;

const dtLongInteger: u32 = 0;
const dtShortInteger: u32 = 8;
const dtReal34: u32 = 1;

const RM_HALF_EVEN: u8 = 0;
const RM_HALF_UP: u8 = 1;
const RM_HALF_DOWN: u8 = 2;
const RM_UP: u8 = 3;
const RM_DOWN: u8 = 4;
const RM_CEIL: u8 = 5;
const RM_FLOOR: u8 = 6;

const DEC_ROUND_DOWN: c_int = 5;

// STD_* macro byte sequences (fonts.h).
const STD_SPACE_6_PER_EM = "\xa0\x06";
const STD_SPACE_3_PER_EM = "\xa0\x04";
const STD_ONE_HALF = "\x80\xbd";
const STD_UP_ARROW = "\xa1\x91";
const STD_DOWN_ARROW = "\xa1\x93";
const STD_LEFT_ARROW = "\xa1\x90";
const STD_RIGHT_ARROW = "\xa1\x92";
const STD_MAT_TL = "\xa3\xa1";
const STD_MAT_TR = "\xa3\xa4";
const STD_MAT_BL = "\xa3\xa3";
const STD_MAT_BR = "\xa3\xa6";
const STD_INFINITY = "\xa2\x1e";

// ---------------------------------------------------------------------------
// letteredFlagDisplay[] table (TO_QSPI const).
// ---------------------------------------------------------------------------
pub export const letteredFlagDisplay linksection(code_data_section) = [_]letteredFlagDisplay_t{
    .{ .txt = STD_SPACE_6_PER_EM ++ "X", .position = 3 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "Y", .position = 3 + 1 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "Z", .position = 3 + 2 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "T", .position = 3 + 3 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "A", .position = 3 + 4 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "B", .position = 3 + 5 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "C", .position = 3 + 6 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "D", .position = 3 + 7 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "L", .position = 3 + 8 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "I", .position = 8 + 10 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "J", .position = 4 + 11 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "K", .position = 2 + 12 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "M", .position = 4 + 15 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "N", .position = 5 + 16 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "P", .position = 6 + 17 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "Q", .position = 6 + 18 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "R", .position = 6 + 19 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "S", .position = 6 + 20 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "E", .position = 9 + 22 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "F", .position = 9 + 23 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "G", .position = 8 + 24 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "H", .position = 8 + 25 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "O", .position = 9 + 28 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "U", .position = 9 + 29 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "V", .position = 8 + 30 * 12 },
    .{ .txt = STD_SPACE_6_PER_EM ++ "W", .position = 8 + 31 * 12 },
};

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var hourGlassIconEnabled: bool_t;
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var currentFlgScr: u8;
extern var lastFlgScr: u8;
extern var cursorEnabled: u8;
extern var tmpString: [*c]u8;
extern var roundingMode: u8;
extern var significantDigits: u8;
extern var ctxtReal34: realContext_t;

extern const registerFlagLetters: [27]u8;
extern const KEY_X: [7]c_int;
const LAST_ITEM: usize = 2791;
extern const indexOfItems: [LAST_ITEM]item_t;
extern const standardFont: font_t;

const subroutineLevelHeader_t = extern struct {
    returnProgramNumber: i16,
    returnLocalStep: u16,
    numberOfLocalFlags: u8,
    numberOfLocalRegisters: u8,
    subroutineLevel: u16,
    ptrToNextLevel: u16,
    ptrToPreviousLevel: u16,
};
extern var currentSubroutineLevelData: *subroutineLevelHeader_t;

// menu_SYSFL is declared `extern int16_t menu_SYSFL[]` inside the C function; its
// symbol address is the table base.
const menu_SYSFL = @extern([*]const i16, .{ .name = "menu_SYSFL" });

// static int16_t line (file-static persistent state).
var line: i16 = 0;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getFlag(flag: u16) bool_t;
extern fn getSystemFlag(flag: c_int) bool_t;
extern fn clearSystemFlag(flag: c_uint) void;
extern fn hideCursor() void;
extern fn refreshScreen(source: u16) void;
extern fn getFreeRamMemory() u32;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*]u8;
extern fn supNumberToDisplayString(supNumber: i32, displayString: [*c]u8, displayValueString: [*c]u8, insertGap: bool_t) void;

extern fn showString(str: [*:0]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) u32;
extern fn stringWidth(str: [*:0]const u8, font: *const font_t, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) i16;

extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
extern fn xcopy(dst: *anyopaque, src: *const anyopaque, n: u32) *anyopaque;

// decQuad (real34) helpers (the real34 macros).
extern fn decQuadIsInfinite(r: *align(1) const real34_t) u32;
extern fn decQuadNextPlus(res: *real34_t, operand: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadNextMinus(res: *real34_t, operand: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadSubtract(res: *real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctx: *realContext_t) *real34_t;
extern fn decQuadGetExponent(src: *align(1) const real34_t) i32;

// lcd_fill_rect — DMCP-ROM fixed-address call on firmware; real symbol on host.
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

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn reg34(reg: calcRegister_t) *align(1) const real34_t {
    return @ptrCast(getRegisterDataPointer(reg));
}
inline fn real34IsInfinite(src: *align(1) const real34_t) bool {
    return decQuadIsInfinite(src) != 0;
}
inline fn real34NextPlus(operand: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadNextPlus(res, operand, &ctxtReal34);
}
inline fn real34NextMinus(operand: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadNextMinus(res, operand, &ctxtReal34);
}
inline fn real34Subtract(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *real34_t) void {
    _ = decQuadSubtract(res, op1, op2, &ctxtReal34);
}
inline fn real34GetExponent(src: *align(1) const real34_t) i32 {
    return decQuadGetExponent(src);
}
inline fn minI(a: i16, b: i16) i16 {
    return if (a < b) a else b;
}
// tmpString + CHARS_PER_LINE * n  (C pointer arithmetic on char*).
inline fn lineStr(n: i32) [*c]u8 {
    return tmpString + @as(usize, @intCast(CHARS_PER_LINE * n));
}

// ===========================================================================
// flagBrowser
// ===========================================================================
pub export fn flagBrowser(init: u16) callconv(.c) void {
    var f: i16 = undefined;
    var i: i16 = undefined;
    var firstFlag: bool_t = undefined;

    hourGlassIconEnabled = false;

    if (calcMode != CM_FLAG_BROWSER) {
        if (calcMode == CM_AIM) {
            hideCursor();
            cursorEnabled = 0;
        }

        previousCalcMode = calcMode;
        calcMode = CM_FLAG_BROWSER;
        clearSystemFlag(FLAG_ALPHA);
        currentFlgScr = @intCast(init);
        refreshScreen(190);
    }

    if (currentFlgScr < FIRST_SCREEN) {
        currentFlgScr = LAST_SCREEN;
    }

    if (currentFlgScr > LAST_SCREEN) {
        currentFlgScr = FIRST_SCREEN;
    }

    if (currentFlgScr == STATUS_SCREEN) { // Init new style
        var flagNumber: [4]u8 = undefined;

        line = 0;

        _ = sprintf(lineStr(blk: {
            const v = line;
            line += 1;
            break :blk v;
        }), "%u bytes free in RAM.", getFreeRamMemory());

        _ = sprintf(lineStr(blk: {
            const v = line;
            line += 1;
            break :blk v;
        }), "Global user flags set:");

        lineStr(line)[0] = 0;
        firstFlag = true;
        f = 0;
        while (f <= FLAG_W) : (f += 1) {
            if (f > FLAG_K and f < FLAG_M) {
                continue;
            }

            if (getFlag(@bitCast(f))) {
                if (f < 10) {
                    flagNumber[0] = @intCast('0' + f);
                    flagNumber[1] = 0;
                } else if (f < 100) {
                    flagNumber[0] = @intCast('0' + @divTrunc(f, 10));
                    flagNumber[1] = @intCast('0' + @rem(f, 10));
                    flagNumber[2] = 0;
                } else {
                    flagNumber[0] = registerFlagLetters[@intCast(if (f <= FLAG_K) f - FLAG_X else f - (FLAG_M - 12))];
                    flagNumber[1] = 0;
                }

                if (@as(i32, stringWidth(lineStr(line), &standardFont, true, true)) + @as(i32, stringWidth(@ptrCast(&flagNumber), &standardFont, true, false)) <= SCREEN_WIDTH - 1 - 8) {
                    if (!firstFlag) {
                        _ = strcat(lineStr(line), " ");
                    } else {
                        firstFlag = false;
                    }
                    _ = strcat(lineStr(line), &flagNumber);
                } else {
                    line += 1;
                    _ = xcopy(lineStr(line), &flagNumber, 4);
                }
            }
        }

        if (currentNumberOfLocalFlags() == 0) {
            line += 1;
            _ = sprintf(lineStr(line), "No local flags or registers allocated.");
        } else {
            line += 1;
            _ = sprintf(lineStr(line), "Local user flags set:");
            line += 1;
            lineStr(line)[0] = 0;
            firstFlag = true;
            f = 0;
            while (f < NUMBER_OF_LOCAL_FLAGS) : (f += 1) {
                if (getFlag(@bitCast(FIRST_LOCAL_FLAG + f))) {
                    if (f < 10) {
                        flagNumber[0] = @intCast('0' + f);
                        flagNumber[1] = 0;
                    } else {
                        flagNumber[0] = @intCast('0' + @divTrunc(f, 10));
                        flagNumber[1] = @intCast('0' + @rem(f, 10));
                        flagNumber[2] = 0;
                    }

                    if (@as(i32, stringWidth(lineStr(line), &standardFont, true, true)) + @as(i32, stringWidth(@ptrCast(&flagNumber), &standardFont, true, false)) <= SCREEN_WIDTH - 1 - 8) {
                        if (!firstFlag) {
                            _ = strcat(lineStr(line), " ");
                        } else {
                            firstFlag = false;
                        }
                        _ = strcat(lineStr(line), &flagNumber);
                    } else {
                        line += 1;
                        _ = xcopy(lineStr(line), &flagNumber, 4);
                    }
                }
            }
        }

        // Empty line
        line += 1;
        lineStr(line)[0] = 0;

        // Rounding mode
        line += 1;
        _ = strcpy(lineStr(line), "RMODE=");
        switch (roundingMode) {
            RM_HALF_EVEN => _ = strcat(lineStr(line), STD_ONE_HALF ++ "E"),
            RM_HALF_UP => _ = strcat(lineStr(line), STD_ONE_HALF ++ STD_UP_ARROW),
            RM_HALF_DOWN => _ = strcat(lineStr(line), STD_ONE_HALF ++ STD_DOWN_ARROW),
            RM_UP => _ = strcat(lineStr(line), STD_LEFT_ARROW ++ "0" ++ STD_RIGHT_ARROW),
            RM_DOWN => _ = strcat(lineStr(line), STD_RIGHT_ARROW ++ "0" ++ STD_LEFT_ARROW),
            RM_CEIL => _ = strcat(lineStr(line), STD_MAT_TL ++ "x" ++ STD_MAT_TR),
            RM_FLOOR => _ = strcat(lineStr(line), STD_MAT_BL ++ "x" ++ STD_MAT_BR),
            else => _ = strcat(lineStr(line), "???"),
        }

        // Significant digits
        _ = strcat(lineStr(line), "  SDIGS=");
        const sd: u8 = if (significantDigits == 0) 34 else significantDigits;
        if (sd < 10) {
            flagNumber[0] = '0' + sd;
            flagNumber[1] = 0;
        } else {
            flagNumber[0] = '0' + sd / 10;
            flagNumber[1] = '0' + sd % 10;
            flagNumber[2] = 0;
        }
        _ = strcat(lineStr(line), &flagNumber);

        // ULP of X
        switch (getRegisterDataType(REGISTER_X)) {
            dtLongInteger, dtShortInteger => {
                _ = strcat(lineStr(line), "  ULP of reg X = 1");
            },
            dtReal34 => {
                if (real34IsInfinite(reg34(REGISTER_X))) {
                    _ = strcat(lineStr(line), "  ULP of reg X = " ++ STD_INFINITY);
                } else {
                    var x34: real34_t = undefined;
                    real34NextPlus(reg34(REGISTER_X), &x34);
                    if (real34IsInfinite(&x34)) {
                        real34NextMinus(reg34(REGISTER_X), &x34);
                        real34Subtract(reg34(REGISTER_X), &x34, &x34);
                    } else {
                        real34Subtract(&x34, reg34(REGISTER_X), &x34);
                    }
                    _ = strcat(lineStr(line), "  ULP of reg X = 10");
                    supNumberToDisplayString(real34GetExponent(&x34), lineStr(line) + strlen(lineStr(line)), null, false);
                }
            },
            else => {},
        }
        line += 1;
        lineStr(line)[0] = 0;
    }

    if (currentFlgScr == STATUS_SCREEN) {
        f = 0;
        while (f < minI(9, line)) : (f += 1) {
            _ = showString(lineStr(f), &standardFont, 1, @intCast(22 * @as(i32, f) + 43), vmNormal, true, false);
        }
    }

    if (currentFlgScr == SYSTEM_FLAGS_SCREEN_1 or currentFlgScr == SYSTEM_FLAGS_SCREEN_2) { // System Flags 00 to 59
        var systemFlag: u16 = undefined;
        var param: u16 = undefined;
        var x1: u16 = undefined;
        var x2: u16 = undefined;
        var y1: u16 = undefined;
        const fOffset: u16 = if (currentFlgScr == SYSTEM_FLAGS_SCREEN_1) 0 else 60;
        f = 0;
        while (f <= 59) : (f += 1) {
            if (@as(i32, f) + fOffset > NUMBER_OF_SYSTEM_FLAGS - 1) {
                break;
            }
            systemFlag = @bitCast(menu_SYSFL[@intCast(@as(i32, f) + fOffset)]);
            param = indexOfItems[systemFlag].param;
            x1 = @intCast(KEY_X[@intCast(@rem(f, 6))] + 2);
            x2 = @intCast(KEY_X[@intCast(@rem(f, 6) + 1)] - 1);
            y1 = @intCast(22 * @divTrunc(@as(i32, f), 6) + 66 - 1 - 44);
            if (getSystemFlag(@intCast(param))) {
                lcdFillRect(
                    x1,
                    y1,
                    x2 - x1,
                    @intCast(22 * @divTrunc(@as(i32, f), 6) + 66 + 20 - 1 - 44 - @as(i32, y1) + 1),
                    LCD_EMPTY_VALUE,
                );
            }
            _ = sprintf(tmpString, "%s", @as([*c]const u8, @ptrCast(&indexOfItems[systemFlag].itemCatalogName)));
            _ = showString(tmpString, &standardFont, @intCast(@divTrunc(@as(i32, x1) + x2 - stringWidth(tmpString, &standardFont, false, false), 2)), y1, if (getSystemFlag(@intCast(param))) vmReverse else vmNormal, true, true);
        }
    }

    if (currentFlgScr == GLOBAL_FLAGS_SCREEN) { // Global flags from 0 to 99
        f = 0;
        while (f <= 99) : (f += 1) {
            if (getFlag(@bitCast(f))) {
                lcdFillRect(@intCast(40 * @rem(@as(i32, f), 10) + 1), @intCast(22 * @divTrunc(@as(i32, f), 10) + 66 - 1 - 44), @intCast(40 * @rem(@as(i32, f), 10) + 39 - (40 * @rem(@as(i32, f), 10) + 1)), @intCast(22 * @divTrunc(@as(i32, f), 10) + 66 + 20 - 1 - 44 - (22 * @divTrunc(@as(i32, f), 10) + 66 - 1 - 44) + 1), LCD_EMPTY_VALUE);
            }
            _ = sprintf(tmpString, "%d", @as(c_int, f));
            _ = showString(tmpString, &standardFont, @intCast(40 * @rem(@as(i32, f), 10) + 19 - @divTrunc(@as(i32, stringWidth(tmpString, &standardFont, false, false)), 2)), @intCast(22 * @divTrunc(@as(i32, f), 10) + 66 - 1 - 44), if (getFlag(@bitCast(f))) vmReverse else vmNormal, true, true);
        }
    }

    if (currentFlgScr == LETTERED_AND_LOCAL_FLAGS_SCREEN) { // Lettered flags, local registers and flags
        _ = showString("Global flag status (continued):", &standardFont, 1, 22 - 1, vmNormal, true, true);

        // Lettered flags
        f = FLAG_X;
        while (f <= FLAG_W) : (f += 1) {
            f = if (f == FLAG_K + 1) FLAG_M else f; // Skip from FLAG_K (111) to FLAG_M (211)
            i = if (f <= FLAG_K) f - FLAG_X else f - FLAG_X - 99; // Index in the flag display table
            _ = showString(letteredFlagDisplay[@intCast(i)].txt, &standardFont, @intCast(letteredFlagDisplay[@intCast(i)].position), 43, if (getFlag(@bitCast(f))) vmReverse else vmNormal, true, true);
        }

        _ = showString("[" ++ STD_SPACE_6_PER_EM ++ "  100..108   " ++ STD_SPACE_3_PER_EM ++ STD_SPACE_6_PER_EM ++ "109..111  " ++ STD_SPACE_3_PER_EM ++ "211..216  217..220" ++ STD_SPACE_6_PER_EM ++ " 221..224]", &standardFont, 1, 44 + 66 - 1 - 44, vmNormal, true, true);

        if (currentNumberOfLocalFlags() == 0) {
            _ = sprintf(tmpString, "No local flags or registers allocated.");
            _ = showString(tmpString, &standardFont, 1, 109, vmNormal, true, true);
        } else {
            // Local Registers
            _ = sprintf(tmpString, "%u local register%s allocated.", @as(c_uint, currentNumberOfLocalRegisters()), if (currentNumberOfLocalRegisters() > 1) @as([*c]const u8, "s") else @as([*c]const u8, ""));
            _ = showString(tmpString, &standardFont, 1, 109, vmNormal, true, true);
            _ = showString("Local flag status:", &standardFont, 1, 153, vmNormal, true, true);

            // Local Flags
            f = 0;
            while (f < NUMBER_OF_LOCAL_FLAGS) : (f += 1) {
                if (getFlag(@bitCast(FIRST_LOCAL_FLAG + f))) {
                    lcdFillRect(@intCast(25 * @rem(@as(i32, f), 16) + 1), @intCast(22 * @divTrunc(@as(i32, f), 16) + 175), 22, 21, LCD_EMPTY_VALUE);
                }

                _ = sprintf(tmpString, "%d", @as(c_int, f));
                _ = showString(tmpString, &standardFont, @intCast(25 * @rem(@as(i32, f), 16) + 5 + 4 * @as(i32, @intFromBool(f <= 9)), ), @intCast(22 * @divTrunc(@as(i32, f), 16) + 175), if (getFlag(@bitCast(FIRST_LOCAL_FLAG + f))) vmReverse else vmNormal, true, true);
            }
        }
    }
    lastFlgScr = currentFlgScr;
}

// ---------------------------------------------------------------------------
// currentNumberOfLocalFlags / currentNumberOfLocalRegisters macros.
// ---------------------------------------------------------------------------
inline fn currentNumberOfLocalFlags() u8 {
    return currentSubroutineLevelData.numberOfLocalFlags;
}
inline fn currentNumberOfLocalRegisters() u8 {
    return currentSubroutineLevelData.numberOfLocalRegisters;
}
