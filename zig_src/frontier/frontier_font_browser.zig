// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/browsers/fontBrowser.c: initFontBrowser (computes the
// glyph-row table from the four fonts) and fontBrowser (the on-screen font
// browser application). This is a faithful, line-by-line port of the C. The
// font_t flexible-array glyph table is reached via a typed pointer at the
// struct's glyphs offset; min()/max() are reproduced inline. The PC_BUILD
// overflow self-check (printf + exit) is host-only, gated on !dmcp_build.
//
// fontBrowser.c is not reachable from the testSuite; verification is by
// build/link across every target plus the boundary gates.

const std = @import("std");
const frontier_build_options = @import("frontier_build_options");
const abi = @import("abi");
const dmcp_build: bool = frontier_build_options.dmcp_build;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const videoMode_t = c_int;

// glyph_t — natural C ABI layout (charCode first). Only charCode is read; the
// rest matters for the element stride of the glyphs[] array.
const glyph_t = abi.Glyph;
const font_t = abi.Font;
inline fn glyphsOf(font: *const font_t) [*]const glyph_t {
    return @ptrCast(&font.glyphs);
}

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const CM_FONT_BROWSER: u8 = 7;
const FLAG_ALPHA: c_uint = 0x800e;
const FLAG_BOLD: c_uint = 0x8069;
const vmNormal: videoMode_t = 0;

const NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN: u16 = 5;
const NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN: u16 = 8;
const NUMBER_OF_GLYPH_ROWS: usize = 267; // defines.h: 267 (matches glyphRow[] global size)
const NUMERIC_FONT_HEIGHT: u16 = 36;
const STANDARD_FONT_HEIGHT: u16 = 22;
const SCREEN_WIDTH: i16 = 400;

// STD arrow byte sequences (fonts.h).
const STD_UP_ARROW = "\xa1\x91";
const STD_DOWN_ARROW = "\xa1\x93";

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var numScreensStandardFont: u8;
extern var numScreensNumericFont: u8;
extern var numScreensNumericFontBold: u8;
extern var numScreensTinyFont: u8;
extern var currentFntScr: u8;
extern var numLinesNumericFont: u8;
extern var numLinesNumericFontBold: u8;
extern var numLinesStandardFont: u8;
extern var numLinesTinyFont: u8;
extern var glyphRow: [NUMBER_OF_GLYPH_ROWS]u16;
extern var previousCalcMode: u8;
extern var calcMode: u8;
extern var hourGlassIconEnabled: bool;
extern var tmpString: [*c]u8;

extern const numericFont: font_t;
extern const numericFontBold: font_t;
extern const standardFont: font_t;
extern const tinyFont: font_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn showGlyphCode(charCode: u16, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool, showEndingCols: bool, noPreClear: bool) u32;
extern fn showString(str: [*:0]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool, showEndingCols: bool) u32;
extern fn stringWidth(str: [*:0]const u8, font: *const font_t, withLeadingEmptyRows: bool, withEndingEmptyRows: bool) i16;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn exit(status: c_int) noreturn;
extern fn getSystemFlag(sf: c_uint) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(flag: c_uint) void;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
inline fn minU16(a: u16, b: u16) u16 {
    return if (a < b) a else b;
}

