// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/charString.c: the glyph/string utilities (charCodeFromString,
// convertDigits, replace, charCodeHPReplacement, expandConversionName,
// compressConversionName, stringWidth, stringAfterPixels, stringNextGlyph*,
// stringPrevGlyph, isValidNumber, stringPrevNumberGlyph, stringLastGlyph,
// stringGlyphLength, codePointToUtf8, utf8ToCodePoint, debug_utf8_string,
// stringToUtf8, utf8ToString, stringToRTF, stringToASCII, stringToFileNameChars,
// xcopy, addChrBothSides, addStrBothSides, findTwoChars) plus the three TO_QSPI
// tables (replacementTable, indexOfStringsASCII, indexOfStringsRTF) and the
// file-static helpers (_calculateStringWidth, stringAppend, _getText, _getTextRTF).
// Faithful, line-by-line port.
//
// strReplace is host-only (#if !DMCP_BUILD). stringCopy is __MINGW64__-only and
// never compiled (z47 uses the stpcpy macro). The GENERATE_CATALOGS branches are
// dead (never defined for any z47 build) and omitted; the commented-out
// alternate stringToUtf8 / stringByteLength and the >0x00FFFF UTF-8 cases are dead
// and omitted. _calculateStringWidth's GENERATE_CATALOGS printf is omitted.
//
// The three string tables carry char* pointers, so they live in the
// pointer-safe data section (code_data_section), never __TEXT (dyld rebase).
//
// charString.c is not reachable from the testSuite; verification is build/link
// across every target plus the boundary gates.

const std = @import("std");
const abi = @import("abi");
fn hpRangeShift(char_code: u16, std_1: u16, std_9: u16, std_hp_1: u16, std_sup_1: u16, std_sup_9: u16) ?u16 {
    if (char_code >= std_1 and char_code <= std_9) return char_code - std_1 + std_hp_1;
    if (char_code >= std_sup_1 and char_code <= std_sup_9) return char_code - std_sup_1 + std_hp_1;
    return null;
}
const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const conversion_name_codec = @import("../../convert/conversion_name_codec.zig");
const display_string_transform = @import("../../../core/text/display_string_transform.zig");
const glyph_export = @import("../../../core/text/glyph_export.zig");
const glyph_text_lookup = @import("../../../core/text/glyph_text_lookup.zig");
const string_edit = @import("../../../core/text/string_edit.zig");
const frontier_error = @import("../../error.zig");
const frontier_fonts = @import("../../../core/text/fonts.zig");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;

// Pointer-bearing const tables must avoid __TEXT on macOS (dyld rebase -> SIGBUS).
const code_data_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__DATA_CONST,__const"
else
    ".text";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const glyph_t = abi.Glyph;
const font_t = abi.Font;
// (8 on 64-bit hosts where the data pointer makes glyph_t 8-aligned, 4 on the
// 32-bit firmware). Compute the offset from the alignment to match the C layout.
const FONT_GLYPHS_OFFSET: usize = std.mem.alignForward(usize, 4, @alignOf(glyph_t));
inline fn fontGlyphs(font: *const font_t) [*]const glyph_t {
    const base: [*]const u8 = @ptrCast(font);
    return @ptrCast(@alignCast(base + FONT_GLYPHS_OFFSET));
}

// ---------------------------------------------------------------------------
// Constants (defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const TI_NO_INFO: u8 = 0;
const ID_DP: u8 = 2;
const CM_NORMAL: u8 = 0;
const CM_NIM: u8 = 2;
const DOUBLING_A: u16 = 15; // REPLACEFONT defined
const DOUBLINGBASE_B: u16 = 8;
const HPFONT1: bool = true; // REPLACEFONT defined
const NUMBER_OF_BUG_SCREEN_MESSAGES: usize = 10;
const SIZE_OF_EACH_BUG_SCREEN_MESSAGE: usize = 100;
const bugMsgValueReturnedByFindGlyph: usize = 3;

// ---------------------------------------------------------------------------
// Globals (extern var/const)
// ---------------------------------------------------------------------------
extern var temporaryInformation: u8;
extern var significantDigits: u8;
extern var displayStack: u8;
extern var exponentLimit: i16;
extern var Input_Default: u8;
extern var calcMode: u8;
extern var errorMessage: [*c]u8;
extern const numericFont: font_t;
extern var glyphNotFound: glyph_t;
extern const commonBugScreenMessages: [NUMBER_OF_BUG_SCREEN_MESSAGES][SIZE_OF_EACH_BUG_SCREEN_MESSAGE]u8;

// ---------------------------------------------------------------------------
// Function externs (linkable everywhere)
// ---------------------------------------------------------------------------

// libc.
extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strstr(haystack: [*c]const u8, needle: [*c]const u8) [*c]u8;
extern fn memcpy(dst: ?*anyopaque, src: ?*const anyopaque, n: usize) ?*anyopaque;
extern fn sprintf(buf: [*c]u8, fmt: [*:0]const u8, ...) c_int;

// host-only libc (referenced under !dmcp_build by strReplace and debug_utf8_string).
extern fn printf(fmt: [*:0]const u8, ...) c_int;
extern fn malloc(n: usize) ?*anyopaque;
extern fn free(p: ?*anyopaque) void;
extern fn exit(code: c_int) noreturn;

// checkHP / HPFONT macros.
inline fn checkHP() bool {
    return significantDigits <= 16 and displayStack == 1 and exponentLimit == 99 and Input_Default == ID_DP and (calcMode == CM_NORMAL or calcMode == CM_NIM);
}
inline fn hpFont() bool {
    return if (checkHP()) HPFONT1 else false;
}
inline fn doublingNumeric(font: *const font_t) u16 {
    // DOUBLING (numericFont) vs DOUBLINGBASEX selection in _calculateStringWidth.
    if (font == &numericFont and temporaryInformation == TI_NO_INFO and checkHP()) {
        return if (checkHP()) DOUBLING_A else 6;
    } else {
        return if (checkHP()) DOUBLINGBASE_B else 8;
    }
}

inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}
inline fn minI(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}

// ---------------------------------------------------------------------------
// charCodeFromString
// ---------------------------------------------------------------------------
pub export fn charCodeFromString(ch: [*c]const u8, offset: ?*u16) callconv(.c) u16 {
    return abi.glyph_code.charCodeFromString(ch, offset);
}

// STD_* byte sequences.
const STD_SUB_0 = "\xa0\x80";
const STD_SUB_a = "\xa4\x9c";
const STD_RATIO = "\xa2\x36";
const STD_SUB_PLUS = "\xa0\x8a";
const STD_SUB_MINUS = "\xa0\x8b";
const STD_SINGLE_LOW_QUOTE = "\xa0\x1a";
const STD_OBLIQUE3 = "\xa4\x25";

