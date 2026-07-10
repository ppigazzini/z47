// SPDX-License-Identifier: GPL-3.0-only
//
// Pure printer glyph-table binary searches, lifted from frontier_print.zig
// (src/c47/printing/print.c findPrinterGlyph / findMartelGlyph). Each printer
// font stores its glyphs sorted by charCode; the search is index arithmetic over
// the caller-supplied glyph array -- no register, dec, GTK, or global state -- so
// it lives here as a std+abi module exercised natively under `zig build
// test:unit`. The owner keeps its font-header pointer math (the glyphs follow the
// header as a flexible array) and delegates the search, passing the glyphs
// pointer + count so the module needs no extern-struct wrapper.
//
// testSuite-BLIND (the IR/82240 printer path is not in the suite, unlike the
// pervasively-covered display findGlyph), so the native tests below are the first
// automated coverage of the boundaries + not-found fallbacks. Transcription is
// verbatim.

const std = @import("std");
const abi = @import("abi");
const GlyphPrinter = abi.GlyphPrinter;
const GlyphMartelPrinter = abi.GlyphMartelPrinter;

/// Binary-search `count` printer glyphs (sorted by charCode) for `charCode`: the
/// matching index, or count - 1 (the last glyph) as the not-found fallback.
pub fn findPrinterGlyph(glyphs: [*]const GlyphPrinter, count: u16, charCode: u16) i16 {
    var first: i16 = 0;
    var last: i16 = @as(i16, @bitCast(count)) - 1;
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
    return @as(i16, @bitCast(count)) - 1;
}

/// Binary-search `count` Martel-24 glyphs; the matching index, or 255 on a miss.
pub fn findMartelGlyph(glyphs: [*]const GlyphMartelPrinter, count: u16, charCode: u16) u16 {
    var first: u16 = 0;
    var last: u16 = count - 1;
    var middle: u16 = (first + last) / 2;
    while (last > first + 1) {
        if (charCode < glyphs[middle].charCode) {
            last = middle;
        } else {
            first = middle;
        }
        middle = (first + last) / 2;
    }
    if (glyphs[first].charCode == charCode) {
        return first;
    }
    if (glyphs[last].charCode == charCode) {
        return last;
    }
    return 255;
}

// ---------------------------------------------------------------------------
// Native tests -- first coverage of the boundaries + the not-found fallbacks.
// ---------------------------------------------------------------------------
const testing = std.testing;

test "findPrinterGlyph binary-searches and falls back to the last index" {
    const g = [_]GlyphPrinter{
        .{ .charCode = 10, .data = undefined },
        .{ .charCode = 20, .data = undefined },
        .{ .charCode = 30, .data = undefined },
        .{ .charCode = 40, .data = undefined },
    };
    try testing.expectEqual(@as(i16, 0), findPrinterGlyph(&g, g.len, 10)); // first
    try testing.expectEqual(@as(i16, 3), findPrinterGlyph(&g, g.len, 40)); // last
    try testing.expectEqual(@as(i16, 1), findPrinterGlyph(&g, g.len, 20)); // middle
    try testing.expectEqual(@as(i16, 3), findPrinterGlyph(&g, g.len, 25)); // miss -> count-1
}

test "findMartelGlyph binary-searches and falls back to 255" {
    const g = [_]GlyphMartelPrinter{
        .{ .charCode = 5, .data = undefined },
        .{ .charCode = 15, .data = undefined },
        .{ .charCode = 25, .data = undefined },
    };
    try testing.expectEqual(@as(u16, 0), findMartelGlyph(&g, g.len, 5)); // first
    try testing.expectEqual(@as(u16, 2), findMartelGlyph(&g, g.len, 25)); // last
    try testing.expectEqual(@as(u16, 1), findMartelGlyph(&g, g.len, 15)); // middle
    try testing.expectEqual(@as(u16, 255), findMartelGlyph(&g, g.len, 99)); // miss -> 255
}
