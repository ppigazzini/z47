// SPDX-License-Identifier: GPL-3.0-only
//
// Pure IR-printer text-width arithmetic, lifted from frontier_print.zig
// (src/c47/printing/print.c). Each character's printed width is packed 3-per-byte
// into charWidths[] and unpacked by dividing by charDivs[] and taking mod 6; from
// that, pixelLength sums a string's width and findLengths builds the cumulative
// x-position table. It is std-only integer arithmetic over two private packed
// tables -- no register, dec, GTK, or global state -- so it lives here exercised
// natively under `zig build test:unit`. The owner keeps the printer I/O and
// delegates.
//
// testSuite-BLIND (the 82240 / IR printer path is not in the suite), so the native
// tests below are the first automated coverage of the width unpacking + sums.
// Transcription is verbatim; the C byte pointer becomes a sentinel pointer and the
// c_int small-font flag becomes a bool.

const std = @import("std");

// Printed character widths, packed three per byte (a 174-value 82240 width table;
// not a glyph-code table, so it moves wholesale with the arithmetic).
const charWidths = [171]u8{
    162, 143, 210, 208, 215, 179, 100, 209, 130, 167, 178, 199,
    215, 85,  107, 123, 160, 172, 172, 88,  178, 177, 208, 208,
    166, 208, 179, 173, 209, 215, 130, 165, 170, 172, 172, 165,
    177, 172, 172, 214, 171, 117, 131, 209, 143, 215, 131, 178,
    215, 213, 143, 201, 213, 179, 172, 214, 170, 172, 215, 209,
    215, 95,  129, 129, 172, 172, 172, 172, 129, 207, 215, 136,
    172, 208, 173, 172, 172, 172, 136, 129, 172, 172, 166, 172,
    172, 112, 135, 147, 129, 171, 130, 129, 176, 131, 141, 208,
    115, 143, 82,  140, 50,  93,  129, 129, 57,  128, 165, 129,
    129, 57,  135, 137, 171, 129, 135, 93,  123, 123, 129, 129,
    87,  195, 129, 129, 129, 131, 57,  135, 141, 172, 171, 131,
    207, 165, 202, 177, 93,  167, 178, 135, 165, 124, 129, 177,
    136, 142, 143, 86,  129, 129, 129, 129, 129, 87,  165, 129,
    129, 129, 129, 129, 129, 129, 129, 129, 123, 129, 129, 129,
    129, 129, 21,
};
const charDivs = [3]u8{ 1, 6, 36 };

/// Printed width (1..6) of character code `c`, unpacked from the 3-per-byte table.
fn charlengths(c: u32) u32 {
    return (@as(u32, charWidths[c / 3]) / charDivs[c % 3]) % 6 + 1;
}

/// Fill `posns[0..=256]` with the cumulative left x-position of each character
/// code 0..255 (small font when `small`), each advancing by width - 1.
pub fn findLengths(posns: *[257]u16, small: bool) void {
    const mask: u32 = if (small) 256 else 0;
    posns[0] = 0;
    var i: u32 = 0;
    while (i < 256) : (i += 1) {
        posns[i + 1] = posns[i] + @as(u16, @intCast(charlengths(i + mask))) - 1;
    }
}

/// Total printed pixel width of the NUL-terminated string `s` (small font when
/// `small`). The INCLUDE_FONT_ESCAPE branch is dead for z47, so it is omitted.
pub fn pixelLength(s: [*:0]const u8, small: bool) c_int {
    var len: c_int = 0;
    const offset: u32 = if (small) 256 else 0;
    var p = s;
    while (p[0] != 0) : (p += 1) {
        len += @intCast(charlengths(@as(u32, p[0]) + offset));
    }
    return len;
}

// ---------------------------------------------------------------------------
// Native tests -- first coverage of the packed-width unpacking and the sums.
// ---------------------------------------------------------------------------
const testing = std.testing;

test "charlengths unpacks the 3-per-byte width table" {
    // charWidths[0] = 162: /1 %6 +1 = 1; /6 =27 %6 +1 = 4; /36 =4 %6 +1 = 5.
    try testing.expectEqual(@as(u32, 1), charlengths(0));
    try testing.expectEqual(@as(u32, 4), charlengths(1));
    try testing.expectEqual(@as(u32, 5), charlengths(2));
    // charWidths[1] = 143: /1 = 143 %6 +1 = 6.
    try testing.expectEqual(@as(u32, 6), charlengths(3));
    // Every width is in 1..6.
    var c: u32 = 0;
    while (c < 171 * 3) : (c += 1) {
        const w = charlengths(c);
        try testing.expect(w >= 1 and w <= 6);
    }
}

test "pixelLength sums the per-character widths" {
    try testing.expectEqual(@as(c_int, 0), pixelLength("", false));
    // "\x01\x02\x03" -> 4 + 5 + 6 = 15.
    try testing.expectEqual(@as(c_int, 15), pixelLength("\x01\x02\x03", false));
}

test "findLengths builds the cumulative (width-1) x positions" {
    var posns: [257]u16 = undefined;
    findLengths(&posns, false);
    try testing.expectEqual(@as(u16, 0), posns[0]);
    try testing.expectEqual(@as(u16, 0), posns[1]); // +charlengths(0)-1 = +0
    try testing.expectEqual(@as(u16, 3), posns[2]); // +charlengths(1)-1 = +3
    try testing.expectEqual(@as(u16, 7), posns[3]); // +charlengths(2)-1 = +4
    // Monotonic non-decreasing over the whole range.
    var i: usize = 1;
    while (i <= 256) : (i += 1) try testing.expect(posns[i] >= posns[i - 1]);
}