// ---------------------------------------------------------------------------
// convertDigits
// ---------------------------------------------------------------------------
pub export fn convertDigits(refstr: [*c]u8, outstr: [*c]u8) callconv(.c) void {
    display_string_transform.convertDigits(outstr, refstr, .{
        .sub_0 = STD_SUB_0[0..2].*,
        .sub_a = STD_SUB_a[0..2].*,
        .ratio = STD_RATIO[0..2].*,
        .sub_plus = STD_SUB_PLUS[0..2].*,
        .sub_minus = STD_SUB_MINUS[0..2].*,
        .low_quote = STD_SINGLE_LOW_QUOTE[0..2].*,
        .oblique3 = STD_OBLIQUE3[0..2].*,
    });
}

// ---------------------------------------------------------------------------
// replacementTable (TO_QSPI, pointer-bearing -> code_data_section)
// ---------------------------------------------------------------------------
const replaceTable_t = struct {
    Nr: u16,
    inStr: [*c]const u8,
    outStr: [*c]const u8,
};

// STD_* used in replacementTable.
const STD_SUP_MINUS = "\xa1\x6b";
const STD_HP_MINUS = "\xa4\xfe";
const STD_MINUS = "\x2d";
const STD_SUP_PLUS = "\xa1\x6a";
const STD_HP_PLUS = "\xa4\xff";
const STD_PLUS = "\x2b";
const STD_EulerE = "\xa1\x47";
const STD_e = "\x65";
const STD_op_i = "\xa1\x48";
const STD_i = "\x69";
const STD_op_j = "\xa1\x49";
const STD_j = "\x6a";
const STD_WDOT = "\xa2\xc5";
const STD_HP_PERIOD = "\xa0\x24";
const STD_CROSS = "\x80\xd7";
const STD_SPACE_PUNCTUATION = "\xa0\x08";
const STD_DOT = "\x80\xb7";
const STD_SUB_10 = "\xa4\x7d";
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_0 = "\x30";
const STD_HP_0 = "\xa4\xea";
const STD_SUP_0 = "\xa1\x60";

const replacementTable linksection(code_data_section) = [_]replaceTable_t{
    .{ .Nr = 0, .inStr = STD_SUP_MINUS, .outStr = STD_HP_MINUS },
    .{ .Nr = 0, .inStr = STD_MINUS, .outStr = STD_HP_MINUS },
    .{ .Nr = 0, .inStr = STD_SUP_PLUS, .outStr = STD_HP_PLUS },
    .{ .Nr = 0, .inStr = STD_PLUS, .outStr = STD_HP_PLUS },
    .{ .Nr = 0, .inStr = STD_EulerE, .outStr = STD_e },
    .{ .Nr = 0, .inStr = STD_op_i, .outStr = STD_i },
    .{ .Nr = 0, .inStr = STD_op_j, .outStr = STD_j },
    .{ .Nr = 0, .inStr = STD_WDOT, .outStr = STD_HP_PERIOD },
    .{ .Nr = 0, .inStr = STD_CROSS, .outStr = STD_SPACE_PUNCTUATION },
    .{ .Nr = 0, .inStr = STD_DOT, .outStr = STD_SPACE_PUNCTUATION },
    .{ .Nr = 0, .inStr = STD_SUB_10, .outStr = STD_SPACE_4_PER_EM },
    .{ .Nr = 0, .inStr = STD_0, .outStr = STD_HP_0 },
    .{ .Nr = 0, .inStr = STD_SUP_0, .outStr = STD_HP_0 },
};

// ---------------------------------------------------------------------------
// replace
// ---------------------------------------------------------------------------
pub export fn replace(charCode: *u16) callconv(.c) bool_t {
    const n = replacementTable.len;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        if (charCode.* == charCodeFromString(replacementTable[i].inStr, null)) {
            charCode.* = charCodeFromString(replacementTable[i].outStr, null);
            return true;
        }
    }
    return false;
}

// STD_* for charCodeHPReplacement.
const STD_1 = "\x31";
const STD_9 = "\x39";
const STD_HP_1 = "\xa4\xf5";
const STD_SUP_1 = "\xa1\x61";
const STD_SUP_9 = "\xa1\x69";

// ---------------------------------------------------------------------------
// charCodeHPReplacement (GENERATE_CATALOGS never defined -> always present)
// ---------------------------------------------------------------------------
pub export fn charCodeHPReplacement(charCode: *u16) callconv(.c) void {
    if (replace(charCode)) {
        // handled by replace
    } else if (hpRangeShift(charCode.*, charCodeFromString(STD_1, null), charCodeFromString(STD_9, null), charCodeFromString(STD_HP_1, null), charCodeFromString(STD_SUP_1, null), charCodeFromString(STD_SUP_9, null))) |c| {
        charCode.* = c;
    }
}

// ---------------------------------------------------------------------------
// expandConversionName
// ---------------------------------------------------------------------------
pub export fn expandConversionName(msg1: [*c]u8) callconv(.c) void {
    conversion_name_codec.expandConversionName(msg1);
}

// STD_* for compressConversionName.
const STD_BINARY_ONE = "\xa0\x27";
const STD_BINARY_ZERO = "\xa2\x0e";

// compressBinary (charString.c:166) now lives in conversion_name_codec.zig,
// called from that module's expandAbbreviations.

// ---------------------------------------------------------------------------
// expandAbbreviations — twin of charString.c:183
// ---------------------------------------------------------------------------
pub export fn expandAbbreviations(msg1: [*c]u8) callconv(.c) void {
    conversion_name_codec.expandAbbreviations(msg1, .{
        .one = STD_BINARY_ONE[0..2].*,
        .zero = STD_BINARY_ZERO[0..2].*,
    });
}

// ---------------------------------------------------------------------------
// compressConversionName
// ---------------------------------------------------------------------------
pub export fn compressConversionName(msg1: [*c]u8) callconv(.c) void {
    conversion_name_codec.compressConversionName(msg1, .{
        .one = STD_BINARY_ONE[0..2].*,
        .zero = STD_BINARY_ZERO[0..2].*,
    });
}

