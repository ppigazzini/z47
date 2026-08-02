// SPDX-License-Identifier: GPL-3.0-only
//
// Pure glyph-table binary search, lifted from the fonts owner fonts.zig
// (src/c47/display.c findGlyph). A font stores its glyphs sorted by charCode; the
// search is a plain index computation over the caller-supplied abi.Font -- no
// register, dec, GTK, or global state -- so it lives here as a std+abi module
// exercised natively under `zig build test:unit`. The owner keeps its C-ABI
// export wrappers (and leaves the QSPI-placed not-found-glyph generation behind)
// and delegates.
//
// findGlyph is testSuite-covered pervasively (every character-display test walks
// it); the native tests below pin the binary-search boundaries and the id-based
// not-found codes directly. Transcription is verbatim.

const std = @import("std");
const abi = @import("abi");
const Font = abi.Font;

/// Binary-search `font`'s glyphs (sorted by charCode) for `charCode`: the matching
/// index, or -1 on a miss (no id fallback, so a miss is never read as index 0).
pub fn findGlyphExact(font: *const Font, charCode: u16) i16 {
    const glyphs = font.glyphsPtr();

    var first: i16 = 0;
    var last: i16 = @as(i16, @intCast(font.numberOfGlyphs)) - 1;

    var middle: i16 = @divTrunc(first + last, 2);
    while (last > first + 1) {
        if (charCode < glyphs[@intCast(middle)].charCode) {
            last = middle;
        } else {
            first = middle;
        }
        middle = @divTrunc(first + last, 2);
    }

    if (glyphs[@intCast(first)].charCode == charCode) {
        return first;
    }
    if (glyphs[@intCast(last)].charCode == charCode) {
        return last;
    }
    return -1;
}

/// Index on a hit, else the id-based not-found codes the display layer expects
/// (-1 for font id 1, -2 for id 0, 0 otherwise).
pub fn findGlyph(font: *const Font, charCode: u16) i16 {
    const id = findGlyphExact(font, charCode);
    if (id >= 0) {
        return id;
    }
    if (font.id == 1) {
        return -1;
    }
    if (font.id == 0) {
        return -2;
    }
    return 0;
}

// ---------------------------------------------------------------------------
// Native tests -- first DIRECT coverage of the search boundaries + id fallback.
// A test font is a real abi.Font header followed by N glyphs, built through the
// abi layout (glyphsPtr) so it needs no assumptions about field offsets.
// ---------------------------------------------------------------------------
const testing = std.testing;
const Glyph = abi.Glyph;
const FONT_BUF = @sizeOf(Font) + 8 * @sizeOf(Glyph);

// The one pointer reinterpret in the module: an already-Font-aligned byte buffer
// viewed as an abi.Font.
fn makeFont(buf: *align(@alignOf(Font)) [FONT_BUF]u8, id: i8, codes: []const u16) *Font {
    @memset(buf, 0);
    const font: *Font = @ptrCast(buf);
    font.id = id;
    font.numberOfGlyphs = @intCast(codes.len);
    const glyphs = @constCast(font.glyphsPtr());
    for (codes, 0..) |cc, i| glyphs[i].charCode = cc;
    return font;
}

test "findGlyphExact binary-searches the charCode-sorted glyphs" {
    var buf: [FONT_BUF]u8 align(@alignOf(Font)) = undefined;
    const font = makeFont(&buf, 2, &.{ 10, 20, 30, 40, 55, 60 });
    try testing.expectEqual(@as(i16, 0), findGlyphExact(font, 10)); // first
    try testing.expectEqual(@as(i16, 5), findGlyphExact(font, 60)); // last
    try testing.expectEqual(@as(i16, 2), findGlyphExact(font, 30)); // middle
    try testing.expectEqual(@as(i16, 4), findGlyphExact(font, 55));
    try testing.expectEqual(@as(i16, -1), findGlyphExact(font, 25)); // gap miss
    try testing.expectEqual(@as(i16, -1), findGlyphExact(font, 99)); // above-range miss
}

test "findGlyph returns the id-based not-found code on a miss" {
    var buf: [FONT_BUF]u8 align(@alignOf(Font)) = undefined;
    // Hit still returns the index regardless of id.
    try testing.expectEqual(@as(i16, 1), findGlyph(makeFont(&buf, 1, &.{ 10, 20, 30 }), 20));
    // Misses fall back by font id.
    try testing.expectEqual(@as(i16, -1), findGlyph(makeFont(&buf, 1, &.{ 10, 20, 30 }), 25));
    try testing.expectEqual(@as(i16, -2), findGlyph(makeFont(&buf, 0, &.{ 10, 20, 30 }), 25));
    try testing.expectEqual(@as(i16, 0), findGlyph(makeFont(&buf, 2, &.{ 10, 20, 30 }), 25));
}