// ===========================================================================
// initFontBrowser
// ===========================================================================
pub export fn initFontBrowser() callconv(.c) void {
    var g: u16 = undefined;

    numLinesNumericFont = 0;
    g = 0;
    while (g < numericFont.numberOfGlyphs) {
        glyphRow[numLinesNumericFont] = glyphsOf(&numericFont)[g].charCode & 0xfff0;
        while (g < numericFont.numberOfGlyphs and ((glyphsOf(&numericFont)[g].charCode & 0xfff0) == glyphRow[numLinesNumericFont])) {
            g += 1;
        }
        numLinesNumericFont += 1;
    }

    numScreensNumericFont = @intCast(numLinesNumericFont / NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN);
    if (numLinesNumericFont % NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN != 0) {
        numScreensNumericFont += 1;
    }

    numLinesNumericFontBold = 0;
    g = 0;
    while (g < numericFontBold.numberOfGlyphs) {
        glyphRow[@as(usize, numLinesNumericFont) + numLinesNumericFontBold] = glyphsOf(&numericFontBold)[g].charCode & 0xfff0;
        while (g < numericFontBold.numberOfGlyphs and ((glyphsOf(&numericFontBold)[g].charCode & 0xfff0) == glyphRow[@as(usize, numLinesNumericFont) + numLinesNumericFontBold])) {
            g += 1;
        }
        numLinesNumericFontBold += 1;
    }

    numScreensNumericFontBold = @intCast(numLinesNumericFontBold / NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN);
    if (numLinesNumericFontBold % NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN != 0) {
        numScreensNumericFontBold += 1;
    }

    numLinesStandardFont = 0;
    g = 0;
    while (g < standardFont.numberOfGlyphs) {
        glyphRow[@as(usize, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont] = glyphsOf(&standardFont)[g].charCode & 0xfff0;
        while (g < standardFont.numberOfGlyphs and ((glyphsOf(&standardFont)[g].charCode & 0xfff0) == glyphRow[@as(usize, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont])) {
            g += 1;
        }
        numLinesStandardFont += 1;
    }

    numScreensStandardFont = @intCast(numLinesStandardFont / NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN);
    if (numLinesStandardFont % NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN != 0) {
        numScreensStandardFont += 1;
    }

    numLinesTinyFont = 0;
    g = 0;
    while (g < tinyFont.numberOfGlyphs) {
        glyphRow[@as(usize, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont + numLinesTinyFont] = glyphsOf(&tinyFont)[g].charCode & 0xfff0;
        while (g < tinyFont.numberOfGlyphs and ((glyphsOf(&tinyFont)[g].charCode & 0xfff0) == glyphRow[@as(usize, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont + numLinesTinyFont])) {
            g += 1;
        }
        numLinesTinyFont += 1;
    }

    numScreensTinyFont = @intCast(numLinesTinyFont / NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN);
    if (numLinesTinyFont % NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN != 0) {
        numScreensTinyFont += 1;
    }

    currentFntScr = 1;

    if (comptime !dmcp_build) { // PC_BUILD
        if (@as(u16, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont + numLinesTinyFont > NUMBER_OF_GLYPH_ROWS) {
            _ = printf("In file defines.h NUMBER_OF_GLYPH_ROWS must be increased from %d to %d\n", @as(c_int, NUMBER_OF_GLYPH_ROWS), @as(c_int, @as(u16, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont + numLinesTinyFont));
            exit(@bitCast(@as(c_int, -1)));
        }
    }
}

// ===========================================================================
// fontBrowser
// ===========================================================================
pub export fn fontBrowser(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;

    var x: u16 = undefined;
    var y: u16 = undefined;
    var first: u16 = undefined;

    hourGlassIconEnabled = false;

    if (calcMode != CM_FONT_BROWSER) {
        previousCalcMode = calcMode;
        calcMode = CM_FONT_BROWSER;
        clearSystemFlag(FLAG_ALPHA);
        return;
    }

    if (currentFntScr >= 1 and currentFntScr <= numScreensNumericFont) { // Numeric font
        x = 0;
        while (x <= 9) : (x += 1) {
            _ = showGlyphCode('0' + x, &standardFont, 50 + 20 * x, 20, vmNormal, false, false, false);
        }
        x = 0;
        while (x <= 5) : (x += 1) {
            _ = showGlyphCode('A' + x, &standardFont, 50 + 200 + 20 * x, 20, vmNormal, false, false, false);
        }

        const mem = getSystemFlag(FLAG_BOLD); // Prevent system BOLD setting from overriding the normal Numeric font with Bold
        clearSystemFlag(FLAG_BOLD);
        first = (@as(u16, currentFntScr) - 1) * NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN;
        y = first;
        while (y < minU16(@as(u16, currentFntScr) * NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN, numLinesNumericFont)) : (y += 1) {
            abi.fmtBufZ(tmpString[0..2560], "{X:0>4}", .{@as(u32, if (glyphRow[y] < 0x8000) glyphRow[y] else glyphRow[y] -% 0x8000)});
            _ = showString(tmpString, &standardFont, 5, NUMERIC_FONT_HEIGHT * (y - first) + 43, vmNormal, false, false);
            x = 0;
            while (x <= 15) : (x += 1) {
                _ = showGlyphCode(glyphRow[y] +% x, &numericFont, 46 + 20 * x, NUMERIC_FONT_HEIGHT * (y - first) + 40, vmNormal, false, false, false);
            }
        }
        if (mem) {
            setSystemFlag(FLAG_BOLD);
        }

        if (currentFntScr == 1) {
            _ = showString("Numeric font. Press " ++ STD_DOWN_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        } else {
            _ = showString("Numeric font. Press " ++ STD_UP_ARROW ++ ", " ++ STD_DOWN_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        }

        abi.fmtBufZ(tmpString[0..2560], "{d}/{d}", .{ @as(i32, currentFntScr), @as(i32, @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont + numScreensTinyFont) });
        _ = showString(tmpString, &standardFont, @as(u32, @intCast(SCREEN_WIDTH - stringWidth(tmpString, &standardFont, false, true))), 220, vmNormal, false, true);
    } else if (currentFntScr > numScreensNumericFont and currentFntScr <= @as(u16, numScreensNumericFont) + numScreensNumericFontBold) { // Numeric font bold
        x = 0;
        while (x <= 9) : (x += 1) {
            _ = showGlyphCode('0' + x, &standardFont, 50 + 20 * x, 20, vmNormal, false, false, false);
        }
        x = 0;
        while (x <= 5) : (x += 1) {
            _ = showGlyphCode('A' + x, &standardFont, 50 + 200 + 20 * x, 20, vmNormal, false, false, false);
        }

        first = @as(u16, numLinesNumericFont) + (@as(u16, currentFntScr) - numScreensNumericFont - 1) * NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN;
        y = first;
        while (y < minU16(@as(u16, numLinesNumericFont) + (@as(u16, currentFntScr) - numScreensNumericFont) * NUMBER_OF_NUMERIC_FONT_LINES_PER_SCREEN, @as(u16, numLinesNumericFont) + numLinesNumericFontBold)) : (y += 1) {
            abi.fmtBufZ(tmpString[0..2560], "{X:0>4}", .{@as(u32, if (glyphRow[y] < 0x8000) glyphRow[y] else glyphRow[y] -% 0x8000)});
            _ = showString(tmpString, &standardFont, 5, NUMERIC_FONT_HEIGHT * (y - first) + 43, vmNormal, false, false);
            x = 0;
            while (x <= 15) : (x += 1) {
                _ = showGlyphCode(glyphRow[y] +% x, &numericFontBold, 46 + 20 * x, NUMERIC_FONT_HEIGHT * (y - first) + 40, vmNormal, false, false, false);
            }
        }

        if (currentFntScr == 1) {
            _ = showString("Numeric font bold. Press " ++ STD_DOWN_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        } else {
            _ = showString("Numeric font bold. Press " ++ STD_UP_ARROW ++ ", " ++ STD_DOWN_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        }

        abi.fmtBufZ(tmpString[0..2560], "{d}/{d}", .{ @as(i32, currentFntScr), @as(i32, @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont + numScreensTinyFont) });
        _ = showString(tmpString, &standardFont, @as(u32, @intCast(SCREEN_WIDTH - stringWidth(tmpString, &standardFont, false, true))), 220, vmNormal, false, true);
    } else if (currentFntScr > @as(u16, numScreensNumericFont) + numScreensNumericFontBold and currentFntScr <= @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont) { // Standard font
        x = 0;
        while (x <= 9) : (x += 1) {
            _ = showGlyphCode('0' + x, &standardFont, 50 + 20 * x, 20, vmNormal, false, false, false);
        }
        x = 0;
        while (x <= 5) : (x += 1) {
            _ = showGlyphCode('A' + x, &standardFont, 50 + 200 + 20 * x, 20, vmNormal, false, false, false);
        }

        first = @as(u16, numLinesNumericFont) + numLinesNumericFontBold + (@as(u16, currentFntScr) - numScreensNumericFont - numScreensNumericFontBold - 1) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN;
        y = first;
        while (y < minU16(@as(u16, numLinesNumericFont) + numLinesNumericFontBold + (@as(u16, currentFntScr) - numScreensNumericFont - numScreensNumericFontBold) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN, @as(u16, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont)) : (y += 1) {
            abi.fmtBufZ(tmpString[0..2560], "{X:0>4}", .{@as(u32, if (glyphRow[y] < 0x8000) glyphRow[y] else glyphRow[y] -% 0x8000)});
            _ = showString(tmpString, &standardFont, 5, STANDARD_FONT_HEIGHT * (y - first) + 40, vmNormal, false, false);
            x = 0;
            while (x <= 15) : (x += 1) {
                _ = showGlyphCode(glyphRow[y] +% x, &standardFont, 50 + 20 * x, STANDARD_FONT_HEIGHT * (y - first) + 40, vmNormal, false, false, false);
            }
        }

        // NOTE: faithful to C (fontBrowser.c:198) — this "last page" check omits the bold term.
        if (currentFntScr == @as(u16, numScreensNumericFont) + numScreensStandardFont + numScreensTinyFont) {
            _ = showString("Standard font. Press " ++ STD_UP_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        } else {
            _ = showString("Standard font. Press " ++ STD_UP_ARROW ++ ", " ++ STD_DOWN_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        }

        abi.fmtBufZ(tmpString[0..2560], "{d}/{d}", .{ @as(i32, currentFntScr), @as(i32, @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont + numScreensTinyFont) });
        _ = showString(tmpString, &standardFont, @as(u32, @intCast(SCREEN_WIDTH - stringWidth(tmpString, &standardFont, false, true))), 220, vmNormal, false, true);
    } else if (currentFntScr > @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont and currentFntScr <= @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont + numScreensTinyFont) { // Tiny font
        x = 0;
        while (x <= 9) : (x += 1) {
            _ = showGlyphCode('0' + x, &standardFont, 50 + 20 * x, 20, vmNormal, false, false, false);
        }
        x = 0;
        while (x <= 5) : (x += 1) {
            _ = showGlyphCode('A' + x, &standardFont, 50 + 200 + 20 * x, 20, vmNormal, false, false, false);
        }

        first = @as(u16, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont + (@as(u16, currentFntScr) - numScreensNumericFont - numScreensNumericFontBold - numScreensStandardFont - 1) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN;
        y = first;
        while (y < minU16(@as(u16, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont + (@as(u16, currentFntScr) - numScreensNumericFont - numScreensNumericFontBold - numScreensStandardFont) * NUMBER_OF_STANDARD_FONT_LINES_PER_SCREEN, @as(u16, numLinesNumericFont) + numLinesNumericFontBold + numLinesStandardFont + numLinesTinyFont)) : (y += 1) {
            abi.fmtBufZ(tmpString[0..2560], "{X:0>4}", .{@as(u32, if (glyphRow[y] < 0x8000) glyphRow[y] else glyphRow[y] -% 0x8000)});
            _ = showString(tmpString, &standardFont, 5, STANDARD_FONT_HEIGHT * (y - first) + 40, vmNormal, false, false);
            x = 0;
            while (x <= 15) : (x += 1) {
                _ = showGlyphCode(glyphRow[y] +% x, &tinyFont, 52 + 20 * x, STANDARD_FONT_HEIGHT * (y - first) + 46, vmNormal, false, false, false);
            }
        }

        if (currentFntScr == @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont + numScreensTinyFont) {
            _ = showString("Tiny font. Press " ++ STD_UP_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        } else {
            _ = showString("Tiny font. Press " ++ STD_UP_ARROW ++ ", " ++ STD_DOWN_ARROW ++ " or EXIT", &standardFont, 5, 220, vmNormal, false, false);
        }

        abi.fmtBufZ(tmpString[0..2560], "{d}/{d}", .{ @as(i32, currentFntScr), @as(i32, @as(u16, numScreensNumericFont) + numScreensNumericFontBold + numScreensStandardFont + numScreensTinyFont) });
        _ = showString(tmpString, &standardFont, @as(u32, @intCast(SCREEN_WIDTH - stringWidth(tmpString, &standardFont, false, true))), 220, vmNormal, false, true);
    } else {
        // displayBugScreen(bugScreenShowFonts);
    }
}