// ---------------------------------------------------------------------------
// _calculateStringWidth (static)
// ---------------------------------------------------------------------------
fn calculateStringWidth(str: [*c]const u8, font: *const font_t, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t, width: *i16, resultStr: ?*[*c]const u8) void {
    var charCode: u16 = undefined;
    var ch: i16 = 0;
    var numPixels: i16 = 0;
    var glyphId: i16 = undefined;
    var glyph: ?*const glyph_t = null;
    var firstChar: bool_t = true;
    const doubling: u16 = doublingNumeric(font);

    while (str[@intCast(ch)] != 0) {
        charCode = str[@intCast(ch)];
        ch += 1;
        if (charCode & 0x80 != 0) {
            charCode = (charCode << 8) | @as(u16, str[@intCast(ch)]);
            ch += 1;
        }

        if (checkHP() and font == &numericFont and hpFont()) {
            charCodeHPReplacement(&charCode);
        }

        if (charCode != 1) {
            glyphId = frontier_fonts.findGlyph(font, charCode);
            if (glyphId >= 0) {
                glyph = &fontGlyphs(font)[@intCast(glyphId)];
            } else if (glyphId == -1) {
                frontier_fonts.generateNotFoundGlyph(-1, charCode);
                glyph = &glyphNotFound;
            } else if (glyphId == -2) {
                frontier_fonts.generateNotFoundGlyph(-2, charCode);
                glyph = &glyphNotFound;
            } else {
                glyph = null;
            }

            if (glyph == null) {
                abi.fmtBufZ(errorMessage[0..512], "In function {s}: {d} is an unexpected value returned by findGlyph!", .{ "_calculateStringWidth", @as(c_int, glyphId) });
                frontier_error.displayBugScreen(errorMessage);
                width.* = 0;
                return;
            }

            numPixels += @intCast((@as(u32, doubling) * (@as(u32, glyph.?.colsGlyph) + @as(u32, glyph.?.colsAfterGlyph))) >> 3);
            if (firstChar) {
                firstChar = false;
                if (withLeadingEmptyRows) {
                    numPixels += @intCast((@as(u32, doubling) * @as(u32, glyph.?.colsBeforeGlyph)) >> 3);
                }
            } else {
                numPixels += @intCast((@as(u32, doubling) * @as(u32, glyph.?.colsBeforeGlyph)) >> 3);
            }

            if (resultStr != null) {
                if (numPixels > width.*) {
                    break;
                } else {
                    resultStr.?.* = str + @as(usize, @intCast(ch));
                }
            }
        }
    }

    if (glyph != null and withEndingEmptyRows == false) {
        numPixels -= @intCast((@as(u32, doubling) * @as(u32, glyph.?.colsAfterGlyph)) >> 3);
        if (resultStr != null and numPixels <= width.*) {
            if (resultStr.?.*[0] & 0x80 != 0) {
                resultStr.?.* += 2;
            } else if (resultStr.?.*[0] != 0) {
                resultStr.?.* += 1;
            }
        }
    }
    width.* = numPixels;
}

// ---------------------------------------------------------------------------
// stringWidth
// ---------------------------------------------------------------------------
pub export fn stringWidth(str: [*c]const u8, font: *const font_t, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) callconv(.c) i16 {
    var width: i16 = 0;
    calculateStringWidth(str, font, withLeadingEmptyRows, withEndingEmptyRows, &width, null);
    return width;
}

// ---------------------------------------------------------------------------
// stringAfterPixels
// ---------------------------------------------------------------------------
pub export fn stringAfterPixels(str: [*c]const u8, font: *const font_t, widthIn: i16, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) callconv(.c) [*c]u8 {
    var resultStr: [*c]const u8 = str;
    var width = widthIn;
    calculateStringWidth(str, font, withLeadingEmptyRows, withEndingEmptyRows, &width, &resultStr);
    return @constCast(resultStr);
}

// ---------------------------------------------------------------------------
// stringNextGlyphNoEndCheck_JM
// ---------------------------------------------------------------------------
pub export fn stringNextGlyphNoEndCheck_JM(str: [*c]const u8, posIn: i16) callconv(.c) i16 {
    return abi.c47_string.nextGlyphNoEndCheck(str, posIn);
}

// ---------------------------------------------------------------------------
// stringNextGlyph
// ---------------------------------------------------------------------------
pub export fn stringNextGlyph(str: [*c]const u8, posIn: i16) callconv(.c) i16 {
    return abi.c47_string.nextGlyph(str, posIn);
}

// ---------------------------------------------------------------------------
// stringPrevGlyph
// ---------------------------------------------------------------------------
pub export fn stringPrevGlyph(str: [*c]const u8, posIn: i16) callconv(.c) i16 {
    return abi.c47_string.prevGlyph(str, posIn);
}

// ---------------------------------------------------------------------------
// isValidNumber
// ---------------------------------------------------------------------------
pub export fn isValidNumber(ss: [*c]const u8, template: [*c]const u8) callconv(.c) bool_t {
    return abi.c47_string.isValidNumber(ss, template);
}

// ---------------------------------------------------------------------------
// stringPrevNumberGlyph
// ---------------------------------------------------------------------------
pub export fn stringPrevNumberGlyph(str: [*c]const u8, pos: i16) callconv(.c) i16 {
    return abi.c47_string.prevNumberGlyph(str, pos);
}

// ---------------------------------------------------------------------------
// stringLastGlyph
// ---------------------------------------------------------------------------
pub export fn stringLastGlyph(str: [*c]const u8) callconv(.c) i16 {
    if (str == null) {
        return -1;
    }
    return abi.c47_string.lastGlyph(str);
}

// ---------------------------------------------------------------------------
// stringGlyphLength
// ---------------------------------------------------------------------------
pub export fn stringGlyphLength(strIn: [*c]const u8) callconv(.c) i32 {
    return abi.c47_string.glyphLength(strIn);
}

// ---------------------------------------------------------------------------
// codePointToUtf8
// ---------------------------------------------------------------------------
pub export fn codePointToUtf8(codePoint: u32, utf8: [*c]u8) callconv(.c) void {
    abi.c47_string.codePointToUtf8(codePoint, utf8);
}

// ---------------------------------------------------------------------------
// utf8ToCodePoint
// ---------------------------------------------------------------------------
pub export fn utf8ToCodePoint(utf8: [*c]const u8, codePoint: *u32) callconv(.c) u32 {
    return abi.c47_string.utf8ToCodePoint(utf8, codePoint);
}

// ---------------------------------------------------------------------------
// debug_utf8_string
// ---------------------------------------------------------------------------
pub export fn debug_utf8_string(label: [*c]const u8, str: [*c]const u8, max_len: usize) callconv(.c) void {
    _ = printf("%s:", label);
    _ = printf("  Hex:   ");
    var i: usize = 0;
    while (i < max_len) : (i += 1) {
        _ = printf("%02X ", @as(c_uint, str[i]));
    }
    _ = printf("; ");

    _ = printf("  Dec:   ");
    i = 0;
    while (i < max_len) : (i += 1) {
        _ = printf("%3d ", @as(c_int, str[i]));
    }
    _ = printf("; ");

    _ = printf("  Char:  ");
    i = 0;
    while (i < max_len) : (i += 1) {
        if (str[i] >= 32 and str[i] < 127) {
            _ = printf(" %c  ", @as(c_int, str[i]));
        } else {
            _ = printf("    ");
        }
    }
    _ = printf("\n");
}

// ---------------------------------------------------------------------------
// stringToUtf8
// ---------------------------------------------------------------------------
pub export fn stringToUtf8(strIn: [*c]const u8, utf8In: [*c]u8) callconv(.c) void {
    abi.c47_string.stringToUtf8(strIn, utf8In);
}

// ---------------------------------------------------------------------------
// utf8ToString
// ---------------------------------------------------------------------------
// Host-only diagnostic for a UTF-8 code point that had to be replaced with '?'
// (0x00 low byte, not one of the three relocated glyphs). Injected into the pure
// codec so abi.c47_string stays std-only; no-op on firmware, as upstream gates it.
fn reportForbiddenUtf8(codePoint: u32) void {
    if (comptime !dmcp_build) {
        _ = printf("In function utf8ToString: code point U+%04X has a 0x00 second byte and was replaced with '?'\n", codePoint);
    }
}

pub export fn utf8ToString(utf8In: [*c]const u8, strIn: [*c]u8) callconv(.c) void {
    abi.c47_string.utf8ToString(utf8In, strIn, reportForbiddenUtf8);
}

// utf8ToString into a fixed buffer fed by a file-supplied source: at most maxBytes bytes, the terminating NUL included, so an over-long name cannot overrun it.
pub export fn utf8ToStringWithLength(utf8In: [*c]const u8, strIn: [*c]u8, maxBytes: usize) callconv(.c) void {
    abi.c47_string.utf8ToStringWithLength(utf8In, strIn, maxBytes, reportForbiddenUtf8);
}

// ---------------------------------------------------------------------------
// indexOfStringsASCII / indexOfStringsRTF (TO_QSPI, pointer-bearing).
// ---------------------------------------------------------------------------
const function_t2 = struct {
    item_in: [*c]const u8,
    item_out: [*c]const u8,
};

// STD_* used in the ASCII/RTF tables (continuation).
const STD_NOT = "\x80\xac";
const STD_DEGREE = "\x80\xb0";
const STD_PLUS_MINUS = "\x80\xb1";
const STD_A_GRAVE = "\x80\xc0";
const STD_U_GRAVE = "\x80\xd9";
const STD_a_GRAVE = "\x80\xe0";
const STD_DIVIDE = "\x80\xf7";
const STD_u_GRAVE = "\x80\xf9";
const STD_A_BREVE = "\x81\x02";
const STD_a_BREVE = "\x81\x03";
const STD_E_MACRON = "\x81\x12";
const STD_e_MACRON = "\x81\x13";
const STD_I_MACRON = "\x81\x2a";
const STD_i_MACRON = "\x81\x2b";
const STD_I_BREVE = "\x81\x2c";
const STD_i_BREVE = "\x81\x2d";
const STD_U_BREVE = "\x81\x6c";
const STD_u_BREVE = "\x81\x6d";
const STD_Y_CIRC = "\x81\x76";
const STD_y_CIRC = "\x81\x77";
const STD_y_BAR = "\x82\x33";
const STD_x_BAR = "\x83\x78";
const STD_x_CIRC = "\x83\x79";
const STD_ALPHA = "\x83\x91";
const STD_BETA = "\x83\x92";
const STD_GAMMA = "\x83\x93";
const STD_DELTA = "\x83\x94";
const STD_EPSILON = "\x83\x95";
const STD_ZETA = "\x83\x96";
const STD_PI = "\x83\xa0";
const STD_SIGMA = "\x83\xa3";
const STD_PHI = "\x83\xa6";
const STD_CHI = "\x83\xa7";
const STD_PSI = "\x83\xa8";
const STD_alpha = "\x83\xb1";
const STD_beta = "\x83\xb2";
const STD_gamma = "\x83\xb3";
const STD_delta = "\x83\xb4";
const STD_epsilon = "\x83\xb5";
const STD_zeta = "\x83\xb6";
const STD_lambda = "\x83\xbb";
const STD_mu = "\x83\xbc";
const STD_pi = "\x83\xc0";
const STD_SUB_pi = "\xac\x64";
const STD_SUP_pi = "\xac\x65";
const STD_sigma = "\x83\xc3";
const STD_phi = "\x83\xc6";
const STD_phi_m = "\x83\xd5";
const STD_theta = "\x83\xd1";
const STD_theta_m = "\x83\xb8";
const STD_chi = "\x83\xc7";
const STD_psi = "\x83\xc8";
const STD_omega = "\x83\xc9";
const STD_ELLIPSIS = "\xa0\x26";
const STD_SUB_E_OUTLINE = "\xa0\x73";
const STD_SUP_ASTERISK = "\xa0\x8f";
const STD_SUP_INFINITY = "\xa0\x9e";
const STD_SUB_INFINITY = "\xa0\x9f";
const STD_PLANCK = "\xa1\x0e";
const STD_PLANCK_2PI = "\xa1\x0f";
const STD_INFINITY = "\xa2\x1e";
const STD_INTEGRAL = "\xa2\x2b";
const STD_ALMOST_EQUAL = "\xa2\x48";
const STD_NOT_EQUAL = "\xa2\x60";
const STD_LESS_EQUAL = "\xa2\x64";
const STD_GREATER_EQUAL = "\xa2\x65";
const STD_MEASURED_ANGLE = "\xa2\x21";
const STD_SUB_EARTH = "\xa2\x95";
const STD_SUB_alpha = "\xa2\x96";
const STD_SUB_delta = "\xa2\x97";
const STD_SUB_mu = "\xa2\x98";
const STD_SUB_SUN = "\xa2\x9a";
const STD_PRINTER = "\xa3\x99";
const STD_UK = "\xa4\x2d";
const STD_US = "\xa4\x2e";
const STD_GAUSS_BLACK_L = "\xa4\x30";
const STD_GAUSS_WHITE_R = "\xa4\x31";
const STD_GAUSS_WHITE_L = "\xa4\x32";
const STD_GAUSS_BLACK_R = "\xa4\x33";
const STD_RIGHT_OVER_LEFT_ARROW = "\xa1\xc4";
const STD_SQUARE_ROOT = "\xa2\x1a";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_RIGHT_DOUBLE_QUOTE = "\xa0\x1d";
const STD_CR = "\xa1\xb5";
const STD_RIGHT_TACK = "\xa2\xa2";
const STD_WPERIOD = "\xa7\x89";
const STD_WCOMMA = "\xa7\x88";
const STD_NQUOTE = "\x82\xbc";
const STD_INV_BRIDGE = "\xa3\xb5";
const STD_SPACE_EM = "\xa0\x03";
const STD_SPACE_3_PER_EM = "\xa0\x04";
const STD_SPACE_6_PER_EM = "\xa0\x06";
const STD_SPACE_FIGURE = "\xa0\x07";
const STD_SPACE_HAIR = "\xa0\x0a";
const STD_TIME_T = "\xa1\x38";
const STD_DATE_D = "\xa1\x45";
const STD_COMPLEX_C = "\xa1\x02";
const STD_INTEGER_Z = "\xa1\x24";
const STD_INTEGER_Z_SMALL = "\xa1\x25";
const STD_NATURAL_N = "\xa1\x15";
const STD_RATIONAL_Q = "\xa1\x1a";
const STD_IRRATIONAL_I = "\xa1\x10";
const STD_REAL_R = "\xa1\x1d";
const STD_u_BAR = "\x83\x80";
const STD_v_BAR = "\x83\x81";
const STD_w_BAR = "\x83\x82";
const STD_RIGHT_DOUBLE_ARROW = "\xa1\xd2";
const STD_RIGHT_DASHARROW = "\xa1\xe2";
const STD_RIGHT_ARROW = "\xa1\x92";
const STD_RIGHT_SHORT_ARROW = "\xa1\xc0";
const STD_LEFT_DASHARROW = "\xa1\xe0";
const STD_LEFT_ARROW = "\xa1\x90";
const STD_UP_DASHARROW = "\xa1\xe1";
const STD_UP_ARROW = "\xa1\x91";
const STD_HOLLOW_UP_ARROW = "\xa1\xe7";
const STD_DOWN_DASHARROW = "\xa1\xe3";
const STD_DOWN_ARROW = "\xa1\x93";
const STD_HOLLOW_DOWN_ARROW = "\xa1\xe9";
const STD_LEFT_RIGHT_ARROWS = "\xa1\x94";
const STD_SUP_pir = "\xac\x66";
const STD_M_ALPHA = "\x84\x50";
const STD_N_ASTERISK = "\x84\x51";
const STD_D_MINUS1 = "\x84\x52";
const STD_1_ASTERISK = "\x84\x54";
const STD_K_ASTERISK = "\x84\x53";
const STD_EQUALS_SH = "\x84\x55";
const STD_TRI_LHB_2 = "\x84\x57";
const STD_TRI_RHB_2 = "\x84\x58";
const STD_P_2 = "\x84\x56";
const STD_TRI_LHB = "\xa5\xed";
const STD_TRI_RHB = "\xa5\xee";
const ELLIPSIS_UTF8 = "\xe2\x80\xa6";

const indexOfStringsASCII linksection(code_data_section) = [_]function_t2{
    .{ .item_in = STD_NOT, .item_out = "<>" },
    .{ .item_in = STD_DEGREE, .item_out = "deg" },
    .{ .item_in = STD_PLUS_MINUS, .item_out = "+-" },
    .{ .item_in = STD_A_GRAVE, .item_out = "`A" },
    .{ .item_in = STD_CROSS, .item_out = "*" },
    .{ .item_in = STD_U_GRAVE, .item_out = "`U" },
    .{ .item_in = STD_a_GRAVE, .item_out = "`a" },
    .{ .item_in = STD_DIVIDE, .item_out = "/" },
    .{ .item_in = STD_u_GRAVE, .item_out = "`u" },
    .{ .item_in = STD_A_BREVE, .item_out = "`A" },
    .{ .item_in = STD_a_BREVE, .item_out = "`a" },
    .{ .item_in = STD_E_MACRON, .item_out = "`E" },
    .{ .item_in = STD_e_MACRON, .item_out = "`e" },
    .{ .item_in = STD_I_MACRON, .item_out = "`I" },
    .{ .item_in = STD_i_MACRON, .item_out = "`i" },
    .{ .item_in = STD_I_BREVE, .item_out = "`I" },
    .{ .item_in = STD_i_BREVE, .item_out = "`i" },
    .{ .item_in = STD_U_BREVE, .item_out = "`U" },
    .{ .item_in = STD_u_BREVE, .item_out = "`u" },
    .{ .item_in = STD_Y_CIRC, .item_out = "`Y" },
    .{ .item_in = STD_y_CIRC, .item_out = "`y" },
    .{ .item_in = STD_y_BAR, .item_out = "y_mean" },
    .{ .item_in = STD_x_BAR, .item_out = "x_mean" },
    .{ .item_in = STD_x_CIRC, .item_out = "x_circ" },
    .{ .item_in = STD_ALPHA, .item_out = "Alpha" },
    .{ .item_in = STD_BETA, .item_out = "Beta" },
    .{ .item_in = STD_GAMMA, .item_out = "Gamma" },
    .{ .item_in = STD_DELTA, .item_out = "Delta" },
    .{ .item_in = STD_EPSILON, .item_out = "Epsilon" },
    .{ .item_in = STD_ZETA, .item_out = "Zeta" },
    .{ .item_in = STD_PI, .item_out = "Pi" },
    .{ .item_in = STD_SIGMA, .item_out = "Sigma" },
    .{ .item_in = STD_PHI, .item_out = "Phi" },
    .{ .item_in = STD_CHI, .item_out = "Chi" },
    .{ .item_in = STD_PSI, .item_out = "Psi" },
    .{ .item_in = STD_alpha, .item_out = "alpha" },
    .{ .item_in = STD_beta, .item_out = "beta" },
    .{ .item_in = STD_gamma, .item_out = "gamma" },
    .{ .item_in = STD_delta, .item_out = "delta" },
    .{ .item_in = STD_epsilon, .item_out = "epsilon" },
    .{ .item_in = STD_zeta, .item_out = "zeta" },
    .{ .item_in = STD_lambda, .item_out = "lambda" },
    .{ .item_in = STD_mu, .item_out = "mu" },
    .{ .item_in = STD_pi, .item_out = "pi" },
    .{ .item_in = STD_SUB_pi, .item_out = "pi" },
    .{ .item_in = STD_SUP_pi, .item_out = "pi" },
    .{ .item_in = STD_sigma, .item_out = "sigma" },
    .{ .item_in = STD_phi, .item_out = "phi" },
    .{ .item_in = STD_phi_m, .item_out = "phi" },
    .{ .item_in = STD_theta, .item_out = "theta" },
    .{ .item_in = STD_theta_m, .item_out = "theta" },
    .{ .item_in = STD_chi, .item_out = "chi" },
    .{ .item_in = STD_psi, .item_out = "psi" },
    .{ .item_in = STD_omega, .item_out = "omega" },
    .{ .item_in = STD_ELLIPSIS, .item_out = ELLIPSIS_UTF8 },
    .{ .item_in = STD_BINARY_ONE, .item_out = "1" },
    .{ .item_in = STD_SUB_E_OUTLINE, .item_out = "`E" },
    .{ .item_in = STD_SUB_PLUS, .item_out = "`+" },
    .{ .item_in = STD_SUB_MINUS, .item_out = "`-" },
    .{ .item_in = STD_SUP_ASTERISK, .item_out = "`*" },
    .{ .item_in = STD_SUP_INFINITY, .item_out = "inf" },
    .{ .item_in = STD_SUB_INFINITY, .item_out = "inf" },
    .{ .item_in = STD_PLANCK, .item_out = "Planck" },
    .{ .item_in = STD_PLANCK_2PI, .item_out = "Planck2pi" },
    .{ .item_in = STD_SUP_PLUS, .item_out = "+" },
    .{ .item_in = STD_SUP_MINUS, .item_out = "-" },
    .{ .item_in = STD_BINARY_ZERO, .item_out = "0" },
    .{ .item_in = STD_INFINITY, .item_out = "inf" },
    .{ .item_in = STD_MEASURED_ANGLE, .item_out = "angle" },
    .{ .item_in = STD_INTEGRAL, .item_out = "integral" },
    .{ .item_in = STD_ALMOST_EQUAL, .item_out = "approx" },
    .{ .item_in = STD_NOT_EQUAL, .item_out = "<>" },
    .{ .item_in = STD_LESS_EQUAL, .item_out = "<=" },
    .{ .item_in = STD_GREATER_EQUAL, .item_out = ">=" },
    .{ .item_in = STD_SUB_EARTH, .item_out = "`earth" },
    .{ .item_in = STD_SUB_alpha, .item_out = "`alpha" },
    .{ .item_in = STD_SUB_delta, .item_out = "`delta" },
    .{ .item_in = STD_SUB_mu, .item_out = "`mu" },
    .{ .item_in = STD_SUB_SUN, .item_out = "`sun" },
    .{ .item_in = STD_PRINTER, .item_out = "Print" },
    .{ .item_in = STD_UK, .item_out = "UK" },
    .{ .item_in = STD_US, .item_out = "US" },
    .{ .item_in = STD_GAUSS_BLACK_L, .item_out = "GAUSS_BL_L " },
    .{ .item_in = STD_GAUSS_WHITE_R, .item_out = "GAUSS_WH_R " },
    .{ .item_in = STD_GAUSS_WHITE_L, .item_out = "GAUSS_WH_L " },
    .{ .item_in = STD_GAUSS_BLACK_R, .item_out = "GAUSS_BL_R " },
    .{ .item_in = STD_SUB_10, .item_out = "10^" },
    .{ .item_in = STD_EulerE, .item_out = "e" },
    .{ .item_in = STD_RIGHT_OVER_LEFT_ARROW, .item_out = "<>" },
    .{ .item_in = STD_SQUARE_ROOT, .item_out = "root" },
    .{ .item_in = STD_RIGHT_SINGLE_QUOTE, .item_out = "'" },
    .{ .item_in = STD_RIGHT_DOUBLE_QUOTE, .item_out = "\"" },
    .{ .item_in = STD_op_i, .item_out = "i" },
    .{ .item_in = STD_op_j, .item_out = "j" },
    .{ .item_in = STD_BINARY_ONE, .item_out = "1" },
    .{ .item_in = STD_BINARY_ZERO, .item_out = "0" },
    .{ .item_in = STD_CR, .item_out = "|" },
    .{ .item_in = STD_RIGHT_TACK, .item_out = "'" },
    .{ .item_in = STD_WDOT, .item_out = "." },
    .{ .item_in = STD_DOT, .item_out = "." },
    .{ .item_in = STD_WPERIOD, .item_out = "." },
    .{ .item_in = STD_WCOMMA, .item_out = "," },
    .{ .item_in = STD_NQUOTE, .item_out = "'" },
    .{ .item_in = STD_INV_BRIDGE, .item_out = "," },
    .{ .item_in = STD_SPACE_EM, .item_out = " " },
    .{ .item_in = STD_SPACE_3_PER_EM, .item_out = " " },
    .{ .item_in = STD_SPACE_4_PER_EM, .item_out = " " },
    .{ .item_in = STD_SPACE_6_PER_EM, .item_out = " " },
    .{ .item_in = STD_SPACE_FIGURE, .item_out = " " },
    .{ .item_in = STD_SPACE_PUNCTUATION, .item_out = " " },
    .{ .item_in = STD_SPACE_HAIR, .item_out = " " },
    .{ .item_in = STD_TIME_T, .item_out = "T" },
    .{ .item_in = STD_DATE_D, .item_out = "D" },
    .{ .item_in = STD_COMPLEX_C, .item_out = "C" },
    .{ .item_in = STD_INTEGER_Z, .item_out = "Z" },
    .{ .item_in = STD_INTEGER_Z_SMALL, .item_out = "Z" },
    .{ .item_in = STD_NATURAL_N, .item_out = "N" },
    .{ .item_in = STD_RATIONAL_Q, .item_out = "Q" },
    .{ .item_in = STD_IRRATIONAL_I, .item_out = "I" },
    .{ .item_in = STD_REAL_R, .item_out = "R" },
    .{ .item_in = STD_u_BAR, .item_out = "u_vec" },
    .{ .item_in = STD_v_BAR, .item_out = "v_vec" },
    .{ .item_in = STD_w_BAR, .item_out = "w_vec" },
    .{ .item_in = STD_RIGHT_DOUBLE_ARROW, .item_out = ">>" },
    .{ .item_in = STD_RIGHT_DASHARROW, .item_out = "->" },
    .{ .item_in = STD_RIGHT_ARROW, .item_out = "->" },
    .{ .item_in = STD_RIGHT_SHORT_ARROW, .item_out = "->" },
    .{ .item_in = STD_LEFT_DASHARROW, .item_out = "<-" },
    .{ .item_in = STD_LEFT_ARROW, .item_out = "<-" },
    .{ .item_in = STD_UP_DASHARROW, .item_out = "^" },
    .{ .item_in = STD_UP_ARROW, .item_out = "^" },
    .{ .item_in = STD_HOLLOW_UP_ARROW, .item_out = "^" },
    .{ .item_in = STD_DOWN_DASHARROW, .item_out = "v" },
    .{ .item_in = STD_DOWN_ARROW, .item_out = "v" },
    .{ .item_in = STD_HOLLOW_DOWN_ARROW, .item_out = "v" },
    .{ .item_in = STD_LEFT_RIGHT_ARROWS, .item_out = "><" },
    .{ .item_in = STD_SUP_pir, .item_out = "pi" },
    .{ .item_in = STD_M_ALPHA, .item_out = "ma" },
    .{ .item_in = STD_N_ASTERISK, .item_out = "*n" },
    .{ .item_in = STD_D_MINUS1, .item_out = "d^-1" },
    .{ .item_in = STD_1_ASTERISK, .item_out = "1*" },
    .{ .item_in = STD_K_ASTERISK, .item_out = "k*" },
    .{ .item_in = STD_EQUALS_SH, .item_out = "=" },
    .{ .item_in = STD_TRI_LHB_2, .item_out = "^2_LHB" },
    .{ .item_in = STD_TRI_RHB_2, .item_out = "^2_RHB" },
    .{ .item_in = STD_P_2, .item_out = "^2p" },
    .{ .item_in = STD_TRI_LHB, .item_out = "GAUSS_LHB" },
    .{ .item_in = STD_TRI_RHB, .item_out = "GAUSS_RHB" },
};

const indexOfStringsRTF linksection(code_data_section) = [_]function_t2{
    .{ .item_in = STD_BINARY_ONE, .item_out = "1" },
    .{ .item_in = STD_BINARY_ZERO, .item_out = "0" },
};

// ---------------------------------------------------------------------------
// stringAppend (static)
// ---------------------------------------------------------------------------
fn stringAppend(dest: [*c]u8, source: [*c]const u8) [*c]u8 {
    var l: usize = 0;
    while (source[l] != 0) : (l += 1) {}
    var i: usize = 0;
    while (i <= l) : (i += 1) dest[i] = source[i];
    return dest + l;
}

// ---------------------------------------------------------------------------
// _getText / _getTextRTF (static)
// ---------------------------------------------------------------------------
fn getText(a1: u8, a2: u8, str: [*c]u8) bool_t {
    return glyph_text_lookup.lookupGlyphText(a1, a2, str, &indexOfStringsASCII);
}

fn getTextRTF(a1: u8, a2: u8, str: [*c]u8) bool_t {
    return glyph_text_lookup.lookupGlyphText(a1, a2, str, &indexOfStringsRTF);
}

// STD_* used by stringToRTF range checks.
const STD_SUP_a = "\xa4\x82";
const STD_SUP_z = "\xa4\x9b";
const STD_SUP_A = "\xa4\xb6";
const STD_SUP_Z = "\xa4\xcf";
const STD_SUB_9 = "\xa0\x89";
const STD_SUB_z = "\xa4\xb5";
const STD_SUB_A = "\xa4\xd0";
const STD_SUB_Z = "\xa4\xe9";

// ---------------------------------------------------------------------------
// stringToRTF
// ---------------------------------------------------------------------------
pub export fn stringToRTF(strIn: [*c]const u8, asciiIn: [*c]u8) callconv(.c) void {
    var str = strIn;
    var ascii = asciiIn;
    var a1: u8 = undefined;
    var a2: u8 = undefined;
    var aa: [32]u8 = undefined;

    const len: i16 = @intCast(stringGlyphLength(str));

    if (len == 0) {
        ascii[0] = 0;
        return;
    }

    const ss = glyph_export.SupSubRanges{
        .sup_digit = .{ .lead = STD_SUP_0[0], .lo = STD_SUP_0[1], .hi = STD_SUP_9[1] },
        .sup_lower = .{ .lead = STD_SUP_a[0], .lo = STD_SUP_a[1], .hi = STD_SUP_z[1] },
        .sup_upper = .{ .lead = STD_SUP_A[0], .lo = STD_SUP_A[1], .hi = STD_SUP_Z[1] },
        .sub_digit = .{ .lead = STD_SUB_0[0], .lo = STD_SUB_0[1], .hi = STD_SUB_9[1] },
        .sub_lower = .{ .lead = STD_SUB_a[0], .lo = STD_SUB_a[1], .hi = STD_SUB_z[1] },
        .sub_upper = .{ .lead = STD_SUB_A[0], .lo = STD_SUB_A[1], .hi = STD_SUB_Z[1] },
    };

    var ii: i16 = 0;
    while (ii < len) : (ii += 1) {
        if (str[0] & 0x80 != 0) {
            a1 = str[0];
            str += 1;
            a2 = str[0];
            str += 1;

            if (getTextRTF(a1, a2, &aa)) {
                var j: i16 = 0;
                while (aa[@intCast(j)] != 0) {
                    ascii[0] = aa[@intCast(j)];
                    j += 1;
                    ascii += 1;
                }
                ascii -= 1;
            } else if (glyph_export.rtfFromGlyph(a1, a2, ascii, ss)) |n| {
                ascii += n - 1;
            } else {
                abi.fmtBufZ(&aa, "\\u{d}?", .{@as(i32, (@as(i32, a1 & 0x7F) << 8) | @as(i32, a2))});
                var j: i16 = 0;
                while (aa[@intCast(j)] != 0) {
                    ascii[0] = aa[@intCast(j)];
                    j += 1;
                    ascii += 1;
                }
                ascii -= 1;
            }
        } else {
            ascii[0] = str[0];
            str += 1;
        }
        ascii += 1;
        ascii[0] = 0;
    }
}

// STD_* for stringToASCII range checks.
const STD_BASE_1 = "\xa4\x60";
const STD_BASE_9 = "\xa4\x68";
const STD_BASE_10 = "\xa4\x69";
const STD_BASE_16 = "\xa4\x6f";
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_SINGLE_HIGH_QUOTE = "\xa0\x1b";
const STD_LEFT_DOUBLE_QUOTE = "\xa0\x1c";
const STD_DOUBLE_HIGH_QUOTE = "\xa0\x1f";

// ---------------------------------------------------------------------------
// stringToASCII
// ---------------------------------------------------------------------------
pub export fn stringToASCII(strIn: [*c]const u8, asciiIn: [*c]u8) callconv(.c) void {
    var str = strIn;
    var ascii = asciiIn;
    var a1: u8 = undefined;
    var a2: u8 = undefined;
    var aa: [32]u8 = undefined;

    const len: i16 = @intCast(stringGlyphLength(str));

    if (len == 0) {
        ascii[0] = 0;
        return;
    }

    const ranges = glyph_export.AsciiRanges{
        .sup_digit = .{ .lead = STD_SUP_0[0], .lo = STD_SUP_0[1], .hi = STD_SUP_9[1] },
        .sup_lower = .{ .lead = STD_SUP_a[0], .lo = STD_SUP_a[1], .hi = STD_SUP_z[1] },
        .sup_upper = .{ .lead = STD_SUP_A[0], .lo = STD_SUP_A[1], .hi = STD_SUP_Z[1] },
        .sub_digit = .{ .lead = STD_SUB_0[0], .lo = STD_SUB_0[1], .hi = STD_SUB_9[1] },
        .sub_lower = .{ .lead = STD_SUB_a[0], .lo = STD_SUB_a[1], .hi = STD_SUB_z[1] },
        .sub_upper = .{ .lead = STD_SUB_A[0], .lo = STD_SUB_A[1], .hi = STD_SUB_Z[1] },
        .base_low = .{ .lead = STD_BASE_1[0], .lo = STD_BASE_1[1], .hi = STD_BASE_9[1] },
        .base_high = .{ .lead = STD_BASE_10[0], .lo = STD_BASE_10[1], .hi = STD_BASE_16[1] },
        .single_quote = .{ .lead = STD_LEFT_SINGLE_QUOTE[0], .lo = STD_LEFT_SINGLE_QUOTE[1], .hi = STD_SINGLE_HIGH_QUOTE[1] },
        .double_quote = .{ .lead = STD_LEFT_DOUBLE_QUOTE[0], .lo = STD_LEFT_DOUBLE_QUOTE[1], .hi = STD_DOUBLE_HIGH_QUOTE[1] },
    };

    var ii: i16 = 0;
    while (ii < len) : (ii += 1) {
        if (str[0] & 0x80 != 0) {
            a1 = str[0];
            str += 1;
            a2 = str[0];
            str += 1;

            if (getText(a1, a2, &aa)) {
                var j: i16 = 0;
                while (aa[@intCast(j)] != 0) {
                    ascii[0] = aa[@intCast(j)];
                    j += 1;
                    ascii += 1;
                }
                ascii -= 1;
            } else if (glyph_export.asciiFromGlyph(a1, a2, ascii, ranges)) |n| {
                // asciiFromGlyph wrote n bytes; the trailing `ascii += 1` below
                // advances the last one, so consume the other n-1 here.
                ascii += n - 1;
            } else if (a1 >= 0x81 and a1 <= 0x83) {
                ascii[0] = '_';
            } else {
                if (comptime !dmcp_build) {
                    _ = printf("Not decoded, replace with _: --a1=%u--a2=%u\n", @as(c_uint, a1), @as(c_uint, a2));
                }
                ascii[0] = 0x5F;
            }
        } else {
            ascii[0] = str[0];
            str += 1;
        }
        ascii += 1;
        ascii[0] = 0;
    }
}

// ---------------------------------------------------------------------------
// stringToFileNameChars
// ---------------------------------------------------------------------------
pub export fn stringToFileNameChars(strIn: [*c]const u8, asciiIn: [*c]u8, distinctQuotes: u8) callconv(.c) void {
    glyph_export.fileNameChars(strIn, asciiIn, @intCast(stringGlyphLength(strIn)), distinctQuotes != 0);
}

// ---------------------------------------------------------------------------
// xcopy
// ---------------------------------------------------------------------------
// Moved to the base kernel (engine/kernel/byte_copy.zig); it is a pure
// overlap-safe byte copy with no text coupling. Re-declared here so the owners
// that reach it through this module resolve unchanged; the definition now links
// from the kernel.
pub extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, nIn: u32) callconv(.c) ?*anyopaque;

// On Windows (MINGW) the ucrt has no stpcpy, so charString.h declares stringCopy
// as a real function (`#if defined(__MINGW64__)`) instead of a `#define
// stringCopy stpcpy`; C units call it by name and must link it. Upstream defines
// it in charString.c under that guard. Export it on Windows only (elsewhere
// stringCopy is the macro, so this symbol must not exist / would be unused).
fn stringCopyWindows(dest: [*c]u8, source: [*c]const u8) callconv(.c) [*c]u8 {
    const l: u32 = @intCast(stringByteLength(source));
    const p: [*c]u8 = @ptrCast(xcopy(dest, source, l + 1));
    return p + @as(usize, l);
}
comptime {
    if (builtin.target.os.tag == .windows) {
        @export(&stringCopyWindows, .{ .name = "stringCopy", .linkage = .strong });
    }
}

// ---------------------------------------------------------------------------
// addChrBothSides
// ---------------------------------------------------------------------------
pub export fn addChrBothSides(t: u8, str: [*c]u8) callconv(.c) void {
    string_edit.addChrBothSides(t, str);
}

// ---------------------------------------------------------------------------
// addStrBothSides
// ---------------------------------------------------------------------------
pub export fn addStrBothSides(str: [*c]u8, str_b: [*c]u8, str_e: [*c]u8) callconv(.c) void {
    string_edit.addStrBothSides(str, str_b, str_e);
}

// ---------------------------------------------------------------------------
// strReplace (host-only; #if !DMCP_BUILD)
// ---------------------------------------------------------------------------
fn strReplaceImpl(haystack: [*c]u8, needle: [*c]const u8, newNeedle: [*c]const u8) callconv(.c) void {
    while (strstr(haystack, needle) != null) {
        const needleLg: c_int = @intCast(strlen(needle));
        const needleLocation = strstr(haystack, needle);
        const str: [*c]u8 = @ptrCast(malloc(strlen(needleLocation + @as(usize, @intCast(needleLg))) + 1));
        if (str == null) {
            _ = printf("In function strReplace: error allocating memory for str!\n");
            exit(1);
        }
        _ = strcpy(str, needleLocation + @as(usize, @intCast(needleLg)));
        strstr(haystack, needle)[0] = 0;
        _ = strcat(haystack, newNeedle);
        _ = strcat(haystack, str);
        free(str);
    }
}

comptime {
    if (!dmcp_build) {
        @export(&strReplaceImpl, .{ .name = "strReplace", .linkage = .strong });
    }
}

// ---------------------------------------------------------------------------
// findTwoChars
// ---------------------------------------------------------------------------
pub export fn findTwoChars(tmpString: [*c]const u8, char1: u8, char2: u8, position: *u16) callconv(.c) bool_t {
    return string_edit.findTwoChars(tmpString, char1, char2, position);
}
